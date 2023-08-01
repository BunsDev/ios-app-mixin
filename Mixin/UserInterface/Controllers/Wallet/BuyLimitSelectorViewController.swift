import UIKit

class BuyLimitSelectorViewController: PopupSelectorViewController {
    
    var onSelected: ((BuyLimit) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 74
        tableView.register(R.nib.buyLimitCell)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
}

extension BuyLimitSelectorViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        BuyLimit.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.buy_limit, for: indexPath)!
        let limit = BuyLimit.allCases[indexPath.row]
        cell.nameLabel.text = limit.name
        cell.limitLabel.text = limit.limit
        cell.descriptionLabel.text = limit.description
        return cell
    }
    
}

extension BuyLimitSelectorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let limit = BuyLimit.allCases[indexPath.row]
        onSelected?(limit)
        close(tableView)
    }
    
}
