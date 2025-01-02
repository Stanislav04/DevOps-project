//
//  AuthTokenModel.swift
//
//
//  Created by Stanislav Ivanov on 13.05.24.
//

import FluentKit
import Foundation

final class AuthTokenModel: Model {
    static let schema: String = "auth_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Timestamp(key: "delete_date", on: .delete)
    var deleteDate: Date?

    @Parent(key: "user_id")
    var user: UserModel

    init() {}

    init(id: UUID? = nil, token: String, deleteAt deleteDate: Date?, userId: UserModel.IDValue) {
        self.id = id
        self.token = token
        self.deleteDate = deleteDate
        $user.id = userId
    }
}
