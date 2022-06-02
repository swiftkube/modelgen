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
				throw ModelGenError.RuntimeError(message: "[R.renderDescription]: Input must be a definition Schema")
			}
			let description = schema.description
			let indented = description.replacingOccurrences(of: "\n", with: "\n\t/// ")
			return "///\n\t/// \(indented)\n\t///"
		}

		registerFilter("R.protocols") { input in
			guard let schema = input as? Resource else {
				throw ModelGenError.RuntimeError(message: "[R.protocols]: Input must be a definition Schema")
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
			var additionalProtocols: [String] = []
			if schema.isEvictableResource {
				additionalProtocols.append("EvictableResource")
			}
			if schema.isScalableResource {
				additionalProtocols.append("ScalableResource")
			}
			if schema.hasStatus {
				additionalProtocols.append("StatusHavingResource")
			}

			let renderedMain = mainProtocols.joined(separator: ", ")
			let renderedVerbs = verbsProtocols.joined(separator: ", ")
			let renderedAdditional = additionalProtocols.joined(separator: ", ")

			if verbsProtocols.isEmpty && additionalProtocols.isEmpty {
				return  renderedMain + " {"
			} else if additionalProtocols.isEmpty {
				return renderedMain + ",\n\t\t" + renderedVerbs + "\n\t{"
			}

			return renderedMain + ",\n\t\t" + renderedVerbs + ",\n\t\t" + renderedAdditional + "\n\t{"
		}

		registerFilter("P.renderDescription") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "[P.renderDescription]: Input must be a Property: \(String(describing: input))")
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
				throw ModelGenError.RuntimeError(message: "[P.render]: Input must be a Property: \(String(describing: input))")
			}

			let varOrLet = { () -> String in
				if property.isConstant {
					return "let"
				} else {
					return "var"
				}
			}()

			let name = { () -> String in
				let name = property.name!
				guard !Keywords.contains(name) else {
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
				throw ModelGenError.RuntimeError(message: "[P.renderArg]: Input must be a Property: \(String(describing: input))")
			}

			let name = { () -> String in
				let name = property.name!
				guard !Keywords.contains(name) else {
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
				throw ModelGenError.RuntimeError(message: "[P.renderArgDefaultNil]: Input must be a Property: \(String(describing: input))")
			}

			if property.isOptional {
				return " = nil"
			}

			return ""
		}

		registerFilter("P.type") { input in
			guard let property = input as? Property else {
				throw ModelGenError.RuntimeError(message: "[P.type]: Input must be a Property: \(String(describing: input))")
			}
			return "\(property.type.renderedType)"
		}

		registerFilter("P.escapeKeywords") { input in
			guard let name = input as? String else {
				throw ModelGenError.RuntimeError(message: "[P.escapeKeywords]: Input must be a String: \(String(describing: input))")
			}

			guard !Keywords.contains(name) else {
				return "`\(name)`"
			}

			return name
		}

		registerFilter("GVK.group") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.group]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedGroup)"
		}

		registerFilter("GVK.version") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.version]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedVersion)"
		}

		registerFilter("GVK.kind") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.version]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.kind)"
		}

		registerFilter("GVK.case") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.case]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedCase)"
		}

		registerFilter("GVK.full") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.full]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedFull)"
		}

		registerFilter("GVK.type") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.type]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedTypeCase)"
		}

		registerFilter("GVK.plural") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.plural]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedPluralName)"
		}

		registerFilter("GVK.pluralVariable") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.pluralVariable]: Input must be a GroupVersionKind: \(String(describing: input))")
			}

			let name = gvk.renderedPluralVariableName

			if name.hasPrefix("API") {
				return "api" + name.dropFirst(3)
			} else if name.hasPrefix("CSI") {
				return "csi" + name.dropFirst(3)
			} else if name.hasPrefix("RBAC") {
				return "rbac" + name.dropFirst(4)
			} else {
				return "\(name.lowercasingFirstLetter())"
			}
		}

		registerFilter("GVK.short") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.short]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return (gvk.renderedShortName != nil) ? "\"\(gvk.renderedShortName!)\"" : "nil"
		}

		registerFilter("GVK.nsScope") { input in
			guard let gvk = input as? GroupVersionKind else {
				throw ModelGenError.RuntimeError(message: "[GVK.nsScope]: Input must be a GroupVersionKind: \(String(describing: input))")
			}
			return "\(gvk.renderedNamespaceScope)"
		}

		registerFilter("GV.type") { input in
			guard let gv = input as? GroupVersion else {
				throw ModelGenError.RuntimeError(message: "[GV.type]: Input must be a GroupVersion: \(String(describing: input))")
			}
			return "\(gv.renderedType)"
		}

		registerFilter("GV.typeVariable") { input in
			guard let gv = input as? GroupVersion else {
				throw ModelGenError.RuntimeError(message: "[GV.type]: Input must be a GroupVersion: \(String(describing: input))")
			}

			let type = gv.renderedType

			if type.hasPrefix("API") {
				return "api" + type.dropFirst(3)
			} else if type.hasPrefix("CSI") {
				return "csi" + type.dropFirst(3)
			} else if type.hasPrefix("RBAC") {
				return "rbac" + type.dropFirst(4)
			} else {
				return "\(type.lowercasingFirstLetter())"
			}
		}

		registerFilter("GV.raw") { input in
			guard let gv = input as? GroupVersion else {
				throw ModelGenError.RuntimeError(message: "[GV.type]: Input must be a GroupVersion: \(String(describing: input))")
			}
			return "\(gv.renderedRaw)"
		}
	}
}
