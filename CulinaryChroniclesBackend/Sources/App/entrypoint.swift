import Vapor
import Logging

@main
enum Entrypoint {
    static func main() async throws {
        var environment = try Environment.detect()
        try LoggingSystem.bootstrap(from: &environment)

        let app = Application(environment)
        defer { app.shutdown() }

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.execute()
    }
}

extension LoggingSystem {
    static func bootstrap(from environment: inout Environment) throws {
        try LoggingSystem.bootstrap(fragment: TimestampFragment().and(LabelFragment().separated(" ")).and(defaultLoggerFragment().separated(" ")),
                                    console: Terminal(),
                                    level: Logger.Level.detect(from: &environment))
    }
}
