import UIKit

class IdentityVerificationSubmittedViewController: IntroViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iconImageView.image = R.image.identity_verifying()
        titleLabel.text = "Identity Verifying"
        descriptionTextLabel.text = "Your identity is being verified. We will send you message on once your verification has completed by Mixin Messenger."
        noticeTextView.isHidden = true
        nextButton.isHidden = true
        actionDescriptionLabel.text = "Most people get verified within a few minutes, thank you for your patience."
    }
    
}
