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

enum Type: String, Decodable {
	case string, integer, number, boolean, null, array, object
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

struct Definitions: Decodable {
	var definitions: [String: Resource]
}

struct Resource: Decodable, Comparable {

	let gvk: GroupVersionKind?
	let type: Type
	let description: String
	let required: [String]
	var properties: [Property]
	var deprecated: Bool = false
	var requiresCodableExtension: Bool = false
	var hasMetadata: Bool = false
	var isListResource: Bool = false
	var isAPIResource: Bool = false
	var isListableResource: Bool = false
	var isNamespaced: Bool = false
	var isClusterScoped: Bool = false

	enum CodingKeys: String, CodingKey {
		case type
		case description
		case required
		case properties
		case gvk = "x-kubernetes-group-version-kind"
	}

	init(from decoder: Decoder) throws {
		let resourceKey = decoder.codingPath.last?.stringValue

		if let _ = IgnoredTypes.first(where: { resourceKey?.hasPrefix($0) ?? false }) {
			self.gvk = nil
			self.type = .null
			self.description = ""
			self.required = []
			self.properties = []
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.gvk = try container.decodeIfPresent([GroupVersionKind].self, forKey: .gvk)?.first
		self.type = try container.decode(Type.self, forKey: .type)
		self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "No description"
		self.required = try container.decodeIfPresent([String].self, forKey: .required) ?? []
		self.deprecated = (self.description.range(of: "deprecated", options: .caseInsensitive) != nil)
		self.properties = []

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
		self.hasMetadata = properties.contains { $0.type.isMetadata }
		self.isListResource = properties.contains(where: { $0.name == "items" }) && gvk?.kind.hasSuffix("List") ?? false
		self.isAPIResource = APITypes.contains(gvk?.kind ?? "")
		self.isNamespaced = NamespaceScope.contains { (key: String, value: Bool) -> Bool in
			key == gvk?.kind && value == true
		}
		self.isClusterScoped = NamespaceScope.contains { (key: String, value: Bool) -> Bool in
			key == gvk?.kind && value == false
		}
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
