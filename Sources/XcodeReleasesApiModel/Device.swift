import Foundation

public final class Device: Codable {
    public var id: Int?
    public var type: String
    public var token: String
    
    public init(type: String, token: String) {
        self.type = type
        self.token = token
    }
    
}
