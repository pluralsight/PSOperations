//
//  DispatchQueue+.swift
//  PSOperations
//
//  Created by Dev Team on 8/29/17.
//  Copyright © 2017 Pluralsight. All rights reserved.
//

import Foundation

extension DispatchQueue {
    class func global(qos: QualityOfService) -> DispatchQueue {
        return global(qos: .init(qos: qos))
    }
}
