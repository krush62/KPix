#!/bin/bash

# Define the path to the Flutter binary
FLUTTER_BIN=~/flutter/flutter/bin/flutter

# Navigate to the Flutter project directory (one level up from release_tools)
cd ..

# Run the Flutter build command for Linux in release mode
$FLUTTER_BIN build linux --release
