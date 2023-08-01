import Foundation
import Alamofire

enum SumsubAPI {
    
    struct Request: Encodable {
        
        let userID: String
        
        enum CodingKeys: String, CodingKey {
            case userID = "mixin_id"
        }
        
    }
    
    enum Response: Decodable {
        
        private enum CodingKeys: String, CodingKey {
            case token
            case state
        }
        
        case pending(String)
        case success
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let state = try container.decode(String.self, forKey: .state)
            switch state {
            case "pending":
                let token = try container.decode(String.self, forKey: .token)
                self = .pending(token)
            case "success":
                self = .success
            default:
                let context = DecodingError.Context(codingPath: [CodingKeys.state], debugDescription: "")
                throw DecodingError.dataCorrupted(context)
            }
        }
        
    }
    
    @discardableResult
    static func token(userID: String, completion: @escaping (Result<Response, AFError>) -> Void) -> DataRequest {
        let url = URL(string: "https://wallet.touge.fun/kyc/token")!
        let request = Request(userID: userID)
        return AF.request(url, method: .post, parameters: request, encoder: .json)
            .responseDecodable(of: Response.self, queue: .main) { response in
                completion(response.result)
            }
    }
    
}
