//
//  configure.swift
//
//
//  Created by Stanislav Ivanov on 5.05.24.
//

@testable import App
import Fluent
import FluentSQLiteDriver
import Vapor

func configure(_ app: Application) async throws {
    try await App.configure(app)

    try app.register(collection: RecipeController(recipeImageRepository: LocalRecipeImageRepository(imageRepository: Application.imageRepository)))

    app.databases.use(.sqlite(.memory), as: .sqlite)
    try await app.autoMigrate()
}

extension Application {
    static let imageRepository = ImageRepositoryMock()
}
