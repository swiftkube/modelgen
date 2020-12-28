//
// Copyright 2020 Swiftkube Project
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
import ShellOut

enum ModelGenError: Error {
	case RuntimeError(message: String)
}

struct ModelGen: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "swiftkube-modelgen",
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

		if clear {
			try? outputPath.delete()
		}
		try outputPath.mkpath()

		var schema = try JSONSchemaProcessor(apiVersion: apiVersion).process(outputPath: outputPath)
		try OpenAPIProcessor(apiVersion: apiVersion).process(schema: &schema)

		let environment = makeStencilEnv(templatesPath: templatesPath)
		let allGVK = schema.definitions.filter { $1.isAPIResource }.compactMap { $1.gvk }.sorted()
		try renderGroupVersionKinds(outputPath: outputPath, environment: environment, allGVK: allGVK)
		try rendeAnyKubernetesAPIResource(outputPath: outputPath, environment: environment, allGVK: allGVK)

		try schema.definitions
			.filter { $0.value.type != .null }
			.forEach { key, resource in
				let typeReference = TypeReference(ref: key)
				let context: [String: Any] = [
					"type": typeReference,
					"resource": resource,
					"meta": ["modelVersion": apiVersion],
				]

				try makeModelDirectories(outputPath: outputPath, environment: environment, typeReference: typeReference)
				try renderResource(outputPath: outputPath, environment: environment, typeReference: typeReference, context: context)
		}
	}

	private func makeStencilEnv(templatesPath: PathKit.Path) -> Environment {
		let loader = FileSystemLoader(paths: [templatesPath])
		let ext = Extension()
		ext.registerModelFilters()
		return Environment(loader: loader, extensions: [ext])
	}

	private func renderGroupVersionKinds(outputPath: PathKit.Path, environment: Environment, allGVK: [GroupVersionKind]) throws {
		let context: [String : Any] = [
			"meta": ["modelVersion": apiVersion],
			"allGVK": allGVK
		]
		let rendered = try environment.renderTemplate(name: "GroupVersionKind.swift.stencil", context: context)
		let filePath = outputPath + Path("GroupVersionKind.swift")
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)

		let renderedExt = try environment.renderTemplate(name: "GroupVersionKind+KubernetesAPIResource.swift.stencil", context: context)
		let extFilePath = outputPath + Path("GroupVersionKind+KubernetesAPIResource.swift")
		try extFilePath.write(renderedExt.cleanupWhitespace(), encoding: .utf8)
	}

	private func rendeAnyKubernetesAPIResource(outputPath: PathKit.Path, environment: Environment, allGVK: [GroupVersionKind]) throws {
		let context: [String : Any] = [
			"meta": ["modelVersion": apiVersion],
			"allGVK": allGVK
		]
		let rendered = try environment.renderTemplate(name: "AnyKubernetesAPIResource.swift.stencil", context: context)
		let filePath = outputPath + Path("AnyKubernetesAPIResource.swift")
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)
	}

	private func makeModelDirectories(outputPath: PathKit.Path, environment: Environment, typeReference: TypeReference) throws {
		let groupPath = outputPath + Path(typeReference.group)
		try groupPath.mkpath()

		let context: [String: Any] = [
			"type": typeReference,
			"meta": ["modelVersion": apiVersion]
		]

		let groupSwift = try environment.renderTemplate(name: "Group.swift.stencil", context: context)
		let groupFilePath = groupPath + Path("\(typeReference.group).swift")
		try groupFilePath.write(groupSwift, encoding: .utf8)

		let groupVersionPath = groupPath + Path(typeReference.version)
		try groupVersionPath.mkpath()

		let versionSwift = try environment.renderTemplate(name: "Version.swift.stencil", context: context)
		let versionFilePath = groupVersionPath + Path("\(typeReference.group)+\(typeReference.version).swift")
		try versionFilePath.write(versionSwift, encoding: .utf8)
	}

	private func renderResource(outputPath: PathKit.Path, environment: Environment, typeReference: TypeReference, context: [String: Any]) throws {
		let rendered = try environment.renderTemplate(name: "Resource.swift.stencil", context: context)
		let gvPath = outputPath + Path(typeReference.group) + Path(typeReference.version)
		let filePath = gvPath + Path("\(typeReference.kind)+\(typeReference.group).\(typeReference.version).swift")
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)
	}
}

ModelGen.main()
