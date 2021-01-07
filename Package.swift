// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftkubeModelGen",
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
		.package(url: "https://github.com/stencilproject/Stencil", from: "0.13.1"),
		.package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0")
	],
	targets: [
		.target(
			name: "swiftkube-modelgen",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Stencil", package: "Stencil"),
				.product(name: "ShellOut", package: "ShellOut"),
			],
			path: "Sources/SwiftkubeModelGen"
		),
	]
)
