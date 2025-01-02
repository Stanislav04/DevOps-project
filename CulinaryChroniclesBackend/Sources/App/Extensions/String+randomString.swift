//
//  String+randomString.swift
//
//
//  Created by Stanislav Ivanov on 9.05.24.
//

import Foundation

extension String {
    private static let alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    static func randomString(withLength length: Int, from characters: String = .alphanumeric) -> Self {
        (0 ..< length).map { _ in String(characters.randomElement() ?? " ") }.reduce("", +)
    }
}
