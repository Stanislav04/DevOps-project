//
//  InstructionModel.swift
//
//
//  Created by Stanislav Ivanov on 8.04.24.
//

import FluentKit
import Foundation

final class InstructionModel: Model {
    static let schema: String = "instructions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "instruction")
    var value: String

    @Field(key: "position")
    var position: UInt

    @Parent(key: "recipe_id")
    var recipe: RecipeModel

    init() {}

    init(id: UUID? = nil, value: String, position: UInt, recipeId: RecipeModel.IDValue) {
        self.id = id
        self.value = value
        self.position = position
        $recipe.id = recipeId
    }
}
