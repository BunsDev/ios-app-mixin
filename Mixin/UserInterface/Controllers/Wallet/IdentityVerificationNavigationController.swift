import UIKit

class IdentityVerificationNavigationController: LoneBackButtonNavigationController {
    
    private let dismissButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.isHidden = true
        dismissButton.tintColor = R.color.icon_tint()
        dismissButton.setImage(R.image.ic_title_close(), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissAction(sender:)), for: .touchUpInside)
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.snp.makeConstraints { (make) in
            make.edges.equalTo(backButton)
        }
    }
    
    @objc func dismissAction(sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
