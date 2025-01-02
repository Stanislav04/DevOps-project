//
//  UserCredentialsAuthenticator.swift
//
//
//  Created by Stanislav Ivanov on 14.05.24.
//

import Fluent
import Vapor

struct UserCredentialsAuthenticator: AsyncBasicAuthenticator {
    private let logger = Logger(label: "User Credentials Authenticator")

    func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        guard let user = try await request.db.query(UserModel.self).filter(\.$username == basic.username).first(),
              try request.password.verify(basic.password, created: user.passwordHash),
              let userId = user.id else {
            logger.info("Trying to log in with incorrect credentials!")
            return
        }
        request.auth.login(User(id: userId))
    }
}
