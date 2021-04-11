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

#if os(Linux)
	typealias NSRegularExpression = RegularExpression
#endif

extension String {

	func sanitizedRef() -> String {
		var sanitized = deletingPrefix("#/definitions/")
		sanitized = TypePrefixes.reduce(sanitized) { result, prefix in result.deletingPrefix(prefix) }
		return sanitized
	}

	func deletingPrefix(_ prefix: String) -> String {
		guard hasPrefix(prefix) else {
			return self
		}
		return String(dropFirst(prefix.count))
	}

	func deletingSuffix(_ suffix: String) -> String {
		guard hasSuffix(suffix) else {
			return self
		}
		return String(dropLast(suffix.count))
	}

	func cleanupWhitespace() -> String {
		let regex = try! NSRegularExpression(pattern: #"^\n\s*\n"#, options: .anchorsMatchLines)
		return regex.stringByReplacingMatches(
			in: self,
			range: NSRange(startIndex..., in: self),
			withTemplate: ""
		)
	}

	func capitalizingFirstLetter() -> String {
		prefix(1).capitalized + dropFirst()
	}

	mutating func capitalizeFirstLetter() {
		self = capitalizingFirstLetter()
	}

	func lowercasingFirstLetter() -> String {
		prefix(1).lowercased() + dropFirst()
	}

	mutating func lowercaseFirstLetter() {
		self = lowercasingFirstLetter()
	}

	func camelCased() -> String {
		guard !isEmpty else {
			return ""
		}

		let parts = components(separatedBy: CharacterSet.alphanumerics.inverted)

		let first = String(describing: parts.first!).lowercasingFirstLetter()
		let rest = parts.dropFirst().map { String($0).capitalizingFirstLetter() }

		return ([first] + rest).joined(separator: "")
	}
}
