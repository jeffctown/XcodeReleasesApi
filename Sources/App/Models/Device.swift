import FluentSQLite
import Vapor

final class Device: Codable {
    var id: Int?
    var type: String
    var token: String
    
    init(type: String, token: String) {
        self.type = type
        self.token = token
    }
    
    var records: Children<Device, PushRecord> {
        return children(\.deviceID)
    }
}

extension Device: SQLiteModel { }
extension Device: Migration { }
extension Device: Content { }
extension Device: Parameter { }
