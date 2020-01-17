//
//  XcodeRelease+Vapor.swift
//  App
//
//  Created by Jeff Lett on 7/13/19.
//

import APNS
import Foundation
import FluentSQLite
import Vapor
import XcodeReleasesKit

extension XcodeRelease: SQLiteModel { }
extension XcodeRelease: Migration { }
extension XcodeRelease: Content { }
extension XcodeRelease: Parameter { }
extension XcodeRelease: Hashable {
    
    var displayName: String {
        var display = "\(name)"
        if let number = version.number {
            display += " \(number)"
        }
        display += " \(version.release.description)"
        return display
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(version.build)
        hasher.combine(version.number)
        hasher.combine(requires)
        hasher.combine(links?.download?.url)
        hasher.combine(links?.notes?.url)
    }
    
    public func json() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(bytes: data, encoding: .utf8)!
    }
    
    public func payload() -> Payload {
        PayloadBuilder { builder in
            builder.title = "Just Released: \(self.displayName)!"
            builder.body = "\(self.displayName) is now available for download!\n\nTap here to read the release notes."
            if let url = self.links?.notes?.url {
                builder.extra["notes"] = url
                builder.extra["release"] = try! self.json()
            }
        }.build()
    }
}

extension Sequence where Element == XcodeRelease {
    func sortedByDate() -> [Element] {
        return self.sorted {
            guard let date0 = $0.date.dateComponents.date else {
                print("Failed To Create Date: \($0.date)")
                return false
            }
            guard let date1 = $1.date.dateComponents.date else {
                print("Failed To Create Date: \($1.date)")
                return false
            }
            return date0.compare(date1) == .orderedAscending
        }
    }
}
