//
//  XcodeController.swift
//  App
//
//  Created by Jeff Lett on 7/13/19.
//

import Vapor
import XCModel

final class XcodeController {
    func index(_ req: Request) throws -> Future<[Xcode]> {
        return Xcode.query(on: req).sort(\.id, .descending).all()
    }
}
