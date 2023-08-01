import Foundation
import Alamofire

enum CheckoutAPI {
    
    struct Request: Encodable {
        
        let token: String
        let currency: String
        let userID: String
        let amount: Int64
        let assetID: String
        
        enum CodingKeys: String, CodingKey {
            case token
            case currency
            case userID = "user_id"
            case amount
            case assetID = "asset_id"
        }
        
    }
    
    struct Response: Decodable {
        let trace_id: String
    }
    
    static func payment(request: Request, completion: @escaping (Result<String, AFError>) -> Void) -> DataRequest {
        let url = URL(string: "https://wallet.touge.fun/checkout/payment")!
        return AF.request(url, method: .post, parameters: request, encoder: .json)
            .responseDecodable(of: Response.self, queue: .main) { response in
                completion(response.result.map(\.trace_id))
            }
    }
    
}
