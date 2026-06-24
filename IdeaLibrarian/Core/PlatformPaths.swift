import Foundation

public enum PlatformPaths {
    public static func userLibraryURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let explicit = environment["LIBRARIAN_CORPUS_PATH"], !explicit.isEmpty {
            return URL(fileURLWithPath: explicit, isDirectory: true).standardizedFileURL
        }

        return documentsDirectory(environment: environment)
            .appendingPathComponent("Librarian", isDirectory: true)
            .appendingPathComponent("UserLibrary", isDirectory: true)
            .standardizedFileURL
    }

    public static func databaseURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let explicit = environment["LIBRARIAN_DB_PATH"], !explicit.isEmpty {
            return URL(fileURLWithPath: explicit, isDirectory: false).standardizedFileURL
        }

        return applicationDataDirectory(environment: environment)
            .appendingPathComponent("Librarian", isDirectory: true)
            .appendingPathComponent("librarian.db", isDirectory: false)
            .standardizedFileURL
    }

    public static func dotEnvCandidateURLs(environment: [String: String] = ProcessInfo.processInfo.environment) -> [URL] {
        var urls: [URL] = []

        if let explicit = environment["LIBRARIAN_ENV_FILE"], !explicit.isEmpty {
            urls.append(URL(fileURLWithPath: explicit, isDirectory: false))
        }

        urls.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).appendingPathComponent(".env"))
        urls.append(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".env"))
        urls.append(configDirectory(environment: environment).appendingPathComponent(".env"))

        var seen = Set<String>()
        return urls.map { $0.standardizedFileURL }.filter { seen.insert($0.path).inserted }
    }

    public static func ensureParentDirectoryExists(for fileURL: URL) throws {
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    }

    public static func ensureDirectoryExists(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static func documentsDirectory(environment: [String: String]) -> URL {
        #if os(Windows)
        if let userProfile = environment["USERPROFILE"], !userProfile.isEmpty {
            return URL(fileURLWithPath: userProfile, isDirectory: true).appendingPathComponent("Documents", isDirectory: true)
        }
        #endif

        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documents
        }

        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
    }

    private static func applicationDataDirectory(environment: [String: String]) -> URL {
        #if os(Windows)
        if let localAppData = environment["LOCALAPPDATA"], !localAppData.isEmpty {
            return URL(fileURLWithPath: localAppData, isDirectory: true)
        }
        if let appData = environment["APPDATA"], !appData.isEmpty {
            return URL(fileURLWithPath: appData, isDirectory: true)
        }
        #endif

        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return appSupport
        }

        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/share", isDirectory: true)
    }

    private static func configDirectory(environment: [String: String]) -> URL {
        #if os(Windows)
        if let appData = environment["APPDATA"], !appData.isEmpty {
            return URL(fileURLWithPath: appData, isDirectory: true).appendingPathComponent("Librarian", isDirectory: true)
        }
        #endif

        if let xdgConfig = environment["XDG_CONFIG_HOME"], !xdgConfig.isEmpty {
            return URL(fileURLWithPath: xdgConfig, isDirectory: true).appendingPathComponent("librarian", isDirectory: true)
        }

        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/librarian", isDirectory: true)
    }
}
