import UIKit
import Alamofire
import IdensicMobileSDK
import MixinServices

class IdentityVerificationIntroViewController: IntroViewController {
    
    private var request: DataRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iconImageView.image = R.image.ic_identity_verification()
        titleLabel.text = "Identity Verification"
        descriptionTextLabel.text = "Financial regulations require us to verify your identity. To start verifying, you will allow us and our service provides can collect, use, and store your information. Before you star, please:"
        noticeTextView.attributedText = {
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 8
            style.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: [:])]
            style.defaultTabInterval = 15
            style.firstLineHeadIndent = 0
            style.headIndent = 13
            
            let noticeAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: R.color.text_accessory()!,
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .paragraphStyle: style,
            ]
            
            let notice = "•  " + "Prepare a valid government-issued ID"
            + "\n•  " + "Check if your device’s camera is uncovered and working"
            + "\n•  " + "Be prepared to take a selfie and photos of your ID"
            
            return NSAttributedString(string: notice, attributes: noticeAttributes)
        }()
        let disclamerLabel = {
            let text = "By proceeding, you agree to the Privacy Policy and Terms of Service."
            let label = TextLabel()
            label.backgroundColor = .background
            label.textColor = .accessoryText
            label.lineSpacing = 4
            label.linkColor = .theme
            label.detectLinks = false
            label.delegate = self
            label.text = text
            let privacyPolicyRange = (text as NSString).range(of: "Privacy Policy", options: [.backwards, .caseInsensitive])
            if privacyPolicyRange.location != NSNotFound && privacyPolicyRange.length != 0 {
                label.additionalLinksMap = [privacyPolicyRange: URL.blank] // TODO: Real link
            }
            let termsOfServiceRange = (text as NSString).range(of: "Terms of Service", options: [.backwards, .caseInsensitive])
            if termsOfServiceRange.location != NSNotFound && termsOfServiceRange.length != 0 {
                label.additionalLinksMap = [termsOfServiceRange: URL.blank] // TODO: Real link
            }
            return label
        }()
        contentStackView.addArrangedSubview(disclamerLabel)
        nextButton.setTitle("Start Verification", for: .normal)
        actionDescriptionLabel.isHidden = true
    }
    
    override func continueToNext(_ sender: RoundedButton) {
        sender.isBusy = true
        SumsubAPI.token(userID: myUserId) { [weak self] result in
            switch result {
            case let .success(.pending(token)):
                self?.presentSDKController(with: token)
            case .success(.success):
                if let self {
                    self.navigationController?.presentingViewController?.dismiss(animated: true)
                }
            case let .failure(error):
                self?.alert("Request failed", message: error.localizedDescription)
            }
        }
    }
    
    private func presentSDKController(with token: String) {
        guard let navigationController = navigationController as? IdentityVerificationNavigationController else {
            return
        }
        let sdk = SNSMobileSDK(accessToken: "")
        guard sdk.isReady else {
            alert("Sumsub is not ready", message: sdk.verboseStatus)
            return
        }
        sdk.setTokenExpirationHandler { onComplete in
            SumsubAPI.token(userID: myUserId) { result in
                switch result {
                case let .success(.pending(token)):
                    onComplete(token)
                default:
                    onComplete(nil)
                }
            }
        }
        sdk.setDismissHandler { sdk, controller in
            switch sdk.status {
            case .pending, .approved:
                navigationController.setViewControllers([IdentityVerificationSubmittedViewController()], animated: false)
                navigationController.dismiss(animated: true)
            case .ready, .initial, .incomplete:
                navigationController.dismiss(animated: true)
            case .actionCompleted, .failed, .finallyRejected, .temporarilyDeclined:
                navigationController.presentingViewController?.dismiss(animated: true)
            }
        }
        sdk.present(from: navigationController)
    }
    
}
