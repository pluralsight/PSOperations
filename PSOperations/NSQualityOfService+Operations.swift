//
//  NSQualityOfService+Operations.swift
//  PSOperations
//
//  Created by Cezary Wojcik on 4/16/16.
//

import Foundation

public extension NSQualityOfService {

    func stringRepresentation() -> String {
        switch self {
        case .UserInteractive:
            return "UserInteractive"
        case .UserInitiated:
            return "UserInitiated"
        case .Utility:
            return "Utility"
        case .Background:
            return "Background"
        case .Default:
            return "Default"
        }
    }
    
}
