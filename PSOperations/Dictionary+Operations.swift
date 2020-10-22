/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to Swift.Dictionary.
*/

extension Dictionary {
    /**
        It's not uncommon to want to turn a sequence of values into a dictionary,
        where each value is keyed by some unique identifier. This initializer will
        do that.
        
        - parameter sequence: The sequence to be iterated

        - parameter keyer: The closure that will be executed for each element in 
            the `sequence`. The return value of this closure, will
            be used as the key for the value in the `Dictionary`.
    */
    init<Sequence: Swift.Sequence>(sequence: Sequence, keyMapper: (Value) -> Key) where Sequence.Element == Value {
        self.init(sequence.map { (keyMapper($0), $0) }, uniquingKeysWith: { $1 })
    }
}
