import Foundation
import GRDB

public final class TranscriptMessage {
    
    public let transcriptId: String
    public let messageId: String
    public let userId: String?
    public var userFullName: String?
    public var category: String
    public let createdAt: String
    public var content: String?
    public var mediaUrl: String?
    public let mediaName: String?
    public let mediaSize: Int64?
    public var mediaWidth: Int?
    public var mediaHeight: Int?
    public let mediaMimeType: String?
    public let mediaDuration: Int64?
    public var mediaStatus: String?
    public let mediaWaveform: Data?
    public let thumbImage: String?
    public let thumbUrl: String?
    public var mediaKey: Data?
    public var mediaDigest: Data?
    public var mediaCreatedAt: String?
    public var stickerId: String?
    public let sharedUserId: String?
    public let mentions: String?
    public let quoteMessageId: String?
    public let quoteContent: String?
    public let caption: String?
    
    public init(transcriptId: String, mediaUrl: String?, message m: TranscriptMessage) {
        self.transcriptId = transcriptId
        self.messageId = m.messageId
        self.userId = m.userId
        self.userFullName = m.userFullName
        self.category = m.category
        self.createdAt = m.createdAt
        self.content = m.content
        self.mediaUrl = mediaUrl
        self.mediaName = m.mediaName
        self.mediaSize = m.mediaSize
        self.mediaWidth = m.mediaWidth
        self.mediaHeight = m.mediaHeight
        self.mediaMimeType = m.mediaMimeType
        self.mediaDuration = m.mediaDuration
        self.mediaStatus = m.mediaStatus
        self.mediaWaveform = m.mediaWaveform
        self.thumbImage = m.thumbImage
        self.thumbUrl = m.thumbUrl
        self.mediaKey = m.mediaKey
        self.mediaDigest = m.mediaDigest
        self.mediaCreatedAt = m.mediaCreatedAt
        self.stickerId = m.stickerId
        self.sharedUserId = m.sharedUserId
        self.mentions = m.mentions
        self.quoteMessageId = m.quoteMessageId
        self.quoteContent = m.quoteContent
        self.caption = m.caption
    }
    
    public init?(transcriptId: String, mediaUrl: String?, thumbImage: String?, messageItem item: MessageItem) {
        let (content, mediaCreatedAt) = { () -> (String?, String?) in
            guard let category = MessageCategory(rawValue: item.category) else {
                return (item.content, nil)
            }
            switch category {
            case .APP_CARD:
                return (AppCardContentConverter.generalAppCard(from: item.content), nil)
            case .SIGNAL_VIDEO, .PLAIN_VIDEO, .ENCRYPTED_VIDEO, .SIGNAL_IMAGE, .PLAIN_IMAGE, .ENCRYPTED_IMAGE:
                if let data = item.content?.data(using: .utf8), let tad = try? JSONDecoder.default.decode(TransferAttachmentData.self, from: data) {
                    return (tad.attachmentId, tad.createdAt)
                } else if let data = Data(base64Encoded: item.content ?? ""), let tad = try? JSONDecoder.default.decode(TransferAttachmentData.self, from: data) {
                    return (tad.attachmentId, tad.createdAt)
                } else {
                    return (item.content, nil)
                }
            default:
                return (item.content, nil)
            }
        }()
        self.transcriptId = transcriptId
        self.messageId = item.messageId
        self.userId = item.userId
        self.userFullName = item.userFullName
        self.category = item.category
        self.content = content
        self.mediaUrl = mediaUrl ?? item.assetUrl
        self.mediaMimeType = item.mediaMimeType
        self.mediaSize = item.mediaSize
        self.mediaDuration = item.mediaDuration
        self.mediaWidth = item.mediaWidth ?? item.assetWidth
        self.mediaHeight = item.mediaHeight ?? item.assetHeight
        self.mediaKey = item.mediaKey
        self.mediaDigest = item.mediaDigest
        self.mediaStatus = item.mediaStatus
        self.mediaWaveform = item.mediaWaveform
        self.mediaCreatedAt = mediaCreatedAt
        self.thumbImage = thumbImage
        self.thumbUrl = item.thumbUrl
        self.mediaName = item.name
        self.caption = nil
        self.stickerId = item.stickerId
        self.sharedUserId = item.sharedUserId
        self.quoteMessageId = item.quoteMessageId
        self.quoteContent = QuoteContentConverter.generalQuoteContent(from: item.quoteContent)
        self.mentions = MentionConverter.generalMention(from: item.mentionsJson)
        self.createdAt = item.createdAt
    }
    
    public init(transcriptId: String, messageId: String, userId: String?, userFullName: String?, category: String, createdAt: String, content: String?, mediaUrl: String?, mediaName: String?, mediaSize: Int64?, mediaWidth: Int?, mediaHeight: Int?, mediaMimeType: String?, mediaDuration: Int64?, mediaStatus: String?, mediaWaveform: Data?, thumbImage: String?, thumbUrl: String?, mediaKey: Data?, mediaDigest: Data?, mediaCreatedAt: String?, stickerId: String?, sharedUserId: String?, mentions: String?, quoteMessageId: String?, quoteContent: String?, caption: String?) {
        self.transcriptId = transcriptId
        self.messageId = messageId
        self.userId = userId
        self.userFullName = userFullName
        self.category = category
        self.createdAt = createdAt
        self.content = content
        self.mediaUrl = mediaUrl
        self.mediaName = mediaName
        self.mediaSize = mediaSize
        self.mediaWidth = mediaWidth
        self.mediaHeight = mediaHeight
        self.mediaMimeType = mediaMimeType
        self.mediaDuration = mediaDuration
        self.mediaStatus = mediaStatus
        self.mediaWaveform = mediaWaveform
        self.thumbImage = thumbImage
        self.thumbUrl = thumbUrl
        self.mediaKey = mediaKey
        self.mediaDigest = mediaDigest
        self.mediaCreatedAt = mediaCreatedAt
        self.stickerId = stickerId
        self.sharedUserId = sharedUserId
        self.mentions = mentions
        self.quoteMessageId = quoteMessageId
        self.quoteContent = quoteContent
        self.caption = caption
    }
    
}

extension TranscriptMessage {
    
    public struct LocalContent: Codable {
        
        public let name: String?
        public let category: String
        public let content: String?
        
        public init(transcriptMessage t: TranscriptMessage) {
            self.name = t.userFullName
            self.category = t.category
            self.content = t.content
        }
        
        public init?(messageItem m: MessageItem) {
            self.name = m.userFullName
            self.category = m.category
            switch category {
            case MessageCategory.APP_CARD.rawValue:
                self.content = AppCardContentConverter.generalAppCard(from: m.content)
            case MessageCategory.APP_BUTTON_GROUP.rawValue:
                self.content = AppButtonGroupContentConverter.generalAppButtonGroup(from: m.content)
            default:
                self.content = m.content
            }
        }
        
    }
    
}

extension TranscriptMessage: Codable, DatabaseColumnConvertible, MixinFetchableRecord, MixinEncodableRecord {
    
    public enum CodingKeys: String, CodingKey {
        case transcriptId = "transcript_id"
        case messageId = "message_id"
        case userId = "user_id"
        case userFullName = "user_full_name"
        case category
        case createdAt = "created_at"
        case content
        case mediaUrl = "media_url"
        case mediaName = "media_name"
        case mediaSize = "media_size"
        case mediaWidth = "media_width"
        case mediaHeight = "media_height"
        case mediaMimeType = "media_mime_type"
        case mediaDuration = "media_duration"
        case mediaStatus = "media_status"
        case mediaWaveform = "media_waveform"
        case thumbImage = "thumb_image"
        case thumbUrl = "thumb_url"
        case mediaKey = "media_key"
        case mediaDigest = "media_digest"
        case mediaCreatedAt = "media_created_at"
        case stickerId = "sticker_id"
        case sharedUserId = "shared_user_id"
        case mentions
        case quoteMessageId = "quote_id"
        case quoteContent = "quote_content"
        case caption
    }
    
}

extension TranscriptMessage: TableRecord, PersistableRecord {
    
    public static let databaseTableName = "transcript_messages"
    
}
