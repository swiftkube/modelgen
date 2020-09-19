//
// Copyright 2020 Iskandar Abudiab (iabudiab.dev)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ArgumentParser
import Stencil
import PathKit

enum ModelGenError: Error {
	case RuntimeError(message: String)
}

let baseUrl = URL(string: "https://kubernetesjsonschema.dev")!

func versionedUrl(version: String) -> URL {
	return baseUrl.appendingPathComponent(version)
}

func allTypesUrl(version: String) -> URL {
	return versionedUrl(version: version).appendingPathComponent("all.json")
}

func definitionsUrl(version: String) -> URL {
	return versionedUrl(version: version).appendingPathComponent("_definitions.json")
}

func loadAndDecodeJson<T: Decodable>(url: URL, type: T.Type) throws -> T {
	guard let data = try String(contentsOf: url, encoding: .utf8).data(using: .utf8) else {
		throw ModelGenError.RuntimeError(message: "Error decoding JSON")
	}
	return try JSONDecoder().decode(type, from: data)
}

struct ModelGen: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "SwiftkubeModelGen",
		subcommands: []
	)

	@Option(name: .shortAndLong, help: "Kubernetes API version")
	var apiVersion: String

	@Option(name: .shortAndLong, help: "Templates directory")
	var templates: String

	@Option(name: .shortAndLong, help: "Output directory")
	var output: String

	@Flag(help: "Clear output directory")
	var clear: Bool = false

	mutating func run() throws {
		let templatesPath = Path(templates).absolute()
		let outputPath = Path(output).absolute()
		print("Generating model version: \(apiVersion) using templates at: [\(templatesPath)], output path: [\(outputPath)]")

		guard !outputPath.exists || clear else {
			throw ModelGenError.RuntimeError(message: "Output directory arleady exists and clear flag is not set")
		}

		let schemas = try loadAndDecodeJson(url: definitionsUrl(version: apiVersion), type: Definitions.self)
		let environment = makeStencilEnv(templatesPath: templatesPath)

		if clear {
			try outputPath.delete()
		}
		try outputPath.mkpath()

		let allGroupVersions = Set(schemas.definitions.compactMap { $1.gvk?.makeGroupVersion() })
		try renderAPIGroupEnum(outputPath: outputPath, allGroupVersions: allGroupVersions, environment: environment)

		try schemas.definitions
			.filter { $0.value.type != .null }
			.forEach { key, resource in
				let typeReference = TypeReference(ref: key)
				let context: [String: Any] = [
					"type": typeReference,
					"resource": resource
				]

				try makeDirectories(outputPath: outputPath, typeReference: typeReference, environment: environment)
				try renderResource(outputPath: outputPath, typeReference: typeReference, environment: environment, context: context)
		}
	}

	private func makeStencilEnv(templatesPath: Path) -> Environment {
		let loader = FileSystemLoader(paths: [templatesPath])
		let ext = Extension()
		ext.registerModelFilters()
		return Environment(loader: loader, extensions: [ext])
	}

	private func makeDirectories(outputPath: Path, typeReference: TypeReference, environment: Environment) throws {
		let groupPath = outputPath + Path(typeReference.group)
		try groupPath.mkpath()

		let groupSwift = try environment.renderTemplate(name: "Group.swift.stencil", context: ["type": typeReference])
		let groupFilePath = groupPath + Path("\(typeReference.group).swift")
		try groupFilePath.write(groupSwift, encoding: .utf8)

		let groupVersionPath = groupPath + Path(typeReference.version)
		try groupVersionPath.mkpath()

		let versionSwift = try environment.renderTemplate(name: "Version.swift.stencil", context: ["type": typeReference])
		let versionFilePath = groupVersionPath + Path("\(typeReference.group)+\(typeReference.version).swift")
		try versionFilePath.write(versionSwift, encoding: .utf8)
	}

	private func renderAPIGroupEnum(outputPath: Path, allGroupVersions: Set<GroupVersion>, environment: Environment) throws {
		let context = ["allGroupVersions": allGroupVersions.sorted()]
		let rendered = try environment.renderTemplate(name: "APIGroupVersionEnum.swift.stencil", context: context)
		let filePath = outputPath + Path("APIGroupVersion.swift")
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)
	}

	private func renderResource(outputPath: Path, typeReference: TypeReference, environment: Environment, context: [String: Any]) throws {
		let rendered = try environment.renderTemplate(name: "Resource.swift.stencil", context: context)
		let gvPath = outputPath + Path(typeReference.group) + Path(typeReference.version)
		let filePath = gvPath + Path("\(typeReference.kind)+\(typeReference.group).\(typeReference.version).swift")
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)
	}
}

ModelGen.main()
