import Foundation

open class UploadOrDownloadJob: AsynchronousJob {
    
    public let messageId: String
    public var message: Message!
    public var task: URLSessionTask?
    
    public lazy var completionHandler = { [weak self] (data: Any?, response: URLResponse?, error: Error?) in
        guard let weakSelf = self else {
            return
        }
        if weakSelf.isCancelled || !LoginManager.shared.isLoggedIn {
            weakSelf.finishJob()
            return
        } else if let err = error {
            switch err.errorCode {
            case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost:
                if weakSelf.retry() {
                    return
                }
                weakSelf.finishJob()
                return
            default:
                weakSelf.finishJob()
                return
            }
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard statusCode != 404 else {
            weakSelf.downloadExpired()
            weakSelf.finishJob()
            return
        }
        guard statusCode == 200 else {
            if weakSelf.retry() {
                return
            }
            weakSelf.finishJob()
            return
        }
        
        weakSelf.taskFinished()
        weakSelf.finishJob()
    }
    
    public init(messageId: String) {
        self.messageId = messageId
    }
    
    override open func cancel() {
        task?.cancel()
        super.cancel()
    }
    
    open func downloadExpired() {
        
    }
    
    private func retry() -> Bool {
        checkNetworkAndWebSocket()

        if !isCancelled {
            if !execute() {
                finishJob()
            }
            return true
        }
        return false
    }
    
    open func taskFinished() {
        
    }
    
}
