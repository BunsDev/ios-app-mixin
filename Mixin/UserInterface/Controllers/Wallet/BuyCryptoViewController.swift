import UIKit
import PassKit
import Frames
import Checkout3DS
import MixinServices

class BuyCryptoViewController: KeyboardBasedLayoutViewController {
    
    @IBOutlet weak var cryptoView: AssetComboBoxView!
    @IBOutlet weak var paymentView: ImageComboBoxView!
    @IBOutlet weak var amountTextField: InsetTextField!
    @IBOutlet weak var paymentCurrencyView: ImageComboBoxView!
    @IBOutlet weak var payButtonContainerView: UIView!
    
    @IBOutlet weak var payButtonContainerBottomConstraint: NSLayoutConstraint!
    
    private var asset: AssetItem?
    
    init(asset: AssetItem?) {
        self.asset = asset
        let nib = R.nib.buyCryptoView
        super.init(nibName: nib.name, bundle: nib.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not supported")
    }
    
    static func buy(asset: AssetItem?, on viewController: UIViewController) {
        let selector = BuyLimitSelectorViewController()
        selector.onSelected = { (limit) in
            switch limit {
            case .unverified:
                let intro = IdentityVerificationIntroViewController()
                let navigation = IdentityVerificationNavigationController(rootViewController: intro)
                viewController.dismiss(animated: true) {
                    viewController.present(navigation, animated: true)
                }
            case .verified:
                let buy = BuyCryptoViewController(asset: asset)
                let container = ContainerViewController.instance(viewController: buy, title: "Buy CNB")
                viewController.navigationController?.pushViewController(container, animated: true)
            }
        }
        viewController.present(selector, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let asset {
            cryptoView.load(asset: asset)
            cryptoView.button.isUserInteractionEnabled = true
            cryptoView.accessoryImageView.isHidden = false
        } else {
            cryptoView.button.isUserInteractionEnabled = false
            DispatchQueue.global().async {
                let asset = AssetDAO.shared.getDefaultTransferAsset() ?? .xin
                DispatchQueue.main.async {
                    self.cryptoView.load(asset: asset)
                    self.cryptoView.button.isUserInteractionEnabled = true
                    self.cryptoView.accessoryImageView.isHidden = false
                }
            }
        }
        cryptoView.button.addTarget(self, action: #selector(selectAsset(_:)), for: .touchUpInside)
        
        paymentView.titleLabel.text = "Visa / Mastercard"
        paymentView.subtitleLabel.text = "Gateway Fee: 1.99%"
        if PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard]) {
            paymentView.accessoryImageView.isHidden = false
            paymentView.button.addTarget(self, action: #selector(selectPayment(_:)), for: .touchUpInside)
        } else {
            paymentView.accessoryImageView.isHidden = true
            paymentView.button.removeTarget(self, action: nil, for: .touchUpInside)
        }
        
        paymentCurrencyView.accessoryImageView.isHidden = false
        paymentCurrencyView.button.addTarget(self, action: #selector(selectPaymentCurrency(_:)), for: .touchUpInside)
        
        let continueButton = RoundedButton()
        continueButton.setTitle(R.string.localizable.continue(), for: .normal)
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 26, bottom: 0, right: 26)
        payButtonContainerView.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.center.equalToSuperview()
        }
        continueButton.addTarget(self, action: #selector(payWithCard(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func layout(for keyboardFrame: CGRect) {
        payButtonContainerBottomConstraint.constant = keyboardFrame.height
        view.layoutIfNeeded()
    }
    
    @objc private func selectAsset(_ sender: Any) {
        
    }
    
    @objc private func selectPayment(_ sender: Any) {
        let selector = PaymentSelectorViewController(payments: [.applePay, .creditCard], selectedIndex: 0)
        selector.onSelected = { payment in
            
        }
        present(selector, animated: true)
    }
    
    @objc private func selectPaymentCurrency(_ sender: Any) {
        
    }
    
    @objc private func payWithCard(_ sender: Any) {
        let config = PaymentFormConfiguration(apiKey: MixinKeys.frames,
                                              environment: .sandbox,
                                              supportedSchemes: [.visa, .mastercard],
                                              billingFormData: nil)
        let style = PaymentStyle(paymentFormStyle: MixinPaymentFormStyle(),
                                 billingFormStyle: MixinBillingFormStyle())
        let frames = PaymentFormFactory.buildViewController(configuration: config, style: style) { result in
            switch result {
            case .success(let detail):
                self.placeOrder(with: detail.token)
            case .failure(let error):
                print(error)
            }
        }
        frames.title = "Pay with Card"
        frames.navigationItem.standardAppearance = HomeNavigationController.navigationBarAppearance()
        navigationController?.pushViewController(frames, animated: true)
        
        let request = PKPaymentRequest()
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Exchange", amount: NSDecimalNumber(value: 1), type: .final),
            PKPaymentSummaryItem(label: "Fee", amount: NSDecimalNumber(value: 0.2), type: .final),
        ]
        request.merchantIdentifier = "merchant.one.mixin.messenger.checkout.sandbox"
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.supportedNetworks = [.visa, .masterCard]
        request.shippingType = .servicePickup
        
        let authorization = PKPaymentAuthorizationController(paymentRequest: request)
        authorization.delegate = self
        authorization.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
            }
        })
        
    }
    
    private func reloadViews(with asset: AssetItem) {
        cryptoView.load(asset: asset)
    }
    
    private func placeOrder(with token: String) {
        let request = CheckoutAPI.Request(token: token,
                                          currency: "USD",
                                          userID: myUserId,
                                          amount: 100,
                                          assetID: "965e5c6e-434c-3fa9-b780-c50f43cd955c")
        CheckoutAPI.payment(request: request) { result in
            print(result)
        }
    }
    
}

extension BuyCryptoViewController: PKPaymentAuthorizationControllerDelegate {
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
    
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        let checkout = CheckoutAPIService(publicKey: MixinKeys.frames, environment: .sandbox)
        let paymentData = payment.token.paymentData
        checkout.createToken(.applePay(ApplePay(tokenData: paymentData))) { result in
            switch result {
            case .success(let details):
                print(details.token, details.scheme, details.issuerCountry)
//                let request = CheckoutAPI.Request(token: details.token,
//                                                  currency: "USD",
//                                                  userID: myUserId,
//                                                  amount: 100,
//                                                  assetID: "965e5c6e-434c-3fa9-b780-c50f43cd955c")
//                CheckoutAPI.payment(request: request) { result in
//                    switch result {
//                    case .success(let traceID):
//                        print(traceID)
//                        completion(.init(status: .success, errors: nil))
//                    case .failure(let error):
//                        completion(.init(status: .failure, errors: [error]))
//                    }
//                }
            case .failure(let request):
                completion(.init(status: .failure, errors: [request]))
            }
        }
    }
    
}

fileprivate enum PaymentColor {
    static let mainFontColor: UIColor = .text
    static let secondaryFontColor: UIColor = R.color.text_desc()!
    static let errorColor: UIColor = .mixinRed
    static let backgroundColor: UIColor = .background
    static let textFieldBackgroundColor: UIColor = R.color.background_input()!
    static let borderRadius: CGFloat = 8
    static let borderWidth: CGFloat = 0
}

struct MixinPaymentFormStyle: PaymentFormStyle {
    var backgroundColor: UIColor = PaymentColor.backgroundColor
    var headerView: PaymentHeaderCellStyle = StyleOrganiser.PaymentHeaderViewStyle()
    var addBillingSummary: CellButtonStyle? = StyleOrganiser.BillingStartButton()
    var editBillingSummary: BillingSummaryViewStyle? = StyleOrganiser.BillingSummaryStyle()
    var cardholderInput: CellTextFieldStyle?
    var cardNumber: CellTextFieldStyle = StyleOrganiser.CardNumberSection()
    var expiryDate: CellTextFieldStyle = StyleOrganiser.ExpiryDateSection()
    var securityCode: CellTextFieldStyle? = StyleOrganiser.SecurityNumberSection()
    var payButton: ElementButtonStyle = StyleOrganiser.PayButtonStyle()
}

struct MixinBillingFormStyle: BillingFormStyle {
    var mainBackground: UIColor = PaymentColor.backgroundColor
    var header: BillingFormHeaderCellStyle = StyleOrganiser.BillingHeaderViewStyle()
    var cells: [BillingFormCell] = [
        .fullName(StyleOrganiser.BillingFullNameInput()),
        .addressLine1(StyleOrganiser.BillingAddressLine1Input()),
        .addressLine2(StyleOrganiser.BillingAddressLine2Input()),
        .city(StyleOrganiser.BillingCityInput()),
        .state(StyleOrganiser.BillingStateInput()),
        .postcode(StyleOrganiser.BillingPostcodeInput()),
        .country(StyleOrganiser.BillingCountryInput()),
        .phoneNumber(StyleOrganiser.BillingPhoneInput())
    ]
}

private enum StyleOrganiser {
    
    struct PaymentHeaderViewStyle: PaymentHeaderCellStyle {
        var shouldHideAcceptedCardsList = true
        var backgroundColor: UIColor = PaymentColor.backgroundColor
        var headerLabel: ElementStyle? = PaymentHeaderLabel()
        var subtitleLabel: ElementStyle? = PaymentHeaderSubtitle()
        var schemeIcons: [UIImage?] = []
    }
    
    struct BillingHeaderViewStyle: BillingFormHeaderCellStyle {
        var backgroundColor: UIColor = .clear
        var headerLabel: ElementStyle = BillingHeaderLabel()
        var cancelButton: ElementButtonStyle = CancelButtonStyle()
        var doneButton: ElementButtonStyle = DoneButtonStyle()
    }
    
    struct BillingHeaderLabel: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var isHidden = false
        var text: String = "Billing address"
        var font: UIFont = .systemFont(ofSize: 24, weight: .semibold)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct PayButtonStyle: ElementButtonStyle {
        var image: UIImage?
        var textAlignment: NSTextAlignment = .center
        var text: String = R.string.localizable.continue()
        var font = UIFont.systemFont(ofSize: 15)
        var disabledTextColor: UIColor = R.color.button_text_disabled()!
        var disabledTintColor: UIColor = R.color.icon_tint_disabled()!
        var activeTintColor: UIColor = PaymentColor.mainFontColor
        var backgroundColor: UIColor = R.color.theme()!
        var textColor: UIColor = .white
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = .clear
        var imageTintColor: UIColor = .clear
        var isHidden = false
        var isEnabled = true
        var height: Double = 56
        var width: Double = 0
        var cornerRadius: CGFloat = 10
        var borderWidth: CGFloat = 0
        var textLeading: CGFloat = 0
    }
    
    struct CancelButtonStyle: ElementButtonStyle {
        var textAlignment: NSTextAlignment = .natural
        var isEnabled = true
        var disabledTextColor: UIColor = PaymentColor.secondaryFontColor
        var disabledTintColor: UIColor = .clear
        var activeTintColor: UIColor = .clear
        var imageTintColor: UIColor = .clear
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = .clear
        var image: UIImage?
        var textLeading: CGFloat = 0
        var cornerRadius: CGFloat = PaymentColor.borderRadius
        var borderWidth: CGFloat = PaymentColor.borderWidth
        var height: Double = 60
        var width: Double = 70
        var isHidden = false
        var text: String = R.string.localizable.cancel()
        var font: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct DoneButtonStyle: ElementButtonStyle {
        var textAlignment: NSTextAlignment = .natural
        var isEnabled = true
        var disabledTextColor: UIColor = PaymentColor.secondaryFontColor
        var disabledTintColor: UIColor = .clear
        var activeTintColor: UIColor = .clear
        var imageTintColor: UIColor = .clear
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = .clear
        var image: UIImage?
        var textLeading: CGFloat = 0
        var cornerRadius: CGFloat = PaymentColor.borderRadius
        var borderWidth: CGFloat = PaymentColor.borderWidth
        var height: Double = 60
        var width: Double = 70
        var isHidden = false
        var text: String = R.string.localizable.done()
        var font: UIFont = .systemFont(ofSize: 17, weight: .semibold)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct PaymentHeaderLabel: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var isHidden = false
        var text: String = "Payment details"
        var font: UIFont = .systemFont(ofSize: 24)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct PaymentHeaderSubtitle: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var isHidden = false
        var text: String = "Visa, Mastercard and Maestro accepted."
        var font: UIFont = .systemFont(ofSize: 12)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct CardNumberSection: CellTextFieldStyle {
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var textfield: ElementTextFieldStyle = TextFieldStyle()
        var title: ElementStyle? = TitleStyle(text: "Card number")
        var mandatory: ElementStyle? = MandatoryStyle(text: "")
        var hint: ElementStyle?
        var error: ElementErrorViewStyle? = ErrorViewStyle(text: "Insert a valid card number")
    }
    
    struct ExpiryDateSection: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(placeholder: "_ _ / _ _")
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Expiry date")
        var mandatory: ElementStyle? = MandatoryStyle(text: "")
        var hint: ElementStyle?
        var error: ElementErrorViewStyle? = ErrorViewStyle(text: "Insert a valid expiry date")
    }
    
    struct SecurityNumberSection: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle()
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Security code")
        var mandatory: ElementStyle? = MandatoryStyle(text: "")
        var hint: ElementStyle?
        var error: ElementErrorViewStyle? = ErrorViewStyle(text: "Insert a valid security code")
    }
    
    struct TextFieldStyle: ElementTextFieldStyle {
        var textAlignment: NSTextAlignment = .natural
        var text: String = ""
        var isSupportingNumericKeyboard = true
        var height: Double = 56
        var cornerRadius: CGFloat = PaymentColor.borderRadius
        var borderWidth: CGFloat = PaymentColor.borderWidth
        var placeholder: String?
        var tintColor: UIColor = PaymentColor.mainFontColor
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = PaymentColor.errorColor
        var isHidden = false
        var font: UIFont = .systemFont(ofSize: 15)
        var backgroundColor: UIColor = PaymentColor.textFieldBackgroundColor
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct TitleStyle: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var text: String
        var isHidden = false
        var font: UIFont = .systemFont(ofSize: 15)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct MandatoryStyle: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var text: String
        var isHidden = false
        var font: UIFont = .systemFont(ofSize: 13)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.secondaryFontColor
    }
    
    struct SubtitleElementStyle: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var text: String
        var textColor: UIColor = PaymentColor.secondaryFontColor
        var backgroundColor: UIColor = .clear
        var tintColor: UIColor = PaymentColor.mainFontColor
        var image: UIImage?
        var height: Double = 30
        var isHidden = false
        var font: UIFont = .systemFont(ofSize: 13)
    }
    
    struct ErrorViewStyle: ElementErrorViewStyle {
        var textAlignment: NSTextAlignment = .natural
        var text: String
        var textColor: UIColor = PaymentColor.errorColor
        var backgroundColor: UIColor = .clear
        var tintColor: UIColor = PaymentColor.errorColor
        var image: UIImage?
        var height: Double = 30
        var isHidden = true
        var font: UIFont = .systemFont(ofSize: 13)
    }
    
    struct BillingStartButton: CellButtonStyle {
        var isMandatory = true
        var button: ElementButtonStyle = AddBillingDetailsButtonStyle()
        var backgroundColor: UIColor = .red// .clear
        var title: ElementStyle? = TitleStyle(text: "Billing address")
        var mandatory: ElementStyle?
        var hint: ElementStyle? = {
            var element = SubtitleElementStyle(text: "We need this information as an additional security measure to verify this card.")
            element.textColor = PaymentColor.mainFontColor
            return element
        }()
        var error: ElementErrorViewStyle?
    }
    
    struct BillingSummaryStyle: BillingSummaryViewStyle {
        var summary: ElementStyle? = BillingSummaryElementStyle(text: "")
        var cornerRadius: CGFloat = PaymentColor.borderRadius
        var borderWidth: CGFloat = PaymentColor.borderWidth
        var separatorLineColor: UIColor = PaymentColor.secondaryFontColor
        var borderColor: UIColor = PaymentColor.mainFontColor
        var button: ElementButtonStyle = AddBillingDetailsButtonStyle(textLeading: 20, text: "\u{276F} Update Billing Address")
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Billing address")
        var mandatory: ElementStyle?
        var hint: ElementStyle? = {
            var element = SubtitleElementStyle(text: "We need this information as an additional security measure to verify this card.")
            element.textColor = PaymentColor.mainFontColor
            return element
        }()
        var error: ElementErrorViewStyle?
    }
    
    struct AddBillingDetailsButtonStyle: ElementButtonStyle {
        var textAlignment: NSTextAlignment = .natural
        var isEnabled = true
        var disabledTextColor: UIColor = PaymentColor.secondaryFontColor
        var disabledTintColor: UIColor = PaymentColor.secondaryFontColor
        var activeTintColor: UIColor = PaymentColor.mainFontColor
        var imageTintColor: UIColor = .clear
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = .clear
        var image: UIImage?
        var textLeading: CGFloat = 0
        var cornerRadius: CGFloat = 0
        var borderWidth: CGFloat = 0
        var height: Double = 56
        var width: Double = 300
        var isHidden = false
        var text: String = "\u{276F} Add billing address"
        var font: UIFont = .systemFont(ofSize: 15, weight: .semibold)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.mainFontColor
    }
    
    struct BillingFullNameInput: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Full name")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingAddressLine1Input: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Address line 1")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingAddressLine2Input: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = false
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Address line 2")
        var mandatory: ElementStyle? = MandatoryStyle(text: "Optional")
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingCityInput: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "City")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingStateInput: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "State")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingPostcodeInput: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle(isSupportingNumericKeyboard: false)
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Postcode/Zip")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingCountryInput: CellButtonStyle {
        var button: ElementButtonStyle = BillingCountryButton()
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Country")
        var mandatory: ElementStyle?
        var hint: ElementStyle?
        var error: ElementErrorViewStyle?
    }
    
    struct BillingPhoneInput: CellTextFieldStyle {
        var textfield: ElementTextFieldStyle = TextFieldStyle()
        var isMandatory = true
        var backgroundColor: UIColor = .clear
        var title: ElementStyle? = TitleStyle(text: "Phone number")
        var mandatory: ElementStyle?
        var hint: ElementStyle? = SubtitleElementStyle(text: "We will only use this to confirm identity if necessary")
        var error: ElementErrorViewStyle?
    }
    
    struct BillingSummaryElementStyle: ElementStyle {
        var textAlignment: NSTextAlignment = .natural
        var isHidden = false
        var text: String
        var font: UIFont = .systemFont(ofSize: 14)
        var backgroundColor: UIColor = .clear
        var textColor: UIColor = PaymentColor.secondaryFontColor
    }
    
    struct BillingCountryButton: ElementButtonStyle {
        var textAlignment: NSTextAlignment = .natural
        var isEnabled = true
        var disabledTextColor: UIColor = PaymentColor.secondaryFontColor
        var disabledTintColor: UIColor = .clear
        var activeTintColor: UIColor = PaymentColor.mainFontColor
        var imageTintColor: UIColor = PaymentColor.mainFontColor
        var normalBorderColor: UIColor = .clear
        var focusBorderColor: UIColor = .clear
        var errorBorderColor: UIColor = .clear
        var image: UIImage? = UIImage(named: "arrow_green_down")
        var textLeading: CGFloat = 20
        var cornerRadius: CGFloat = PaymentColor.borderRadius
        var borderWidth: CGFloat = 0
        var height: Double = 20
        var width: Double = 80
        var isHidden = false
        var text: String = "Please select a country"
        var font: UIFont = .systemFont(ofSize: 15)
        var backgroundColor: UIColor = PaymentColor.textFieldBackgroundColor
        var textColor: UIColor = PaymentColor.secondaryFontColor
    }
    
}
