//
//  User.swift
//
//
//  Created by Stanislav Ivanov on 14.05.24.
//

import Vapor

struct User: Authenticatable {
    let id: UUID
}
