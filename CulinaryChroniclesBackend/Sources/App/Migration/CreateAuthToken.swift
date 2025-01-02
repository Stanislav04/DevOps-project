//
//  CreateAuthToken.swift
//
//
//  Created by Stanislav Ivanov on 14.05.24.
//

import Fluent

struct CreateAuthToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("auth_tokens")
            .id()
            .field("token", .string, .required)
            .field("delete_date", .datetime, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "token")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("auth_tokens").delete()
    }
}
