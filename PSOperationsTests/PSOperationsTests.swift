//
//  PSOperationsTests.swift
//  PSOperationsTests
//
//  Created by Dev Team on 6/17/15.
//  Copyright (c) 2015 pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

struct TestCondition: OperationCondition {
    
    static let name = "TestCondition"
    static let isMutuallyExclusive = false
    var dependencyOperation: NSOperation?

    var conditionBlock: () -> Bool = { true }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return dependencyOperation
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if conditionBlock() {
            completion(.Satisfied)
        } else {
            completion(.Failed(NSError(code: .ConditionFailed, userInfo: ["Failed": true])))
        }
    }
}

class TestObserver: OperationObserver {
    
    var errors: [NSError]?
    
    var didStartBlock: (()->())?
    var didEndBlock: (()->())?
    var didCancelBlock: (()->())?
    var didProduceBlock: (()->())?
    
    
    func operationDidStart(operation: Operation) {
        if let didStartBlock = didStartBlock {
            didStartBlock()
        }
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        if let didProduceBlock = didProduceBlock {
            didProduceBlock()
        }
    }
    
    func operationDidCancel(operation: Operation) {
        
        if let didCancelBlock = didCancelBlock {
            didCancelBlock()
        }
    }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        self.errors = errors
        
        if let didEndBlock = didEndBlock {
            didEndBlock()
        }
    }

}

class PSOperationsTests: XCTestCase {
    
    override func setUp() {
        var dot: dispatch_once_t = 0
        dispatch_once(&dot, { () -> Void in
            
        })
    }
    
    func testAddingMultipleDeps() {
        let op = NSOperation()
        
        let deps = [NSOperation(),NSOperation(),NSOperation()]
        
        op.addDependencies(deps)
        
        XCTAssertEqual(deps.count, op.dependencies.count)
    }
    
    func testStandardOperation() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = NSBlockOperation { () -> Void in
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testBlockOperation_noConditions_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testOperation_withPassingCondition_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
        }
        
        op.addCondition(TestCondition())
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperation_withFailingCondition_noDependencies() {
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            XCTFail("Should not have run the block operation")
        }
        
        keyValueObservingExpectationForObject(op, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        XCTAssertFalse(op.cancelled, "Should not yet have cancelled the operation")
        
        var condition = TestCondition()

        condition.conditionBlock = {
            return false
        }
        
        let exp = expectationWithDescription("observer")
        
        let observer = TestObserver()
        
        observer.didEndBlock = {
            XCTAssertEqual(observer.errors?.count, 1)
            exp.fulfill()
        }
        
        op.addCondition(condition)
        op.addObserver(observer)
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperation_withPassingCondition_andConditionDependency_noDependencies() {
        
        let expectation = self.expectationWithDescription("block")
        let expectation2 = self.expectationWithDescription("block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
            fulfilledExpectations.append(expectation)
        }
        
        var testCondition = TestCondition()
        testCondition.dependencyOperation = BlockOperation {
            expectation2.fulfill()
            fulfilledExpectations.append(expectation2)
        }
        
        op.addCondition(testCondition)
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectation2, expectation], "Expectations fulfilled out of order")
        }
    }
    
    func testOperation_noCondition_hasDependency() {
        let expectation = expectationWithDescription("block")
        let expectationDependency = expectationWithDescription("block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = OperationQueue()
        
        let op = BlockOperation {
            expectation.fulfill()
            fulfilledExpectations.append(expectation)
        }
        
        let opDependency = BlockOperation {
            expectationDependency.fulfill()
            fulfilledExpectations.append(expectationDependency)
        }
        
        op.addDependency(opDependency)
        
        opQueue.addOperation(op)
        opQueue.addOperation(opDependency)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectationDependency, expectation], "Expectations fulfilled out of order")
        }
    }
    
    func testGroupOperation() {
        let exp1 = expectationWithDescription("block1")
        let exp2 = expectationWithDescription("block2")
        
        let op1 = NSBlockOperation {
            exp1.fulfill()
        }
        
        let op2 = NSBlockOperation {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(groupOp)
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testGroupOperation_cancelBeforeExecuting() {
        let exp1 = expectationWithDescription("block1")
        let exp2 = expectationWithDescription("block2")
        
        let op1 = NSBlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op1.completionBlock = {
            exp1.fulfill()
        }
        
        let op2 = NSBlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op2.completionBlock = {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.suspended = true
        opQ.addOperation(groupOp)
        groupOp.cancel()
        opQ.suspended = false
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testDelayOperation() {
        let delay: NSTimeInterval = 0.1
        
        let then = NSDate()
        let op = DelayOperation(interval: delay)
        
        keyValueObservingExpectationForObject(op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        OperationQueue().addOperation(op)
        
        waitForExpectationsWithTimeout(delay + 1) {
            _ in
            let now = NSDate()
            let diff = now.timeIntervalSinceDate(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testDelayOperation_With0() {
        let delay: NSTimeInterval = 0.0
        
        let then = NSDate()
        let op = DelayOperation(interval: delay)
        
        keyValueObservingExpectationForObject(op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        OperationQueue().addOperation(op)
        
        waitForExpectationsWithTimeout(delay + 1) {
            _ in
            let now = NSDate()
            let diff = now.timeIntervalSinceDate(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testDelayOperation_WithDate() {
        let delay: NSTimeInterval = 1
        let date = NSDate().dateByAddingTimeInterval(delay)
        let op = DelayOperation(until: date)
        
        let then = NSDate()
        keyValueObservingExpectationForObject(op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        OperationQueue().addOperation(op)
        
        waitForExpectationsWithTimeout(delay + 1) {
            _ in
            let now = NSDate()
            let diff = now.timeIntervalSinceDate(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testMutualExclusion() {
        
        enum Test {}
        typealias TestMutualExclusion = MutuallyExclusive<Test>
        let cond = MutuallyExclusive<TestMutualExclusion>()
        
        var running = false
        
        let exp = expectationWithDescription("op2")
        
        let op = BlockOperation {
            running = true
            exp.fulfill()
        }
        op.addCondition(cond)
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 2
        
        let delayOp = DelayOperation(interval: 0.1)
        
        delayOp.addCondition(cond)
        
        keyValueObservingExpectationForObject(delayOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            XCTAssertFalse(running, "op should not yet have started execution")
            
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return true
        }

        opQ.addOperation(delayOp)
        opQ.addOperation(op)
        
        waitForExpectationsWithTimeout(0.9, handler: nil)
    }
    
    func testConditionObserversCalled() {
        
        let startExp = expectationWithDescription("startExp")
        let cancelExp = expectationWithDescription("cancelExp")
        let finishExp = expectationWithDescription("finishExp")
        let produceExp = expectationWithDescription("produceExp")
        
        var op: BlockOperation!
        op = BlockOperation {
            op.produceOperation(BlockOperation(mainQueueBlock: {}))
            op.cancel()
        }
        op.addObserver(BlockObserver(
            startHandler: {
                _ in
                startExp.fulfill()
            },
            cancelHandler: {
                _ in
                cancelExp.fulfill()
            },
            produceHandler: {
                _ in
                produceExp.fulfill()
            },
            finishHandler: {
                _ in
                finishExp.fulfill()
        }))
        
        let q = OperationQueue()
        q.addOperation(op)
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testSilentCondition_failure() {
        
        var testCondition = TestCondition()
        
        testCondition.dependencyOperation = BlockOperation {
            XCTFail("should not run")
        }
        
        let exp = expectationWithDescription("")
        
        testCondition.conditionBlock = {
            exp.fulfill()
            return false
        }
        
        let silentCondition = SilentCondition(condition: testCondition)
        
        let opQ = OperationQueue()
        
        let operation = BlockOperation {
            XCTFail("should not run")
        }
        
        operation.addCondition(silentCondition)
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        opQ.addOperation(operation)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNegateCondition_failure() {
                
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }

        var testCondition = TestCondition()
        testCondition.conditionBlock = { true }

        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation)

        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNegateCondition_success() {
        
        let exp = expectationWithDescription("")
        
        let operation = BlockOperation {
            exp.fulfill()
        }
        
        var testCondition = TestCondition()
        testCondition.conditionBlock = { false }
        
        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels() {
        let dependencyOperation = BlockOperation { }
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)
        
        operation.addDependency(dependencyOperation)

        keyValueObservingExpectationForObject(dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        keyValueObservingExpectationForObject(opQ, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? NSOperationQueue {
                return opQ.operationCount == 0
            }
            
            return false
        }
        

        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation)
        dependencyOperation.cancel()
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOperationRunsEvenIfDepCancels() {
        
        let dependencyOperation = BlockOperation {}
        
        let exp = expectationWithDescription("")
        
        let operation = BlockOperation {
            exp.fulfill()
        }
        
        operation.addDependency(dependencyOperation)
        
        keyValueObservingExpectationForObject(dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation)
        dependencyOperation.cancel()
        
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
    func testCancelledOperationLeavesQueue() {
        
        let operation = BlockOperation { }
        let operation2 = NSBlockOperation { }
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1
        opQ.suspended = true
        
        keyValueObservingExpectationForObject(opQ, keyPath: "operationCount", expectedValue: 0)
        
        opQ.addOperation(operation)
        opQ.addOperation(operation2)
        operation.cancel()
        
        opQ.suspended = false
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
//    This test exhibits odd behavior that needs to be investigated at some point.
//    It seems to be related to setting the maxConcurrentOperationCount to 1 so
//    I don't believe it is critical
//    func testCancelledOperationLeavesQueue() {
//        
//        let operation = BlockOperation { }
//        
//        let exp = expectationWithDescription("")
//        
//        let operation2 = BlockOperation {
//            exp.fulfill()
//        }
//        
//        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
//            (op, changes) -> Bool in
//            
//            if let op = op as? NSOperation {
//                return op.cancelled
//            }
//            
//            return false
//        }
//        
//        
//        let opQ = OperationQueue()
//        opQ.maxConcurrentOperationCount = 1
//        
//        opQ.addOperation(operation)
//        opQ.addOperation(operation2)
//        operation.cancel()
//        
//        waitForExpectationsWithTimeout(1, handler: nil)
//    }
    
    func testCancelOperation_cancelBeforeStart() {
        let operation = BlockOperation {
            XCTFail("This should not run")
        }

        keyValueObservingExpectationForObject(operation, keyPath: "isFinished") {(op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.finished
            }

            return false
        }

        let opQ = OperationQueue()
        opQ.suspended = true
        opQ.addOperation(operation)
        operation.cancel()
        opQ.suspended = false


        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertTrue(operation.cancelled, "")
            XCTAssertTrue(operation.finished, "")
        }
    }
    
    func testCancelOperation_cancelAfterStart() {
        let exp = expectationWithDescription("")
        
        var operation: BlockOperation?
        operation = BlockOperation {
            operation?.cancel()
            exp.fulfill()
        }
        
        let opQ = OperationQueue()
        
        opQ.addOperation(operation!)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testBlockObserver() {
        let opQ = OperationQueue()
        
        var op: BlockOperation!
        op = BlockOperation {
            let producedOperation = BlockOperation {
                
            }
            
            op.produceOperation(producedOperation)
        }
        
        let exp1 = expectationWithDescription("1")
        let exp2 = expectationWithDescription("2")
        let exp3 = expectationWithDescription("3")
        
        let blockObserver = BlockObserver (
            startHandler: {
                _ in
                exp1.fulfill()
            },
            produceHandler: {
                _ in
                exp2.fulfill()
            },
            finishHandler: {
                _ in
                exp3.fulfill()
            }
        )
        
        op.addObserver(blockObserver)
        
        opQ.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testTimeoutObserver() {
        let delayOperation = DelayOperation(interval: 1)
        let timeoutObserver = TimeoutObserver(timeout: 0.1)
        
        delayOperation.addObserver(timeoutObserver)
        
        let opQ = OperationQueue()
        
        keyValueObservingExpectationForObject(delayOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        opQ.addOperation(delayOperation)
        
        waitForExpectationsWithTimeout(0.9, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels_inGroupOperation() {
        
        var dependencyOperation: BlockOperation!
        dependencyOperation = BlockOperation {
            dependencyOperation.cancel()
        }
        
        let operation = BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)
        operation.addDependency(dependencyOperation)
        
        let groupOp = GroupOperation(operations: [dependencyOperation, operation])
        
        keyValueObservingExpectationForObject(dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.cancelled
            }
            
            return false
        }
        
        keyValueObservingExpectationForObject(groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            if let op = op as? NSOperation {
                return op.finished
            }
            
            return false
        }
        
        let opQ = OperationQueue()
        opQ.addOperation(groupOp)
        
        waitForExpectationsWithTimeout(1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testOperationCompletionBlock() {
        let executingExpectation = expectationWithDescription("block")
        let completionExpectation = expectationWithDescription("completion")
        
        let opQueue = OperationQueue()
        
        let op = NSBlockOperation { () -> Void in
            executingExpectation.fulfill()
        }
        
        op.completionBlock = {
            completionExpectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testBlockOperationCanBeCancelledWhileExecuting() {
        
        let exp = expectationWithDescription("")
        
        var blockOperation: BlockOperation!
        blockOperation = BlockOperation {
            XCTAssertFalse(blockOperation.finished)
            blockOperation.cancel()
            exp.fulfill()
        }
        
        let q = OperationQueue()
        q.addOperation(blockOperation)
        
        keyValueObservingExpectationForObject(blockOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in

            guard let op = op as? NSOperation else { return false }
            return op.cancelled
        }
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testDelayOperationIsCancellableAndNotFinishedTillDelayTime() {
        
        let exp = expectationWithDescription("")
        
        let delayOp = DelayOperation(interval: 2)
        let blockOp = BlockOperation {
            XCTAssertFalse(delayOp.finished)
            delayOp.cancel()
            exp.fulfill()
        }
        
        let q = OperationQueue()
        
        q.addOperation(delayOp)
        q.addOperation(blockOp)
        
        keyValueObservingExpectationForObject(delayOp, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            guard let op = op as? NSOperation else { return false }
            
            return op.cancelled
        }
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testConcurrentOpsWithBlockingOp() {
        let exp = expectationWithDescription("")
        
        let delayOp = DelayOperation(interval: 4)
        let blockOp = BlockOperation {
            exp.fulfill()
        }
        
        let timeout = TimeoutObserver(timeout: 2)
        blockOp.addObserver(timeout)
        
        let q = OperationQueue()
        
        q.addOperation(delayOp)
        q.addOperation(blockOp)
        
        keyValueObservingExpectationForObject(q, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? NSOperationQueue where opQ.operationCount == 1 {
                if let _ = opQ.operations.first as? DelayOperation {
                    return true
                }
            }
            
            return false
        }
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testMoveFromPendingToFinishingByWayOfCancelAfterEnteringQueue() {
        let op = Operation()
        let delay = DelayOperation(interval: 0.1)
        op.addDependency(delay)
        
        let q = OperationQueue()
        
        q.addOperation(op)
        q.addOperation(delay)
        op.cancel()
        
        keyValueObservingExpectationForObject(q, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? NSOperationQueue where opQ.operationCount == 0 {
                return true
            }
            
            return false
        }
        
        waitForExpectationsWithTimeout(0.5, handler: nil)
        
    }
    
    
    func testOperationQueueWaitUntilFinished() {
        let opQ = OperationQueue()
        
        class WaitOp : Operation {
            
            var waitCalled = false
            
            override func waitUntilFinished() {
                waitCalled = true
            }
        }
        
        let op = WaitOp()
        
        opQ.addOperations([op], waitUntilFinished: true)
        
        XCTAssertEqual(1, opQ.operationCount)
        XCTAssertTrue(op.waitCalled)
    }
    
    /*
        In 9.1 (at least) we found that occasionaly OperationQueue would get stuck on an operation
        The operation would be ready, not finished, not cancelled, and have no dependencies. The queue
        would have no other operations, but the op still would not execute. We determined a few problems
        that could cause this issue to occur. This test was used to invoke the problem repeatedly. While we've
        seen the opCount surpass 100,000 easily we figured 25_000 operations executing one right after the other was
        a sufficient test and is still probably beyond typical use cases. We wish it could be more concrete, but it is not.
    */
    func testOperationQueueNotGettingStuck() {
        
        var opCount = 0
        var requiredToPassCount = 25_000
        let q = OperationQueue()
        
        let exp = expectationWithDescription("requiredToPassCount")
        
        func go() {
            
            if opCount >= requiredToPassCount {
                exp.fulfill()
                return
            }
            
            let blockOp = BlockOperation {
                (finishBlock: Void -> Void) in
                finishBlock()
                go()
            }
            
            //because of a change in evaluateConditions, this issue would only happen
            //if the op had a condition. NoCancelledDependcies is an easy condition to
            //use for this test.
            let noc = NoCancelledDependencies()
            blockOp.addCondition(noc)
            
            opCount += 1
            
            q.addOperation(blockOp)
        }
        
        go()
        
        waitForExpectationsWithTimeout(15) {
            _ in
            
            //if opCount != requiredToPassCount, the queue is frozen
            XCTAssertEqual(opCount, requiredToPassCount)
        }
    }
}
