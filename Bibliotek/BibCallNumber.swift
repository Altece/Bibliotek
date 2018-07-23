//
//  BibCallNumber.swift
//  Bibliotek
//
//  Created by Steve Brunwasser on 6/10/18.
//  Copyright © 2018 Steve Brunwasser. All rights reserved.
//

import Foundation

extension CallNumber {
    public static func == (lhs: CallNumber, rhs: CallNumber) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}

extension CallNumber: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return description
    }
}
