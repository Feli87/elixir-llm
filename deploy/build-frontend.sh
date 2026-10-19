#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Building React frontend..."
cd "$PROJECT_DIR/frontend"
npm ci
npm run build

echo "==> Copying build to priv/static/app..."
rm -rf "$PROJECT_DIR/priv/static/app"
cp -r dist "$PROJECT_DIR/priv/static/app"

echo "==> Done! Frontend ready at priv/static/app/"
