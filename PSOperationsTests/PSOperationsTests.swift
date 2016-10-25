//
//  PSOperationsTests.swift
//  PSOperationsTests
//
//  Created by Dev Team on 6/17/15.
//  Copyright (c) 2015 pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest
import Foundation

struct TestCondition: OperationCondition {
    
    static let name = "TestCondition"
    static let isMutuallyExclusive = false
    var dependencyOperation: Foundation.Operation?

    var conditionBlock: () -> Bool = { true }
    
    func dependencyForOperation(_ operation: PSOperations.Operation) -> Foundation.Operation? {
        return dependencyOperation
    }
    
    func evaluateForOperation(_ operation: PSOperations.Operation, completion: @escaping (OperationConditionResult) -> Void) {
        if conditionBlock() {
            completion(.satisfied)
        } else {
            completion(.failed(NSError(code: .conditionFailed, userInfo: ["Failed": true])))
        }
    }
}

class TestObserver: OperationObserver {
    
    var errors: [NSError]?
    
    var didStartBlock: (()->())?
    var didEndBlock: (()->())?
    var didCancelBlock: (()->())?
    var didProduceBlock: (()->())?
    
    
    func operationDidStart(_ operation: PSOperations.Operation) {
        if let didStartBlock = didStartBlock {
            didStartBlock()
        }
    }
    
    func operation(_ operation: PSOperations.Operation, didProduceOperation newOperation: Foundation.Operation) {
        if let didProduceBlock = didProduceBlock {
            didProduceBlock()
        }
    }
    
    func operationDidCancel(_ operation: PSOperations.Operation) {
        
        if let didCancelBlock = didCancelBlock {
            didCancelBlock()
        }
    }
    
    func operationDidFinish(_ operation: PSOperations.Operation, errors: [NSError]) {
        self.errors = errors
        
        if let didEndBlock = didEndBlock {
            didEndBlock()
        }
    }

}

class PSOperationsTests: XCTestCase {
    
    func testAddingMultipleDeps() {
        let op = Foundation.Operation()
        
        let deps = [Foundation.Operation(),Foundation.Operation(),Foundation.Operation()]
        
        op.addDependencies(deps)
        
        XCTAssertEqual(deps.count, op.dependencies.count)
    }
    
    func testStandardOperation() {
        
        let expectation = self.expectation(description: "block")
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = Foundation.BlockOperation { () -> Void in
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testBlockOperation_noConditions_noDependencies() {
        
        let expectation = self.expectation(description: "block")
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = PSOperations.BlockOperation {
            expectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOperation_withPassingCondition_noDependencies() {
        
        let expectation = self.expectation(description: "block")
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = PSOperations.BlockOperation {
            expectation.fulfill()
        }
        
        op.addCondition(TestCondition())
        
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testOperation_withFailingCondition_noDependencies() {
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = PSOperations.BlockOperation {
            XCTFail("Should not have run the block operation")
        }
        
        keyValueObservingExpectation(for: op, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        XCTAssertFalse(op.isCancelled, "Should not yet have cancelled the operation")
        
        var condition = TestCondition()

        condition.conditionBlock = {
            return false
        }
        
        let exp = expectation(description: "observer")
        
        let observer = TestObserver()
        
        observer.didEndBlock = {
            XCTAssertEqual(observer.errors?.count, 1)
            exp.fulfill()
        }
        
        op.addCondition(condition)
        op.addObserver(observer)
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testOperation_withPassingCondition_andConditionDependency_noDependencies() {
        
        let expectation = self.expectation(description: "block")
        let expectation2 = self.expectation(description: "block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = PSOperations.BlockOperation {
            expectation.fulfill()
            fulfilledExpectations.append(expectation)
        }
        
        var testCondition = TestCondition()
        testCondition.dependencyOperation = PSOperations.BlockOperation {
            expectation2.fulfill()
            fulfilledExpectations.append(expectation2)
        }
        
        op.addCondition(testCondition)
        
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectation2, expectation], "Expectations fulfilled out of order")
        }
    }
    
    func testOperation_noCondition_hasDependency() {
        let anExpectation = expectation(description: "block")
        let expectationDependency = expectation(description: "block2")
        
        var fulfilledExpectations = [XCTestExpectation]()
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = PSOperations.BlockOperation {
            anExpectation.fulfill()
            fulfilledExpectations.append(anExpectation)
        }
        
        let opDependency = PSOperations.BlockOperation {
            expectationDependency.fulfill()
            fulfilledExpectations.append(expectationDependency)
        }
        
        op.addDependency(opDependency)
        
        opQueue.addOperation(op)
        opQueue.addOperation(opDependency)
        
        waitForExpectations(timeout: 1.0) {
            _ in
            XCTAssertEqual(fulfilledExpectations, [expectationDependency, anExpectation], "Expectations fulfilled out of order")
        }
    }
    
    func testGroupOperation() {
        let exp1 = expectation(description: "block1")
        let exp2 = expectation(description: "block2")
        
        let op1 = Foundation.BlockOperation {
            exp1.fulfill()
        }
        
        let op2 = Foundation.BlockOperation {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectation(for: groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.addOperation(groupOp)
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGroupOperation_cancelBeforeExecuting() {
        let exp1 = expectation(description: "block1")
        let exp2 = expectation(description: "block2")
        
        let op1 = Foundation.BlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op1.completionBlock = {
            exp1.fulfill()
        }
        
        let op2 = Foundation.BlockOperation {
            XCTFail("should not execute -- cancelled")
        }
        
        op2.completionBlock = {
            exp2.fulfill()
        }
        
        let groupOp = GroupOperation(operations: op1, op2)
        
        keyValueObservingExpectation(for: groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.isSuspended = true
        opQ.addOperation(groupOp)
        groupOp.cancel()
        opQ.isSuspended = false
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testDelayOperation() {
        let delay: TimeInterval = 0.1
        
        let then = Date()
        let op = DelayOperation(interval: delay)
        
        keyValueObservingExpectation(for: op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return false
        }
        
        PSOperations.OperationQueue().addOperation(op)
        
        waitForExpectations(timeout: delay + 1) {
            _ in
            let now = Date()
            let diff = now.timeIntervalSince(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testDelayOperation_With0() {
        let delay: TimeInterval = 0.0
        
        let then = Date()
        let op = DelayOperation(interval: delay)
        
        var done = false
        let lock = NSLock()
        
        keyValueObservingExpectation(for: op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            lock.lock()
            if let op = op as? Foundation.Operation, !done {
                done = op.isFinished
                lock.unlock()
                return op.isFinished
            }
            
            lock.unlock()
            
            return false
        }
        
        PSOperations.OperationQueue().addOperation(op)
        
        waitForExpectations(timeout: delay + 1) {
            _ in
            let now = Date()
            let diff = now.timeIntervalSince(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testDelayOperation_WithDate() {
        let delay: TimeInterval = 1
        let date = Date().addingTimeInterval(delay)
        let op = DelayOperation(until: date)
        
        let then = Date()
        keyValueObservingExpectation(for: op, keyPath: "isFinished") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return false
        }
        
        PSOperations.OperationQueue().addOperation(op)
        
        waitForExpectations(timeout: delay + 1) {
            _ in
            let now = Date()
            let diff = now.timeIntervalSince(then)
            XCTAssertTrue(diff >= delay, "Didn't delay long enough")
        }
    }
    
    func testMutualExclusion() {
        
        enum Test {}
        typealias TestMutualExclusion = MutuallyExclusive<Test>
        let cond = MutuallyExclusive<TestMutualExclusion>()
        
        var running = false
        
        let exp = expectation(description: "op2")
        
        let op = PSOperations.BlockOperation {
            running = true
            exp.fulfill()
        }
        op.addCondition(cond)
        
        let opQ = PSOperations.OperationQueue()
        opQ.maxConcurrentOperationCount = 2
        
        let delayOp = DelayOperation(interval: 0.1)
        
        delayOp.addCondition(cond)
        
        keyValueObservingExpectation(for: delayOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            XCTAssertFalse(running, "op should not yet have started execution")
            
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return true
        }

        opQ.addOperation(delayOp)
        opQ.addOperation(op)
        
        waitForExpectations(timeout: 0.9, handler: nil)
    }
    
    func testConditionObserversCalled() {
        
        let startExp = expectation(description: "startExp")
        let cancelExp = expectation(description: "cancelExp")
        let finishExp = expectation(description: "finishExp")
        let produceExp = expectation(description: "produceExp")
        
        var op: PSOperations.BlockOperation!
        op = PSOperations.BlockOperation {
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
        
        let q = PSOperations.OperationQueue()
        q.addOperation(op)
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testSilentCondition_failure() {
        
        var testCondition = TestCondition()
        
        testCondition.dependencyOperation = PSOperations.BlockOperation {
            XCTFail("should not run")
        }
        
        let exp = expectation(description: "")
        
        testCondition.conditionBlock = {
            exp.fulfill()
            return false
        }
        
        let silentCondition = SilentCondition(condition: testCondition)
        
        let opQ = PSOperations.OperationQueue()
        
        let operation = PSOperations.BlockOperation {
            XCTFail("should not run")
        }
        
        operation.addCondition(silentCondition)
        
        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        opQ.addOperation(operation)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testNegateCondition_failure() {
                
        let operation = PSOperations.BlockOperation {
            XCTFail("shouldn't run")
        }

        var testCondition = TestCondition()
        testCondition.conditionBlock = { true }

        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.addOperation(operation)

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testNegateCondition_success() {
        
        let exp = expectation(description: "")
        
        let operation = PSOperations.BlockOperation {
            exp.fulfill()
        }
        
        var testCondition = TestCondition()
        testCondition.conditionBlock = { false }
        
        let negateCondition = NegatedCondition(condition: testCondition)
        
        operation.addCondition(negateCondition)
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.addOperation(operation)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels() {
        let dependencyOperation = PSOperations.BlockOperation { }
        let operation = PSOperations.BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)
        
        operation.addDependency(dependencyOperation)

        keyValueObservingExpectation(for: dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        
        keyValueObservingExpectation(for: opQ, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? Foundation.OperationQueue {
                return opQ.operationCount == 0
            }
            
            return false
        }
        

        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation)
        dependencyOperation.cancel()
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testOperationRunsEvenIfDepCancels() {
        
        let dependencyOperation = PSOperations.BlockOperation {}
        
        let exp = expectation(description: "")
        
        let operation = PSOperations.BlockOperation {
            exp.fulfill()
        }
        
        operation.addDependency(dependencyOperation)
        
        keyValueObservingExpectation(for: dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.addOperation(operation)
        opQ.addOperation(dependencyOperation)
        dependencyOperation.cancel()
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testCancelledOperationLeavesQueue() {
        
        let operation = PSOperations.BlockOperation { }
        let operation2 = Foundation.BlockOperation { }
        
        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        opQ.maxConcurrentOperationCount = 1
        opQ.isSuspended = true
        
        keyValueObservingExpectation(for: opQ, keyPath: "operationCount", expectedValue: 0)
        
        opQ.addOperation(operation)
        opQ.addOperation(operation2)
        operation.cancel()
        
        opQ.isSuspended = false
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
//    This test exhibits odd behavior that needs to be investigated at some point.
//    It seems to be related to setting the maxConcurrentOperationCount to 1 so
//    I don't believe it is critical
//    func testCancelledOperationLeavesQueue() {
//        
//        let operation = PSOperations.BlockOperation { }
//        
//        let exp = expectation(description: "")
//        
//        let operation2 = PSOperations.BlockOperation {
//            exp.fulfill()
//        }
//        
//        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
//            (op, changes) -> Bool in
//            
//            if let op = op as? Foundation.Operation {
//                return op.isCancelled
//            }
//            
//            return false
//        }
//        
//        
//        let opQ = PSOperations.OperationQueue()
//        opQ.maxConcurrentOperationCount = 1
//        
//        opQ.addOperation(operation)
//        opQ.addOperation(operation2)
//        operation.cancel()
//        
//        waitForExpectations(timeout: 1, handler: nil)
//    }
    
    func testCancelOperation_cancelBeforeStart() {
        let operation = PSOperations.BlockOperation {
            XCTFail("This should not run")
        }

        keyValueObservingExpectation(for: operation, keyPath: "isFinished") {(op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }

            return false
        }

        let opQ = PSOperations.OperationQueue()
        opQ.isSuspended = true
        opQ.addOperation(operation)
        operation.cancel()
        opQ.isSuspended = false


        waitForExpectations(timeout: 1.0) {
            _ in
            XCTAssertTrue(operation.isCancelled, "")
            XCTAssertTrue(operation.isFinished, "")
        }
    }
    
    func testCancelOperation_cancelAfterStart() {
        let exp = expectation(description: "")
        
        var operation: PSOperations.BlockOperation?
        operation = PSOperations.BlockOperation {
            operation?.cancel()
            exp.fulfill()
        }
        
        let opQ = PSOperations.OperationQueue()
        
        opQ.addOperation(operation!)
        
        waitForExpectations(timeout: 1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testBlockObserver() {
        let opQ = PSOperations.OperationQueue()
        
        var op: PSOperations.BlockOperation!
        op = PSOperations.BlockOperation {
            let producedOperation = PSOperations.BlockOperation {
                
            }
            
            op.produceOperation(producedOperation)
        }
        
        let exp1 = expectation(description: "1")
        let exp2 = expectation(description: "2")
        let exp3 = expectation(description: "3")
        
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
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testTimeoutObserver() {
        let delayOperation = DelayOperation(interval: 1)
        let timeoutObserver = TimeoutObserver(timeout: 0.1)
        
        delayOperation.addObserver(timeoutObserver)
        
        let opQ = PSOperations.OperationQueue()
        
        keyValueObservingExpectation(for: delayOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        opQ.addOperation(delayOperation)
        
        waitForExpectations(timeout: 0.9, handler: nil)
    }
    
    func testNoCancelledDepsCondition_aDepCancels_inGroupOperation() {
        
        var dependencyOperation: PSOperations.BlockOperation!
        dependencyOperation = PSOperations.BlockOperation {
            dependencyOperation.cancel()
        }
        
        let operation = PSOperations.BlockOperation {
            XCTFail("shouldn't run")
        }
        
        let noCancelledCondition = NoCancelledDependencies()
        operation.addCondition(noCancelledCondition)
        operation.addDependency(dependencyOperation)
        
        let groupOp = GroupOperation(operations: [dependencyOperation, operation])
        
        keyValueObservingExpectation(for: dependencyOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        keyValueObservingExpectation(for: operation, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isCancelled
            }
            
            return false
        }
        
        keyValueObservingExpectation(for: groupOp, keyPath: "isFinished") {
            (op, changes) -> Bool in
            
            if let op = op as? Foundation.Operation {
                return op.isFinished
            }
            
            return false
        }
        
        let opQ = PSOperations.OperationQueue()
        opQ.addOperation(groupOp)
        
        waitForExpectations(timeout: 1.0) {
            _ in
            XCTAssertEqual(opQ.operationCount, 0, "")
        }
    }
    
    func testOperationCompletionBlock() {
        let executingExpectation = expectation(description: "block")
        let completionExpectation = expectation(description: "completion")
        
        let opQueue = PSOperations.OperationQueue()
        
        let op = Foundation.BlockOperation { () -> Void in
            executingExpectation.fulfill()
        }
        
        op.completionBlock = {
            completionExpectation.fulfill()
        }
        
        opQueue.addOperation(op)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testBlockOperationCanBeCancelledWhileExecuting() {
        
        let exp = expectation(description: "")
        
        var blockOperation: PSOperations.BlockOperation!
        blockOperation = PSOperations.BlockOperation {
            XCTAssertFalse(blockOperation.isFinished)
            blockOperation.cancel()
            exp.fulfill()
        }
        
        let q = PSOperations.OperationQueue()
        q.addOperation(blockOperation)
        
        keyValueObservingExpectation(for: blockOperation, keyPath: "isCancelled") {
            (op, changes) -> Bool in

            guard let op = op as? Foundation.Operation else { return false }
            return op.isCancelled
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testDelayOperationIsCancellableAndNotFinishedTillDelayTime() {
        
        let exp = expectation(description: "")
        
        let delayOp = DelayOperation(interval: 2)
        let blockOp = PSOperations.BlockOperation {
            XCTAssertFalse(delayOp.isFinished)
            delayOp.cancel()
            exp.fulfill()
        }
        
        let q = PSOperations.OperationQueue()
        
        q.addOperation(delayOp)
        q.addOperation(blockOp)
        
        keyValueObservingExpectation(for: delayOp, keyPath: "isCancelled") {
            (op, changes) -> Bool in
            
            guard let op = op as? Foundation.Operation else { return false }
            
            return op.isCancelled
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testConcurrentOpsWithBlockingOp() {
        let exp = expectation(description: "")
        
        let delayOp = DelayOperation(interval: 4)
        let blockOp = PSOperations.BlockOperation {
            exp.fulfill()
        }
        
        let timeout = TimeoutObserver(timeout: 2)
        blockOp.addObserver(timeout)
        
        let q = PSOperations.OperationQueue()
        
        q.addOperation(delayOp)
        q.addOperation(blockOp)
        
        keyValueObservingExpectation(for: q, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? Foundation.OperationQueue, opQ.operationCount == 1 {
                if let _ = opQ.operations.first as? DelayOperation {
                    return true
                }
            }
            
            return false
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testMoveFromPendingToFinishingByWayOfCancelAfterEnteringQueue() {
        let op = PSOperations.Operation()
        let delay = DelayOperation(interval: 0.1)
        op.addDependency(delay)
        
        let q = PSOperations.OperationQueue()
        
        q.addOperation(op)
        q.addOperation(delay)
        op.cancel()
        
        keyValueObservingExpectation(for: q, keyPath: "operationCount") {
            (opQ, changes) -> Bool in
            
            if let opQ = opQ as? Foundation.OperationQueue, opQ.operationCount == 0 {
                return true
            }
            
            return false
        }
        
        waitForExpectations(timeout: 0.5, handler: nil)
        
    }
    
    /* I'm not sure what this test is testing and the Foundation waitUntilFinished is being fickle
    func testOperationQueueWaitUntilFinished() {
        let opQ = PSOperations.OperationQueue()
        
        class WaitOp : Foundation.Operation {
            
            var waitCalled = false
            
            override func waitUntilFinished() {
                waitCalled = true
                super.waitUntilFinished()
            }
        }
        
        let op = WaitOp()
        
        opQ.addOperations([op], waitUntilFinished: true)
        
        XCTAssertEqual(0, opQ.operationCount)
        XCTAssertTrue(op.waitCalled)
    }
    */
    
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
        let q = PSOperations.OperationQueue()
        
        let exp = expectation(description: "requiredToPassCount")
        
        func go() {
            
            if opCount >= requiredToPassCount {
                exp.fulfill()
                return
            }
            
            let blockOp = PSOperations.BlockOperation {
                (finishBlock: (Void) -> Void) in
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
        
        waitForExpectations(timeout: 15) {
            _ in
            
            //if opCount != requiredToPassCount, the queue is frozen
            XCTAssertEqual(opCount, requiredToPassCount)
        }
    }
    
    
    
    func testOperationDidStartWhenSetMaxConcurrencyCountOnTheQueue() {
        
        let opQueue = PSOperations.OperationQueue()
        opQueue.maxConcurrentOperationCount = 1;
        
        let exp1 = expectation(description: "1")
        let exp2 = expectation(description: "2")
        let exp3 = expectation(description: "3")
        
        let op1 = PSOperations.BlockOperation {
            exp1.fulfill()
        }
        let op2 = PSOperations.BlockOperation {
            exp2.fulfill()
        }
        let op3 = PSOperations.BlockOperation {
            exp3.fulfill()
        }
        
        
        opQueue.addOperation(op1)
        opQueue.addOperation(op2)
        opQueue.addOperation(op3)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testOperationFinishedWithErrors() {
        let opQ = PSOperations.OperationQueue()
        
        class ErrorOp: PSOperations.Operation {
            
            let sema = DispatchSemaphore(value: 0)
            
            override func execute() {
                finishWithError(NSError(code: .executionFailed))
            }
            
            override func finished(_ errors: [NSError]) {
                sema.signal()
            }
            
            override func waitUntilFinished() {
                let _ = sema.wait(timeout: DispatchTime.distantFuture)
            }
        }
        
        let op = ErrorOp()
        
        opQ.addOperations([op], waitUntilFinished: true)
        
        XCTAssertEqual(op.errors, [NSError(code: .executionFailed)])
    }
    
    func testOperationCancelledWithErrors() {
        let opQ = PSOperations.OperationQueue()
        
        class ErrorOp: PSOperations.Operation {
            
            let sema = DispatchSemaphore(value: 0)
            
            override func execute() {
                cancelWithError(NSError(code: .executionFailed))
            }
            
            override func finished(_ errors: [NSError]) {
                sema.signal()
            }
            
            override func waitUntilFinished() {
                let _ = sema.wait(timeout: DispatchTime.distantFuture)
            }
        }
        
        let op = ErrorOp()
        
        opQ.addOperations([op], waitUntilFinished: true)
        
        XCTAssertEqual(op.errors, [NSError(code: .executionFailed)])
    }
    
}
