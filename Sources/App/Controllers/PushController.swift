
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
    
    func announce(_ req: Request) throws -> Future<[PushRecord]> {
        let payload = APNSPayload()
        payload.title = "New Xcode Release"
        payload.body = "Xcode v11.0 - Tap for Release Notes"
        return try push(req, payload)
    }
    
    func announce(_ req: Request, release: XcodeRelease) throws -> Future<[PushRecord]> {
        let payload = APNSPayload()
        payload.title = "New Xcode Release: \(release.name) \(release.version)"
        payload.body = "Xcode v\(release.version) is now available for download.  Tap to read the release notes."
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
        
        //curl -X POST -d @Push.json --http2 --cert /var/www/vapor/PushCert.pem https://api.development.push.apple.com/3/device/98c9eef814b1cb501ab6af6732016d8e7bbc4d29898a456fa0abada741aa57c3
//        linux!!  let arguments = ["-d", "'\(jsonString)'", "-H", "apns-topic:\(bundleId)", "-H", "apns-expiration: 1", "-H", "apns-priority: 10", "--http2-prior-knowledge", "--cert", "\(certPath):\(password)", messagingBehavior.url + device.token]
        // MAC!! curl -d '{"aps":{"alert":{"title":"New Xcode Release","body":"Xcode v11.0 - Tap for Release Notes"},"contentAvailable":false,"hasMutableContent":false},"extra":{}}' -H apns-topic:com.jefflett.XcodeReleases -H apns-priority: 10 --http2-prior-knowledge --cert /Users/jeff/Documents/XcodeReleases/DevPushCert.pem: https://api.development.push.apple.com/3/device/98c9eef814b1cb501ab6af6732016d8e7bbc4d29898a456fa0abada741aa57c3

        let arguments = ["-d", "\(jsonString)", "-H", "apns-topic:\(bundleId)", "-H", "apns-priority: 10", "--http2-prior-knowledge", "--cert", "\(certPath):\(password)", messagingBehavior.url + device.token]
        //logger.info(arguments.joined(separator: " "))
        
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


