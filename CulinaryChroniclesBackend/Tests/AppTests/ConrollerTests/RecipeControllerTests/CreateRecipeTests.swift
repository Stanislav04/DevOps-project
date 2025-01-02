//
//  CreateRecipeTests.swift
//
//
//  Created by Elena Varbanova on 16.05.24.
//

@testable import App
import XCTVapor

final class RecipeControllerCreateRecipeTests: XCTestCase {
    let app = Application(.testing)

    override func setUp() async throws {
        try await configure(app)

        let user = try UserModel(username: "test", passwordHash: app.password.hash("test"))
        try await user.save(on: app.db)
        try await AuthTokenModel(token: "test-token", deleteAt: .distantFuture, userId: user.requireID()).save(on: app.db)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    private var baseDirectoryPath: String {
        Environment.get("RECIPE_IMAGE_FOLDER",
                        logWith: Logger(label: "Recipe Controller Create Recipe Tests")) ?? "./Resources/Images/recipe-images"
    }

    // MARK: - Create recipe

    func testCreateRecipeWithNoAuthTokenFails() throws {
        try app.test(.POST, "recipe", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testCreateRecipeWithIncorrectDataModelProvidedFails() throws {
        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testCreateRecipeWithEmptyNameFails() throws {
        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(CreateRecipeDto(name: "", originArea: nil, ingredients: [""],
                                                       instructions: [""], photos: [Data()]))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testCreateRecipeWithEmptyIngredientsFails() throws {
        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(CreateRecipeDto(name: "Brownie", originArea: nil, ingredients: [],
                                                       instructions: [""], photos: [Data()]))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testCreateRecipeWithEmptyInstructionsFails() throws {
        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(CreateRecipeDto(name: "Brownie", originArea: nil, ingredients: ["1 sugar", "2 magic"],
                                                       instructions: [], photos: [Data()]))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testCreateRecipeWithEmptyPhotosFails() throws {
        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(CreateRecipeDto(name: "Brownie", originArea: nil, ingredients: ["1 sugar", "2 magic"],
                                                       instructions: ["Add the magic forget about the sugar"], photos: []))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testCreateRecipeWithProvidedDataDecodesModelSuccessfully() async throws {
        let recipe = try CreateRecipeDto(name: "Brownie",
                                         originArea: nil,
                                         ingredients: ["1 sugar", "2 magic"],
                                         instructions: ["Add the maguc forget about the sugar"],
                                         photos: [JSONEncoder().encode("test data")],
                                         isSecret: true)

        try app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(recipe)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .created)

            let responseRecipe = try response.content.decode(CreateRecipeDto.self)

            XCTAssertEqual(responseRecipe.name, recipe.name)
            XCTAssertEqual(responseRecipe.originArea, recipe.originArea)
            XCTAssertEqual(responseRecipe.ingredients, recipe.ingredients)
            XCTAssertEqual(responseRecipe.instructions, recipe.instructions)
            XCTAssertEqual(responseRecipe.photos, try [JSONEncoder().encode("test data")])
            XCTAssertEqual(responseRecipe.isSecret, recipe.isSecret)
        })
    }

    func testCreateRecipeWithProvidedDataModelSucceeds() async throws {
        let recipe = try CreateRecipeDto(name: "Brownie",
                                         originArea: nil,
                                         ingredients: ["1 sugar", "2 magic"],
                                         instructions: ["Add the magic forget about the sugar"],
                                         photos: [JSONEncoder().encode("test data")],
                                         isSecret: true)

        try await app.test(.POST, "recipe", beforeRequest: { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
            try request.content.encode(recipe)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .created)

            let savedRecipes = try await app.db.query(RecipeModel.self).first()
            let savedRecipe = try XCTUnwrap(savedRecipes, "Test recipe should be saved!")
            XCTAssertEqual(savedRecipe.name, recipe.name)
            XCTAssertEqual(savedRecipe.originArea, recipe.originArea)
            XCTAssertEqual(savedRecipe.isSecret, recipe.isSecret)

            let savedIngredients = try await app.db.query(IngredientModel.self).all()
            for (index, ingredient) in recipe.ingredients.enumerated() {
                let savedIngredient = savedIngredients.first { $0.position == index && $0.value == ingredient }
                XCTAssertNotNil(savedIngredient)
            }

            let savedInstructions = try await app.db.query(InstructionModel.self).all()
            for (index, instruction) in recipe.instructions.enumerated() {
                let savedInstruction = savedInstructions.first { $0.position == index && $0.value == instruction }
                XCTAssertNotNil(savedInstruction)
            }

            XCTAssertEqual(Application.imageRepository.images.values.first,
                           try JSONEncoder().encode("test data"))
        })
    }
}
