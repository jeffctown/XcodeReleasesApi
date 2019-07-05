import Vapor

/// Controls basic CRUD operations on `Device`s.
final class DeviceController {
    
    /// Saves a decoded `Device` to the database.
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
    
    
//
//        router.get("users") { req -> Future<View> in
//        return Device.query(on: req).all()//.flatMap { devices in
//            return req.future(devices)
//        }
//    }
//            return User.query(on: req).all().flatMap { users in
//                let data = ["userlist": users]
//                return try req.view().render("userview", data)
//            }
//        }
//        }
//    }
    
}
