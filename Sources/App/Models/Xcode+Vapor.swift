//
//  Xcode+Vapor.swift
//  App
//
//  Created by Jeff Lett on 7/13/19.
//

import APNS
import APNSVapor
import Foundation
import FluentSQLite
import Vapor
import XCModel

// MARK: - Fluent
extension Xcode: Migration { }
extension Xcode: SQLiteModel {
    public typealias ID = Int
}

// MARK: - Vapor
extension Xcode: Content { }
extension Xcode: Parameter { }

// MARK: - APNSVaporEncodable
extension Xcode: APNSVaporEncodable {
    public func payload() -> Payload {
        PayloadBuilder { builder in
            builder.title = "Just Released: \(self)!"
            builder.body = "\(self) is now available for download!"
            builder.extra["release"] = try! self.json()
            if let url = self.links?.notes?.url {
                builder.extra["notes"] = url.absoluteString
            }
            
        }.build()
    }
    
    public func payloadForComplication() -> Payload {
        PayloadBuilder { builder in
            builder.extra["release"] = try! self.json()
            if let url = self.links?.notes?.url {
                builder.extra["notes"] = url.absoluteString
            }
        }.build()
    }
    
    public func json() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(bytes: data, encoding: .utf8)!
    }
}
