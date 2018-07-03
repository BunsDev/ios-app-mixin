import UIKit

class SettingViewController: UITableViewController {

    @IBOutlet weak var blockedUsersDetailLabel: UILabel!
    @IBOutlet weak var conversationDetailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateConversationCell()
        updateBlockedUserCell()
        NotificationCenter.default.addObserver(self, selector: #selector(updateConversationCell), name: .AccountDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBlockedUserCell), name: .UserDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateConversationCell() {
        guard let account = AccountAPI.shared.account else {
            return
        }
        switch account.receive_message_source {
        case ReceiveMessageSource.everybody.rawValue:
            conversationDetailLabel.text = Localized.SETTING_CONVERSATION_EVERYBODY
        case ReceiveMessageSource.contacts.rawValue:
            conversationDetailLabel.text = Localized.SETTING_CONVERSATION_CONTACTS
        default:
            break
        }
    }

    @objc func updateBlockedUserCell() {
        DispatchQueue.global().async {
            let blocked = UserDAO.shared.getBlockUsers()
            DispatchQueue.main.async {
                if blocked.count > 0 {
                    self.blockedUsersDetailLabel.text = String(blocked.count) + Localized.SETTING_BLOCKED_USER_COUNT_SUFFIX
                } else {
                    self.blockedUsersDetailLabel.text = Localized.SETTING_BLOCKED_USER_COUNT_NONE
                }
            }
        }
    }

    class func instance() -> UIViewController {
        return ContainerViewController.instance(viewController: Storyboard.setting.instantiateInitialViewController()!, title: Localized.SETTING_TITLE)
    }
}

extension SettingViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                navigationController?.pushViewController(BlockUserViewController.instance(), animated: true)
            } else {
                navigationController?.pushViewController(ConversationSettingViewController.instance(), animated: true)
            }
        } else if indexPath.section == 1 {
            navigationController?.pushViewController(StorageUsageViewController.instance(), animated: true)
        } else {
            navigationController?.pushViewController(AboutContainerViewController.instance(), animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? Localized.SETTING_PRIVACY_AND_SECURITY_TITLE : nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? Localized.SETTING_PRIVACY_AND_SECURITY_SUMMARY : nil
    }
}
