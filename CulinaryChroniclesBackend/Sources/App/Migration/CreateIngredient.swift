//
//  CreateIngredient.swift
//
//
//  Created by Stanislav Ivanov on 12.04.24.
//

import Fluent

struct CreateIngredient: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("ingredients")
            .id()
            .field("ingredient", .string, .required)
            .field("position", .uint8, .required)
            .field("recipe_id", .uuid, .required)
            .foreignKey("recipe_id", references: "recipes", "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("ingredients").delete()
    }
}
