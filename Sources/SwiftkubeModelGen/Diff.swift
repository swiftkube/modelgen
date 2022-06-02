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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ArgumentParser
import PathKit
import ShellOut
import Stencil

// MARK: - ModelGen

struct Diff: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "diff",
		subcommands: []
	)

//	@Option(name: .shortAndLong, help: "Kubernetes API versions to diff")
//	var apiVersions: [String]

	@Option(name: .shortAndLong, help: "Output directory")
	var output: String

	@Option(name: .shortAndLong, help: "Schema output directory")
	var schemaOutput: String = "/tmp/swiftkube"

	@Flag(help: "Clear output directory")
	var clear: Bool = false

	mutating func run() throws {
		let outputPath = Path(output).absolute()
		let schemaOutputPath = Path(schemaOutput).absolute()

		let suitableOutput = !outputPath.exists || ((try? outputPath.children())?.isEmpty == true)

		guard suitableOutput || clear else {
			throw ModelGenError.RuntimeError(message: "Output directory exists, not empty, and clear flag is not set")
		}

		if clear {
			try? outputPath.delete()
		}
		try outputPath.mkpath()


		var schema1198 = try JSONSchemaProcessor(apiVersion: "v1.19.8").process(outputPath: schemaOutputPath)
		var schema1209 = try JSONSchemaProcessor(apiVersion: "v1.20.9").process(outputPath: schemaOutputPath)

		for def in schema1198.definitions {
			let lhs = def.value
			guard let rhs = schema1209.definitions[def.key] else {
				print("\(def.key) Removed from v1.19.8")
				continue
			}

			let x = Set(lhs.properties)
			let y = Set(rhs.properties)

			let z = x.symmetricDifference(y)

			guard !z.isEmpty else {
				continue
			}

			z.forEach { prop in
				if lhs.properties.contains(prop) {
					print("\(lhs.gvk): \(prop.name) Deleted")
				} else {
					print("\(lhs.gvk): \(prop.name) Added")
				}
			}
		}

		for def in schema1209.definitions {
			let lhs = def.value
			guard let rhs = schema1198.definitions[def.key] else {
				print("\(def.key) Added in 1.20.8")
				continue
			}

			let x = Set(lhs.properties)
			let y = Set(rhs.properties)

			let z = x.symmetricDifference(y)

			guard !z.isEmpty else {
				continue
			}

			z.forEach { prop in
				if lhs.properties.contains(prop) {
					print("\(lhs.gvk): \(prop.name) Deleted")
				} else {
					print("\(lhs.gvk): \(prop.name) Added")
				}
			}
		}
	}
}
