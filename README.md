# Aurora Browser

Aurora is an AI-powered WebKit browser with Nordic Electric AI aesthetics, featuring an integrated terminal and self-modifying capabilities.

![Aurora Browser](docs/images/aurora-screenshot.png)

## Features

- **WebKit-based Browser**: Fast, standards-compliant web browsing
- **Nordic Electric AI Design**: Beautiful, futuristic UI with aurora-inspired aesthetics
- **Integrated Terminal**: Execute commands directly from your browser
- **AI Copilot**: Context-aware AI assistant that understands web content
- **Self-Modifying Capabilities**: The browser can suggest and implement improvements to itself
- **LLaMA Integration**: Powered by local LLaMA models for privacy and performance

## Architecture

Aurora is built with a modular architecture:

1. **WebKit Core**: The rendering engine that powers the browser
2. **Swift UI Layer**: Modern, responsive interface built with SwiftUI
3. **LLaMA Backend**: Local AI model integration for intelligence
4. **Terminal Service**: Secure command execution environment
5. **Self-Evolution System**: Framework for browser self-improvement

## Getting Started

### Prerequisites

- macOS 12.0 or later
- Xcode 14.0 or later
- LLaMA backend server running (see [backend setup](https://github.com/CosmicFreyjaLab/aurora-backend/README.md))

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/CosmicFreyjaLab/aurora-browser.git
   cd aurora-browser
   ```

2. Build the project:
   ```bash
   xcodebuild -project Aurora.xcodeproj -scheme Aurora -configuration Release
   ```

3. Run Aurora:
   ```bash
   open build/Release/Aurora.app
   ```

### Backend Setup

Aurora requires a running LLaMA backend server. See the [backend documentation](https://github.com/CosmicFreyjaLab/aurora-backend/README.md) for setup instructions.

## Development

### Project Structure

```
aurora/
├── src/                  # Source code
│   ├── Views/            # SwiftUI views
│   ├── Models/           # Data models
│   ├── Services/         # Service classes
│   ├── Utils/            # Utility functions
│   └── Resources/        # Assets and resources
├── backend/              # LLaMA backend integration
├── docs/                 # Documentation
└── tests/                # Test suite
```

### Building from Source

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## Nordic Electric AI Design

Aurora features a unique Nordic Electric AI aesthetic, inspired by:

- Northern lights (aurora borealis)
- Scandinavian minimalism
- Electric blue and cyan accents
- Holographic interfaces
- Subtle animations and glowing effects

The design system is implemented in `NordicElectricAI.swift` and can be applied to any SwiftUI view.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- WebKit team for the browser engine
- LLaMA team for the AI models
- The SwiftUI community for UI components and inspiration
