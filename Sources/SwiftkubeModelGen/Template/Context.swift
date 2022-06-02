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

protocol TemplateType {
	var stencilTemplate: String { get }
	func destination(basePath: Path) -> Path
	func stencilContext() -> [String: Any]
}

extension TemplateType {
	func stencilContext() -> [String: Any] {
		[:]
	}
}

struct MetaContext {
	let modelVersion: String
}

struct ResourceContext {
	let resource: Resource
	let typeReference: TypeReference
}

struct TemplateContext {
	let meta: MetaContext
	let groupVersionKinds: [GroupVersionKind]
	let resources: [ResourceContext]

	func stencilContext() -> [String: Any] {
		let newestGroupVersionKinds = groupVersionKinds.removeDuplicates {$0.kind}

		return [
					"meta": ["modelVersion": meta.modelVersion],
					"groupVersionKinds": groupVersionKinds,
					"newestGroupVersionKinds": newestGroupVersionKinds,
					"pluralGroupVersionKinds": newestGroupVersionKinds.filter { gvk in PluralNames.keys.contains(gvk.kind) },
					"shortGroupVersionKinds": newestGroupVersionKinds.filter { gvk in ShortNames.keys.contains(gvk.kind) },
					"resources": resources
				]
	}
}

extension Array {
	func removeDuplicates<T: Hashable>(byProperty: (Element) -> T) -> [Element] {
		var result = [Element]()
		var seen = Set<T>()
		for element in self {
			if seen.insert(byProperty(element)).inserted {
				result.append(element)
			}
		}
		return result
	}
}
