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
import Stencil

extension Extension {

	func registerModelFilters() {
		registerFilter("R.renderDescription") { input in
			guard let schema = input as? Resource else {
				throw ModelGenError.RuntimeError(message: "Input must be a definition Schema")
			}
			let description = schema.description
			let indented = description.replacingOccurrences(of: "\n", with: "\n\t/// ")
			return "///\n\t/// \(indented)\n\t///"
		}

		registerFilter("R.protocols") { input in
			guard let schema = input as? Resource else {
				throw ModelGenError.RuntimeError(message: "Input must be a definition Schema")
			}
			var protocols = ["KubernetesResource"]
			if schema.listResource {
				protocols.append("KubernetesResourceList")
			}
			if schema.hasMetadata {
				protocols.append("ResourceWithMetadata")
			}

			return protocols.joined(separator: ", ")
		}

		registerFilter("P.renderDescription") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}
			let description = property.description
			let indented = description.replacingOccurrences(of: "\n", with: "\n\t\t/// ")
			return "///\n\t\t/// \(indented)\n\t\t///"
		}

		registerFilter("P.render") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}

			let varOrLet = { () -> String in
				if property.isContant {
					return "let"
				} else {
					return "var"
				}
			}()

			let name = { () -> String in
				let name = property.name!
				let keywords = Set(["continue", "default", "operator", "protocol"])
				guard !keywords.contains(name) else {
					return "`\(name)`"
				}
				return name
			}()

			let optional = property.isOptional ? "?" : ""
			let type = "\(property.type.renderedType)\(optional)"

			let value = { () -> String in
				guard let constValue = property.constValue,
					let rendered = property.type.renderedValue(from: constValue) else {
						return ""
				}
				return " = \(rendered)"
			}()

			return "public \(varOrLet) \(name): \(type)\(value)"
		}

		registerFilter("P.renderArg") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}

			let name = { () -> String in
				let name = property.name!
				let keywords = Set(["continue", "default", "operator", "protocol"])
				guard !keywords.contains(name) else {
					return "`\(name)`"
				}
				return name
			}()

			let optional = property.isOptional ? "?" : ""
			let type = "\(property.type.renderedType)\(optional)"

			return "\(name): \(type)"
		}

		registerFilter("P.renderArgDefaultNil") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}

			if property.isOptional {
				return " = nil"
			}

			return ""
		}

		registerFilter("P.type") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}
			return "\(property.type.renderedType)"
		}

		registerFilter("P.escapeKeywords") { input in
			guard let name = input as? String else {
				throw ModelGenError.RuntimeError(message: "Input must be a String: \(String(describing: input))")
			}

			let keywords = Set(["continue", "default", "operator", "protocol"])
			guard !keywords.contains(name) else {
				return "`\(name)`"
			}

			return name
		}

		registerFilter("GVK.case") { input in
			guard let gvk = input as? GroupVersion else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersion: \(String(describing: input))")
			}
			return "\(gvk.renderedCase)"
		}
	}
}
