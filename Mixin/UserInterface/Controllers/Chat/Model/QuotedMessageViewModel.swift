import Foundation

class QuotedMessageViewModel {
    
    static let backgroundMargin = MessageViewModel.Margin(leading: 9, trailing: 2, top: 1, bottom: 4)
    static let contentMargin = MessageViewModel.Margin(leading: 11, trailing: 11, top: 6, bottom: 6)
    static let iconSize = CGSize(width: 15, height: 15)
    static let iconTrailingMargin: CGFloat = 4
    static let subtitleTopMargin: CGFloat = 4
    static let subtitleNumberOfLines = 3
    static let imageSize = CGSize(width: 50, height: 50)
    static let avatarImageMargin: CGFloat = 8
    
    let quote: Quote
    
    private(set) var contentSize: CGSize = .zero
    private(set) var backgroundFrame: CGRect = .zero
    private(set) var titleFrame: CGRect = .zero
    private(set) var iconFrame: CGRect = .zero
    private(set) var subtitleFrame: CGRect = .zero
    private(set) var subtitleFont = MessageFontSet.normalQuoteSubtitle.scaled
    private(set) var imageFrame: CGRect = .zero
    
    private var paddedQuoteIconWidth: CGFloat = 0
    private var titleSize: CGSize = .zero
    private var subtitleSize: CGSize = .zero
    
    init(quote: Quote) {
        self.quote = quote
    }
    
    func ensureContentSize(width: CGFloat) {
        switch quote.category {
        case .normal:
            subtitleFont = MessageFontSet.normalQuoteSubtitle.scaled
        case .recalled:
            subtitleFont = MessageFontSet.recalledQuoteSubtitle.scaled
        }
        
        paddedQuoteIconWidth = quote.icon == nil ? 0 : Self.iconSize.width + Self.iconTrailingMargin
        let quoteImageWidth = quote.image == nil ? 0 : Self.imageSize.width
        let maxTitleWidth = width
            - DetailInfoMessageViewModel.bubbleMargin.horizontal
            - Self.backgroundMargin.horizontal
            - Self.contentMargin.horizontal
            - quoteImageWidth
        let maxSubtitleWidth = width
            - DetailInfoMessageViewModel.bubbleMargin.horizontal
            - Self.backgroundMargin.horizontal
            - Self.contentMargin.horizontal
            - paddedQuoteIconWidth
            - quoteImageWidth
        
        let titleHeight = MessageFontSet.quoteTitle.scaled.lineHeight
        var titleWidth = (quote.title as NSString)
            .size(withAttributes: [.font: MessageFontSet.quoteTitle.scaled])
            .width
        titleWidth = ceil(titleWidth)
        titleWidth = min(maxTitleWidth, titleWidth)
        titleSize = CGSize(width: titleWidth, height: titleHeight)
        
        let subtitleFittingSize = CGSize(width: maxSubtitleWidth, height: UIView.layoutFittingExpandedSize.height)
        subtitleSize = (quote.subtitle as NSString)
            .boundingRect(with: subtitleFittingSize,
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          attributes: [.font: subtitleFont],
                          context: nil)
            .size
        var subtitleHeight = subtitleSize.height
        subtitleHeight = min(subtitleFont.lineHeight * CGFloat(Self.subtitleNumberOfLines), subtitleHeight)
        subtitleHeight = max(ceil(subtitleFont.lineHeight), subtitleHeight)
        subtitleSize = ceil(CGSize(width: subtitleSize.width, height: subtitleHeight))
        
        let contentWidth = max(titleWidth + quoteImageWidth, paddedQuoteIconWidth + subtitleSize.width + quoteImageWidth)
            + Self.contentMargin.horizontal
            + Self.backgroundMargin.horizontal
        let contentHeight = max(Self.imageSize.height,
                                Self.contentMargin.vertical + titleHeight + Self.subtitleTopMargin + subtitleHeight)
        contentSize = CGSize(width: contentWidth, height: contentHeight)
    }
    
    func layout(width: CGFloat, style: MessageViewModel.Style) {
        let backgroundOriginX = style.contains(.received)
            ? Self.backgroundMargin.leading
            : Self.backgroundMargin.trailing
        backgroundFrame = CGRect(x: backgroundOriginX,
                                 y: Self.backgroundMargin.top,
                                 width: width - Self.backgroundMargin.horizontal,
                                 height: contentSize.height)
        let titleOrigin = CGPoint(x: backgroundFrame.origin.x + Self.contentMargin.leading,
                                  y: backgroundFrame.origin.y + Self.contentMargin.top)
        titleFrame = CGRect(origin: titleOrigin, size: titleSize)
        
        let iconOrigin = CGPoint(x: titleFrame.origin.x,
                                 y: round(titleFrame.maxY + Self.subtitleTopMargin + (subtitleFont.lineHeight - Self.iconSize.height) / 2))
        if quote.icon == nil {
            iconFrame = CGRect(origin: iconOrigin, size: .zero)
        } else {
            iconFrame = CGRect(origin: iconOrigin, size: Self.iconSize)
        }
        
        subtitleFrame = CGRect(x: titleFrame.origin.x + paddedQuoteIconWidth,
                               y: titleFrame.maxY + Self.subtitleTopMargin,
                               width: subtitleSize.width,
                               height: subtitleSize.height)
        
        if let image = quote.image {
            let imageOrigin = CGPoint(x: backgroundFrame.maxX - Self.imageSize.width,
                                      y: backgroundFrame.origin.y)
            let imageSize = quote.image == nil ? .zero : Self.imageSize
            if case .user = image {
                imageFrame = CGRect(origin: imageOrigin, size: imageSize)
                    .insetBy(dx: Self.avatarImageMargin, dy: Self.avatarImageMargin)
            } else {
                imageFrame = CGRect(origin: imageOrigin, size: imageSize)
            }
        } else {
            imageFrame = .zero
        }
    }
    
}
