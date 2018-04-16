/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file contains the foundational subclass of NSOperation.
*/

import Foundation

/**
    The subclass of `NSOperation` from which all other operations should be derived.
    This class adds both Conditions and Observers, which allow the operation to define
    extended readiness requirements, as well as notify many interested parties 
    about interesting operation state changes
*/
open class Operation: Foundation.Operation {
    
    // use the KVO mechanism to indicate that changes to "state" affect other properties as well
    private static let stateKey = Set([NSString(string: "state")])
    @objc class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> { return stateKey }
    @objc class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> { return stateKey }
    @objc class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> { return stateKey }
    @objc class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> { return stateKey }
    
    /* The completionBlock property has unexpected behaviors such as executing twice and executing on unexpected threads. BlockObserver
     * executes in an expected manner.
     */
    @available(*, deprecated, message: "use BlockObserver completions instead")
    override open var completionBlock: (() -> Void)? {
        set {
            fatalError("The completionBlock property on NSOperation has unexpected behavior and is not supported in PSOperations.Operation 😈")
        }
        get {
            return nil
        }
    }
    
    fileprivate let state = Atomic<State>(value: .initialized)
    fileprivate var internalErrors = Atomic<[NSError]>(value: [])
    fileprivate(set) var conditions: [OperationCondition] = []
    fileprivate(set) var observers: [OperationObserver] = []
    fileprivate var hasFinishedAlready = Atomic<Bool>(value: false)
    
    open var errors: [NSError] {
        return internalErrors.value
    }
    
    open var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }
        set {
            assert(state.value < .executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .userInitiated : .default
        }
    }
    
    private var _isReady = Atomic<Bool>(value: false)
    private var _isSuperReady = false
    private var _isReadyCanUpdateInternally = Atomic<Bool>(value: false) //rename to signify when it is a local update?
    override open var isReady: Bool {
        let superReady = super.isReady
        if _isReadyCanUpdateInternally.value, superReady, _isSuperReady != superReady {
            _isSuperReady = superReady
            if let updatedState = updateReadinessFromConditions(state: state.value) {
                updateState { $0 = updatedState }
            }
        }
        return _isReady.value
    }
    
    private var _isExecuting = Atomic<Bool>(value: false)
    override open var isExecuting: Bool {
        return _isExecuting.value
    }
    
    private var _isFinished = Atomic<Bool>(value: false)
    override open var isFinished: Bool {
        return _isFinished.value
    }
    
    private var _isCancelled = Atomic<Bool>(value: false)
    override open var isCancelled: Bool {
        return _isCancelled.value
    }
    
    /**
        Indicates that the Operation can now begin to evaluate readiness conditions,
        if appropriate.
    */
    func didEnqueue() {
        updateState { $0 = .pending }
    }

    private func updateState(_ stateModifier: (inout State) -> Void) {
        updateStateAndCancelState { state, cancel in
            stateModifier(&state)
        }
    }
    
    private func updateStateAndCancelState(_ stateModifier: (inout State, inout Bool) -> Void) {
        state.modify { state in
            _isReadyCanUpdateInternally.value = false
            willChangeValue(forKey: "state")
            var newState: State = state {
                willSet {
                    guard newState != newValue else { return }
                    assert(newState.canTransitionToState(newValue, operationIsCancelled: isCancelled), "Performing invalid state transition. from: \(newState) to: \(newValue) \(self)")
                }
                didSet {
                    state = newState
                }
            }

            var newCancel = _isCancelled.value

            stateModifier(&newState, &newCancel)

            let updatedCancelState = newCancel
            if updatedCancelState {
                if updatedCancelState != _isCancelled.value {
                    if let updatedState = updateToCancelled(state: newState) {
                        newState = updatedState
                    }
                }
            } else if let updatedState = updateReadinessFromConditions(state: newState) {
                newState = updatedState
            }
            
            updateOperationStateValues(state: state, cancelled: updatedCancelState)
            
            didChangeValue(forKey: "state")
            _isReadyCanUpdateInternally.value = true
        }
    }
    
    private func updateToCancelled(state: State) -> State? {
        var updatedState: State?
        
        if state == .initialized || state == .pending {
            updatedState = .ready
        }
        
        for observer in observers {
            observer.operationDidCancel(self)
        }
        
        return updatedState
    }
    
    private func updateReadinessFromConditions(state: State) -> State? {
        var updatedState: State?
        if state == .pending, super.isReady {
            if conditions.isEmpty {
                updatedState = .ready
            } else {
                updatedState = .evaluatingConditions
                evaluateConditions()
            }
        }
        return updatedState
    }
    
    private func updateOperationStateValues(state: State, cancelled: Bool) {
        if cancelled {
            _isCancelled.value = true
            _isReady.value = true
        } else {
            switch state {
            case .initialized, .evaluatingConditions, .pending:
                _isReady.value = false
            case .ready, .executing, .finished:
                _isReady.value = true
            }
        }
        
        _isExecuting.value = state == .executing
        _isFinished.value = state == .finished
    }
    
    // MARK: Observers and Conditions
    private func evaluateConditions() {
        OperationConditionEvaluator.evaluate(conditions, operation: self) { failures in
            self.updateStateAndCancelState { state, isCancelled in
                if failures.isEmpty {
                    state = .ready
                } else {
                    self.cancelWithErrors(failures, state: &state, isCancelled: &isCancelled)
                }
            }
        }
    }
    
    open func addCondition(_ condition: OperationCondition) {
        assert(state.value < .evaluatingConditions, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }

    open func addObserver(_ observer: OperationObserver) {
        assert(state.value < .executing, "Cannot modify observers after execution has begun.")
        observers.append(observer)
    }
    
    override open func addDependency(_ operation: Foundation.Operation) {
        assert(state.value <= .executing, "Dependencies cannot be modified after execution has begun.")
        super.addDependency(operation)
    }
    
    // MARK: Execution
    override final public func main() {
        var runExecute = false
        
        updateStateAndCancelState { state, isCancelled in
            if !isCancelled, internalErrors.value.isEmpty  {
                assert(state == .ready, "This operation must be performed on an operation queue.")
                state = .executing

                for observer in observers {
                    observer.operationDidStart(self)
                }
                
                runExecute = true
            }
        }
        
        if runExecute {
            execute()
        } else {
            finish()
        }
    }
    
    /**
    `execute()` is the entry point of execution for all `Operation` subclasses.
    If you subclass `Operation` and wish to customize its execution, you would
    do so by overriding the `execute()` method.
    
    At some point, your `Operation` subclass must call one of the "finish"
    methods defined below; this is how you indicate that your operation has
    finished its execution, and that operations dependent on yours can re-evaluate
    their readiness state.
    */
    open func execute() {
        print("\(type(of: self)) must override `execute()`.")
        finish()
    }
    
    // MARK: Cancellation
    private func cancel(state: inout State, isCancelled: inout Bool) {
        guard !isFinished else { return }
        isCancelled = true
        finish(state: &state)
    }
    
    override open func cancel() {
        updateStateAndCancelState { state, isCancelled in
            cancel(state: &state, isCancelled: &isCancelled)
        }
    }
    
    private func cancelWithErrors(_ errors: [NSError], state: inout State, isCancelled: inout Bool) {
        internalErrors.modify { $0 = $0 + errors }
        cancel(state: &state, isCancelled: &isCancelled)
    }
    
    open func cancelWithErrors(_ errors: [NSError]) {
        internalErrors.modify { $0 = $0 + errors }
        cancel()
    }
    
    open func cancelWithError(_ error: NSError) {
        cancelWithErrors([error])
    }
    
    public final func produceOperation(_ operation: Foundation.Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    // MARK: Finishing
    
    /**
        Most operations may finish with a single error, if they have one at all.
        This is a convenience method to simplify calling the actual `finish()` 
        method. This is also useful if you wish to finish with an error provided 
        by the system frameworks. As an example, see `DownloadEarthquakesOperation` 
        for how an error from an `NSURLSession` is passed along via the 
        `finishWithError()` method.
    */
    public final func finishWithError(_ error: NSError?) {
        if let error = error {
            finish([error])
        } else {
            finish()
        }
    }
    
    /**
        A private property to ensure we only notify the observers once that the 
        operation has finished.
    */
    public final func finish(_ errors: [NSError] = []) {
        updateState { state in
            finish(state: &state, errors)
        }
    }
    
    private func finish(state: inout State, _ errors: [NSError] = []) {
        guard !hasFinishedAlready.value else { return }
        hasFinishedAlready.value = true
        
        var finishWithErrors: [NSError] = []
        internalErrors.modify { internalErrors in
            internalErrors.append(contentsOf: errors)
            finishWithErrors = internalErrors
        }
        
        finished(finishWithErrors)
        
        for observer in observers {
            observer.operationDidFinish(self, errors: finishWithErrors)
        }
        state = .finished
    }
    
    /**
        Subclasses may override `finished(_:)` if they wish to react to the operation
        finishing with errors. For example, the `LoadModelOperation` implements 
        this method to potentially inform the user about an error when trying to
        bring up the Core Data stack.
    */
    open func finished(_ errors: [NSError]) { }
    
    override open func waitUntilFinished() {
        /*
            Waiting on operations is almost NEVER the right thing to do. It is 
            usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
            or `dispatch_group_notify`, or even `NSLocking` objects. Many developers 
            use waiting when they should instead be chaining discrete operations 
            together using dependencies.
            
            To reinforce this idea, invoking `waitUntilFinished()` will crash your
            app, as incentive for you to find a more appropriate way to express
            the behavior you're wishing to create.
        */
        fatalError("Waiting on operations is an anti-pattern.")
    }
}
