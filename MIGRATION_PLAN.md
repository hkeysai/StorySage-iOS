# StorySage iOS App - Server Dependency Removal Migration Plan

## Executive Summary

This document outlines the complete migration strategy to transform the StorySage iOS app from a server-dependent architecture to a fully self-contained application with embedded content and zero external dependencies.

## Current State Analysis

### Server Dependencies Identified

1. **Network Manager (`NetworkManager.swift`)**
   - Base URL: `http://localhost:5010` (dev) / `https://api.storysage.com` (prod)
   - API Endpoints:
     - `/api/categories` - Fetches story categories
     - `/api/stories` - Fetches story list
     - `/api/stories/{id}` - Fetches individual story details
     - `/api/progress/{userId}` - Fetches user progress
     - `/api/progress/{userId}/{storyId}` - Updates progress
     - `/api/health` - Health check
     - `/api/health/audio` - Audio health check

2. **Audio Streaming**
   - Audio files currently streamed from remote URLs
   - `AudioCacheManager.swift` downloads and caches audio files
   - `AudioPlayer.swift` plays from cached or remote URLs

3. **Data Models**
   - Stories contain `audioUrl` pointing to server
   - Categories fetched from server
   - User progress synced with server

### Content Volume
- **Audio Files**: 29 MP3 files
- **Total Size**: 156MB
- **File Sizes**: Range from 1MB to 9MB per story

## Migration Strategy

### Phase 1: Project Setup and Structure

1. **Create Local Data Bundle**
   ```
   StorySage/
   ├── Resources/
   │   ├── Audio/           # All MP3 files
   │   ├── Data/            # JSON data files
   │   │   ├── stories.json
   │   │   ├── categories.json
   │   │   └── metadata.json
   │   └── Images/          # Story thumbnails (if any)
   ```

2. **Build Configuration**
   - Add all audio files to app bundle
   - Configure Copy Bundle Resources build phase
   - Ensure proper compression settings

### Phase 2: Data Layer Transformation

1. **Create Local Data Manager**
   - Replace `NetworkManager` with `LocalDataManager`
   - Load JSON data from bundle
   - Provide same interface as network layer

2. **Update Models**
   - Change `audioUrl` to local file references
   - Add bundle resource path resolution
   - Maintain backward compatibility

3. **Core Data Integration**
   - Add Core Data for user progress storage
   - Migrate from server-based progress to local storage
   - Implement offline-first architecture

### Phase 3: Audio System Updates

1. **Audio Resource Manager**
   - Load audio directly from bundle
   - Remove download/caching logic
   - Optimize memory usage for large files

2. **Update Audio Player**
   - Play from bundle resources
   - Remove network-dependent code
   - Maintain existing playback features

### Phase 4: API Layer Replacement

1. **Mock API Layer**
   - Create protocol-based API interface
   - Implement local data provider
   - Maintain existing ViewModels interface

2. **Remove Network Dependencies**
   - Remove `NetworkManager`
   - Remove health check endpoints
   - Clean up unused network code

### Phase 5: Testing and Optimization

1. **Performance Testing**
   - App size impact (estimate: ~180MB increase)
   - Memory usage during playback
   - Launch time impact

2. **Functionality Testing**
   - All stories playable
   - Progress tracking works offline
   - Navigation remains smooth

## Implementation Steps

### Step 1: Create Data Export Script

```bash
# Extract story data from PostgreSQL to JSON
# Copy audio files to iOS project
# Generate metadata mapping
```

### Step 2: Implement LocalDataManager

```swift
class LocalDataManager {
    static let shared = LocalDataManager()
    
    private let stories: [Story]
    private let categories: [Category]
    
    init() {
        // Load from bundle JSON files
        self.stories = loadStoriesFromBundle()
        self.categories = loadCategoriesFromBundle()
    }
    
    func getStories() async -> [Story] {
        return stories
    }
    
    func getCategories() async -> [Category] {
        return categories
    }
}
```

### Step 3: Update Audio References

```swift
extension Story {
    var localAudioURL: URL? {
        guard let audioFileName = audioUrl?.components(separatedBy: "/").last else {
            return nil
        }
        return Bundle.main.url(forResource: audioFileName.replacingOccurrences(of: ".mp3", with: ""), 
                               withExtension: "mp3", 
                               subdirectory: "Audio")
    }
}
```

### Step 4: Core Data Schema

```swift
// UserProgress entity
@NSManaged public var userId: String
@NSManaged public var storyId: String
@NSManaged public var playbackPosition: Int32
@NSManaged public var isCompleted: Bool
@NSManaged public var lastPlayed: Date
```

### Step 5: Update ViewModels

```swift
// Replace NetworkManager calls with LocalDataManager
// Add Core Data operations for progress
// Remove server sync logic
```

## Timeline Estimate

- **Phase 1**: 2 hours - Project setup and resource integration
- **Phase 2**: 4 hours - Data layer transformation
- **Phase 3**: 3 hours - Audio system updates
- **Phase 4**: 3 hours - API replacement
- **Phase 5**: 2 hours - Testing and optimization

**Total**: ~14 hours of development

## Risks and Mitigation

1. **App Size**
   - Risk: App becomes too large (>200MB)
   - Mitigation: Compress audio files, use AAC instead of MP3

2. **Memory Usage**
   - Risk: Loading all data at once causes memory issues
   - Mitigation: Lazy loading, pagination for stories

3. **Update Mechanism**
   - Risk: No way to add new content
   - Mitigation: Plan for future app updates with new content

## Benefits

1. **Zero Server Dependency**: App works completely offline
2. **Improved Performance**: No network latency
3. **Better Reliability**: No server downtime affects users
4. **Reduced Costs**: No server hosting needed
5. **Privacy**: All data stays on device

## Next Steps

1. Approve migration plan
2. Export data from server
3. Begin implementation following phases
4. Test thoroughly on various devices
5. Plan content update strategy

## Appendix: File Mapping

Sample mapping of server audio URLs to local files:
```json
{
  "https://api.storysage.com/audio/benny-big-feeling-day.mp3": "1b1aa466-389e-48ca-bee3-143b8a128c6c.mp3",
  "https://api.storysage.com/audio/luna-worried-night.mp3": "b6d8f66e-44e8-43d2-9cbc-e06896a8b072.mp3"
  // ... continue for all 29 stories
}
```