
//
//  PushController.swift
//  App
//
//  Created by Jeff Lett on 7/4/19.
//

import APNS
import Vapor
import VaporAPNS
import XcodeReleasesKit

final class PushController {
    
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
                    logger.info("\(Date().description): \(newReleases.count) fetched \(existingReleases.count) existing \(diff.count) new")
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
        guard let release = releases.last else {
            throw Abort(.notModified)
        }
        
        let current = Date()
        guard release.date.year >= Calendar.current.component(.year, from: current),
            release.date.month >= Calendar.current.component(.month, from: current) else {
            print("Release From Previous Date?")
            throw Abort(.unprocessableEntity)
        }
        
        let payload = PayloadBuilder { builder in
            builder.title = "Just Released: \(release.displayName)!"
            builder.body = "\(release.displayName) is now available for download!\n\nTap here to read the release notes."
            if let url = release.links?.notes?.url {
                builder.extra["notes"] = url
            }
        }.build()
        let data = try JSONEncoder().encode(payload)
        let vaporAPNSHandler = VaporAPNS()
        return try vaporAPNSHandler.push(req, data)
    }
 
}


