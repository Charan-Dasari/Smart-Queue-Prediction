#!/bin/bash
set -e

# Install Flutter stable into $HOME/flutter if not already present
if [ ! -d "$HOME/flutter" ]; then
  echo "Installing Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
else
  echo "Flutter already installed at $HOME/flutter"
fi

# Add Flutter to PATH
export PATH="$HOME/flutter/bin:$PATH"

# Verify Flutter version
flutter --version

# Disable Flutter analytics and tracking
flutter config --no-analytics

# Fetch dependencies
flutter pub get

# Build web release bundle
flutter build web --release
