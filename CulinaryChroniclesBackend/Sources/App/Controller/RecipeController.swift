//
//  RecipeController.swift
//
//
//  Created by Elena Varbanova on 16.05.24.
//

import Fluent
import Vapor

struct RecipeController: RouteCollection {
    let logger = Logger(label: "Recipe Controller")
    private(set) var recipeImageRepository: RecipeImageRepository = LocalRecipeImageRepository()

    func boot(routes: any Vapor.RoutesBuilder) throws {
        let routes = routes.grouped(UserTokenAuthenticator(), User.guardMiddleware()).grouped("recipe")

        routes.post(use: createRecipe)
        routes.on(.POST, body: .collect(maxSize: "100mb"), use: createRecipe)
        routes.get(":id", use: getRecipeById)
        routes.get("latest", use: getLatestRecipes)
    }

    @Sendable
    func createRecipe(request: Request) async throws -> Response {
        guard let userId = request.auth.get(User.self)?.id else {
            throw Abort(.unauthorized)
        }

        let recipeData: CreateRecipeDto
        do {
//            try CreateRecipeDto.validate(content: request)
            recipeData = try request.content.decode(CreateRecipeDto.self)
        } catch {
            logger.info("Tried to create recipe with invalid data!")
            throw Abort(.badRequest)
        }

        let recipe: RecipeModel
        let recipeId: UUID
        do {
            recipe = RecipeModel(name: recipeData.name, originArea: recipeData.originArea, isSecret: recipeData.isSecret, userId: userId)
            try await recipe.save(on: request.db)
            recipeId = try recipe.requireID()

            for (index, value) in recipeData.ingredients.enumerated() {
                try await IngredientModel(value: value, position: UInt(index), recipeId: recipe.requireID()).save(on: request.db)
            }

            for (index, value) in recipeData.instructions.enumerated() {
                try await InstructionModel(value: value, position: UInt(index), recipeId: recipe.requireID()).save(on: request.db)
            }

            try recipeData.photos.forEach {
                try recipeImageRepository.save(image: $0, from: userId.uuidString, for: recipeId.uuidString)
            }
        } catch {
            logger.info("Something went wrong with saving the recipe!")
            try? await recipe.delete(on: request.db)
            throw Abort(.internalServerError)
        }

        logger.info("Succesfully saved recipe!")
        let response = Response(status: .created)
        try response.content.encode(GetRecipeDto(id: recipeId,
                                                 name: recipeData.name,
                                                 originArea: recipeData.originArea,
                                                 ingredients: recipeData.ingredients,
                                                 instructions: recipeData.instructions,
                                                 photos: recipeData.photos,
                                                 isSecret: recipeData.isSecret))
        return response
    }

    @Sendable
    func getRecipeById(request: Request) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            logger.info("Missing user information!")
            throw Abort(.badRequest)
        }
        guard let recipeId = request.parameters.get("id", as: UUID.self) else {
            logger.info("Missing recipe ID!")
            throw Abort(.badRequest)
        }

        guard let recipe = try await RecipeModel.query(from: request.db)
            .filter(\.$id == recipeId)
            .first() else {
            logger.info("Recipe with id: \(recipeId) not found!")
            throw Abort(.notFound)
        }

        if recipe.isSecret,
           user.id != recipe.$user.id {
            logger.info("Unauthorized access attempt to secret recipe!")
            throw Abort(.notFound)
        }

        let response = Response(status: .ok)
        try response.content.encode(GetRecipeDto(id: recipeId,
                                                 name: recipe.name,
                                                 originArea: recipe.originArea,
                                                 ingredients: recipe.ingredients.sorted { $0.position < $1.position }.map(\.value),
                                                 instructions: recipe.instructions.sorted { $0.position < $1.position }.map(\.value),
                                                 photos: (try? recipeImageRepository.getImages(for: recipeId.uuidString)) ?? [],
                                                 isSecret: recipe.isSecret))
        return response
    }

    @Sendable
    func getLatestRecipes(request: Request) async throws -> Response {
        do {
            let latestRecipesCount = Environment.get("LATEST_RECIPES_COUNT", logWith: logger).flatMap(Int.init) ?? 50
            let recipes = try await RecipeModel.query(from: request.db)
                .filter(\.$isSecret == false)
                .sort(\.$createDate, .descending)
                .limit(latestRecipesCount).all()

            let response = Response(status: .ok)
            let recipesData = try recipes.map { recipe in
                try GetRecipeDto(id: recipe.requireID(),
                                 name: recipe.name,
                                 originArea: recipe.originArea,
                                 ingredients: recipe.ingredients.sorted { $0.position < $1.position }.map(\.value),
                                 instructions: recipe.instructions.sorted { $0.position < $1.position }.map(\.value),
                                 photos: (try? recipeImageRepository.getImages(for: recipe.requireID().uuidString)) ?? [],
                                 isSecret: recipe.isSecret)
            }
            try response.content.encode(recipesData)
            return response
        } catch {
            logger.info("Something went wrong while fetching and transforming recipes!")
            throw Abort(.internalServerError)
        }
    }
}
