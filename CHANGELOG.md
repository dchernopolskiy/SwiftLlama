# Changelog

All notable changes to SwiftLlama will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Embedding Extraction Support**: New `extractEmbedding(for:)` API for extracting semantic embeddings from text
  - Returns normalized Float vectors (magnitude ≈ 1.0)
  - Supports all embedding models compatible with llama.cpp (e.g., nomic-embed-text-v1.5)
  - Uses llama.cpp's native embedding extraction functions
  - Thread-safe via `@SwiftLlamaActor`
- New error cases for embedding-related failures:
  - `SwiftLlamaError.modelNotLoaded`
  - `SwiftLlamaError.tokenizationFailed`
  - `SwiftLlamaError.embeddingExtractionFailed(_)`
  - `SwiftLlamaError.invalidEmbeddingDimension`
- Comprehensive embedding tests in `SwiftLlamaTests.swift`
- Example command-line tool for testing embeddings (`test-embedding.swift`)
- Detailed embedding extraction guide (`EMBEDDING_GUIDE.md`)
- Updated README with embedding usage examples

### Changed
- Internal `LlamaModel` now includes embedding extraction capabilities
- Added L2 normalization for embedding vectors

## [0.4.0] - Previous Release

- Text generation with streaming support
- AsyncStream and Combine publisher APIs
- Session support for multi-turn conversations
- Stop token handling

---

## Migration Guide

### From 0.4.0 to Unreleased

No breaking changes. The new embedding extraction API is additive:

```swift
// New feature: Embedding extraction
let embedding = try await swiftLlama.extractEmbedding(for: "Your text")

// Existing features still work the same
let response = try await swiftLlama.start(for: prompt)
```

### Requirements

- **Xcode**: 14.0+
- **Swift**: 5.7+
- **iOS**: 16.0+
- **macOS**: 13.0+
- **llama.cpp**: Latest version (included as dependency)

### Example Usage

```swift
import SwiftLlama

// Initialize with embedding model
let swiftLlama = try SwiftLlama(modelPath: "nomic-embed-text-v1.5.Q8_0.gguf")

// Extract embeddings
let text1 = "The cat sat on the mat"
let text2 = "A feline rested on the rug"

let embedding1 = try await swiftLlama.extractEmbedding(for: text1)
let embedding2 = try await swiftLlama.extractEmbedding(for: text2)

// Calculate cosine similarity
let similarity = zip(embedding1, embedding2).reduce(0) { $0 + $1.0 * $1.1 }
print("Similarity: \(similarity)") // ~0.7-0.9 for similar texts
```

For detailed documentation, see [EMBEDDING_GUIDE.md](EMBEDDING_GUIDE.md).

