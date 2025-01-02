import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { _ async -> String in
        "Hello, world!"
    }

    try app.register(collection: AuthenticationController())
    try app.register(collection: RecipeController())
}
