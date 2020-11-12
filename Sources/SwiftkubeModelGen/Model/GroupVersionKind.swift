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

struct GroupVersionKind: Decodable, Hashable {
	let group: String
	let version: String
	let kind: String

	init(group: String, version: String, kind: String) {
		self.group = group
		self.version = version
		self.kind = kind
	}

	var urlPath: String {
		if group == "" {
			return "/api/\(version)"
		} else {
			return "/apis/\(group)/\(version)"
		}
	}

	var renderedGroup: String {
		return (group == "" || group == "core")
			? "core"
			: "\(group)"
	}

	var renderedVersion: String {
		return version
	}

	var renderedCase: String {
		return (group == "" || group == "core")
			? "core\(version.capitalized)\(kind.capitalizingFirstLetter())"
			: "\(String(group.prefix(while: { $0 != "." })))\(version.capitalized)\(kind.capitalizingFirstLetter())"
	}

	var renderedFull: String {
		return (group == "" || group == "core")
			? "\(version)/\(kind)"
			: "\(group)/\(version)/\(kind)"
	}

	var renderedTypeCase: String {
		return (group == "" || group == "core")
			? "core.\(version).\(kind)"
			: "\(String(group.prefix(while: { $0 != "." }))).\(version).\(kind)"
	}

	var renderedPluralName: String {
		return PluralNames[kind]!
	}

	var renderedShortName: String? {
		return ShortNames[kind]
	}

	var renderedNamespaceScope: Bool {
		return NamespaceScope[kind]!
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(group)
		hasher.combine(version)
	}
}

extension GroupVersionKind: Comparable {

	static func < (lhs: GroupVersionKind, rhs: GroupVersionKind) -> Bool {
		switch (lhs, rhs) {
		case let (lhs, rhs) where lhs.group < rhs.group:
			return true
		case let (lhs, rhs) where lhs.group > rhs.group:
			return false
		case let (lhs, rhs) where lhs.group == rhs.group:
			if lhs.version == rhs.version {
				return lhs.kind < rhs.kind
			}

			let lv = lhs.version.parseVersion()
			let rv = rhs.version.parseVersion()

			if lv.level.isEmpty && rv.level.contains("beta") {
				return true
			} else if lv.level.isEmpty && rv.level.contains("alpha") {
				return true
			} else if lv.level.contains("beta") && rv.level.contains("alpha") {
				return true
			} else if lv.level.contains("alpha") && rv.level.contains("beta") {
				return false
			} else if lv.level.contains("beta") && rv.level.isEmpty {
				return false
			}  else if lv.level.contains("alpha") && rv.level.isEmpty {
				return false
			} else if lv.level == rv.level {
				return lv.version < rv.version
			} else if lv.level.contains("alpha") && rv.level.contains("alpha")  {
				return lv.level > rv.level
			} else if lv.level.contains("beta") && rv.level.contains("beta")  {
				return lv.level > rv.level
			} else {
				return false
			}
		default:
			return true
		}
	}
}

extension String {

	func parseVersion() -> (version: String, level: String) {
		let str = lowercased()

		if str.contains("alpha") {
			let index = str.range(of: "alpha")!.lowerBound
			let version = str.prefix(upTo: index)
			return (String(version), String(str.suffix(from: index)))
		} else if str.contains("beta") {
			let index = str.range(of: "beta")!.lowerBound
			let version = str.prefix(upTo: index)
			return (String(version), String(str.suffix(from: index)))
		} else {
			return (str, "")
		}
	}
}
