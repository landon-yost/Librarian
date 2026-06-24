// swift-tools-version: 5.9

import PackageDescription

var products: [Product] = [
    .executable(name: "LibrarianCLI", targets: ["LibrarianCLI"]),
]

var targets: [Target] = [
    .target(
        name: "IdeaLibrarianCore",
        dependencies: [],
        path: "IdeaLibrarian",
        exclude: [
            "IdeaLibrarianApp.swift",
            "ContentView.swift",
            "Assets.xcassets",
            "IdeaLibrarian.xcdatamodeld",
            "Persistence.swift",
            "ViewModels"
        ],
        sources: [
            "Core", "Retriever", "Reasoner", "Scanner", "Index",
            "ContextBuilder", "Distiller"
        ]
    ),
    .executableTarget(
        name: "LibrarianCLI",
        dependencies: ["IdeaLibrarianCore"],
        path: "Sources/LibrarianCLI"
    ),
    .testTarget(
        name: "IdeaLibrarianCoreTests",
        dependencies: ["IdeaLibrarianCore"],
        path: "Tests/IdeaLibrarianCoreTests"
    ),
]

#if os(macOS)
products.append(.executable(name: "Librarian", targets: ["IdeaLibrarian"]))
targets.append(
    .executableTarget(
        name: "IdeaLibrarian",
        dependencies: ["IdeaLibrarianCore"],
        path: "IdeaLibrarian",
        exclude: [
            "Core", "Retriever", "Reasoner", "Scanner", "Index",
            "ContextBuilder", "Distiller", "Assets.xcassets", "IdeaLibrarian.xcdatamodeld"
        ],
        sources: ["IdeaLibrarianApp.swift", "ContentView.swift", "Persistence.swift", "ViewModels"]
    )
)
#endif

let package = Package(
    name: "Librarian",
    products: products,
    dependencies: [],
    targets: targets
)
