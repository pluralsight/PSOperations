import PSOperations
import XCTest

class PSOperationsAppForTestsTests: XCTestCase {

    /*
     This test only exhibits the problem when run in an app container, thus, it is part of a test suite that is
     part of an application. When you have many (less than the tested amount) operations that have dependencies 
     often a crash occurs when all operations in the dependency chain are completed.
     This problem is not limited to PSOperations. If you adapt this test to use NSOperationQueue and NSBlockOperation 
     (or some other NSOperation, doesn't matter) This same crash will occur. While meeting expectations is important
     the real test is whether or not it crashes when the last operation finishes
    */
    func testDependantOpsCrash() {
        let queue = PSOperations.OperationQueue()
        let opcount = 5_000
        var ops: [PSOperations.Operation] = []
        for _ in 0..<opcount {

            let exp = expectation(description: "block should finish")

            let block = PSOperations.BlockOperation { finish in
//                NSLog("op: \(i): opcount: queue: \(queue.operationCount)")
                exp.fulfill()
                finish()
            }

            ops.append(block)
        }

        for index in 1..<opcount {
            let op1 = ops[index]
            op1.addDependency(ops[index - 1])
        }

        queue.addOperations(ops, waitUntilFinished: false)

        waitForExpectations(timeout: 60 * 3, handler: nil)
    }
}
