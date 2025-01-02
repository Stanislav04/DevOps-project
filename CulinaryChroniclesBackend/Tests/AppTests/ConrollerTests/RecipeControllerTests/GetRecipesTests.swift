//
//  GetRecipesTests.swift
//
//
//  Created by Stanislav Ivanov on 22.05.24.
//

@testable import App
import XCTVapor

final class RecipeControllerGetRecipesTests: XCTestCase {
    let app = Application(.testing)
    var recipeCreator = UUID()
    var secretRecipeId = UUID()
    var publicRecipeId = UUID()

    override func setUp() async throws {
        try await configure(app)

        let creator = try UserModel(username: "test", passwordHash: app.password.hash("test"))
        try await creator.save(on: app.db)
        try await AuthTokenModel(token: "test-token", deleteAt: .distantFuture, userId: creator.requireID()).save(on: app.db)
        recipeCreator = try creator.requireID()

        let user = try UserModel(username: "test1", passwordHash: app.password.hash("test1"))
        try await user.save(on: app.db)
        try await AuthTokenModel(token: "test-token1", deleteAt: .distantFuture, userId: user.requireID()).save(on: app.db)

        let publicRecipe = try RecipeModel(name: "Brownie", originArea: nil, userId: creator.requireID())
        try await publicRecipe.save(on: app.db)
        try await IngredientModel(value: "Sugar", position: 0, recipeId: publicRecipe.requireID()).save(on: app.db)
        try await InstructionModel(value: "Add sugar", position: 0, recipeId: publicRecipe.requireID()).save(on: app.db)
        try await InstructionModel(value: "Add cocoa", position: 1, recipeId: publicRecipe.requireID()).save(on: app.db)
        publicRecipeId = try publicRecipe.requireID()

        let secretRecipe = RecipeModel(name: "Brownie", originArea: nil, isSecret: true, userId: recipeCreator)
        try await secretRecipe.save(on: app.db)
        try await IngredientModel(value: "Sugar", position: 0, recipeId: secretRecipe.requireID()).save(on: app.db)
        try await InstructionModel(value: "Add sugar", position: 0, recipeId: secretRecipe.requireID()).save(on: app.db)
        try await InstructionModel(value: "Add cocoa", position: 1, recipeId: secretRecipe.requireID()).save(on: app.db)
        secretRecipeId = try secretRecipe.requireID()

        Application.imageRepository.images["\(baseDirectoryPath)/\(publicRecipeId)/test/public"] = try JSONEncoder().encode("test public data")
        Application.imageRepository.images["\(baseDirectoryPath)/\(secretRecipeId)/test/secret"] = try JSONEncoder().encode("test secret data")
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    private var baseDirectoryPath: String {
        Environment.get("RECIPE_IMAGE_FOLDER",
                        logWith: Logger(label: "Recipe Controller Get Recipes Tests")) ?? "./Resources/Images/recipe-images"
    }

    // MARK: - Get recipe

    func testGetRecipeByIdWithNoAuthTokenFails() throws {
        try app.test(.GET, "recipe/1", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testGetRecipeByIdWithInvalidId() throws {
        try app.test(.GET, "recipe/1", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testGetRecipeByIdWithIncorrectId() throws {
        try app.test(.GET, "recipe/\(UUID())", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }

    func testGetRecipeByIdWithSecretRecipeFailsWhenUserIsNotOwner() async throws {
        try app.test(.GET, "recipe/\(secretRecipeId)", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .notFound)
        })
    }

    func testGetRecipeByIdWithSecretRecipeSucceedsWhenUserIsOwner() throws {
        try app.test(.GET, "recipe/\(secretRecipeId)", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)

            let decodedRecipe = try response.content.decode(GetRecipeDto.self)
            XCTAssertEqual(decodedRecipe.id, secretRecipeId)
            XCTAssertEqual(decodedRecipe.name, "Brownie")
            XCTAssertNil(decodedRecipe.originArea)
            XCTAssertEqual(decodedRecipe.ingredients, ["Sugar"])
            XCTAssertEqual(decodedRecipe.instructions, ["Add sugar", "Add cocoa"])
            XCTAssertEqual(decodedRecipe.isSecret, true)
            XCTAssertEqual(decodedRecipe.photos, try [JSONEncoder().encode("test secret data")])
        })
    }

    func testGetRecipeByIdWithPublicRecipeSucceeds() throws {
        try app.test(.GET, "recipe/\(publicRecipeId)", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)

            let decodedRecipe = try response.content.decode(GetRecipeDto.self)
            XCTAssertEqual(decodedRecipe.id, publicRecipeId)
            XCTAssertEqual(decodedRecipe.name, "Brownie")
            XCTAssertNil(decodedRecipe.originArea)
            XCTAssertEqual(decodedRecipe.ingredients, ["Sugar"])
            XCTAssertEqual(decodedRecipe.instructions, ["Add sugar", "Add cocoa"])
            XCTAssertEqual(decodedRecipe.isSecret, false)
            XCTAssertEqual(decodedRecipe.photos, try [JSONEncoder().encode("test public data")])

        })
    }

    // MARK: - Get latest recipes

    func testGetLatestRecipesWithNoAuthTokenFails() throws {
        try app.test(.GET, "recipe/latest", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testGetLatestRecipesSuccessfullyReturnsLatestRecipes() throws {
        try app.test(.GET, "recipe/latest", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)

            let responseRecipes = try response.content.decode([GetRecipeDto].self)

            XCTAssertEqual(responseRecipes.count, 1)

            let recipe = try XCTUnwrap(responseRecipes.first)
            XCTAssertEqual(recipe.id, publicRecipeId)
            XCTAssertEqual(recipe.name, "Brownie")
            XCTAssertNil(recipe.originArea)
            XCTAssertEqual(recipe.ingredients, ["Sugar"])
            XCTAssertEqual(recipe.instructions, ["Add sugar", "Add cocoa"])
            XCTAssertEqual(recipe.isSecret, false)
            XCTAssertEqual(recipe.photos, try [JSONEncoder().encode("test public data")])

        })
    }
}
