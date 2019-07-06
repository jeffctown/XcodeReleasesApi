//
//  Device+Vapor.swift
//  App
//
//  Created by Jeff Lett on 7/5/19.
//

import Foundation
import FluentSQLite
import Vapor
import XcodeReleasesKit

extension Device {
    var records: Children<Device, PushRecord> {
        return children(\.deviceID)
    }
}

extension Device: SQLiteModel { }
extension Device: Migration { }
extension Device: Content { }
extension Device: Parameter { }
