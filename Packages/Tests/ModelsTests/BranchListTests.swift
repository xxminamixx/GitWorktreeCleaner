import Testing
@testable import Models

struct BranchListTests {
    @Test func branchListParsesAndTrimsEntries() {
        let branches = BranchList.parse(" develop, base/xxxx ,, ")
        #expect(branches == ["develop", "base/xxxx"])
    }

    @Test func branchListFormatsForDisplay() {
        #expect(BranchList.format(["develop", "base/xxxx"]) == "develop, base/xxxx")
    }
}
