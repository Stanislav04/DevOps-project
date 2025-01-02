//
//  AuthenticationControllerTests.swift
//
//
//  Created by Stanislav Ivanov on 2.05.24.
//

@testable import App
import XCTVapor

final class AuthenticationControllerTests: XCTestCase {
    let app = Application(.testing)

    override func setUp() async throws {
        try await configure(app)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    // MARK: - Register route

    func testRegisterWithIncorrectDataModelProvidedFails() throws {
        try app.test(.POST, "register", afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    func testRegisterWithInvalidEmailFails() throws {
        let credentials = [RegisterUserDto(email: "", password: "P4ssword"),
                           RegisterUserDto(email: "test", password: "P4ssword"),
                           RegisterUserDto(email: "test@email", password: "P4ssword"),
                           RegisterUserDto(email: "test..@email", password: "P4ssword"),
                           RegisterUserDto(email: "test@email.", password: "P4ssword"),
                           RegisterUserDto(email: "test@email.c", password: "P4ssword")]

        try credentials.forEach { userData in
            try app.test(.POST, "register", beforeRequest: { request in
                try request.content.encode(userData)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .badRequest)
            })
        }
    }

    func testRegisterWithInvalidPasswordFails() throws {
        let credentials = [RegisterUserDto(email: "test@email.com", password: ""),
                           RegisterUserDto(email: "test@email.com", password: "Sh0rt"),
                           RegisterUserDto(email: "test@email.com", password: "Too l0ng password"),
                           RegisterUserDto(email: "test@email.com", password: "No digits pass"),
                           RegisterUserDto(email: "test@email.com", password: "no uppercase"),
                           RegisterUserDto(email: "test@email.com", password: "NO LOWERCASE"),
                           RegisterUserDto(email: "test@email.com", password: "Spec1al symbol!")]

        try credentials.forEach { userData in
            try app.test(.POST, "register", beforeRequest: { request in
                try request.content.encode(userData)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .badRequest)
            })
        }
    }

    func testRegisterWithNewUserIsSuccessful() async throws {
        let userData = RegisterUserDto(email: "test@email.com", password: "P4ssword")

        try await app.test(.POST, "register", beforeRequest: { request in
            try request.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .created)

            let databaseUser = try await app.db.query(UserModel.self).first()
            let savedUser = try XCTUnwrap(databaseUser, "Test user should be saved!")
            XCTAssertEqual(savedUser.username, userData.email)
            XCTAssertTrue(try app.password.verify(userData.password, created: savedUser.passwordHash))

            let token = try response.content.decode(TokenDto.self)
            let databaseToken = try await app.db.query(AuthTokenModel.self).first()
            let savedToken = try XCTUnwrap(databaseToken, "Token for test user should be saved!")
            XCTAssertEqual(token.token, savedToken.token)
        })
    }

    func testRegisterWithExistingEmailFails() throws {
        let userData = RegisterUserDto(email: "test@email.com", password: "P4ssword")

        try app.test(.POST, "register", beforeRequest: { request in
            try request.content.encode(userData)
        }).test(.POST, "register", beforeRequest: { request in
            try request.content.encode(userData)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }

    // MARK: - Login route

    func testLoginWithoutBasicAuthenticationDataFails() throws {
        try app.test(.POST, "login", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testLoginWithUnexistingUserFails() throws {
        try app.test(.POST, "login", beforeRequest: { request in
            request.headers.basicAuthorization = BasicAuthorization(username: "test", password: "pass")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testLoginWithWrongPasswordFails() async throws {
        try await UserModel(username: "test", passwordHash: app.password.hash("test")).save(on: app.db)

        try app.test(.POST, "login", beforeRequest: { request in
            request.headers.basicAuthorization = BasicAuthorization(username: "test", password: "pass")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testLoginWithNoSavedTokenReturnsToken() async throws {
        try await UserModel(username: "test", passwordHash: app.password.hash("pass")).save(on: app.db)
        let tokens = try await app.db.query(AuthTokenModel.self).all()

        try await app.test(.POST, "login", beforeRequest: { request in
            request.headers.basicAuthorization = BasicAuthorization(username: "test", password: "pass")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)

            let token = try response.content.decode(TokenDto.self)
            XCTAssertNil(tokens.first { $0.token == token.token })

            let savedTokens = try await app.db.query(AuthTokenModel.self).all()
            XCTAssertNotNil(savedTokens.first { $0.token == token.token })
        })
    }

    func testLoginWithSavedTokenRetunsTheSameToken() async throws {
        let user = try UserModel(username: "test", passwordHash: app.password.hash("pass"))
        try await user.save(on: app.db)
        try await AuthTokenModel(token: "test token", deleteAt: .distantFuture, userId: user.requireID()).save(on: app.db)

        try app.test(.POST, "login", beforeRequest: { request in
            request.headers.basicAuthorization = BasicAuthorization(username: "test", password: "pass")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)

            let token = try response.content.decode(TokenDto.self)
            XCTAssertEqual(token.token, "test token")
        })
    }

    // MARK: - Logout route

    func testLogoutWithUnexistingTokenFails() throws {
        try app.test(.POST, "logout", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }

    func testLogoutWithExistingTokenSucceeds() async throws {
        let user = try UserModel(username: "test", passwordHash: app.password.hash("pass"))
        try await user.save(on: app.db)
        try await AuthTokenModel(token: "test-token", deleteAt: .distantFuture, userId: user.requireID()).save(on: app.db)

        try app.test(.POST, "logout", beforeRequest: { request in
            request.headers.bearerAuthorization = BearerAuthorization(token: "test-token")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
    }
}
