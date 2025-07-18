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

// MARK: - ModelGenError

enum ModelGenError: Error {
	case RuntimeError(message: String)
}

// MARK: - SwiftkubeModelGen

struct SwiftkubeModelGen: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "SwiftkubeGenerator",
		discussion: """
		Model and code generator for the Swiftkube tooling
		""",
		subcommands: [ModelGen.self, Diff.self]
	)
}

SwiftkubeModelGen.main()
