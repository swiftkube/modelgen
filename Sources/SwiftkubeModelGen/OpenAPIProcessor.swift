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

var ResourceScope: [GroupVersionKind: Bool] = [:]

let SubResources = [
	"/eviction",
	"/scale",
	"/status",
]

// MARK: - OpenAPIProcessor

class OpenAPIProcessor {

	let apiVersion: String

	init(apiVersion: String) {
		self.apiVersion = apiVersion
	}

	func process(schema: inout Definitions) throws {
		let openAPIURL = URL(string: "https://raw.githubusercontent.com/kubernetes/kubernetes/\(apiVersion)/api/openapi-spec/swagger.json")!
		let data = try Data(contentsOf: openAPIURL)
		let spec = try JSONSerialization.jsonObject(with: data) as! [String: Any]
		let paths = spec["paths"] as! [String: [String: Any]]

		for (path, definition) in paths {
			if let _ = SubResources.first(where: { path.hasSuffix($0) }) {
				continue
			}

			var resource: Resource?
			if let def = definition["get"] as? [String: Any] {
				resource = processGET(path, def, &schema)
			}
			if let def = definition["post"] as? [String: Any] {
				resource = processPOST(path, def, &schema)
			}
			if let def = definition["put"] as? [String: Any] {
				resource = processPUT(path, def, &schema)
			}
			if let def = definition["delete"] as? [String: Any] {
				resource = processDELETE(path, def, &schema)
			}
			if let def = definition["patch"] as? [String: Any] {
				resource = processPATCH(path, def, &schema)
			}

			guard let apiResource = resource, apiResource.isAPIResource else {
				continue
			}

			if path.contains("{namespace}") {
				apiResource.isNamespaced = true
				ResourceScope[apiResource.gvk!] = true
			}
		}
	}

	private func extractGVK(def: [String: Any]) -> String? {
		guard
			let pathGVK = def["x-kubernetes-group-version-kind"] as? [String: String],
			let group = pathGVK["group"],
			let version = pathGVK["version"],
			let kind = pathGVK["kind"]
		else {
			return nil
		}

		let trimmedGroup = (group == "") ? "" : String(group.split(separator: ".").first!)
		let key = (trimmedGroup == "") ? "core.\(version).\(kind)" : "\(trimmedGroup).\(version).\(kind)"
		return key
	}

	private func processGET(_ path: String, _ def: [String: Any], _ schema: inout Definitions) -> Resource? {
		guard let key = extractGVK(def: def), let resource = schema.definitions[key] else {
			return nil
		}

		resource.isAPIResource = true
		resource.isReadableResource = true

		if let listOp = def["x-kubernetes-action"] as? String, listOp == "list" {
			resource.isListableResource = true
		}

		return resource
	}

	private func processPOST(_ path: String, _ def: [String: Any], _ schema: inout Definitions) -> Resource? {
		guard let key = extractGVK(def: def), let resource = schema.definitions[key] else {
			return nil
		}

		resource.isAPIResource = true
		resource.isCreatableResource = true

		return resource
	}

	private func processPUT(_ path: String, _ def: [String: Any], _ schema: inout Definitions) -> Resource? {
		guard let key = extractGVK(def: def), let resource = schema.definitions[key] else {
			return nil
		}

		resource.isAPIResource = true
		resource.isReplaceableResource = true

		return resource
	}

	private func processDELETE(_ path: String, _ def: [String: Any], _ schema: inout Definitions) -> Resource? {
		guard let key = extractGVK(def: def), let resource = schema.definitions[key] else {
			return nil
		}

		resource.isAPIResource = true
		resource.isDeletableResource = true

		if let listOp = def["x-kubernetes-action"] as? String, listOp == "deletecollection" {
			resource.isCollectionDeletableResource = true
		}

		return resource
	}

	private func processPATCH(_ path: String, _ def: [String: Any], _ schema: inout Definitions) -> Resource? {
		// TODO:
		nil
	}
}
