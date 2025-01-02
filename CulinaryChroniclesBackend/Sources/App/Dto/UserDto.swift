//
//  UserDto.swift
//
//
//  Created by Stanislav Ivanov on 1.05.24.
//

import Vapor

struct RegisterUserDto: Content {
    let email: String
    let password: String
}
