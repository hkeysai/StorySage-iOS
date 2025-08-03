# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## StorySage iOS App - Development Guide

StorySage iOS is a SwiftUI-based educational audio storytelling app for children aged 3-9. It connects to the StorySage Flask API to stream and cache audio stories.

## Build & Development Commands

### Building the Project
```bash
# Open in Xcode
open StorySage.xcodeproj

# Build from command line
xcodebuild -project StorySage.xcodeproj -scheme StorySage -configuration Debug build

# Run on iOS Simulator
xcodebuild -project StorySage.xcodeproj -scheme StorySage -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Clean build folder
xcodebuild -project StorySage.xcodeproj -scheme StorySage clean
```

### Development Setup
1. **Bundle ID**: `com.storysage.StorySage`
2. **Swift Version**: 5.0
3. **Minimum iOS**: Check project settings
4. **API Endpoint**: 
   - Debug: `http://localhost:5010`
   - Release: `https://api.storysage.com`

## Architecture Overview

The app follows MVVM-C (Model-View-ViewModel-Coordinator) architecture with SwiftUI:

### Navigation Pattern
- **NavigationRouter** (`Core/Navigation/NavigationRouter.swift`) - Centralized navigation using NavigationStack
- **NavigationDestination** enum defines all possible destinations
- Navigation is handled through `@EnvironmentObject` injection

### Network Layer
- **NetworkManager** (`Core/API/NetworkManager.swift`) - Singleton for all API calls
- **APIEndpoint** enum defines all endpoints with path construction
- Generic async/await request methods with proper error handling
- Automatic retry and connectivity monitoring

### Audio System
- **AudioPlayer** (`Core/Audio/AudioPlayer.swift`) - Manages playback with AVPlayer
- **AudioCacheManager** (`Core/Audio/AudioCacheManager.swift`) - Local file caching in Documents directory
- Background audio support with Remote Command Center integration
- Progress tracking and automatic story completion

### Data Flow
1. ViewModels fetch data using NetworkManager
2. Data is decoded into Swift models (Story, Category, UserProgress)
3. Audio files are cached locally for offline playback
4. Progress updates sync with server

## Key Components

### Models
- **Story**: Main content model with segments, duration, and audio URLs
- **Category**: Story groupings by educational theme
- **UserProgress**: Tracks listening history and achievements
- **StorySegment**: Individual parts of stories with their own audio

### Features Structure
```
Features/
├── Home/           # Main dashboard with categories
├── StoryList/      # Stories filtered by category
└── StoryDetail/    # Story player with controls
```

### Shared Components
- **CategoryCard**: Visual category selection
- **StoryCard**: Story preview with progress
- **MiniPlayerView**: Persistent mini player
- **ErrorView**: Standardized error handling

## API Integration

### Endpoints Used
- `GET /api/categories` - Fetch story categories
- `GET /api/stories?category=X&grade_level=Y` - Filtered stories
- `GET /api/stories/{id}` - Individual story details
- `GET /api/progress/{userId}` - User listening history
- `POST /api/progress/{userId}/{storyId}` - Update progress
- `GET /api/health` - Health check

### Response Format
All API responses follow the pattern:
```swift
struct APIResponse<T: Codable>: Codable {
    let status: String      // "success" or "error"
    let data: T?           // Actual data
    let message: String?   // Optional message
    let error: APIError?   // Error details
}
```

## State Management

### Environment Objects
- **NavigationRouter**: Manages navigation state
- **AudioPlayer**: Global audio playback state

### View Models
Each feature has its own ViewModel:
- Published properties for UI state
- Async methods for data loading
- Error handling and loading states

## Audio Features

### Playback Capabilities
- Stream or download audio files
- Background playback with lock screen controls
- 15-second skip forward/backward
- Variable playback speed (0.5x - 2.0x)
- Automatic progress saving

### Caching Strategy
- Audio files cached in Documents/StorySageAudio/
- Cache cleanup for files older than 30 days
- Progress-tracked downloads
- Offline playback support

## Security & Privacy

### Info.plist Configurations
- **NSAppTransportSecurity**: Allows localhost connections for development
- **UIBackgroundModes**: audio for background playback
- **AVAudioSessionCategoryPlayback**: Required for audio apps

### Data Storage
- User device ID generated and stored in UserDefaults
- Audio files cached locally in Documents directory
- No sensitive data stored on device

## Common Development Tasks

### Adding a New View
1. Create feature folder in Features/
2. Add View and ViewModel files
3. Add navigation case to NavigationDestination enum
4. Update NavigationDestinationModifier switch statement

### Adding API Endpoint
1. Add case to APIEndpoint enum with path construction
2. Add convenience method to NetworkManager
3. Create response model if needed
4. Use in ViewModel with async/await

### Debugging Network Requests
- NetworkManager logs all errors to console
- Check `lastError` property for recent failures
- Use proxy tools to inspect API traffic
- Toggle between local/production API in NetworkManager init

## Testing Approach

Currently no unit tests are implemented. When adding tests:
- Mock NetworkManager for ViewModel testing
- Test audio caching independently
- Use XCTest for unit tests
- UI tests for critical user flows

## Performance Considerations

- Stories are paginated (not all loaded at once)
- Audio files are cached for offline playback
- Images use AsyncImage with caching
- List views use LazyVStack for efficiency

## SwiftUI Best Practices Used

- Environment objects for shared state
- ViewModifiers for reusable UI logic
- Async/await for all network calls
- @MainActor for UI updates
- Proper error boundaries

## Troubleshooting

### Common Issues
1. **Audio won't play**: Check AVAudioSession setup and Info.plist
2. **Network errors**: Verify API is running on port 5010
3. **Navigation issues**: Ensure NavigationRouter is in environment
4. **Cache problems**: Check Documents directory permissions

### Debug Tips
- Use Xcode's Network instrument for API debugging
- Check Console for NetworkManager logs
- Verify audio file URLs are valid
- Test on real device for audio issues