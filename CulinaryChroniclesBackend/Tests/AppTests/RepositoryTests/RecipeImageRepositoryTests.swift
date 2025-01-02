//
//  RecipeImageRepositoryTests.swift
//
//
//  Created by Stanislav Ivanov on 4.06.24.
//

@testable import App
import XCTVapor

final class RecipeImageRepositoryTests: XCTestCase {
    let imageRepository = ImageRepositoryMock()
    lazy var repository: RecipeImageRepository = LocalRecipeImageRepository(imageRepository: imageRepository)

    let app = Application(.testing) // used for loading Environment

    override func setUp() async throws {
        try await configure(app)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    private var baseDirectoryPath: String {
        Environment.get("RECIPE_IMAGE_FOLDER",
                        logWith: Logger(label: "Recipe Image Repository Tests")) ?? "./Resources/Images/recipe-images"
    }

    // MARK: - save(image:, from:, for:)

    func testSaveImageWithSomeDataSucceessfullySavesIt() throws {
        let data = try JSONEncoder().encode("test data")
        try repository.save(image: data, from: "user", for: "recipe")

        XCTAssertEqual(imageRepository.images.values.first, data)
    }

    // MARK: - getImages(for:)

    func testGetImagesReturnsStoredData() throws {
        imageRepository.images["\(baseDirectoryPath)/recipe/user/data"] = try JSONEncoder().encode("test data")

        let storedData = try XCTUnwrap(repository.getImages(for: "recipe").first)
        XCTAssertEqual(try JSONDecoder().decode(String.self, from: storedData), "test data")
    }

    func testGetImagesRetirnsCorrectImagesForRecipe() throws {
        imageRepository.images["\(baseDirectoryPath)/recipe/user/data1"] = try JSONEncoder().encode("test data 1")
        imageRepository.images["\(baseDirectoryPath)/recipe/user/data2"] = try JSONEncoder().encode("test data 2")
        imageRepository.images["\(baseDirectoryPath)/other-recipe/user/data3"] = try JSONEncoder().encode("test data 3")
        imageRepository.images["\(baseDirectoryPath)/another-recipe/user/data4"] = try JSONEncoder().encode("test data 4")

        let storedData = try repository.getImages(for: "recipe")
        XCTAssertEqual(storedData.count, 2)
        let decodedData = try storedData.map { try JSONDecoder().decode(String.self, from: $0) }
        XCTAssertTrue(decodedData.contains("test data 1"))
        XCTAssertTrue(decodedData.contains("test data 2"))
    }

    func testGetImagesReturnsImagesFromAllUsersForRecipe() throws {
        imageRepository.images["\(baseDirectoryPath)/recipe/user/data1"] = try JSONEncoder().encode("test data 1")
        imageRepository.images["\(baseDirectoryPath)/recipe/user/data2"] = try JSONEncoder().encode("test data 2")
        imageRepository.images["\(baseDirectoryPath)/recipe/wrong-user/data3"] = try JSONEncoder().encode("test data 3")
        imageRepository.images["\(baseDirectoryPath)/recipe/random-user/data4"] = try JSONEncoder().encode("test data 4")

        let storedData = try repository.getImages(for: "recipe")
        XCTAssertEqual(storedData.count, 4)
        let decodedData = try storedData.map { try JSONDecoder().decode(String.self, from: $0) }
        XCTAssertTrue(decodedData.contains("test data 1"))
        XCTAssertTrue(decodedData.contains("test data 2"))
        XCTAssertTrue(decodedData.contains("test data 3"))
        XCTAssertTrue(decodedData.contains("test data 4"))
    }
}
