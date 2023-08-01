import Foundation

enum BuyLimit: CaseIterable {
    
    case unverified
    case verified
    
    var name: String {
        switch self {
        case .unverified:
            return "Unverified"
        case .verified:
            return "Identity Verification"
        }
    }
    
    var limit: String {
        switch self {
        case .unverified:
            return "$500 / week"
        case .verified:
            return "$5,000 / day"
        }
    }
    
    var description: String {
        switch self {
        case .unverified:
            return "Buy a little crypto as gas fee or for web3 dapps by Apple Pay."
        case .verified:
            return "Verify your identity to unlock more purchase restrictions"
        }
    }
    
}
