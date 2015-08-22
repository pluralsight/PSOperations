/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to retrieve the user's location with an operation.
*/

import Foundation
import CoreLocation

/**
    `LocationOperation` is an `Operation` subclass to do a "one-shot" request to
    get the user's current location, with a desired accuracy. This operation will
    prompt for `WhenInUse` location authorization, if the app does not already 
    have it.
*/
public class LocationOperation: Operation, CLLocationManagerDelegate {
    // MARK: Properties
    
    private let accuracy: CLLocationAccuracy
    private var manager: CLLocationManager?
    private let handler: CLLocation -> Void
    
    // MARK: Initialization
 
    public init(accuracy: CLLocationAccuracy, locationHandler: CLLocation -> Void) {
        self.accuracy = accuracy
        self.handler = locationHandler
        super.init()
        addCondition(LocationCondition(usage: .WhenInUse))
        addCondition(MutuallyExclusive<CLLocationManager>())
    }
    
    override public func execute() {
        dispatch_async(dispatch_get_main_queue()) {
            /*
                `CLLocationManager` needs to be created on a thread with an active
                run loop, so for simplicity we do this on the main queue.
            */
            let manager = CLLocationManager()
            manager.desiredAccuracy = self.accuracy
            manager.delegate = self
            manager.startUpdatingLocation()
            
            self.manager = manager
        }
    }
    
    override public func cancel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.stopLocationUpdates()
            super.cancel()
        }
    }
    
    private func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
        manager = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last where location.horizontalAccuracy <= accuracy {
            stopLocationUpdates()
            handler(location)
            finish()
        }
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        stopLocationUpdates()
        finishWithError(error)
    }
}
