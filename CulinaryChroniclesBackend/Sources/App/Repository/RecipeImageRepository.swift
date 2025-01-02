//
//  RecipeImageRepository.swift
//
//
//  Created by Stanislav Ivanov on 4.06.24.
//

import Foundation
import Vapor

protocol RecipeImageRepository: Sendable {
    func save(image: Data, from user: String, for recipe: String) throws
    func getImages(for recipe: String) throws -> [Data]
}

final class LocalRecipeImageRepository: RecipeImageRepository {
    private let imageRepository: ImageRepository

    init(imageRepository: ImageRepository = FileManager.default) {
        self.imageRepository = imageRepository
    }

    private var baseDirectoryPath: String {
        Environment.get("RECIPE_IMAGE_FOLDER",
                        logWith: Logger(label: "Local Recipe Image Repository")) ?? "./Resources/Images/recipe-images"
    }

    func save(image: Data, from user: String, for recipe: String) throws {
        try imageRepository.save(image: image, at: "\(baseDirectoryPath)/\(recipe)/\(user)", as: "\(UUID()).png")
    }

    func getImages(for recipe: String) throws -> [Data] {
        try imageRepository.getDirectoryPaths(at: "\(baseDirectoryPath)/\(recipe)")
            .flatMap(imageRepository.getFilePaths)
            .compactMap(imageRepository.getContent)
    }
}
