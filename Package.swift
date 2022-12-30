// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftkubeModelGen",
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
		.package(url: "https://github.com/stencilproject/Stencil", from: "0.15.1"),
		.package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0")
	],

	targets: [
		.executableTarget(
			name: "skgen",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Stencil", package: "Stencil"),
				.product(name: "ShellOut", package: "ShellOut"),
			],
			path: "Sources/SwiftkubeModelGen"
		),
	]
)
