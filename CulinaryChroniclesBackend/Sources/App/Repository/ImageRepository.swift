//
//  ImageRepository.swift
//
//
//  Created by Stanislav Ivanov on 4.06.24.
//

import Foundation

protocol ImageRepository: Sendable {
    func save(image: Data?, at path: String, as filename: String) throws
    func getDirectories(at path: String) throws -> [String]
    func getDirectoryPaths(at path: String) throws -> [String]
    func getFiles(at path: String) throws -> [String]
    func getFilePaths(at path: String) throws -> [String]
    func getContent(of filePath: String) -> Data?
}

extension FileManager: ImageRepository, @unchecked Sendable {
    func save(image: Data?, at path: String, as filename: String) throws {
        if !fileExists(atPath: path) {
            try createDirectory(atPath: path, withIntermediateDirectories: true)
        }
        createFile(atPath: "\(path)/\(filename)", contents: image)
    }

    func getDirectories(at path: String) throws -> [String] {
        try contentsOfDirectory(atPath: path).filter {
            var isDirectory: ObjCBool = false
            fileExists(atPath: "\(path)/\($0)", isDirectory: &isDirectory)
            return isDirectory.boolValue
        }
    }

    func getDirectoryPaths(at path: String) throws -> [String] {
        try getDirectories(at: path).compactMap {
            "\(path)/\($0)"
        }
    }

    func getFiles(at path: String) throws -> [String] {
        try contentsOfDirectory(atPath: path).filter {
            var isDirectory: ObjCBool = true
            fileExists(atPath: "\(path)/\($0)", isDirectory: &isDirectory)
            return !isDirectory.boolValue
        }
    }

    func getFilePaths(at path: String) throws -> [String] {
        try getFiles(at: path).compactMap {
            "\(path)/\($0)"
        }
    }

    func getContent(of filePath: String) -> Data? {
        contents(atPath: filePath)
    }
}
