import APNS
import APNSVapor
import Vapor

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ env: Environment) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()
    let vaporAPNS = try APNSVapor(certificates: certificates())
    try configure(&config, &env, &services, vaporAPNS: vaporAPNS)
    let app = try Application(config: config, environment: env, services: services)
    try vaporAPNS.validateFilesExist(container: app)
    try vaporAPNS.validatePasswords(container: app)
    try boot(app)
    return app
}

public func certificates() -> [APNSVapor.Certificate] {
    var certificates = [APNSVapor.Certificate]()
    certificates.append(APNSVapor.Certificate(environment: .release,
                                                     path: "/var/lib/xcodereleases/data/PushCert.pem",
                                                     bundleIdentifier: "com.jefflett.XcodeReleases"))
    certificates.append(APNSVapor.Certificate(environment: .development,
                                                     path: "/var/lib/xcodereleases/data/DevPushCert.pem",
                                                     bundleIdentifier: "com.jefflett.XcodeReleases"))
    certificates.append(APNSVapor.Certificate(environment: .release,
                                              path: "/var/lib/xcodereleases/data/WatchCertificates.pem",
                                              bundleIdentifier: "com.jefflett.XcodeReleases.watchkitapp.watchkitextension"))
    certificates.append(APNSVapor.Certificate(environment: .development,
                                              path: "/var/lib/xcodereleases/data/WatchCertificates.pem",
                                              bundleIdentifier: "com.jefflett.XcodeReleases.watchkitapp.watchkitextension"))
    return certificates
}
