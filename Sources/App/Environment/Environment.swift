//
//  Environment.swift
//  App
//
//  Created by Jeff Lett on 7/4/19.
//

import Vapor

extension Environment {
    static var PUSH_CERTIFICATE_PATH: [PathComponentsRepresentable] {
        guard let path = Environment.get("PUSH_CERTIFICATE_PATH") else {
            return ["Push","Certificates","aps.pem"]
        }
        return [path]
    }
    
    static var PUSH_CERTIFICATE_PWD: String? {
        return Environment.get("PUSH_CERTIFICATE_PWD") ?? "password"
    }
    
    static var PUSH_DEV_CERTIFICATE_PATH: [PathComponentsRepresentable] {
        guard let path = Environment.get("PUSH_DEV_CERTIFICATE_PATH") else {
            return ["Push","Certificates","aps_development.pem"]
        }
        return [path]
    }
    
    static var PUSH_DEV_CERTIFICATE_PWD: String? {
        return Environment.get("PUSH_DEV_CERTIFICATE_PWD") ?? "password"
    }
    
    static var BUNDLE_IDENTIFIER: String? {
        return Environment.get("BUNDLE_IDENTIFIER")
    }
    
    static var LOG_PATH: [PathComponentsRepresentable] {
        return [Environment.get("LOG_PATH") ?? "Logs"]
    }
}
