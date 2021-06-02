import UIKit

public class AttachmentCleanUpJob: BaseJob {
    
    let conversationId: String
    let mediaUrls: [String: String]
    
    public init(conversationId: String, mediaUrls: [String: String]) {
        self.conversationId = conversationId
        self.mediaUrls = mediaUrls
    }
    
    override open func getJobId() -> String {
        "cleanup-attachment-\(conversationId)"
    }
    
    override open func run() throws {
        guard !conversationId.isEmpty && !mediaUrls.isEmpty else {
            return
        }
        for (mediaUrl, category) in mediaUrls {
            AttachmentContainer.removeMediaFiles(mediaUrl: mediaUrl, category: category)
        }
        NotificationCenter.default.post(onMainThread: storageUsageDidChangeNotification, object: self)
    }
    
}
