
//
//  PushController.swift
//  App
//
//  Created by Jeff Lett on 7/4/19.
//

import FluentSQL
import Vapor
import XcodeReleasesKit

final class PushController {
    
    func push(_ req: Request) throws -> Future<HTTPStatus> {
        let payload = APNSPayload()
        return Device.query(on: req).all().flatMap(to: Bool.self) { devices in
            devices.forEach {
                print("Pushing to \($0.token)")
                do {
                    _ = try self.pushToDevice($0, payload, req)
                } catch {
                    print("Error Pushing to Device Token \(error)")
                }
            }
            return req.future(true)
        }.flatMap(to: HTTPStatus.self) { success in
            return req.future(.ok)
        }
    }
        
    func pushToDevice(_ device: Device, _ payload: APNSPayload, _ req: Request) throws -> Future<PushRecord> {
        let payload = APNSPayload()
        payload.title = "New Xcode Release"
        payload.body = "Xcode v11.0 - Tap for Release Notes"
        
        let shell = try req.make(Shell.self)
        
        let workDir = DirectoryConfig.detect().workDir
        let certURL: URL
        let apnsURL: String
        let password: String
        
        if req.environment.isRelease {
            let filePath = Environment.PUSH_CERTIFICATE_PATH.convertToPathComponents().readable
            guard let path = URL(string: workDir)?.appendingPathComponent(filePath) else {
                throw Abort(.custom(code: 512, reasonPhrase: "APNS push certificate not found"))
            }
            guard let certPwd = Environment.PUSH_CERTIFICATE_PWD else {
                throw Abort(.custom(code: 512, reasonPhrase: "No $PUSH_CERTIFICATE_PWD set on environment. Use `export PUSH_CERTIFICATE_PWD=<password>`"))
            }
            certURL = path
            apnsURL = "https://api.push.apple.com/3/device/"
            password = certPwd
        } else {
            let filePath = Environment.PUSH_DEV_CERTIFICATE_PATH.convertToPathComponents().readable
            guard let path = URL(string: workDir)?.appendingPathComponent(filePath) else {
                throw Abort(.custom(code: 512, reasonPhrase: "APNS development push certificate not found"))
            }
            guard let certPwd = Environment.PUSH_DEV_CERTIFICATE_PWD else {
                throw Abort(.custom(code: 512, reasonPhrase: "No $PUSH_DEV_CERTIFICATE_PWD set on environment. Use `export PUSH_DEV_CERTIFICATE_PWD=<password>`"))
            }
            certURL = path
            apnsURL = "https://api.development.push.apple.com/3/device/"
            password = certPwd
        }
        
        guard let bundleId = Environment.BUNDLE_IDENTIFIER else {
            throw Abort(.custom(code: 512, reasonPhrase: "No $BUNDLE_IDENTIFIER set on environment. Use `export BUNDLE_IDENTIFIER=<identifier>`"))
        }
        
        let certPath = certURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        
        let content = APNSPayloadContent(payload: payload)
        let data = try JSONEncoder().encode(content)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw Abort(.custom(code: 512, reasonPhrase: "Invalid APNS payload"))
        }
        
        let arguments = ["-d", jsonString, "-H", "apns-topic:\(bundleId)", "-H", "apns-expiration: 1", "-H", "apns-priority: 10", "--http2-prior-knowledge", "--cert", "\(certPath):\(password)", apnsURL + device.token]
        
        return try shell.execute(commandName: "curl", arguments: arguments).flatMap(to: PushRecord.self) { data in
            guard data.count != 0 else {
                let record = PushRecord(payload: payload, status: .delivered, deviceID: device.id!)
                return record.save(on: req)
            }
            do {
                let decoder = JSONDecoder()
                let error = try decoder.decode(APNSError.self, from: data)
                let record = PushRecord(payload: payload, error: error, deviceID: device.id!)
                return record.save(on: req)
            } catch _ {
                let record = PushRecord(payload: payload, error: .unknown, deviceID: device.id!)
                return record.save(on: req)
            }
        }
        
    }
    
}


