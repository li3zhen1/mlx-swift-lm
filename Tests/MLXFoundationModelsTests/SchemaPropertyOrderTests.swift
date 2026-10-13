// Copyright © 2026 Apple Inc.

#if FoundationModelsIntegration && canImport(FoundationModels, _version: 2)

import Testing
import Foundation
import FoundationModels
@testable import MLXFoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@Generable
private struct Address {
    var street: String
    var city: String
    var zip: String
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@Generable
private struct Person {
    var name: String
    var age: Int
    var email: String
    var isMember: Bool
    var address: Address
}

/// The order of the keys of the object after the first (or last) `marker` in `json`.
private func keys(
    after marker: String, in json: String, options: String.CompareOptions = []
) throws -> [String] {
    let start = try #require(json.range(of: marker, options: options)).upperBound
    var keys: [String] = []
    var depth = 0
    var index = start
    while index < json.endIndex {
        let character = json[index]
        if character == "{" { depth += 1 }
        if character == "}" {
            depth -= 1
            if depth == 0 { break }
        }
        if depth == 1, character == "\"" {
            let end = json[json.index(after: index)...].firstIndex(of: "\"")!
            let key = String(json[json.index(after: index)..<end])
            if json[json.index(after: end)] == ":" { keys.append(key) }
            index = end
        }
        index = json.index(after: index)
    }
    return keys
}

@Suite struct SchemaPropertyOrderTests {
    @Test func propertiesFollowXOrder() throws {
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else { return }
        let json = try SchemaConverter.encodeToJSON(Person.generationSchema)

        // Root keys are sorted, so the root's properties come after `$defs`.
        #expect(
            try keys(after: "\"properties\":", in: json, options: .backwards)
                == ["name", "age", "email", "isMember", "address"])
    }

    @Test func nestedPropertiesFollowXOrder() throws {
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else { return }
        let json = try SchemaConverter.encodeToJSON(Person.generationSchema)
        let address = String(json[try #require(json.range(of: "\"Address\":{")).lowerBound...])

        #expect(try keys(after: "\"properties\":", in: address) == ["street", "city", "zip"])
    }

    @Test func encodingIsDeterministic() throws {
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else { return }
        let encodings = try (0..<5).map { _ in
            try SchemaConverter.encodeToJSON(
                GenerationSchema(
                    root: DynamicGenerationSchema(type: Person.self), dependencies: []))
        }

        #expect(Set(encodings).count == 1)
    }

    @Test func outputIsValidJSON() throws {
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else { return }
        let json = try SchemaConverter.encodeToJSON(Person.generationSchema)

        #expect(try JSONSerialization.jsonObject(with: Data(json.utf8)) is [String: Any])
    }
}

#endif
