import Foundation

extension UserDefaults {
    func setCodable<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            set(encoded, forKey: key)
        }
    }
    
    func getCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = data(forKey: key),
           let decoded = try? JSONDecoder().decode(type, from: data) {
            return decoded
        }
        return nil
    }
} 