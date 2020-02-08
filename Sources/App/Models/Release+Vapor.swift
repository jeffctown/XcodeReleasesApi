//
//  Release+Vapor.swift
//  App
//
//  Created by Jeff Lett on 2/8/20.
//

import FluentSQLite
import Vapor
import XCModel

// MARK: - ReflectionDecodable
extension Release: ReflectionDecodable {
    public static func reflectDecodedIsLeft(_ item: Release) throws -> Bool {
        switch item {
        case .gm: return true
        default: return false
        }
    }
    
    public static func reflectDecoded() throws -> (Release, Release) {
        return (.gm, .gmSeed(0))
    }
}
