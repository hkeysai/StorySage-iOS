//
//  AudioCacheManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Audio Cache Manager

class AudioCacheManager {
    static let shared = AudioCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Create cache directory in Documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("StorySageAudio", isDirectory: true)
        
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    func cacheAudio(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw AudioCacheError.invalidURL
        }
        
        let fileName = generateFileName(from: urlString)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Check if file already exists
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        // Download and cache the file
        do {
            let data = try await NetworkManager.shared.downloadAudio(from: urlString)
            try data.write(to: localURL)
            return localURL
        } catch {
            throw AudioCacheError.downloadFailed(error)
        }
    }
    
    func cacheAudioWithProgress(
        from urlString: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw AudioCacheError.invalidURL
        }
        
        let fileName = generateFileName(from: urlString)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Check if file already exists
        if fileManager.fileExists(atPath: localURL.path) {
            progressHandler(1.0)
            return localURL
        }
        
        // Download with progress tracking
        do {
            let data = try await NetworkManager.shared.downloadAudioWithProgress(
                from: urlString,
                progressHandler: progressHandler
            )
            try data.write(to: localURL)
            return localURL
        } catch {
            throw AudioCacheError.downloadFailed(error)
        }
    }
    
    func getCachedFileURL(for urlString: String) -> URL? {
        let fileName = generateFileName(from: urlString)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func isFileCached(url: String) -> Bool {
        return getCachedFileURL(for: url) != nil
    }
    
    func removeCachedFile(for urlString: String) throws {
        let fileName = generateFileName(from: urlString)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }
    }
    
    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }
    
    func getCacheSize() -> Int64 {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            var totalSize: Int64 = 0
            for file in contents {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    func getCachedFiles() -> [CachedAudioFile] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
            )
            
            return contents.compactMap { url in
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.path)
                    let size = attributes[.size] as? Int64 ?? 0
                    let creationDate = attributes[.creationDate] as? Date ?? Date()
                    
                    return CachedAudioFile(
                        url: url,
                        fileName: url.lastPathComponent,
                        size: size,
                        creationDate: creationDate
                    )
                } catch {
                    return nil
                }
            }
        } catch {
            return []
        }
    }
    
    func cleanupOldFiles(olderThan days: Int = 30) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let cachedFiles = getCachedFiles()
        
        for file in cachedFiles {
            if file.creationDate < cutoffDate {
                try fileManager.removeItem(at: file.url)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create cache directory: \(error)")
            }
        }
    }
    
    private func generateFileName(from urlString: String) -> String {
        // Extract filename from URL or generate one
        if let url = URL(string: urlString) {
            let fileName = url.lastPathComponent
            if !fileName.isEmpty && fileName.contains(".") {
                return fileName
            }
        }
        
        // Generate filename from URL hash
        let hash = urlString.hash
        return "audio_\(abs(hash)).mp3"
    }
}

// MARK: - Cached Audio File

struct CachedAudioFile {
    let url: URL
    let fileName: String
    let size: Int64
    let creationDate: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

// MARK: - Audio Cache Error

enum AudioCacheError: Error, LocalizedError {
    case invalidURL
    case downloadFailed(Error)
    case fileSystemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        }
    }
}