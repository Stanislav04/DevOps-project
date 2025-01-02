//
//  AuthenticationController.swift
//
//
//  Created by Stanislav Ivanov on 1.05.24.
//

import Fluent
import Vapor

struct AuthenticationController: RouteCollection {
    let logger = Logger(label: "Authentication Controller")

    func boot(routes: RoutesBuilder) throws {
        routes.group("register") { routes in
            routes.post(use: register)
        }
        routes.grouped(UserCredentialsAuthenticator(), User.guardMiddleware()).group("login") { routes in
            routes.post(use: login)
        }
        routes.grouped(UserTokenAuthenticator(), User.guardMiddleware()).group("logout") { routes in
            routes.post(use: logout)
        }
    }

    @Sendable
    func register(request: Request) async throws -> Response {
        guard let userData = try? request.content.decode(RegisterUserDto.self),
              validate(email: userData.email),
              validate(password: userData.password) else {
            logger.info("Tried to register an account without providing credentials!")
            throw Abort(.badRequest)
        }

        let user: UserModel
        do {
            user = try UserModel(username: userData.email,
                                 passwordHash: request.password.hash(userData.password))
            try await user.save(on: request.db)
            logger.info("Successfully created a new account!")
        } catch {
            logger.info("Tried to register duplicate account!")
            throw Abort(.badRequest) // do not reveal that this email is already registered
        }

        do {
            let token = try await createAuthToken(for: user.requireID(), with: request)

            let response = Response(status: .created)
            try response.content.encode(TokenDto(token: token.token))
            return response
        } catch {
            logger.error("Something went wrong trying to create a token for the new user!")
            throw Abort(.internalServerError)
        }
    }

    @Sendable
    func login(request: Request) async throws -> Response {
        guard let user = request.auth.get(User.self) else {
            logger.error("Login called without user information in request.auth!")
            throw Abort(.badRequest)
        }
        do {
            let token = if let savedToken = try await request.db.query(AuthTokenModel.self).filter(\.$user.$id == user.id).first() {
                savedToken
            } else {
                try await createAuthToken(for: user.id, with: request)
            }

            let response = Response(status: .ok)
            try response.content.encode(TokenDto(token: token.token))
            return response
        } catch {
            logger.error("Returning a user token failed!")
            throw Abort(.internalServerError)
        }
    }

    @Sendable
    func logout(request: Request) async throws -> HTTPStatus {
        guard let user = request.auth.get(User.self),
              let token = try await request.db.query(AuthTokenModel.self).filter(\.$user.$id == user.id).first() else {
            logger.error("Missing user data for logout!")
            throw Abort(.internalServerError)
        }
        do {
            try await token.delete(on: request.db)
            logger.info("Successfully logged a user out!")
            return .ok
        } catch {
            logger.info("Could not delete token!")
            throw Abort(.internalServerError)
        }
    }

    private func validate(email: String) -> Bool {
        guard #available(macOS 13, *),
              let match = try? /[a-zA-Z0-9._%+-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}/.wholeMatch(in: email) else {
            logger.info("Invalid email!")
            return false
        }
        return !match.range.isEmpty
    }

    private func validate(password: String) -> Bool {
        guard #available(macOS 13.0, *),
              let match = try? /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[a-zA-Z0-9]{8,15}/.wholeMatch(in: password) else {
            logger.info("Invalid password!")
            return false
        }
        return !match.range.isEmpty
    }

    private func createAuthToken(for userId: UserModel.IDValue, with request: Request) async throws -> AuthTokenModel {
        let tokenLength = Environment.get("TOKEN_LENGTH", logWith: logger).flatMap(Int.init) ?? 16
        let tokenDuration = Environment.get("TOKEN_DURATION", logWith: logger).flatMap(Int.init) ?? 8

        let deletionDate = Calendar.current.date(byAdding: DateComponents(hour: tokenDuration), to: .now)
        let token = AuthTokenModel(token: .randomString(withLength: tokenLength), deleteAt: deletionDate, userId: userId)
        try await token.save(on: request.db)
        logger.info("Successfully created an authentication token for the user!")
        return token
    }
}
