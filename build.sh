#!/usr/bin/env bash
set -e

BUILD_DIR=public

rm -rf $BUILD_DIR/*

hugo

prettier "$BUILD_DIR/**/*.html" --write --ignore-path ".prettierignore"
