#!/bin/bash

# Скрипт для локальной сборки и запуска Japan Car Calculator

set -e

PROJECT_DIR="japan-car-calc"
PROJECT_FILE="japan-car-calc.xcodeproj"
SCHEME="japan-car-calc"
BUILD_DIR="build"

echo "🔨 Сборка приложения..."

cd "$PROJECT_DIR"

xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build

APP_PATH="$BUILD_DIR/Build/Products/Debug/japan-car-calc.app"

echo "🚀 Запуск приложения..."
open "$APP_PATH"
