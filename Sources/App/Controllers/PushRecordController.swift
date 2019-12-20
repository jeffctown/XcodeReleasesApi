//
//  PushRecordController.swift
//  App
//
//  Created by Jeff Lett on 7/5/19.
//

import FluentSQL
import Vapor
import VaporAPNS
import XcodeReleasesKit

final class PushRecordController {
    
    func read(_ req: Request) throws -> Future<[PushRecord]> {
        return try req.parameters.next(Device.self).flatMap({ device in
            return try device.records.query(on: req).all()
        })
    }
    
}
