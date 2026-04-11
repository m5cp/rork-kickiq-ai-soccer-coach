import Foundation

enum ConfigHelper {
    static func value(forKey key: String) -> String {
        if let val = Config.allValues[key], !val.isEmpty {
            return val
        }
        if let val = Bundle.main.infoDictionary?[key] as? String, !val.isEmpty {
            return val
        }
        if let val = ProcessInfo.processInfo.environment[key], !val.isEmpty {
            return val
        }
        return ""
    }
}
