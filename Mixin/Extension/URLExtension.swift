import Foundation

extension URL {
    
    static let blank = URL(string: "about:blank")!
    static let terms = URL(string: "https://mixin.one/pages/terms")!
    static let privacy = URL(string: "https://mixin.one/pages/privacy")!
    static let aboutEncryption = URL(string: "https://mixin.one/pages/1000007")!
    static let emergencyContact = URL(string: "https://mixinmessenger.zendesk.com/hc/articles/360029154692")!
    
    func getKeyVals() -> Dictionary<String, String>? {
        var results = [String: String]()
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems {
            for item in queryItems {
                results.updateValue(item.value ?? "", forKey: item.name)
            }
        }
        return results
    }

    var fileExists: Bool {
        return (try? self.checkResourceIsReachable()) ?? false
    }
    
    var fileSize: Int64 {
        return (try? self.resourceValues(forKeys: [.fileSizeKey]))?.allValues[.fileSizeKey] as? Int64 ?? -1
    }

    static func createTempUrl(fileExtension: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString.lowercased()).\(fileExtension)")
    }
}
