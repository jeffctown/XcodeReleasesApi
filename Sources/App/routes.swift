import APNS
import APNSVapor
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, vaporAPNS: APNSVapor) throws {
    let deviceController = DeviceController()
    router.post("device", use: deviceController.create)
    router.get("device", Device.parameter, use: deviceController.read)
    router.get("device", use: deviceController.index)
    router.delete("device", Device.parameter, use: deviceController.delete)
    
    let pushController = PushController(vaporAPNS: vaporAPNS)
    router.get("push", use: pushController.refreshReleases)
    
    let pushRecordController = PushRecordController()
    router.get("pushrecord", Device.parameter, use: pushRecordController.read)
    router.get("pushrecord", use: pushRecordController.index)
    
    let xcodeReleaseController = XcodeController()
    router.get("release", use: xcodeReleaseController.index)
    
    let linkController = LinkController()
    router.get("link", use: linkController.index)
}
