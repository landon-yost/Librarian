# Librarian Windows Port

This branch is the Windows-compatible second version of Librarian.

The macOS SwiftUI app is preserved. Windows should use the new `LibrarianCLI` executable first, then a native or web UI can wrap the CLI/core later.

## What changed on this branch

- `Package.swift` now always exposes `LibrarianCLI`.
- The existing SwiftUI app target is only included on macOS.
- `PlatformPaths.swift` adds platform-aware default folders.
- `DocumentScanner.swift` no longer hard-requires PDFKit. On Apple platforms it still uses PDFKit. Elsewhere it tries `pdftotext` if available and otherwise skips unreadable PDFs.
- `DeepSeekClient.swift` imports `FoundationNetworking` when available.

## Windows default paths

- Corpus: `%USERPROFILE%\\Documents\\Librarian\\UserLibrary`
- Database: `%LOCALAPPDATA%\\Librarian\\librarian.db`
- Optional config env file: `%APPDATA%\\Librarian\\.env`

You can override these with CLI flags:

```powershell
swift run LibrarianCLI diagnose --corpus "C:\\Users\\you\\Documents\\Librarian\\UserLibrary" --db "C:\\Users\\you\\AppData\\Local\\Librarian\\librarian.db"
```

## Commands

```powershell
swift build
swift run LibrarianCLI diagnose
swift run LibrarianCLI index
swift run LibrarianCLI embed
swift run LibrarianCLI ask "what is in my library?"
```

## Important remaining Claude Code tasks

The GitHub connector blocked edits to a couple existing files that include current OpenAI client code. Claude Code should finish these locally:

1. Add this import block after `import Foundation` in:
   - `IdeaLibrarian/Reasoner/OpenAIChatClient.swift`
   - `IdeaLibrarian/Index/EmbeddingProvider.swift`

```swift
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```

2. Update `IdeaLibrarian/Core/Configuration.swift` to use `PlatformPaths.databaseURL()` for the default DB path instead of force-unwrapping `.applicationSupportDirectory`.

Target replacement:

```swift
self.databasePath = databasePath ?? Configuration.defaultDatabasePath()
```

and add:

```swift
private static func defaultDatabasePath() -> String {
    let url = PlatformPaths.databaseURL()
    try? PlatformPaths.ensureParentDirectoryExists(for: url)
    return url.path
}
```

3. Update the `.env` lookup in `Configuration.swift` to use:

```swift
for url in PlatformPaths.dotEnvCandidateURLs() {
    guard FileManager.default.fileExists(atPath: url.path),
          let contents = try? String(contentsOf: url, encoding: .utf8) else {
        continue
    }
    return parseDotEnv(contents)
}
```

4. Verify SQLite on Windows. If `import SQLite3` fails, add a Windows-compatible SQLite module map or dependency. Do not remove FTS5 support unless there is no other option.

5. Run on Windows:

```powershell
swift build
swift test
swift run LibrarianCLI diagnose
```

## Design direction

Do not port the Mac SwiftUI UI directly. Keep the core cross-platform and wrap it with one of these later:

- Tauri local UI
- Electron local UI
- WinUI front end
- Localhost web app talking to `LibrarianCLI` or a future local server
