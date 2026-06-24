import Foundation
#if canImport(IdeaLibrarianCore)
import IdeaLibrarianCore
#endif

@main
enum LibrarianCLI {
    static func main() async {
        do {
            try await run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("LibrarianCLI error: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func run(_ args: [String]) async throws {
        guard let command = args.first else {
            printUsage()
            return
        }

        let options = CLIOptions(args: Array(args.dropFirst()))
        let corpusURL = URL(fileURLWithPath: options.corpusPath ?? PlatformPaths.userLibraryURL().path, isDirectory: true)
        try PlatformPaths.ensureDirectoryExists(corpusURL)
        let databaseURL = URL(fileURLWithPath: options.databasePath ?? PlatformPaths.databaseURL().path, isDirectory: false)
        try PlatformPaths.ensureParentDirectoryExists(for: databaseURL)
        let policy = options.policy.flatMap { AssistantPolicy(rawValue: $0.lowercased()) } ?? .chat
        let config = Configuration(databasePath: databaseURL.path, corpusPath: corpusURL.path, defaultPolicy: policy)

        switch command.lowercased() {
        case "help", "--help", "-h":
            printUsage()
        case "diagnose":
            print("LibrarianCLI diagnostics")
            print("Corpus: \(corpusURL.path)")
            print("Database: \(databaseURL.path)")
            print("Policy: \(config.defaultPolicy.rawValue)")
        case "index":
            let engine = try AtlasEngine(config: config)
            try await engine.indexKnowledgeBase { progress in
                print("Index: \(progress.indexed)/\(progress.total) \(progress.currentFile ?? "")")
            }
            printStats(try engine.getStatistics())
        case "embed", "embeddings":
            let engine = try AtlasEngine(config: config)
            try await engine.generateEmbeddings { progress in
                print("Embed: \(progress.indexed)/\(progress.total) \(progress.currentFile ?? "")")
            }
            printStats(try engine.getStatistics())
        case "ask", "query":
            let query = options.remaining.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { throw CLIError.missingQuery }
            let engine = try AtlasEngine(config: config)
            let result = try await engine.processQuery(query)
            print(result.response)
            print("\nCCR: \(String(format: "%.3f", result.ccrScore))")
            print("Chunks: \(result.context.results.count)")
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    private static func printStats(_ stats: DatabaseStatistics) {
        print("Documents: \(stats.documentCount)")
        print("Chunks: \(stats.chunkCount)")
        print("Embeddings: \(stats.embeddingCount)")
        print("Saved notes: \(stats.savedNoteCount)")
        print("Concepts: \(stats.conceptCount)")
    }

    private static func printUsage() {
        print("""
        LibrarianCLI
        Commands:
          diagnose [--db PATH] [--corpus PATH] [--policy chat|librarian]
          index    [--db PATH] [--corpus PATH]
          embed    [--db PATH] [--corpus PATH]
          ask "question" [--db PATH] [--corpus PATH]
        """)
    }
}

private struct CLIOptions {
    let databasePath: String?
    let corpusPath: String?
    let policy: String?
    let remaining: [String]

    init(args: [String]) {
        var db: String?
        var corpus: String?
        var policy: String?
        var remaining: [String] = []
        var index = 0
        while index < args.count {
            switch args[index] {
            case "--db": index += 1; if index < args.count { db = args[index] }
            case "--corpus": index += 1; if index < args.count { corpus = args[index] }
            case "--policy": index += 1; if index < args.count { policy = args[index] }
            default: remaining.append(args[index])
            }
            index += 1
        }
        self.databasePath = db
        self.corpusPath = corpus
        self.policy = policy
        self.remaining = remaining
    }
}

private enum CLIError: LocalizedError {
    case missingQuery
    case unknownCommand(String)

    var errorDescription: String? {
        switch self {
        case .missingQuery: return "Missing query after ask command."
        case .unknownCommand(let command): return "Unknown command: \(command)"
        }
    }
}
