//
//  RetryOperation.swift
//  PSOperations
//
//  Created by Bart Whiteley on 9/22/15.
//


public class RetryOperation: GroupOperation {
    private let operationProducer: () -> Operation
    private let shouldRetry: (errors:[NSError], retryCount:Int) -> Bool
    private var numberOfRetries: Int = 0
    
    public convenience init(@autoclosure(escaping) operation: () -> Operation, maximumNumberOfRetries: Int = 5) {
        self.init(operationProducer: operation, shouldRetry: { (_, retries) in return retries < maximumNumberOfRetries })
    }
    
    public init(operationProducer: Void -> Operation, shouldRetry: (errors:[NSError], retryCount:Int) -> Bool) {
        self.operationProducer = operationProducer
        self.shouldRetry = shouldRetry
        
        let initial = operationProducer()
        super.init(operations: [initial])
    }
    
    public override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
        if shouldRetry(errors:errors, retryCount:numberOfRetries) {
            numberOfRetries++
            addOperation(operationProducer())
        }
    }
}

