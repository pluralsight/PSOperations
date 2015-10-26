//
//  URLSessionTaskOperationTests.swift
//  PSOperations
//
//  Created by Matt McMurry on 9/30/15.
//  Copyright © 2015 Pluralsight. All rights reserved.
//

@testable import PSOperations
import XCTest

public extension NSURLSession {
    
    struct SharedInstance {
        static var instance = NSURLSession.sharedSession()
    }
    
    public func setProtocolClasses(classes: [AnyClass]) {
        let sessionconfig = NSURLSession.PSSession.configuration
        sessionconfig.protocolClasses = classes
        SharedInstance.instance = NSURLSession(configuration: sessionconfig)
    }
    
    public static var PSSession: NSURLSession {
        return SharedInstance.instance
    }
}

class TestURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    func GETjson() -> [String: AnyObject] {
        return ["cool": "beans"]
    }
    
    override func startLoading() {
        let resp = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])
        
        client?.URLProtocol(self, didReceiveResponse: resp!, cacheStoragePolicy: .NotAllowed)
        client?.URLProtocol(self, didLoadData: try! NSJSONSerialization.dataWithJSONObject(GETjson(), options: []))
        client?.URLProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
}

class URLSessionTaskOperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        NSURLSession.PSSession.setProtocolClasses([TestURLProtocol.self])
    }
    
    override func tearDown() {
        super.tearDown()
        NSURLSession.PSSession.setProtocolClasses([])
    }
    
    func testSuccess() {
        
        let taskThing: NSURLSessionTask = NSURLSession.PSSession.dataTaskWithURL(NSURL(string: "http://winning")!) {
            data, response, error in
            XCTAssertNil(error)
        }
        
        let op = URLSessionTaskOperation(task: taskThing)
        let q = OperationQueue()
        q.addOperation(op)
        
        keyValueObservingExpectationForObject(op, keyPath: "isFinished") {
            _ in
            return op.finished
        }
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCancel() {
        
        let exp = expectationWithDescription("")
        
        let taskThing: NSURLSessionTask = NSURLSession.PSSession.dataTaskWithURL(NSURL(string: "http://winning")!) {
            data, response, error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }
        
        let op = URLSessionTaskOperation(task: taskThing)
        let q = OperationQueue()
        q.suspended = true
        q.addOperation(op)
        op.cancel()
        q.suspended = false
        
        XCTAssertTrue(op.cancelled)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
