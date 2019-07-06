import Vapor
import XcodeReleasesApiModel

final class DeviceController {
    
    func create(_ req: Request) throws -> Future<Device> {
        return try req.content.decode(Device.self).flatMap(to: Device.self) { device in
            return device.save(on: req)
        }
    }
    
    func read(_ req: Request) throws -> Future<Device> {
        return try req.parameters.next(Device.self)
    }
    
    func index(_ req: Request) throws -> Future<[Device]> {
        return Device.query(on: req).all()
    }
    
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Device.self).flatMap { device in
            return device.delete(on: req)
        }.transform(to: .ok)
    }
    
}
