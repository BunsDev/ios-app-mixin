import UIKit

struct Payment {
    
    static let applePay = Payment(icon: R.image.wallet.apple_pay(), name: "Apple Pay", fee: "1.99%")
    static let creditCard = Payment(icon: nil, name: "Visa / Mastercard", fee: "1.99%")
    
    let icon: UIImage?
    let name: String
    let fee: String
    
}
