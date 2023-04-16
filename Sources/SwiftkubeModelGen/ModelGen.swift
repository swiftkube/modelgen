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
import PathKit
import ShellOut
import Stencil

// MARK: - ModelGen

struct ModelGen: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "modelgen",
		subcommands: []
	)

	@Option(name: .shortAndLong, help: "Kubernetes API version")
	var apiVersion: String

	@Option(name: .shortAndLong, help: "Templates directory")
	var templates: String

	@Option(name: .shortAndLong, help: "Output directory")
	var output: String

	@Option(name: .shortAndLong, help: "Schema output directory")
	var schemaOutput: String = "/tmp/swiftkube"

	@Flag(help: "Clear output directory")
	var clear: Bool = false

	mutating func run() throws {
		let templatesPath = Path(templates).absolute()
		let outputPath = Path(output).absolute()
		let schemaOutputPath = Path(schemaOutput).absolute()

		let suitableOutput = !outputPath.exists || ((try? outputPath.children())?.isEmpty == true)

		guard suitableOutput || clear else {
			throw ModelGenError.RuntimeError(message: "Output directory exists, not empty, and clear flag is not set")
		}

		print("Generating model version: \(apiVersion) using templates at: [\(templatesPath)], output path: [\(outputPath)]")

		if clear {
			try? outputPath.delete()
		}
		try outputPath.mkpath()

		let context = try prepareContext(outputPath: outputPath, schemaOutputPath: schemaOutputPath)
		let environment = makeStencilEnv(templatesPath: templatesPath)

		try Pipeline(steps: [
			RenderClientDSL(environment: environment),
			RenderTemplate(environment: environment, template: GroupVersionKindResourceNameTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionKindDefaultResourcesTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionKindAPIResourceTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionKindMetaTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionResourceResourceNameTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionResourceAPIResourceTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionResourceDefaultResourcesTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionResourceMetaTemplate()),
			RenderResources(environment: environment)
		])
		.process(basePath: outputPath, context: context)
	}

	private func prepareContext(outputPath: Path, schemaOutputPath: Path) throws -> TemplateContext {
		var schema = try JSONSchemaProcessor(apiVersion: apiVersion).process(outputPath: schemaOutputPath)
		try OpenAPIProcessor(apiVersion: apiVersion).process(schema: &schema)

		var gvks = [GroupVersionKind]()
		var resources = [ResourceContext]()

		schema.definitions.forEach { key, resource in
			if resource.isAPIResource, let gvk = resource.gvk {
				gvks.append(gvk)
			}

			if resource.type != .null {
				let typeReference = TypeReference(ref: key)
				let resourceContext = ResourceContext(resource: resource, typeReference: typeReference)
				resources.append(resourceContext)
			}
		}

		return TemplateContext(
			meta: MetaContext(modelVersion: apiVersion),
			groupVersionKinds: gvks.sorted(),
			resources: resources
		)
	}

	private func makeStencilEnv(templatesPath: PathKit.Path) -> Environment {
		let loader = FileSystemLoader(paths: [templatesPath])
		let ext = Extension()
		ext.registerModelFilters()
		return Environment(loader: loader, extensions: [ext])
	}
}
