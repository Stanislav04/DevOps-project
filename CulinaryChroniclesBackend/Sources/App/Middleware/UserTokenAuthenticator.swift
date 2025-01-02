//
//  UserTokenAuthenticator.swift
//
//
//  Created by Stanislav Ivanov on 14.05.24.
//

import Fluent
import Vapor

struct UserTokenAuthenticator: AsyncBearerAuthenticator {
    private let logger = Logger(label: "User Token Authenticator")

    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        guard let token = try await request.db.query(AuthTokenModel.self).filter(\.$token == bearer.token).first() else {
            logger.info("Trying to log in with invalid token!")
            return
        }
        request.auth.login(User(id: token.$user.id))
    }
}
