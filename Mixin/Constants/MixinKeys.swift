import Foundation

enum MixinKeys {
    
    static let keys: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Mixin-Keys", ofType: "plist") else {
            return [:]
        }
        return (NSDictionary(contentsOfFile: path) as? [String: Any]) ?? [:]
    }()
    
    static let reCaptcha = keys["ReCaptcha"] as? String
    static let giphy = keys["Giphy"] as? String
    
}
