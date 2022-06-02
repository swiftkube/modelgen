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

struct TypeReference: Hashable, Comparable {
	let ref: String
	let gvk: GroupVersionKind
	let group: String
	let version: String
	let kind: String
	let listItemKind: String
	let apiVersion: String

	init(ref: String) {
		self.ref = ref.sanitizedRef()
		let gvk = self.ref.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: true)
		group = String(gvk[0])
		version = String(gvk[1])
		kind = String(gvk[2])
		self.gvk = GroupVersionKind(group: group, version: version, kind: kind)
		listItemKind = kind.deletingSuffix("List")

		if group == "core" {
			apiVersion = version
		} else {
			apiVersion = "\(group)/\(version)"
		}
	}

	static func < (lhs: TypeReference, rhs: TypeReference) -> Bool {
		let lgvk = GroupVersionKind(group: lhs.group, version: lhs.version, kind: lhs.kind)
		let rgvk = GroupVersionKind(group: rhs.group, version: rhs.version, kind: rhs.kind)
		return lgvk < rgvk
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(ref)
	}
}
