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


let ManualTypes = Set([
	"io.k8s.apimachinery.pkg.api.resource.Quantity",
	"io.k8s.apimachinery.pkg.util.intstr.IntOrString",
])

let JSONTypes = [
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.JSONSchemaProps": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.apis.meta.v1.Patch": PropertyType.map(valueType: .any),
	"io.k8s.apimachinery.pkg.runtime.RawExtension": PropertyType.map(valueType: .any),
]

let OtherTypes = [
	"io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime": PropertyType.string,
	"io.k8s.apimachinery.pkg.apis.meta.v1.Time": PropertyType.string,
]

private let IgnoredTypes = Set([
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON",
	"io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1beta1.JSON",
	"io.k8s.apimachinery.pkg.api.resource.Quantity",
	"io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1",
	"io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime",
	"io.k8s.apimachinery.pkg.apis.meta.v1.Patch",
	"io.k8s.apimachinery.pkg.apis.meta.v1.Time",
	"io.k8s.apimachinery.pkg.runtime.RawExtension",
	"io.k8s.apimachinery.pkg.version.Info",
	"io.k8s.apimachinery.pkg.util.intstr.IntOrString",
])

enum Type: String, Decodable {
	case string, integer, number, boolean, null, array, object
}

indirect enum PropertyType {
	case string
	case integer
	case integer32
	case integer64
	case double
	case number
	case boolean
	case array(itemType: PropertyType)
	case map(valueType: PropertyType)
	case ref(typeRef: TypeReference)
	case any
	case unknown

	var requiresCodableExtension: Bool {
		switch self {
		case .any:
			return true
		case let .ref(typeRef: typeRef) where JSONTypes.keys.contains(typeRef.ref):
			return true
		case let .array(itemType: .ref(typeRef: typeRef)) where JSONTypes.keys.contains(typeRef.ref):
			return true
		case let .map(valueType: .ref(typeRef: typeRef)) where JSONTypes.keys.contains(typeRef.ref):
			return true
		default:
			return false
		}
	}

	var isMetadata: Bool {
		switch self {
		case let .ref(typeRef: typeRef) where typeRef.kind == "ObjectMeta":
			return true
		default:
			return false
		}
	}

	init(from type: Type, container: KeyedDecodingContainer<Property.CodingKeys>) throws {
		switch type {
		case .string:
			self = .string
		case .boolean:
			self = .boolean
		case .integer:
			let format = try container.decodeIfPresent(String.self, forKey: .format)
			if format == "int32" {
				self = .integer32
			} else if format == "int64" {
				self = .integer64
			} else {
				self = .integer
			}
		case .number:
			let format = try container.decodeIfPresent(String.self, forKey: .format)
			if format == "double" {
				self = .double
			} else {
				self = .number
			}
		case .array:
			let arrayItems = try container.nestedContainer(keyedBy: Property.CodingKeys.self, forKey: .items)
			if let subtype = try arrayItems.decodeIfPresent(Type.self, forKey: .type) {
				let propertySubtype = try PropertyType(from: subtype, container: arrayItems)
				self = .array(itemType: propertySubtype)
			} else {
				let reference = try arrayItems.decode(String.self, forKey: .ref)
				let typeReference = TypeReference(ref: reference)
				self = .array(itemType: .ref(typeRef: typeReference))
			}
		case .object:
			let mapItems = try container.nestedContainer(keyedBy: Property.CodingKeys.self, forKey: .additionalProperties)
			if let subtype = try mapItems.decodeIfPresent(Type.self, forKey: .type) {
				let propertySubtype = try PropertyType(from: subtype, container: mapItems)
				self = .map(valueType: propertySubtype)
			} else {
				let reference = try mapItems.decode(String.self, forKey: .ref)
				let typeReference = TypeReference(ref: reference)
				self = .map(valueType: .ref(typeRef: typeReference))
			}
		default:
			self = .unknown
		}
	}

	var renderedType: String {
		switch self {
		case .string:
			return "String"
		case .integer:
			return "Int"
		case .integer32:
			return "Int32"
		case .integer64:
			return "Int64"
		case .double:
			return "Double"
		case .boolean:
			return "Bool"
		case let .array(itemType: subtype):
			return "[\(subtype.renderedType)]"
		case let .map(valueType: subtype):
			return "[String: \(subtype.renderedType)]"
		case let .ref(typeRef: typeReference):
			switch typeReference.ref {
			case let ref where ManualTypes.contains(ref):
				return String(ref.split(separator: ".").last!)
			case let ref where JSONTypes.keys.contains(ref):
				return JSONTypes[ref]!.renderedType
			case let ref where OtherTypes.keys.contains(ref):
				return OtherTypes[ref]!.renderedType
			default:
				return "\(typeReference.group).\(typeReference.version).\(typeReference.kind)"
			}
		case .any:
			return "Any"
		default:
			return "UNKNOWN"
		}
	}

	func renderedValue(from value: String) -> String? {
		switch self {
		case .string:
			return "\"\(value)\""
		default:
			return nil
		}
	}
}

struct Property: Decodable, Comparable {

	let type: PropertyType
	let description: String
	var name: String!
	var constValue: String? = nil
	var required: Bool = false

	var isContant: Bool {
		return constValue != nil
	}

	var isOptional: Bool {
		return !isContant && !required
	}

	static func < (lhs: Property, rhs: Property) -> Bool {
		switch (lhs.name, rhs.name) {
		case ("apiVersion", _):
			return true
		case (_, "apiVersion"):
			return false
		case ("kind", let val) where val != "apiVersion":
			return true
		case (let val, "kind") where val != "apiVersion":
			return false
		case ("metadata", let val) where val != "apiVersion" && val != "kind":
			return true
		case (let val, "metadata") where val != "apiVersion" && val != "kind":
			return false
		case let (l, r):
			return l! < r!
		}
	}

	static func == (lhs: Property, rhs: Property) -> Bool {
		return lhs.name == rhs.name
	}

	enum CodingKeys: String, CodingKey {
		case description
		case type
		case format
		case items
		case additionalProperties
		case ref = "$ref"
		case enumeration = "enum"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description"
		if let type = try container.decodeIfPresent(Type.self, forKey: .type) {
			self.type = try PropertyType(from: type, container: container)
		} else {
			let reference = try container.decode(String.self, forKey: .ref)
			let typeReference = TypeReference(ref: reference)
			self.type = .ref(typeRef: typeReference)
		}

		if let constValue = try container.decodeIfPresent([String].self, forKey: .enumeration)?.first {
			self.constValue = constValue
		}
	}
}

struct DynamicCodingKeys: CodingKey {
	let stringValue: String
	init?(stringValue: String) {
		self.stringValue = stringValue
	}
	var intValue: Int?
	init?(intValue: Int) {
		return nil
	}
}

struct GroupVersionKind: Decodable {
	let group: String
	let version: String
	let kind: String

	func makeGroupVersion() -> GroupVersion {
		return GroupVersion(group: group, version: version)
	}
}

struct GroupVersion: Hashable, Comparable {
	let group: String
	let version: String
	let urlPath: String

	init(group: String, version: String) {
		self.group = group
		self.version = version
		self.urlPath = {
			if group == "" {
				return "/api/\(version)"
			} else {
				return "/apis/\(group)/\(version)"
			}
		}()
	}

	var renderedGroup: String {
		return group == ""
			? "core"
			: "\(String(group.prefix(while: { $0 != "." })))"
	}

	var renderedVersion: String {
		return version
	}

	var renderedCase: String {
		return group == ""
			? "core\(version.capitalized)"
			: "\(String(group.prefix(while: { $0 != "." })))\(version.capitalized)"
	}

	var renderedFull: String {
		return group == ""
			? "\(version)"
			: "\(group)/\(version)"
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(group)
		hasher.combine(version)
	}

	static func < (lhs: GroupVersion, rhs: GroupVersion) -> Bool {
		switch (lhs, rhs) {
		case let (lhs, rhs) where lhs.group < rhs.group:
			return true
		case let (lhs, rhs) where lhs.group > rhs.group:
			return false
		case let (lhs, rhs) where lhs.group == rhs.group:
			return lhs.version < rhs.version
		default:
			return true
		}
	}
}

private let TypePrefixes = Set([
	"io.k8s.api.",
	"io.k8s.apiextensions-apiserver.pkg.apis.",
	"io.k8s.apimachinery.pkg.apis.",
	"io.k8s.kube-aggregator.pkg.apis.",
])

struct TypeReference: Hashable {
	let ref: String
	let group: String
	let version: String
	let kind: String
	let listItemKind: String

	init(ref: String) {
		let sanitized = ref.deletingPrefix("#/definitions/")

		self.ref = sanitized
		let key = TypePrefixes.reduce(self.ref) { result, prefix in
			result.deletingPrefix(prefix)
		}

		let gvk = key.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: true)
		self.group = String(gvk[0])
		self.version = String(gvk[1])
		self.kind = String(gvk[2])
		self.listItemKind = self.kind.deletingSuffix("List")
	}

	func renderedApiVersion() -> String {
		if group == "core" {
			return version
		}
		return "\(group)/\(version)"
	}
}

struct Resource: Decodable {

	let gvk: GroupVersionKind?
	let type: Type
	let description: String
	let deprecated: Bool
	let required: [String]
	var properties: [Property]
	var requiresCodableExtension: Bool
	var hasMetadata: Bool
	var listResource: Bool
	var isAPIResource: Bool

	enum CodingKeys: String, CodingKey {
		case type
		case description
		case required
		case properties
		case gvk = "x-kubernetes-group-version-kind"
	}

	init(from decoder: Decoder) throws {
		if let _ = IgnoredTypes.first(where: { decoder.codingPath.last?.stringValue.hasPrefix($0) ?? false }) {
			self.gvk = nil
			self.type = .null
			self.description = ""
			self.deprecated = false
			self.required = []
			self.properties = []
			self.requiresCodableExtension = false
			self.hasMetadata = false
			self.listResource = false
			self.isAPIResource = false
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.gvk = try container.decodeIfPresent([GroupVersionKind].self, forKey: .gvk)?.first
		self.type = try container.decode(Type.self, forKey: .type)
		self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description"
		self.required = try container.decodeIfPresent([String].self, forKey: .required) ?? []
		self.deprecated = (self.description.range(of: "deprecated", options: .caseInsensitive) != nil)
		self.properties = []
		self.requiresCodableExtension = false
		self.hasMetadata = false
		self.listResource = false
		self.isAPIResource = false

		guard container.allKeys.contains(.properties) else {
			return
		}

		let propertiesContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .properties)

		let props = try propertiesContainer.allKeys.map { key -> Property in
			var property = try propertiesContainer.decode(Property.self, forKey: key)
			property.name = key.stringValue

			if required.contains(key.stringValue) {
				property.required = true
			}
			if key.stringValue == "apiVersion" {
				if let gvk = self.gvk {
					if gvk.group.isEmpty {
						property.constValue = gvk.version
					} else {
						property.constValue = "\(gvk.group)/\(gvk.version)"
					}
				}
			}
			return property
		}

		self.properties.append(contentsOf: props.sorted())
		self.requiresCodableExtension = properties.contains { $0.type.requiresCodableExtension }
		self.hasMetadata = properties.contains { $0.type.isMetadata && $0.isOptional }
		self.listResource = properties.contains(where: { $0.name == "items" }) && gvk?.kind.hasSuffix("List") ?? false
		self.isAPIResource =
			!self.listResource &&
			properties.contains(where: { $0.name == "apiVersion" && $0.isContant }) &&
			properties.contains(where: { $0.name == "kind" && $0.isContant })
	}
}

struct Definitions: Decodable {
	var definitions: [String: Resource]
}
