import UIKit

class SeparatorShadowFooterView: UITableViewHeaderFooterView {
        
    let shadowView = SeparatorShadowView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.addSubview(shadowView)
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(shadowView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.frame = bounds
    }
    
}
