import FluentSQLite
import Vapor

public final class PushRecord: Codable {
    
    public static var path: [PathComponentsRepresentable] {
        return ["push"]
    }
    
    public enum DeliveryStatus: Int, Codable {
        case delivered = 1
        case deliveryFailed = 0
    }
    
    // MARK: - Properties
    
    public var id: Int?
    public var deviceID: Int
    public var createdAt: Date?
    public var updatedAt: Date?
    public var deletedAt: Date?
    public var payload: APNSPayload
    public var status: DeliveryStatus
    public var error: String?
    
    // MARK: - Initialization
    
    public init(payload: APNSPayload, status: DeliveryStatus, deviceID: Int, date: Date = Date()) {
        self.payload = payload
        self.status = status
        self.deviceID = deviceID
        self.createdAt = date
    }
    
    public init(payload: APNSPayload, error: APNSError, deviceID: Int, date: Date = Date()) {
        self.payload = payload
        self.status = .deliveryFailed
        self.error = error.rawValue
        self.deviceID = deviceID
        self.createdAt = date
    }
    
}

extension PushRecord: SQLiteModel { }
extension PushRecord: Migration { }
extension PushRecord: Content { }
extension PushRecord: Parameter { }
