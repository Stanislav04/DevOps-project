//
//  ImageRepositoryMock.swift
//
//
//  Created by Stanislav Ivanov on 4.06.24.
//

@testable import App
import Foundation

private enum FileType {
    case file(name: String, content: Data?)
    case directory(name: String, children: [FileType])
}

final class ImageRepositoryMock: ImageRepository, @unchecked Sendable {
    var images: [String: Data] = [:]

    nonisolated func save(image: Data?, at path: String, as filename: String) throws {
        guard let image else { return }
        images["\(path)/\(filename)"] = image
    }

    nonisolated func getDirectories(at path: String) throws -> [String] {
        // Used `.appending` to convert `String.SubSequence` to `String`
        try getDirectoryPaths(at: path).compactMap { $0.split(separator: "/").last?.appending("") }
    }

    nonisolated func getDirectoryPaths(at path: String) throws -> [String] {
        images.keys.filter { $0.hasPrefix("\(path)/") }.compactMap {
            let directoryComponents = $0.split(separator: "/")
            let pathComponents = path.split(separator: "/")
            guard directoryComponents.count > pathComponents.count + 1 else { return nil }
            return directoryComponents[...pathComponents.count].joined(separator: "/")
        }.uniqued
    }

    nonisolated func getFiles(at path: String) throws -> [String] {
        // Used `.appending` to convert `String.SubSequence` to `String`
        try getFilePaths(at: path).compactMap { $0.split(separator: "/").last?.appending("") }
    }

    nonisolated func getFilePaths(at path: String) throws -> [String] {
        images.keys.filter { $0.hasPrefix(path) && $0.split(separator: "/").count == path.split(separator: "/").count + 1 }
    }

    nonisolated func getContent(of filePath: String) -> Data? {
        images[filePath]
    }
}
