
# Building Aurora Browser

This document provides instructions for building Aurora Browser from source.

## Prerequisites

Before you begin, ensure you have the following installed:

- macOS 12.0 or later
- Xcode 14.0 or later
- Command Line Tools for Xcode
- Python 3.9 or later
- CMake 3.20 or later
- Node.js 16 or later
- Git

## Step 1: Clone WebKit

First, clone the WebKit repository if you haven't already:

```bash
cd /Users/dima/Development
git clone https://github.com/WebKit/WebKit.git
cd WebKit
```

## Step 2: Apply Aurora Patches

Apply our custom patches to WebKit:

```bash
cd /Users/dima/Development/WebKit
git apply /Users/dima/Development/llama-webkit-browser/aurora/patches/webkit-aurora.patch
```

Note: The patch file will be created in a future step of development.

## Step 3: Build WebKit

Build WebKit with our modifications:

```bash
cd /Users/dima/Development/WebKit
Tools/Scripts/build-webkit --release
```

This process may take a while (30-60 minutes depending on your machine).

## Step 4: Build Aurora UI

Now build the Aurora browser UI:

```bash
cd /Users/dima/Development/llama-webkit-browser/aurora
xcodebuild -project Aurora.xcodeproj -scheme Aurora -configuration Release
```

## Step 5: Link Components

Link the WebKit build with Aurora:

```bash
cd /Users/dima/Development/llama-webkit-browser/aurora
./scripts/link-webkit.sh
```

Note: The linking script will be created in a future step of development.

## Step 6: Run Aurora

You can now run Aurora:

```bash
cd /Users/dima/Development/llama-webkit-browser/aurora/build/Release
open Aurora.app
```

## Troubleshooting

### Common Issues

#### WebKit Build Fails

If the WebKit build fails, try:

```bash
cd /Users/dima/Development/WebKit
Tools/Scripts/clean-webkit
Tools/Scripts/build-webkit --debug
```

#### Missing Dependencies

If you're missing dependencies, install them with:

```bash
brew install cmake python node
```

#### Linking Errors

If you encounter linking errors:

```bash
cd /Users/dima/Development/llama-webkit-browser/aurora
./scripts/fix-links.sh
```

Note: The fix-links script will be created in a future step of development.

## Development Workflow

For active development, you may want to use a more streamlined workflow:

1. Make changes to Aurora UI code
2. Build with `xcodebuild -project Aurora.xcodeproj -scheme Aurora -configuration Debug`
3. Run with `open build/Debug/Aurora.app`

For WebKit changes:

1. Make changes to WebKit code
2. Rebuild WebKit with `Tools/Scripts/build-webkit --debug`
3. Relink with `./scripts/link-webkit.sh`
4. Run Aurora

## Creating a Distribution Build

To create a distributable version of Aurora:

```bash
cd /Users/dima/Development/llama-webkit-browser/aurora
./scripts/create-dmg.sh
```

This will create `Aurora.dmg` in the `dist` directory.

Note: The create-dmg script will be created in a future step of development.
