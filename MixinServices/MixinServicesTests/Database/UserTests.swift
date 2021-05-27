import XCTest
@testable import MixinServices

class UserTests: XCTestCase {
    
    let url = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("mixin.db", isDirectory: false)
    
    var db: UserDatabase!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        print("Testing with URL: \(url)")
        db = try UserDatabase(url: url)
    }
    
    override func tearDownWithError() throws {
        autoreleasepool {
            db = nil
        }
        try FileManager.default.removeItem(at: url)
    }
    
    func testUUIDTokenizing() {
        let uuids = [
            UUID().uuidString,
            UUID().uuidString,
            UUID().uuidString,
            UUID().uuidString,
            UUID().uuidString,
        ]
        let uppercasedUUIDs = uuids.map { $0.uppercased() }
        let lowercasedUUIDs = uuids.map { $0.lowercased() }
        let uppercasedTokens = uppercasedUUIDs.map(uuidTokenString(uuidString:))
        let lowercasedTokens = lowercasedUUIDs.map(uuidTokenString(uuidString:))
        XCTAssertEqual(uppercasedUUIDs, uppercasedTokens.map(uuidString(uuidTokenString:)))
        XCTAssertEqual(lowercasedUUIDs, lowercasedTokens.map(uuidString(uuidTokenString:)))
        
        let invalidUUID = "828514A6-7EEF-4545-BF18-8E136E7F11-5"
        XCTAssertEqual(invalidUUID, uuidString(uuidTokenString: uuidTokenString(uuidString: invalidUUID)))
    }
    
}
