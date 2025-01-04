import Fluent
import FluentMySQLDriver
import Leaf
import NIOSSL
import Vapor

public func configure(_ app: Application) async throws {
    app.logger = Logger(label: "Culinary Chronicles")
    let setupLogger = Logger(label: "server setup")

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if app.environment != .testing {
        guard let databaseUsername = Environment.get("ADMIN_USERNAME", logWith: setupLogger),
              let databasePassword = Environment.get("ADMIN_PASSWORD", logWith: setupLogger) else {
            throw MissingCredentialsError()
        }
        app.databases.use(DatabaseConfigurationFactory.mysql(
            hostname: Environment.get("DATABASE_HOST", logWith: setupLogger) ?? "localhost",
            port: Environment.get("DATABASE_PORT", logWith: setupLogger).flatMap(Int.init) ?? MySQLConfiguration.ianaPortNumber,
            username: databaseUsername,
            password: databasePassword,
            database: Environment.get("DATABASE_NAME", logWith: setupLogger) ?? "vapor_database",
            tlsConfiguration: .makePreSharedKeyConfiguration()
        ), as: .mysql)
    }

    app.migrations.add(CreateUser())
    app.migrations.add(CreateAuthToken())
    app.migrations.add(CreateRecipe())
    app.migrations.add(CreateIngredient())
    app.migrations.add(CreateInstruction())

    app.views.use(.leaf)

    // register routes
    try routes(app)
}

private struct MissingCredentialsError: Error {}

extension Environment {
    static func get(_ key: String, logWith logger: Logger) -> String? {
        let value = get(key)
        if value == nil {
            logger.warning("No value found for key \"\(key)\" in environment!")
        }
        return value
    }
}
