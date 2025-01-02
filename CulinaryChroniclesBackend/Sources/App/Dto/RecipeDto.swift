//
//  RecipeDto.swift
//  
//
//  Created by Elena Varbanova on 16.05.24.
//

import Vapor

struct CreateRecipeDto: Content, Validatable {
    let name: String
    let originArea: String?
    let ingredients: [String]
    let instructions: [String]
    let photos: [Data]
    var isSecret = false

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("ingredients", as: [String].self, is: !.empty)
        validations.add("instructions", as: [String].self, is: !.empty)
        validations.add("photos", as: [String].self, is: !.empty)
    }
}

struct GetRecipeDto: Content {
    let id: UUID
    let name: String
    let originArea: String?
    let ingredients: [String]
    let instructions: [String]
    let photos: [Data]
    let isSecret: Bool
}
