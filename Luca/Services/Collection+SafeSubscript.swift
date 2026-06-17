//
//  Collection+SafeSubscript.swift
//  Luca
//
//  Created by Assistant on 09/06/26.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
