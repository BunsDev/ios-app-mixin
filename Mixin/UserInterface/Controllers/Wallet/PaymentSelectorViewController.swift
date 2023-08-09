import UIKit

final class PaymentSelectorViewController: PopupSelectorViewController {
    
    var onSelected: ((Payment) -> Void)?
    
    private let payments: [Payment]
    private let selectedIndex: Int
    
    init(payments: [Payment], selectedIndex: Int) {
        self.payments = payments
        self.selectedIndex = selectedIndex
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 74
        tableView.register(R.nib.paymentCell)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
}

extension PaymentSelectorViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        payments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.payment, for: indexPath)!
        let payment = payments[indexPath.row]
        cell.iconImageView.image = payment.icon
        cell.nameLabel.text = payment.name
        return cell
    }
    
}

extension PaymentSelectorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let payment = payments[indexPath.row]
        onSelected?(payment)
        close(tableView)
    }
    
}
