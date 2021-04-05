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
import PathKit
import Stencil

protocol PipelineStep {
	func process(basePath: Path, cotext: TemplateContex) throws
}

struct Pipeline {

	let steps: [PipelineStep]

	func process(basePath: Path, cotext: TemplateContex) throws {
		try steps.forEach {
			try $0.process(basePath: basePath, cotext: cotext)
		}
	}
}

struct RenderTemplate: PipelineStep {

	let environment: Environment
	let template: TemplateType

	func process(basePath: Path, cotext: TemplateContex) throws {
		var stencilContext = cotext.stencilContext()
		stencilContext.merge(template.stencilContext()) { (_, new) in new }

		let rendered = try environment.renderTemplate(name: template.stencilTemplate, context: stencilContext)
		let filePath = template.destination(basePath: basePath)
		try filePath.write(rendered.cleanupWhitespace(), encoding: .utf8)
	}
}

struct MakeDirectories: PipelineStep {

	let dirs: [String]

	func process(basePath: Path, cotext: TemplateContex) throws {
		try dirs.reduce(basePath, +).mkpath()
	}
}

struct RenderResources: PipelineStep {

	let environment: Environment

	func process(basePath: Path, cotext: TemplateContex) throws {
		try cotext.resources
			.flatMap(makeSteps(resourceContext:))
			.forEach { (step: PipelineStep) in
				try step.process(basePath: basePath, cotext: cotext)
			}
	}

	private func makeSteps(resourceContext: ResourceContext) -> [PipelineStep] {
		let typreReference = resourceContext.typreReference
		let resource = resourceContext.resource

		return [
			MakeDirectories(dirs: [typreReference.group, typreReference.version]),
			RenderTemplate(environment: environment, template: GroupTemplate(typeReference: typreReference)),
			RenderTemplate(environment: environment, template: VersionTemplate(typeReference: typreReference)),
			RenderTemplate(environment: environment, template: ResourceTemplate(typeReference: typreReference, resource: resource))
		]
	}
}
