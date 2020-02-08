@testable import App
import XCModel
import XCTest

final class AppTests: XCTestCase {
    
    func testNonFilteringReleases() {
        let lastRelease = Xcode(version: Version("1.0"), date: (2020, 8, 20), requires: "10.3")
        
        let newReleases = [
            Xcode(name: "Xcode Tools", version: Version("1.1", "asldkj", .gmSeed(1)), date: (2020, 8, 21), requires: "10.3")
        ]
        
        let filteredReleases = newReleases.filterReleases(before: lastRelease)
        XCTAssertEqual(filteredReleases.count, 1)
    }
    
    func testFilteringReleases() {
        let lastRelease = Xcode(version: Version("11.1"), date: (2020, 8, 20), requires: "10.3")
        
        let newReleases = [
            Xcode(name: "Xcode Tools", version: Version("1.1", "asldkj", .gmSeed(1)), date: (2020, 8, 21), requires: "10.3"), //filter
            Xcode(name: "Xcode Tools", version: Version("1.1", "asldkj", .gmSeed(1)), date: (2019, 8, 21), requires: "10.3"), //filter
            Xcode(name: "Xcode Tools", version: Version("1.1", "asldkj", .gmSeed(1)), date: (2020, 7, 21), requires: "10.3"), //filter
            Xcode(name: "Xcode Tools", version: Version("1.1", "asldkj", .gmSeed(1)), date: (2020, 8, 19), requires: "10.3"), //keep
            Xcode(name: "Xcode Tools", version: Version("11.0", "asldkj", .gmSeed(1)), date: (2020, 8, 21), requires: "10.3") //keep
        ]
        
        let filteredReleases = newReleases.filterReleases(before: lastRelease)
        XCTAssertEqual(filteredReleases.count, 2)
    }
    
    
    func testDateIsDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("1.0"), date: (2020, 8, 20), requires: "")
        let release2 = Xcode(name: "Xcode", version: Version("1.0"), date: (2020, 8, 13), requires: "")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 1)
    }
    
    func testVersionIsDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("HBCD", "1.1"), date: (2020, 8, 20), requires: "")
        let release2 = Xcode(name: "Xcode", version: Version("HBCD", "1.0"), date: (2020, 8, 20), requires: "")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 1, "Should Be Different Hashes, \(release1.hashValue) != \(release2.hashValue)")
    }
    
    func testNameIsDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("1.0"), date: (2020, 8, 20), requires: "")
        let release2 = Xcode(name: "Xcode Tools", version: Version("1.0"), date: (2020, 8, 20), requires: "")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 1)
    }
    
    func testRequiresIsNotDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("1.0"), date: (2020, 8, 20), requires: "10.4")
        let release2 = Xcode(name: "Xcode", version: Version("1.0"), date: (2020, 8, 20), requires: "10.3")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 0)
    }
    
    func testBuildIsDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("ABS", "1.0"), date: (2020, 8, 20), requires: "")
        let release2 = Xcode(name: "Xcode", version: Version("ABS", "1.1"), date: (2020, 8, 20), requires: "")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 1)
    }
    func testReleaseIsDiff() {
        let release1 = Xcode(name: "Xcode", version: Version("ASB", "1.0", .gmSeed(1)), date: (2020, 8, 20), requires: "")
        let release2 = Xcode(name: "Xcode", version: Version("ASB", "1.0", .gm), date: (2020, 8, 20), requires: "")
        let diff = [release1].diff(with: [release2])
        XCTAssertEqual(diff.count, 1)
    }
    
    static let allTests = [
        ("testNonFilteringReleases", testNonFilteringReleases),
        ("testFilteringReleases", testFilteringReleases),
        ("testDateIsDiff", testDateIsDiff),
        ("testVersionIsDiff", testVersionIsDiff),
        ("testNameIsDiff", testNameIsDiff),
        ("testRequiresIsNotDiff", testRequiresIsNotDiff),
        ("testBuildIsDiff", testBuildIsDiff),
        ("testReleaseIsDiff", testReleaseIsDiff)
    ]
}
