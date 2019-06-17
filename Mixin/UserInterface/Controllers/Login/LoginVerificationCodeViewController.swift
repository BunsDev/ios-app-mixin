import UIKit

class LoginVerificationCodeViewController: VerificationCodeViewController {
    
    var context: LoginContext!
    
    private lazy var backupAvailabilityQuery = BackupAvailabilityQuery()
    
    deinit {
        ReCaptchaManager.shared.clean()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let displayNumber = "+\(context.callingCode) \(context.mobileNumber)"
        titleLabel.text = Localized.NAVIGATION_TITLE_ENTER_VERIFICATION_CODE(mobileNumber: displayNumber)
    }
    
    override func verificationCodeFieldEditingChanged(_ sender: Any) {
        let code = verificationCodeField.text
        let codeCountMeetsRequirement = code.count == verificationCodeField.numberOfDigits
        continueButton.isHidden = !codeCountMeetsRequirement
        if !isBusy && codeCountMeetsRequirement {
            login()
        }
    }
    
    override func continueAction(_ sender: Any) {
        login()
    }
    
    override func requestVerificationCode(reCaptchaToken token: String?) {
        AccountAPI.shared.sendCode(to: context.fullNumber, reCaptchaToken: token, purpose: .session) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case let .success(verification):
                weakSelf.context.verificationId = verification.id
                weakSelf.context.hasEmergencyContact = verification.hasEmergencyContact
                weakSelf.resendButton.isBusy = false
                weakSelf.resendButton.beginCountDown(weakSelf.resendInterval)
            case let .failure(error):
                if error.code == 10005 {
                    ReCaptchaManager.shared.validate(onViewController: weakSelf) { (result) in
                        switch result {
                        case .success(let token):
                            self?.requestVerificationCode(reCaptchaToken: token)
                        default:
                            self?.resendButton.isBusy = false
                        }
                    }
                } else {
                    UIApplication.traceError(error)
                    weakSelf.alert(error.localizedDescription)
                    weakSelf.resendButton.isBusy = false
                }
            }
        }
    }
    
    func login() {
        isBusy = true
        guard let keyPair = KeyUtil.generateRSAKeyPair() else {
            UIApplication.trackError("KeyUtil", action: "generateRSAKeyPair failed")
            isBusy = false
            return
        }
        let code = verificationCodeField.text
        let registrationId = Int(SignalProtocol.shared.getRegistrationId())
        login(code: code, registrationId: registrationId, keyPair: keyPair)
    }
    
    func login(code: String, registrationId: Int, keyPair: KeyUtil.RSAKeyPair) {
        let request = AccountRequest.createAccountRequest(verificationCode: code, registrationId: registrationId, pin: nil, sessionSecret: keyPair.publicKey)
        AccountAPI.shared.login(verificationId: context.verificationId, accountRequest: request, completion: { [weak self] (result) in
            DispatchQueue.global().async {
                self?.handleLoginResult(result, privateKeyPem: keyPair.privateKeyPem)
            }
        })
    }
    
    func handleLoginResult(_ result: APIResult<Account>, privateKeyPem: String) {
        switch result {
        case let .success(account):
            let pinToken = KeyUtil.rsaDecrypt(pkString: privateKeyPem, sessionId: account.session_id, pinToken: account.pin_token)
            AccountUserDefault.shared.storePinToken(pinToken: pinToken)
            AccountUserDefault.shared.storeToken(token: privateKeyPem)
            AccountAPI.shared.account = account
            
            let sema = DispatchSemaphore(value: 0)
            var backupExist = false
            DispatchQueue.main.sync {
                let voipToken = UIApplication.appDelegate().voipToken
                if !voipToken.isEmpty {
                    AccountAPI.shared.updateSession(deviceToken: "", voip_token: voipToken)
                }
                self.backupAvailabilityQuery.fileExist(callback: { (exist) in
                    backupExist = exist
                    sema.signal()
                })
            }
            sema.wait()
            if CommonUserDefault.shared.hasForceLogout || !backupExist {
                CommonUserDefault.shared.hasForceLogout = false
                MixinDatabase.shared.configure(reset: true)
                UserDAO.shared.updateAccount(account: account)
                DispatchQueue.main.sync {
                    if account.full_name.isEmpty {
                        let vc = UsernameViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        ContactAPI.shared.syncContacts()
                        AppDelegate.current.window?.rootViewController = makeInitialViewController()
                    }
                }
            } else {
                DispatchQueue.main.sync {
                    AccountUserDefault.shared.hasRestoreChat = true
                    AccountUserDefault.shared.hasRestoreFilesAndVideos = true
                    AppDelegate.current.window?.rootViewController = makeInitialViewController()
                }
            }
        case let .failure(error):
            DispatchQueue.main.sync {
                self.handleVerificationCodeError(error)
            }
        }
    }
    
}
