import UIKit

protocol SearchableViewController {
    var searchTextField: UITextField { get }
    var trimmedLowercaseKeyword: String { get }
}

extension SearchableViewController where Self: UIViewController {
    
    var trimmedLowercaseKeyword: String {
        guard let text = searchTextField.text else {
            return ""
        }
        return text.trimmingCharacters(in: .whitespaces).lowercased()
    }
    
    var homeNavigationController: UINavigationController? {
        assert(parent?.parent is HomeViewController)
        return parent?.parent?.navigationController
    }
    
    var searchNavigationController: SearchNavigationViewController? {
        return navigationController as? SearchNavigationViewController
    }
    
    func pushViewController(keyword: String, result: SearchResult) {
        switch result.target {
        case let .contact(user):
            let vc = ConversationViewController.instance(ownerUser: user)
            homeNavigationController?.pushViewController(vc, animated: true)
        case let .group(conversation):
            let vc = ConversationViewController.instance(conversation: conversation)
            homeNavigationController?.pushViewController(vc, animated: true)
        case .searchMessageWithContact, .searchMessageWithGroup:
            let vc = R.storyboard.home.search_conversation()!
            vc.load(searchResult: result)
            vc.inheritedKeyword = keyword
            searchNavigationController?.pushViewController(vc, animated: true)
        case .message:
            assertionFailure()
        }
    }
    
    func pushAssetViewController(asset: AssetItem) {
        let vc = AssetViewController.instance(asset: asset)
        homeNavigationController?.pushViewController(vc, animated: true)
    }
    
}
