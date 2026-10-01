#!/usr/bin/env bash
# Formats all Swift sources in place with swift-format (config: .swift-format).
set -euo pipefail
cd "$(dirname "$0")/.."

swift format format --in-place --recursive --parallel Sources Tests Package.swift
