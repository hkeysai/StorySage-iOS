# StorySage iOS

Educational storytelling app for children aged 3-9, featuring AI-generated audio stories with educational content.

## Features

- 📚 Grade-level content (Pre-K through 2nd Grade)
- 🎧 Professional audio narration with character voices
- 📱 Offline playback with smart caching
- 🎯 Educational focus with key lessons
- 🏃‍♂️ Progress tracking and achievements
- 🎨 Beautiful, child-friendly UI

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

## Setup

1. Clone the repository:
```bash
git clone git@github.com:hkeysai/StorySage-iOS.git
cd StorySage-iOS
```

2. Open in Xcode:
```bash
open StorySage.xcodeproj
```

3. Configure API endpoint:
- Development: `http://localhost:5010` (default)
- Production: Update in `NetworkManager.swift`

4. Build and run (⌘R)

## Architecture

The app follows MVVM-C (Model-View-ViewModel-Coordinator) pattern:

- **Views**: SwiftUI views for UI
- **ViewModels**: Business logic and state management
- **Models**: Data structures matching API responses
- **Network Layer**: Async/await based API client
- **Audio System**: AVPlayer with caching and background playback
- **Navigation**: Centralized NavigationRouter

## Project Structure

```
StorySage/
├── App/                    # App entry point and configuration
├── Core/                   # Core functionality
│   ├── API/               # Network layer
│   ├── Audio/             # Audio playback and caching
│   ├── Models/            # Data models
│   └── Navigation/        # Navigation system
├── Features/              # Feature modules
│   ├── Home/             # Main dashboard
│   ├── StoryList/        # Category story lists
│   └── StoryDetail/      # Story player
├── Shared/               # Reusable components
│   ├── Components/       # UI components
│   ├── Extensions/       # Swift extensions
│   └── Utilities/        # Helper classes
└── Assets.xcassets/      # Images and colors
```

## API Integration

The app connects to the StorySage Flask API:

- Categories: `/api/categories`
- Stories: `/api/stories`
- Progress: `/api/progress/{userId}/{storyId}`
- Health checks: `/api/health`

## Development

### Running Tests
```bash
# Unit tests
xcodebuild test -scheme StorySage -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Style
- SwiftLint configuration coming soon
- Follow Apple's Swift API Design Guidelines

### Debugging
- Network logs in console
- Audio caching in Documents/StorySageAudio/
- User defaults for device ID and preferences

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Copyright © 2025 StorySage. All rights reserved.