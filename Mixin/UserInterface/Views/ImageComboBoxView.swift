import UIKit

class ImageComboBoxView: ComboBoxView {

    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        insertIconView(imageView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        insertIconView(imageView)
    }
    
}
