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

// MARK: - Type

enum Type: String, Decodable {
	case string, integer, number, boolean, null, array, object
}

// MARK: - DynamicCodingKeys

struct DynamicCodingKeys: CodingKey {
	let stringValue: String
	init?(stringValue: String) {
		self.stringValue = stringValue
	}

	var intValue: Int?
	init?(intValue: Int) {
		nil
	}
}

// MARK: - Definitions

struct Definitions: Decodable {
	var definitions: [String: Resource]
}

// MARK: - Resource

class Resource: Decodable, Comparable {

	var gvk: GroupVersionKind?
	var type: Type
	var description: String
	var required: [String]
	var properties: [Property]
	var deprecated: Bool = false
	var requiresCodableExtension: Bool = false
	var hasMetadata: Bool = false
	var isListResource: Bool = false
	var isAPIResource: Bool = false
	var isNamespaced: Bool = false
	var isReadableResource: Bool = false
	var isListableResource: Bool = false
	var isCreatableResource: Bool = false
	var isReplaceableResource: Bool = false
	var isDeletableResource: Bool = false
	var isCollectionDeletableResource: Bool = false
	var isScalableResource: Bool = false
	var isEvictableResource: Bool = false
	var hasStatus: Bool = false

	enum CodingKeys: String, CodingKey {
		case type
		case description
		case required
		case properties
		case gvk = "x-kubernetes-group-version-kind"
	}

	required init(from decoder: Decoder) throws {
		let resourceKey = decoder.codingPath.last?.stringValue

		if let _ = IgnoredSchemaTypes.first(where: { resourceKey?.hasPrefix($0) ?? false }) {
			gvk = nil
			type = .null
			description = ""
			required = []
			properties = []
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)

		gvk = try container.decodeIfPresent([GroupVersionKind].self, forKey: .gvk)?.first
		type = try container.decode(Type.self, forKey: .type)
		description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description"
		required = try container.decodeIfPresent([String].self, forKey: .required) ?? []
		deprecated = (description.range(of: "deprecated", options: .caseInsensitive) != nil)
		properties = []

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

			if key.stringValue == "apiVersion", let gvk = gvk {
				if gvk.group.isEmpty {
					property.constValue = gvk.version
				} else {
					property.constValue = "\(gvk.group)/\(gvk.version)"
				}
			}

			return property
		}

		properties.append(contentsOf: props.sorted())
		requiresCodableExtension = properties.contains { $0.type.requiresCodableExtension }
		hasMetadata = properties.contains { $0.type.isMetadata }
		isListResource = properties.contains(where: { $0.name == "items" }) && gvk?.kind.hasSuffix("List") ?? false
	}

	static func < (lhs: Resource, rhs: Resource) -> Bool {
		switch (lhs.gvk, rhs.gvk) {
		case let (.some(a), .some(b)):
			return a < b
		case (.some(_), .none):
			return true
		case (.none, .some(_)):
			return false
		default:
			return false
		}
	}

	static func == (lhs: Resource, rhs: Resource) -> Bool {
		switch (lhs.gvk, rhs.gvk) {
		case let (.some(a), .some(b)):
			return a == b
		case (.some(_), .none):
			return false
		case (.none, .some(_)):
			return false
		default:
			return false
		}
	}
}
