import XCTest
@testable import Rockstar

final class RockstarTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Rockstar().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
