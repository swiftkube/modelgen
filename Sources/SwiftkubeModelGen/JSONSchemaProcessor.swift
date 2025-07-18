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
import ShellOut

class JSONSchemaProcessor {

	let apiVersion: String

	init(apiVersion: String) {
		self.apiVersion = apiVersion
	}

	func process(outputPath: Path) throws -> Definitions {
		let definitionsPath = try generateJSONSchema(outputPath: outputPath)
		var schema = try loadAndDecodeJson(url: definitionsPath.url, type: Definitions.self)
		schema.definitions = Dictionary(uniqueKeysWithValues: schema.definitions.map { key, value in
			(key.sanitizedRef(), value)
		})

		return schema
	}

	private func generateJSONSchema(outputPath: PathKit.Path) throws -> PathKit.Path {
		let jsonSchemaPath = outputPath + Path("schema-\(apiVersion)")
		let definitionsPath = jsonSchemaPath + Path("_definitions.json")

		if definitionsPath.exists {
			print("Found schema for \(apiVersion) at: \(jsonSchemaPath)")
			return definitionsPath
		}

		print("Writing schema for \(apiVersion) at: \(outputPath)/\(apiVersion)")

		let openAPIURL = "https://raw.githubusercontent.com/kubernetes/kubernetes/\(apiVersion)/api/openapi-spec/swagger.json"

		_ = try shellOut(to: "/usr/local/bin/openapi2jsonschema", arguments: [
			"--expanded", "--kubernetes",
			"--prefix", "https://swiftkube.dev/schema/\(apiVersion)/_definitions.json",
			"-o", jsonSchemaPath.absolute().string,
			openAPIURL,
		])

		return definitionsPath
	}

	private func loadAndDecodeJson<T: Decodable>(url: URL, type: T.Type) throws -> T {
		guard let data = try String(contentsOf: url, encoding: .utf8).data(using: .utf8) else {
			throw ModelGenError.RuntimeError(message: "Error decoding JSON")
		}
		return try JSONDecoder().decode(type, from: data)
	}
}
