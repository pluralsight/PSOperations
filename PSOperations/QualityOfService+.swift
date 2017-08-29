//
//  QualityOfService+.swift
//  PSOperations
//
//  Created by Dev Team on 8/29/17.
//  Copyright © 2017 Pluralsight. All rights reserved.
//

import Foundation

extension DispatchQoS.QoSClass {
    init(qos: QualityOfService) {
        switch qos {
        case .userInteractive:
            self = .userInteractive
        case .userInitiated:
            self = .userInitiated
        case .utility:
            self = .utility
        case .background:
            self = .background
        case .default:
            self = .default
        }
    }
}
