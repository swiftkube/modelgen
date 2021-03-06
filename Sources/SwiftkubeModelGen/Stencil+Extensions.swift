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
			var mainProtocols: [String] = []
			if schema.isListResource {
				mainProtocols.append("KubernetesResource")
				mainProtocols.append("KubernetesResourceList")
			}
			if schema.isAPIResource {
				mainProtocols.append("KubernetesAPIResource")
			}
			if schema.hasMetadata {
				mainProtocols.append("MetadataHavingResource")
			}
			if schema.isAPIResource, schema.isNamespaced {
				mainProtocols.append("NamespacedResource")
			}
			if schema.isAPIResource, !schema.isNamespaced {
				mainProtocols.append("ClusterScopedResource")
			}
			if mainProtocols.isEmpty {
				mainProtocols.append("KubernetesResource")
			}
			var verbsProtocols: [String] = []
			if schema.isReadableResource {
				verbsProtocols.append("ReadableResource")
			}
			if schema.isListableResource {
				verbsProtocols.append("ListableResource")
			}
			if schema.isCreatableResource {
				verbsProtocols.append("CreatableResource")
			}
			if schema.isReplaceableResource {
				verbsProtocols.append("ReplaceableResource")
			}
			if schema.isDeletableResource {
				verbsProtocols.append("DeletableResource")
			}
			if schema.isCollectionDeletableResource {
				verbsProtocols.append("CollectionDeletableResource")
			}

			if verbsProtocols.isEmpty {
				return mainProtocols.joined(separator: ", ")
			}

			return mainProtocols.joined(separator: ", ") + ",\n\t\t" + verbsProtocols.joined(separator: ", ")
		}

		registerFilter("P.renderDescription") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "Input must be a Property: \(String(describing: input))")
			}
			let indentedNewLine = "\n\t\t///"
			let description = property.description
			let indented = description.replacingOccurrences(of: "\n", with: "\(indentedNewLine) ")

			return """
					///
					/// \(indented)
					///
			"""
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
				      let rendered = property.type.renderedValue(from: constValue)
				else {
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

		registerFilter("GVK.group") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedGroup)"
		}

		registerFilter("GVK.version") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedVersion)"
		}

		registerFilter("GVK.case") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedCase)"
		}

		registerFilter("GVK.full") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedFull)"
		}

		registerFilter("GVK.type") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedTypeCase)"
		}

		registerFilter("GVK.plural") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedPluralName)"
		}

		registerFilter("GVK.short") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return (gvk.renderedShortName != nil) ? "\"\(gvk.renderedShortName!)\"" : "nil"
		}

		registerFilter("GVK.nsScope") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedNamespaceScope)"
		}
	}
}
