//
//  LinkController.swift
//  APNS
//
//  Created by Jeff Lett on 1/17/20.
//

import Vapor
import XCModel

final class LinkController {
    func index(_ req: Request) throws -> Future<[Link]> {
        let links = [
            Link("https://github.com/jeffctown/XcodeReleases", name: "Github"),
            Link("https://xcodereleases.jefflett.com/privacy/", name: "Privacy Policy"),
        ]
        return req.future(links)
    }
}
