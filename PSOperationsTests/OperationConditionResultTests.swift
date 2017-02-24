@testable import PSOperations
import XCTest

class OperationConditionResultTests: XCTestCase {

    struct MockCondition: OperationCondition {
        static let name: String = "MockCondition"
        static let isMutuallyExclusive: Bool = false

        func dependencyForOperation(_ operation: PSOperation) -> Foundation.Operation? {
            return nil
        }

        func evaluateForOperation(_ operation: PSOperation, completion: @escaping (OperationConditionResult) -> Void) {
            completion(.satisfied)
        }
    }

    struct MockError: ConditionError {
        typealias Condition = MockCondition
    }

    func testOperationConditionResults_HasError() {
        let failed = OperationConditionResult.failed(MockError())

        XCTAssertNotNil(failed.error)
    }

    func testOperationConditionResults_NoError() {
        let sat = OperationConditionResult.satisfied

        XCTAssertNil(sat.error)
    }
}
