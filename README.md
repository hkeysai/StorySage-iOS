# StorySage iOS - Serverless Edition

Self-contained educational storytelling app for children aged 3-9, with all audio stories bundled in the app.

## Features

- 📚 Grade-level content (Pre-K through 2nd Grade) 
- 🎧 20+ professional audio stories bundled in app
- 📱 100% offline - no internet required
- 🎯 Educational focus with key lessons
- 🏃‍♂️ Local progress tracking and achievements
- 🎨 Beautiful, child-friendly UI
- 🔒 Complete privacy - no data leaves device

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

3. Add Resources folder to Xcode project:
- See `SERVERLESS_MIGRATION.md` for detailed instructions

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

## Serverless Architecture

The app is completely self-contained with:

- **Bundled Audio**: All MP3 files included in app bundle
- **Local Data**: Stories and categories stored in JSON files
- **Offline Progress**: User progress saved to UserDefaults
- **No Server Dependencies**: Zero external API calls

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