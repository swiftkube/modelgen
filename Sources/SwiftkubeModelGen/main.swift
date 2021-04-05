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

// MARK: - ModelGenError

enum ModelGenError: Error {
	case RuntimeError(message: String)
}

// MARK: - ModelGen

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

		let context = try prepareContext(outputPath: outputPath)
		let environment = makeStencilEnv(templatesPath: templatesPath)

		try Pipeline(steps: [
			RenderTemplate(environment: environment, template: GroupVersionKindTemplate()),
			RenderTemplate(environment: environment, template: GroupVersionKindAPIResourceTemplate()),
			RenderTemplate(environment: environment, template: AnyKubernetesAPIResourceTemplate()),
			RenderResources(environment: environment)
		])
		.process(basePath: outputPath, cotext: context)
	}

	private func prepareContext(outputPath: Path) throws -> TemplateContex {
		var schema = try JSONSchemaProcessor(apiVersion: apiVersion).process(outputPath: outputPath)
		try OpenAPIProcessor(apiVersion: apiVersion).process(schema: &schema)

		var gvks = [GroupVersionKind]()
		var resources = [ResourceContext]()

		schema.definitions.forEach { key, resource in
			if resource.isAPIResource, let gvk = resource.gvk {
				gvks.append(gvk)
			}

			if resource.type != .null {
				let typeReference = TypeReference(ref: key)
				let resourceContext = ResourceContext(resource: resource, typreReference: typeReference)
				resources.append(resourceContext)
			}
		}

		return TemplateContex(
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

ModelGen.main()
