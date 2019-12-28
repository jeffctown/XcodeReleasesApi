import Vapor
import VaporAPNS

final class DeviceController {
    
    func create(_ req: Request) throws -> Future<Device> {
        return try req.content.decode(Device.self).flatMap(to: Device.self) { device in
            return Device.query(on: req)
                .filter(\Device.token, .equal, device.token)
                .filter(\Device.environment, .equal, device.environment)
                .first()
                .flatMap { (existing) -> EventLoopFuture<Device> in
                if let existingDevice = existing {
                    existingDevice.type = device.type
                    existingDevice.environment = device.environment
                    return existingDevice.update(on: req)
                } else {
                    return device.save(on: req)
                }
            }
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
