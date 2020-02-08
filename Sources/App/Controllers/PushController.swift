
//
//  PushController.swift
//  App
//
//  Created by Jeff Lett on 7/4/19.
//

import APNS
import APNSVapor
import Vapor
import XCModel

final class PushController {
    
    let vaporAPNS: APNSVapor
    
    init(vaporAPNS: APNSVapor) {
        self.vaporAPNS = vaporAPNS
    }
    
    func refreshReleases(_ req: Request) throws -> Future<[PushRecord]> {
        let url = "https://xcodereleases.com/data.json"
        let client = try req.make(Client.self)
        let getReleases = client.get(url)
        let logger = try req.make(Logger.self)
        
        return getReleases.flatMap(to: [PushRecord].self) { response in
            return try response.content.decode([Xcode].self).flatMap({ (newReleases) -> EventLoopFuture<[PushRecord]> in
                return Xcode.query(on: req).all().flatMap { (existingReleases) -> EventLoopFuture<[PushRecord]> in
                    let diff = existingReleases.diff(with: newReleases)
                    let announcements = diff.filterReleases(before: existingReleases.first)
                    logger.info("\(Date().description): \(newReleases.count) fetched \(existingReleases.count) existing \(diff.count) new")
                    _ = existingReleases.map {
                        $0.delete(force: true, on: req)
                    }
                    _ = newReleases.reversed().map {
                        $0.save(on: req)
                    }
                    return try self.announce(req, releases: announcements)
                }
            })
        }
    }
    
    private func announce(_ req: Request, releases: [Xcode]) throws -> Future<[PushRecord]> {
        let logger = try req.make(Logger.self)
        logger.info("Announcing \(releases.count) new releases.")
        guard let release = releases.last else {
            throw Abort(.notModified)
        }
        return try vaporAPNS.push(req: req, encodable: release)
    }
 
}

extension Sequence where Element == Xcode {
    func filterReleases(before release: Xcode?) -> [Xcode] {
        guard let release = release else {
            return self as! [Xcode]
        }
        
        return self.filter { (xcode) -> Bool in
            xcode.date.year >= release.date.year &&
                xcode.date.month >= release.date.month &&
                xcode.date.day >= release.date.day
        }
    }
    
    func diff(with newReleases: [Xcode]) -> [Xcode] {
        Array(Set(newReleases).subtracting(self))
    }
}

