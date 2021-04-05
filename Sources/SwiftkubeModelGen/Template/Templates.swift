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

struct GroupVersionKindTemplate: TemplateType {

	let stencilTemplate = "GroupVersionKind.swift.stencil"

	func destination(basePath: Path) -> Path {
		return basePath + Path("GroupVersionKind.swift")
	}
}

struct GroupVersionKindAPIResourceTemplate: TemplateType {

	let stencilTemplate = "GroupVersionKind+KubernetesAPIResource.swift.stencil"

	func destination(basePath: Path) -> Path {
		return basePath + Path("GroupVersionKind+KubernetesAPIResource.swift")
	}
}

struct AnyKubernetesAPIResourceTemplate: TemplateType {

	let stencilTemplate = "AnyKubernetesAPIResource.swift.stencil"

	func destination(basePath: Path) -> Path {
		return basePath + Path("AnyKubernetesAPIResource.swift")
	}
}

struct GroupTemplate: TemplateType {

	let stencilTemplate = "Group.swift.stencil"
	let typeReference: TypeReference

	func destination(basePath: Path) -> Path {
		return basePath + Path(typeReference.group) + Path("\(typeReference.group).swift")
	}

	func stencilContext() -> [String : Any] {
		return ["type": typeReference]
	}
}

struct VersionTemplate: TemplateType {

	let stencilTemplate = "Version.swift.stencil"
	let typeReference: TypeReference

	func destination(basePath: Path) -> Path {
		return basePath
			+ Path(typeReference.group)
			+ Path(typeReference.version)
			+ Path("\(typeReference.group)+\(typeReference.version).swift")
	}

	func stencilContext() -> [String : Any] {
		return ["type": typeReference]
	}
}

struct ResourceTemplate: TemplateType {

	let stencilTemplate = "Resource.swift.stencil"
	let typeReference: TypeReference
	let resource: Resource

	func destination(basePath: Path) -> Path {
		return basePath
			+ Path(typeReference.group)
			+ Path(typeReference.version)
			+ Path("\(typeReference.kind)+\(typeReference.group).\(typeReference.version).swift")
	}

	func stencilContext() -> [String : Any] {
		return [
			"type": typeReference,
			"resource": resource
		]
	}
}
