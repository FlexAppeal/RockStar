import XCTest
@testable import Rockstar

final class RockstarTests: XCTestCase {
    func testHexColor() {
        var color = Color(hex: "#FF0000")
        XCTAssertEqual(color?.byteView.red, 0xFF)
        XCTAssertEqual(color?.byteView.green, 0x00)
        XCTAssertEqual(color?.byteView.blue, 0x00)
        
        color = Color(hex: "#FABCDE")
        XCTAssertEqual(color?.byteView.red, 0xFA)
        XCTAssertEqual(color?.byteView.green, 0xBC)
        XCTAssertEqual(color?.byteView.blue, 0xDE)
        
        color = Color(hex: "#00a00A")
        XCTAssertEqual(color?.byteView.red, 0x00)
        XCTAssertEqual(color?.byteView.green, 0xA0)
        XCTAssertEqual(color?.byteView.blue, 0x0A)
        
        color = Color(hex: "BbBccC")
        XCTAssertEqual(color?.byteView.red, 0xBB)
        XCTAssertEqual(color?.byteView.green, 0xBC)
        XCTAssertEqual(color?.byteView.blue, 0xCC)
        
        XCTAssertNil(Color(hex: "$AAAAAA"))
        XCTAssertNil(Color(hex: "0x00000"))
        XCTAssertNil(Color(hex: "0x000000"))
        XCTAssertNil(Color(hex: "0x000000"))
        XCTAssertNil(Color(hex: "0x000000"))
        XCTAssertNil(Color(hex: "ZAAAAG"))
        XCTAssertNil(Color(hex: "GAAAAA"))
        XCTAssertNil(Color(hex: "@AAAAA"))
        XCTAssertNil(Color(hex: "gaaaaaa"))
        XCTAssertNil(Color(hex: ":aaaaaa"))
        XCTAssertNil(Color(hex: "/aaaaaa"))
        
        XCTAssertNotNil(Color(hex: "AAAAAA"))
        XCTAssertNotNil(Color(hex: "aaaaaa"))
    }
    
    static var allTests = [
        ("testHexColor", testHexColor),
    ]
}
