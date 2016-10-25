//
//  URLSessionTaskOperationTests.swift
//  PSOperations
//
//  Created by Matt McMurry on 9/30/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

public extension URLSession {
    
    struct SharedInstance {
        static var instance = URLSession.shared
    }
    
    public func setProtocolClasses(classes: [AnyClass]) {
        let sessionconfig = URLSession.PSSession.configuration
        sessionconfig.protocolClasses = classes
        SharedInstance.instance = URLSession(configuration: sessionconfig)
    }
    
    public static var PSSession: URLSession {
        return SharedInstance.instance
    }
}

class TestURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    func GETjson() -> [String: AnyObject] {
        return ["cool": "beans" as AnyObject]
    }
    
    override func startLoading() {
        let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])
        
        client?.urlProtocol(self, didReceive: resp!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: GETjson(), options: []))
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
}

class URLSessionTaskOperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLSession.PSSession.setProtocolClasses(classes: [TestURLProtocol.self])
    }
    
    override func tearDown() {
        super.tearDown()
        URLSession.PSSession.setProtocolClasses(classes: [])
    }
    
    func testSuccess() {
        
        let taskThing: URLSessionTask = URLSession.PSSession.dataTask(with: URL(string: "http://winning")!) {
            data, response, error in
            XCTAssertNil(error)
        }
        
        let op = URLSessionTaskOperation(task: taskThing)
        let q = PSOperations.OperationQueue()
        q.addOperation(op)
        
        keyValueObservingExpectation(for: op, keyPath: "isFinished") {
            _ in
            return op.isFinished
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testCancel() {
        
        let exp = expectation(description: "")
        
        let taskThing: URLSessionTask = URLSession.PSSession.dataTask(with: URL(string: "http://winning")!) {
            data, response, error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        
        let op = URLSessionTaskOperation(task: taskThing)
        let q = PSOperations.OperationQueue()
        q.isSuspended = true
        q.addOperation(op)
        op.cancel()
        q.isSuspended = false
        
        XCTAssertTrue(op.isCancelled)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
