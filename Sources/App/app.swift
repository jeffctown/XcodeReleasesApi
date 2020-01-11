import APNSVapor
import Vapor

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ env: Environment) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()
    let vaporAPNS = try APNSVapor()
    try configure(&config, &env, &services, vaporAPNS: vaporAPNS)
    let app = try Application(config: config, environment: env, services: services)
    try vaporAPNS.validateFilesExist(container: app)
    try vaporAPNS.validatePasswords(container: app)
    try boot(app)
    return app
}
