
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
                    var diffSet = Set(newReleases)
                    diffSet.subtract(existingReleases)
                    let diff = Array(diffSet).sortedByDate()
                    logger.info("\(Date().description): \(newReleases.count) fetched \(existingReleases.count) existing \(diff.count) new")
                    _ = diff.map {
                        $0.save(on: req)
                    }
                    return try self.announce(req, releases: diff)
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


