//
//  CreateRecipe.swift
//
//
//  Created by Stanislav Ivanov on 12.04.24.
//

import Fluent

struct CreateRecipe: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipes")
            .id()
            .field("create_date", .datetime, .required)
            .field("name", .string, .required)
            .field("origin_area", .string)
            .field("is_secret", .bool, .required, .sql(.default(false)))
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipes").delete()
    }
}
