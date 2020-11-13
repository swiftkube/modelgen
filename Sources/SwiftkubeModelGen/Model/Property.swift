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

indirect enum PropertyType {
	case string
	case integer
	case integer32
	case integer64
	case double
	case number
	case boolean
	case date
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
		case .date:
			return "Date"
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
			case let ref where ConvertedTypes.keys.contains(ref):
				return ConvertedTypes[ref]!.renderedType
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
