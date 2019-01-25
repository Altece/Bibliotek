//
//  _BibMarcRecord.swift
//  Bibliotek
//
//  Created by Steve Brunwasser on 7/18/18.
//  Copyright © 2018 Steve Brunwasser. All rights reserved.
//

import Foundation

extension _MarcRecord: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return fields.map { $0.description }
    }
}
