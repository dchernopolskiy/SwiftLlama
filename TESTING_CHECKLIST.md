# 🧪 Testing Checklist for Embedding Extraction

Use this checklist to verify the embedding extraction implementation works correctly before merging.

---

## Prerequisites

### 1. Download Test Model

```bash
# Download nomic-embed-text-v1.5 (Q8_0 quantization)
cd ~/models  # or your preferred location
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf

# Verify download
ls -lh nomic-embed-text-v1.5.Q8_0.gguf
# Should be ~450MB
```

### 2. Set Environment Variable

```bash
export EMBEDDING_MODEL_PATH="$HOME/models/nomic-embed-text-v1.5.Q8_0.gguf"
```

---

## Unit Tests

### Run All Tests

```bash
cd /Users/grae/Developer/SwiftLlama
swift test
```

**Expected Output:**
```
Test Suite 'All tests' passed at 2024-11-13 ...
    Executed 4 tests, with 0 failures
```

### Individual Test Verification

- [ ] `testEmbeddingNormalization` passes
  - Verifies embedding dimension > 0
  - Verifies magnitude ≈ 1.0 (normalized)

- [ ] `testSimilarTextSimilarity` passes
  - Verifies cosine similarity > 0.6 for similar texts

- [ ] `testDifferentTextSimilarity` passes
  - Verifies cosine similarity < 0.4 for different texts

- [ ] `testEmptyStringEmbedding` passes
  - Verifies proper error handling for edge cases

---

## Manual Testing

### Test 1: Basic Embedding Extraction

```bash
# Create a simple test script
cat > test_basic.swift << 'EOF'
import SwiftLlama

let model = try SwiftLlama(modelPath: ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"]!)
let embedding = try await model.extractEmbedding(for: "Hello, world!")

print("✅ Dimension: \(embedding.count)")
print("✅ First 5 values: \(embedding.prefix(5))")
print("✅ Magnitude: \(sqrt(embedding.reduce(0) { $0 + $1 * $1 }))")
EOF

swift test_basic.swift
```

**Expected:**
- [ ] Dimension is 384
- [ ] Magnitude is ~1.0 (within 0.001)
- [ ] No errors thrown

### Test 2: Similarity Calculation

```bash
# Run the provided example tool
swift run test-embedding $EMBEDDING_MODEL_PATH
```

**Expected:**
- [ ] Test 1 shows dimension = 384, magnitude ≈ 1.0
- [ ] Test 2 shows high similarity (0.7-0.9) for similar texts
- [ ] Test 3 shows low similarity (0.0-0.3) for different texts
- [ ] No crashes or errors

### Test 3: Error Handling

Create test script:

```swift
import SwiftLlama

// Test 1: Invalid model path
do {
    let model = try SwiftLlama(modelPath: "/invalid/path.gguf")
    print("❌ Should have thrown error")
} catch {
    print("✅ Correctly threw error: \(error)")
}

// Test 2: Empty string
let model = try SwiftLlama(modelPath: ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"]!)
do {
    let emb = try await model.extractEmbedding(for: "")
    print("✅ Handled empty string: dimension \(emb.count)")
} catch {
    print("✅ Correctly threw error for empty string: \(error)")
}
```

**Expected:**
- [ ] Invalid model path throws error
- [ ] Empty string either returns valid embedding or throws `tokenizationFailed`

---

## Integration Testing

### Test with Different Model Quantizations

Test with multiple quantization levels to ensure compatibility:

```bash
# Q8_0 (already tested above)
export EMBEDDING_MODEL_PATH="$HOME/models/nomic-embed-text-v1.5.Q8_0.gguf"
swift test

# Q6_K (download if available)
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q6_K.gguf
export EMBEDDING_MODEL_PATH="$HOME/models/nomic-embed-text-v1.5.Q6_K.gguf"
swift test

# Q4_K_M (download if available)
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_K_M.gguf
export EMBEDDING_MODEL_PATH="$HOME/models/nomic-embed-text-v1.5.Q4_K_M.gguf"
swift test
```

**Expected:**
- [ ] All quantizations work correctly
- [ ] Embeddings are always dimension 384
- [ ] Embeddings are always normalized

### Test Long Text

```swift
import SwiftLlama

let longText = String(repeating: "This is a test sentence. ", count: 100)
let model = try SwiftLlama(modelPath: ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"]!)
let embedding = try await model.extractEmbedding(for: longText)

print("✅ Long text dimension: \(embedding.count)")
print("✅ Long text magnitude: \(sqrt(embedding.reduce(0) { $0 + $1 * $1 }))")
```

**Expected:**
- [ ] No crashes with long text
- [ ] Embedding still normalized
- [ ] Dimension still 384

---

## Performance Testing

### Benchmark Embedding Speed

```swift
import SwiftLlama
import Foundation

let model = try SwiftLlama(modelPath: ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"]!)

// Warm-up
_ = try await model.extractEmbedding(for: "warm up")

// Benchmark
let texts = [
    "Short text",
    "This is a medium length text with several words",
    String(repeating: "This is a long text. ", count: 50)
]

for text in texts {
    let start = Date()
    let embedding = try await model.extractEmbedding(for: text)
    let duration = Date().timeIntervalSince(start)
    
    print("Text length: \(text.count) chars")
    print("Time: \(duration * 1000) ms")
    print("Dimension: \(embedding.count)")
    print("---")
}
```

**Expected:**
- [ ] Short text: < 150ms
- [ ] Medium text: < 250ms
- [ ] Long text: < 500ms
- [ ] Times are reasonable for device

### Memory Test

```bash
# Monitor memory while running tests
# On macOS:
while true; do
    ps aux | grep swift | grep -v grep
    sleep 1
done

# In another terminal:
swift test
```

**Expected:**
- [ ] Memory usage ~500-600MB (model size + overhead)
- [ ] No memory leaks (memory returns to baseline after tests)

---

## Code Quality Checks

### Linting

```bash
# Check for linting errors
# (If you have SwiftLint installed)
swiftlint lint

# Or just check modified files
swiftlint lint --path Sources/SwiftLlama/
```

**Expected:**
- [ ] No new linting errors introduced

### Code Review

Manually review the implementation:

- [ ] Error handling is comprehensive
- [ ] Memory is properly managed (defer blocks)
- [ ] Thread safety via `@SwiftLlamaActor`
- [ ] Documentation is clear
- [ ] Code follows existing patterns

---

## Documentation Review

### README

- [ ] README includes embedding extraction section
- [ ] Code examples are correct
- [ ] Links work

### EMBEDDING_GUIDE

- [ ] Guide is comprehensive
- [ ] Examples are runnable
- [ ] Model links work
- [ ] No typos

### CHANGELOG

- [ ] All changes documented
- [ ] Version number appropriate
- [ ] Migration guide clear

---

## Platform Testing

### macOS

```bash
# Build for macOS
swift build

# Run tests
swift test
```

**Expected:**
- [ ] Builds successfully
- [ ] All tests pass

### iOS (via Xcode)

```bash
# Open test project
cd TestProjects
open TestApp.xcodeproj
```

In Xcode:
1. Select iOS target
2. Build (Cmd+B)
3. Run tests (Cmd+U)

**Expected:**
- [ ] iOS target builds
- [ ] Tests run on iOS simulator

### iOS Device (if available)

1. Connect iPhone/iPad
2. Select device in Xcode
3. Build and run

**Expected:**
- [ ] Builds for device
- [ ] Runs without crashes
- [ ] Performance acceptable

---

## Final Checks

### Git Status

```bash
git status
```

**Expected:**
- [ ] On branch `support-embedding-extraction`
- [ ] No untracked critical files
- [ ] Ready to commit

### Build Clean State

```bash
# Clean build
swift package clean
swift build

# Run tests from clean state
swift test
```

**Expected:**
- [ ] Clean build succeeds
- [ ] Tests pass from clean state

### Create Release Build

```bash
# Build in release mode
swift build -c release
```

**Expected:**
- [ ] Release build succeeds
- [ ] No warnings

---

## Release Preparation

Once all tests pass:

### 1. Commit Changes

```bash
git add .
git commit -m "Add embedding extraction support

- Add extractEmbedding(for:) API for semantic embeddings
- Support nomic-embed and other embedding models
- Add comprehensive tests and documentation
- Add example tool and usage guide
"
```

### 2. Tag Release

```bash
git tag -a v0.5.0 -m "Add embedding extraction support"
```

### 3. Push to GitHub

```bash
git push origin support-embedding-extraction
git push origin v0.5.0
```

### 4. Create GitHub Release

- Go to GitHub releases
- Create new release from v0.5.0 tag
- Copy CHANGELOG content
- Publish release

---

## Post-Release

### Test Installation

```bash
# In a new project
mkdir test-install
cd test-install
swift package init --type executable

# Edit Package.swift to include SwiftLlama v0.5.0
swift build
```

**Expected:**
- [ ] Package resolves correctly
- [ ] Builds without errors

### Update MyBioAge

In MyBioAge project:

```swift
// Update Package.swift
.package(url: "https://github.com/graemerycyk/SwiftLlama.git", from: "0.5.0")

// Update dependencies
swift package update
```

**Expected:**
- [ ] MyBioAge builds with new version
- [ ] Embedding extraction works in app

---

## Summary Checklist

- [ ] ✅ All unit tests pass
- [ ] ✅ Manual testing complete
- [ ] ✅ Error handling verified
- [ ] ✅ Performance acceptable
- [ ] ✅ Memory usage acceptable
- [ ] ✅ Documentation complete
- [ ] ✅ Code reviewed
- [ ] ✅ Platform testing done
- [ ] ✅ Release prepared
- [ ] ✅ Post-release verification

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Notes

Add any observations or issues encountered during testing:

```
[Your notes here]
```

---

**Last Updated**: November 13, 2024  
**Tested By**: _____________  
**Date**: _____________

