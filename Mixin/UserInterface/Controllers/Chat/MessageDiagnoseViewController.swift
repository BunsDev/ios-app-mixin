import UIKit
import MixinServices

class MessageDiagnoseViewController: UIViewController {
    
    static var isEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    @IBOutlet weak var textView: UITextView!
    
    private let messageId: String
    
    init(messageId: String) {
        self.messageId = messageId
        super.init(nibName: R.nib.messageDiagnoseView.name, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let message = MessageDAO.shared.getMessage(messageId: messageId)
        let messageRepresentation: String
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let message, let data = try? encoder.encode(message), let string = String(data: data, encoding: .utf8) {
            messageRepresentation = string
        } else {
            messageRepresentation = "(null)"
        }
        
        let expiration = ExpiredMessageDAO.shared.getExpiredMessage(with: messageId)
        let expirationRepresentation: String
        if let expiration {
            let expireAtRepresentation: String
            if let expireAt = expiration.expireAt {
                let date = Date(timeIntervalSince1970: TimeInterval(expireAt))
                expireAtRepresentation = Logger.dateFormatter.string(from: date)
            } else {
                expireAtRepresentation = "(null)"
            }
            expirationRepresentation = "expire_in: \(expiration.expireIn)\nexpire_at: \(expireAtRepresentation)"
        } else {
            expirationRepresentation = "(null)"
        }
        
        textView.text = "Message:\n\(messageRepresentation)\n\nExpiration:\n\(expirationRepresentation)"
    }
    
    @IBAction func copyText(_ sender: Any) {
        UIPasteboard.general.string = textView.text
        showAutoHiddenHud(style: .notification, text: R.string.localizable.copied())
    }
    
    @IBAction func close(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
}
