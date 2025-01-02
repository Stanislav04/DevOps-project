//
//  RecipeModel.swift
//
//
//  Created by Stanislav Ivanov on 5.04.24.
//

import FluentKit
import Foundation

final class RecipeModel: Model {
    static let schema = "recipes"

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "create_date", on: .create)
    var createDate: Date?

    @Field(key: "name")
    var name: String

    @Field(key: "origin_area")
    var originArea: String?

    @Field(key: "is_secret")
    var isSecret: Bool

    @Children(for: \.$recipe)
    var ingredients: [IngredientModel]

    @Children(for: \.$recipe)
    var instructions: [InstructionModel]

    @Parent(key: "user_id")
    var user: UserModel

    init() {}

    init(id: UUID? = nil, name: String, originArea: String?, isSecret: Bool = false, userId: UserModel.IDValue) {
        self.id = id
        self.name = name
        self.originArea = originArea
        self.isSecret = isSecret
        $user.id = userId
    }

    static func query(from database: Database) -> QueryBuilder<RecipeModel> {
        RecipeModel.query(on: database)
            .with(\.$ingredients)
            .with(\.$instructions)
    }
}
