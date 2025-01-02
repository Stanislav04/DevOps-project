//
//  Array+uniqued.swift
//
//
//  Created by Stanislav Ivanov on 4.06.24.
//

import Foundation

extension Array where Element: Hashable {
    var uniqued: Self {
        var visited: Set<Element> = []
        return filter { visited.insert($0).inserted }
    }
}
