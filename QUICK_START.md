# 🚀 Quick Start: Embedding Extraction

Get started with SwiftLlama's embedding extraction in 5 minutes!

---

## Step 1: Download an Embedding Model (2 min)

```bash
# Create models directory
mkdir -p ~/models
cd ~/models

# Download nomic-embed-text-v1.5 (recommended)
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf

# Verify download (~450MB)
ls -lh nomic-embed-text-v1.5.Q8_0.gguf
```

---

## Step 2: Add SwiftLlama to Your Project (1 min)

### Option A: Swift Package Manager (Recommended)

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/graemerycyk/SwiftLlama.git", branch: "support-embedding-extraction")
]
```

### Option B: Xcode

1. File → Add Package Dependencies
2. Enter: `https://github.com/graemerycyk/SwiftLlama.git`
3. Select branch: `support-embedding-extraction`

---

## Step 3: Extract Your First Embedding (2 min)

```swift
import SwiftLlama

// Initialize with embedding model
let swiftLlama = try SwiftLlama(
    modelPath: "\(NSHomeDirectory())/models/nomic-embed-text-v1.5.Q8_0.gguf"
)

// Extract embedding
let embedding = try await swiftLlama.extractEmbedding(for: "Hello, world!")

// Verify
print("✅ Dimension: \(embedding.count)")  // 384
print("✅ Magnitude: \(sqrt(embedding.reduce(0) { $0 + $1 * $1 }))")  // ~1.0
print("✅ Sample values: \(embedding.prefix(3))")
```

---

## Common Use Cases

### Semantic Search

```swift
// 1. Embed your documents
let documents = [
    "How to reset your password",
    "Creating a new account",
    "Updating profile information"
]

let docEmbeddings = try await documents.asyncMap { doc in
    try await swiftLlama.extractEmbedding(for: doc)
}

// 2. Embed user query
let query = "I forgot my password"
let queryEmbedding = try await swiftLlama.extractEmbedding(for: query)

// 3. Find most similar documents
let similarities = docEmbeddings.map { docEmb in
    zip(queryEmb, docEmb).reduce(0) { $0 + $1.0 * $1.1 }
}

let bestMatchIndex = similarities.enumerated().max(by: { $0.1 < $1.1 })!.0
print("Best match: \(documents[bestMatchIndex])")  // "How to reset your password"
```

### Duplicate Detection

```swift
let text1 = "The cat sat on the mat"
let text2 = "The feline sat on the mat"

let emb1 = try await swiftLlama.extractEmbedding(for: text1)
let emb2 = try await swiftLlama.extractEmbedding(for: text2)

let similarity = zip(emb1, emb2).reduce(0) { $0 + $1.0 * $1.1 }

if similarity > 0.9 {
    print("⚠️  Potential duplicate detected!")
}
```

### Content Recommendation

```swift
// User liked this article
let likedArticle = "Understanding quantum computing basics"
let likedEmbedding = try await swiftLlama.extractEmbedding(for: likedArticle)

// Find similar articles to recommend
let recommendations = articles
    .asyncMap { article in
        let emb = try await swiftLlama.extractEmbedding(for: article.title)
        let similarity = zip(likedEmbedding, emb).reduce(0) { $0 + $1.0 * $1.1 }
        return (article, similarity)
    }
    .sorted { $0.1 > $1.1 }
    .prefix(5)
```

---

## Helper Functions

Add these to your project for convenience:

```swift
// Calculate cosine similarity
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count else { return 0 }
    return zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
}

// Batch process multiple texts
extension SwiftLlama {
    func extractEmbeddings(for texts: [String]) async throws -> [[Float]] {
        try await texts.asyncMap { text in
            try await self.extractEmbedding(for: text)
        }
    }
}

// Find top-k similar texts
func findTopK(
    query: [Float],
    in embeddings: [[Float]],
    k: Int = 5
) -> [(index: Int, similarity: Float)] {
    embeddings.enumerated()
        .map { (index, emb) in
            (index, cosineSimilarity(query, emb))
        }
        .sorted { $0.1 > $1.1 }
        .prefix(k)
        .map { $0 }
}
```

---

## What's Next?

- 📖 **Comprehensive Guide**: See [EMBEDDING_GUIDE.md](EMBEDDING_GUIDE.md) for detailed documentation
- 🧪 **Testing**: See [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md) for validation steps
- 📦 **Implementation Details**: See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- 🎯 **Example Code**: See `TestProjects/TestApp-Commandline/test-embedding.swift`

---

## Troubleshooting

### "Model not loaded" error

Make sure the model path is correct:

```swift
// ❌ Wrong
let model = "nomic-embed.gguf"

// ✅ Correct
let model = "\(NSHomeDirectory())/models/nomic-embed-text-v1.5.Q8_0.gguf"
```

### "Invalid embedding dimension" error

You're using a chat model instead of an embedding model:

```swift
// ❌ Wrong: Chat model
let model = "llama-3-8b-instruct.gguf"

// ✅ Correct: Embedding model
let model = "nomic-embed-text-v1.5.Q8_0.gguf"
```

### Low similarity for similar texts

Try preprocessing your text:

```swift
func normalize(_ text: String) -> String {
    text.lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

let emb = try await swiftLlama.extractEmbedding(for: normalize(text))
```

---

## Performance Tips

1. **Cache embeddings** for frequently used texts
2. **Use Q4/Q6 quantization** on mobile devices for faster inference
3. **Preprocess text** before embedding (lowercase, trim)
4. **Process in batches** for large datasets

---

## Need Help?

- 📝 **Documentation**: [EMBEDDING_GUIDE.md](EMBEDDING_GUIDE.md)
- 💬 **Issues**: [GitHub Issues](https://github.com/graemerycyk/SwiftLlama/issues)
- 📧 **Contact**: Open a discussion on GitHub

---

**Happy embedding! 🎉**

