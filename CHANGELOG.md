# Changelog

All notable changes to SwiftLlama will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.2] - 2025-12-05

### Fixed
- **Duplicate symbols linker error (continued)**: Additional fixes for "35 duplicate symbols for architecture arm64"
  - Changed library type to explicit `.static` to prevent dynamic linking issues
  - Added `-fvisibility-inlines-hidden` for C++ inline functions
  - Removed x86-specific source files (not needed for Apple Silicon/iOS)

## [0.8.1] - 2025-12-05

### Fixed
- **Duplicate symbols linker error**: Fixed "35 duplicate symbols for architecture arm64" when linking SwiftLlama in iOS apps
  - Added `static` keyword to inline C++ functions in `ggml-impl.h` to prevent multiple definitions
  - Added `-fvisibility=hidden` compiler flag to hide internal symbols
  - Ensures llama.cpp symbols are only exported once

## [0.8.0] - 2025-12-05

### Added
- **Sampling Parameters Support**: New `SamplingParameters` struct for controlling text generation quality
  - `temperature` - Controls randomness (0.0-1.0+, lower = more focused)
  - `repeatPenalty` - Penalizes repeated tokens (1.0 = disabled, 1.1-1.2 typical)
  - `topP` - Nucleus sampling threshold (0.9 typical)
  - `topK` - Limits vocabulary to top K tokens (40 typical)
  - `penaltyLastN` - Number of tokens to consider for repeat penalty
  - `seed` - For reproducible sampling
- Preset sampling configurations: `.default`, `.creative`, `.focused`
- Convenience methods with individual parameters on `start(for:)`:
  ```swift
  try await llama.start(for: prompt, temperature: 0.3, repeatPenalty: 1.1, topP: 0.9, topK: 40)
  ```

### Changed
- Updated llama.cpp to stable release b6906 (October 2025)
- Sampler chain now properly applies: penalties → top-k → top-p → temperature → distribution
- Updated deprecated llama.cpp API calls to new names

### Fixed
- **8B model gibberish output**: Proper sampling parameters now prevent degenerate repetition loops
- **3B model consistency**: Lower temperature and repeat penalty produce more coherent output
- Build errors from incompatible llama.cpp sources

## [0.7.0] - Previous Release

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

## [0.6.0] - Previous Release

- Text generation with streaming support
- AsyncStream and Combine publisher APIs
- Session support for multi-turn conversations
- Stop token handling

---

## Migration Guide

### From 0.7.0 to 0.8.0

No breaking changes. The new sampling parameters API is additive and backward compatible:

```swift
// New feature: Sampling parameters for better output quality
let params = SamplingParameters(temperature: 0.3, repeatPenalty: 1.1, topP: 0.9, topK: 40)
let response = try await swiftLlama.start(for: prompt, samplingParams: params)

// Or use presets
let response = try await swiftLlama.start(for: prompt, samplingParams: .focused)

// Or individual parameters
let response = try await swiftLlama.start(for: prompt, temperature: 0.3, repeatPenalty: 1.1)

// Existing code still works (uses sensible defaults)
let response = try await swiftLlama.start(for: prompt)
```

### From 0.6.0 to 0.7.0

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

