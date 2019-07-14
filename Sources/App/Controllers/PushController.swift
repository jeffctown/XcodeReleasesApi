
//
//  PushController.swift
//  App
//
//  Created by Jeff Lett on 7/4/19.
//

import FluentSQL
import Vapor
import XcodeReleasesKit

protocol PushControllerMessagingBehavior {
    var url: String { get }
    var certPath: String { get }
    var errorNoCert: String { get }
    var password: String? { get }
    var errorNoPassword: String { get }
}

final class PushController {
    
    private struct DebugControllerBehavior: PushControllerMessagingBehavior {
        let url: String = "https://api.development.push.apple.com/3/device/"
        let certPath: String = Environment.PUSH_DEV_CERTIFICATE_PATH.convertToPathComponents().readable
        let errorNoCert: String = "APNS development push certificate not found. Use `export PUSH_DEV_CERTIFICATE_PATH=<path>`"
        let password: String? = Environment.PUSH_DEV_CERTIFICATE_PWD
        let errorNoPassword: String = "No $PUSH_DEV_CERTIFICATE_PWD set on environment. Use `export PUSH_DEV_CERTIFICATE_PWD=<password>`"
    }
    
    private struct ReleaseControllerBehavior: PushControllerMessagingBehavior {
        let url: String = "https://api.push.apple.com/3/device/"
        let certPath: String = Environment.PUSH_CERTIFICATE_PATH.convertToPathComponents().readable
        var errorNoCert: String = "APNS push certificate not found. Use `export PUSH_CERTIFICATE_PATH=<path>`"
        var password: String? = Environment.PUSH_CERTIFICATE_PWD
        var errorNoPassword: String = "No $PUSH_CERTIFICATE_PWD set on environment. Use `export PUSH_CERTIFICATE_PWD=<password>`"
    }
    
    func refreshReleases(_ req: Request) throws -> Future<[PushRecord]> {
        let url = "https://xcodereleases.com/data.json"
        let client = try req.make(Client.self)
        let response = client.get(url)
        let logger = try req.make(Logger.self)
        
        return response.flatMap(to: [PushRecord].self) { response in
            return try response.content.decode([XcodeRelease].self).flatMap({ (newReleases) -> EventLoopFuture<[PushRecord]> in
                return XcodeRelease.query(on: req).all().flatMap { (existingReleases) -> EventLoopFuture<[PushRecord]> in
                    var diffSet = Set(newReleases)
                    diffSet.subtract(existingReleases)
                    let diff = Array(diffSet).sortedByDate()
                    logger.info("\(newReleases.count) fetched \(existingReleases.count) existing \(diff.count) new")
                    _ = diff.map {
                        $0.save(on: req)
                    }
                    return try self.announce(req, releases: diff)
                }
            })
        }
    }
    
    private func announce(_ req: Request, releases: [XcodeRelease]) throws -> Future<[PushRecord]> {
        let logger = try req.make(Logger.self)
        logger.info("Announcing \(releases.count) new releases.")
        let payload = APNSPayload()
        guard let release = releases.last else {
            throw Abort(.notModified)
        }
        payload.title = "Just Released: \(release.displayName)!"
        payload.body = "\(release.displayName) is now available for download!\n\nTap here to read the release notes."
        if let url = release.links?.notes?.url {
            payload.extra["notes"] = url
        }
        return try push(req, payload)
    }
    
    private func messagingBehavior(for req: Request) -> PushControllerMessagingBehavior {
        req.environment.isRelease ? ReleaseControllerBehavior() : DebugControllerBehavior()
    }
    
    private func push(_ req: Request, _ payload: APNSPayload) throws -> Future<[PushRecord]> {
        let logger = try req.make(Logger.self)
        return Device.query(on: req).all().flatMap(to: [PushRecord].self) { devices in
            logger.info("Sending Push to \(devices.count) devices.")
            logger.info("Payload: \(payload)")
            return devices.compactMap {
                logger.info("Pushing to \($0.token)")
                do {
                    return try self.pushToDevice($0, payload, req)
                } catch {
                    logger.error("Error Pushing to Device Token \(error)")
                }
                return nil
            }.flatten(on: req)
        }
    }
        
    private func pushToDevice(_ device: Device, _ payload: APNSPayload, _ req: Request) throws -> Future<PushRecord> {
        let logger = try req.make(Logger.self)
        let shell = try req.make(Shell.self)
        
        let workDir = DirectoryConfig.detect().workDir
        let messagingBehavior = self.messagingBehavior(for: req)
        
        guard let certURL = URL(string: workDir)?.appendingPathComponent(messagingBehavior.certPath) else {
            logger.error(messagingBehavior.errorNoCert)
            throw Abort(.custom(code: 512, reasonPhrase: messagingBehavior.errorNoCert))
        }
        guard let password = messagingBehavior.password else {
            logger.error(messagingBehavior.errorNoPassword)
            throw Abort(.custom(code: 512, reasonPhrase: messagingBehavior.errorNoPassword))
        }
        guard let bundleId = Environment.BUNDLE_IDENTIFIER else {
            let errorMessage = "No $BUNDLE_IDENTIFIER set on environment. Use `export BUNDLE_IDENTIFIER=<identifier>`"
            logger.error(errorMessage)
            throw Abort(.custom(code: 512, reasonPhrase: errorMessage))
        }
        
        let certPath = certURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        let content = APNSPayloadContent(payload: payload)
        let data = try JSONEncoder().encode(content)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            let errorMessage = "Invalid APNS payload"
            logger.error(errorMessage)
            throw Abort(.custom(code: 512, reasonPhrase: errorMessage))
        }
        
        let arguments = ["-d", "\(jsonString)", "-H", "apns-topic:\(bundleId)", "-H", "apns-priority: 10", "--http2-prior-knowledge", "--cert", "\(certPath):\(password)", messagingBehavior.url + device.token]
        logger.debug(arguments.joined(separator: " "))
        
        return try shell.execute(commandName: "curl", arguments: arguments).flatMap(to: PushRecord.self) { data in
            guard data.count != 0 else {
                let record = PushRecord(payload: payload, status: .delivered, deviceID: device.id!)
                return record.save(on: req)
            }
            do {
                let decoder = JSONDecoder()
                let error = try decoder.decode(APNSError.self, from: data)
                logger.error(error.rawValue)
                let record = PushRecord(payload: payload, error: error, deviceID: device.id!)
                return record.save(on: req)
            } catch _ {
                let errorMessage = String(data: data, encoding: .utf8)
                logger.error("Unknown Error Parsing Curl Error. \(errorMessage ?? "nil") \(data.count)")
                let record = PushRecord(payload: payload, error: .unknown, deviceID: device.id!)
                return record.save(on: req)
            }
        }
    }
}


