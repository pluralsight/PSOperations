//
//  Array+FMap.swift
//  pluralsight
//
//  Created by Dev Team on 6/17/15.
//  Copyright (c) 2015 pluralsight. All rights reserved.
//

import Foundation

extension Array {
    func fMap<T>(transform: (Array.Generator.Element) -> T?) -> [T] {
        let optionalArray = self.map(transform)
        
        var nonOptionalArray = [T]()
        
        for t in optionalArray {
            if let t = t {
                nonOptionalArray.append(t)
            }
        }
        
        return nonOptionalArray
    }
}

private func globalFilter<S : SequenceType>(source: S, includeElement: (S.Generator.Element) -> Bool) -> [S.Generator.Element] {
    return filter(source, includeElement)
}