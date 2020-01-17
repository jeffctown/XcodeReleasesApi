//
//  LinkController.swift
//  APNS
//
//  Created by Jeff Lett on 1/17/20.
//

import Vapor
import XcodeReleasesKit

final class LinkController {
    func index(_ req: Request) throws -> Future<[Link]> {
        let links = [
            Link(url: "https://github.com/jeffctown/XcodeReleases/issues", name: "Suggestions"),
            Link(url: "https://github.com/jeffctown/XcodeReleases", name: "Github"),
            Link(url: "https://xcodereleases.jefflett.com/privacy/", name: "Privacy Policy"),
        ]
        return req.future(links)
    }
}
