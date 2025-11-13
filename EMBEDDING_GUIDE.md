# 🎯 Embedding Extraction Guide

This guide provides comprehensive information about using SwiftLlama's embedding extraction feature.

## Table of Contents

- [What Are Embeddings?](#what-are-embeddings)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Model Selection](#model-selection)
- [Use Cases](#use-cases)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

## What Are Embeddings?

Embeddings are dense vector representations of text that capture semantic meaning. Text with similar meanings will have similar embeddings (high cosine similarity), while unrelated text will have dissimilar embeddings.

**Key Properties:**
- **Dimension**: Fixed-size vectors (e.g., 384 floats for nomic-embed)
- **Normalized**: Vector magnitude ≈ 1.0 for efficient similarity calculations
- **Semantic**: Captures meaning, not just keywords

## Quick Start

### 1. Download an Embedding Model

```bash
# Download nomic-embed-text-v1.5 (recommended)
wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf
```

### 2. Extract Embeddings

```swift
import SwiftLlama

// Initialize with embedding model
let swiftLlama = try SwiftLlama(modelPath: "path/to/nomic-embed-text-v1.5.Q8_0.gguf")

// Extract embedding for a single text
let embedding = try await swiftLlama.extractEmbedding(for: "Hello, world!")

print("Embedding dimension: \(embedding.count)")
print("First 5 values: \(embedding.prefix(5))")
```

### 3. Calculate Similarity

```swift
let text1 = "The cat sat on the mat"
let text2 = "A feline rested on the rug"

let embedding1 = try await swiftLlama.extractEmbedding(for: text1)
let embedding2 = try await swiftLlama.extractEmbedding(for: text2)

// Cosine similarity (dot product for normalized vectors)
let similarity = zip(embedding1, embedding2).reduce(0) { $0 + $1.0 * $1.1 }

print("Similarity: \(similarity)") // ~0.7-0.9 for similar texts
```

## API Reference

### extractEmbedding(for:)

Extracts a normalized embedding vector from input text.

```swift
@SwiftLlamaActor
public func extractEmbedding(for text: String) async throws -> [Float]
```

**Parameters:**
- `text`: Input text to embed (String)

**Returns:**
- Normalized `[Float]` array with magnitude ≈ 1.0

**Throws:**
- `SwiftLlamaError.modelNotLoaded`: Model context not initialized
- `SwiftLlamaError.tokenizationFailed`: Text couldn't be tokenized
- `SwiftLlamaError.invalidEmbeddingDimension`: Model doesn't support embeddings
- `SwiftLlamaError.embeddingExtractionFailed(_)`: llama.cpp extraction failed

**Example:**
```swift
do {
    let embedding = try await swiftLlama.extractEmbedding(for: "Sample text")
    print("Embedding extracted successfully: \(embedding.count) dimensions")
} catch {
    print("Error: \(error)")
}
```

## Model Selection

### Recommended Models

#### 1. nomic-embed-text-v1.5 ⭐ (Recommended)

- **Dimension**: 384
- **Max tokens**: 2048
- **Use case**: General-purpose semantic search
- **Download**: [Hugging Face](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF)

```swift
// Use Q8_0 quantization for best quality/size trade-off
let model = "nomic-embed-text-v1.5.Q8_0.gguf"
```

#### 2. all-MiniLM-L6-v2

- **Dimension**: 384
- **Max tokens**: 256
- **Use case**: Fast, lightweight embeddings
- **Download**: [Hugging Face](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)

### Model Quantization Guide

| Quantization | Quality | Size | Speed | Recommended |
|--------------|---------|------|-------|-------------|
| Q8_0         | Highest | Large | Slower | ✅ Best balance |
| Q6_K         | High    | Medium | Medium | ✅ Good alternative |
| Q4_K_M       | Good    | Small | Fast | For mobile |
| Q4_K_S       | Fair    | Smallest | Fastest | Limited memory |

## Use Cases

### 1. Semantic Search

Find documents similar to a query:

```swift
// Embed all documents
let docEmbeddings = try await documents.asyncMap { doc in
    try await swiftLlama.extractEmbedding(for: doc.text)
}

// Embed query
let queryEmbedding = try await swiftLlama.extractEmbedding(for: "How to reset password?")

// Find most similar documents
let similarities = docEmbeddings.map { docEmb in
    zip(queryEmb, docEmb).reduce(0) { $0 + $1.0 * $1.1 }
}

let topMatches = similarities.enumerated()
    .sorted { $0.element > $1.element }
    .prefix(5)
```

### 2. RAG (Retrieval-Augmented Generation)

Retrieve relevant context for LLM prompts:

```swift
// 1. Embed knowledge base
let knowledgeEmbeddings = try await knowledgeBase.asyncMap { article in
    (article, try await swiftLlama.extractEmbedding(for: article.content))
}

// 2. Embed user question
let questionEmbedding = try await swiftLlama.extractEmbedding(for: userQuestion)

// 3. Retrieve top-k relevant articles
let relevantArticles = knowledgeEmbeddings
    .map { (article, emb) in
        let similarity = zip(questionEmbedding, emb).reduce(0) { $0 + $1.0 * $1.1 }
        return (article, similarity)
    }
    .sorted { $0.1 > $1.1 }
    .prefix(3)
    .map { $0.0 }

// 4. Build prompt with context
let prompt = """
Context:
\(relevantArticles.map { $0.content }.joined(separator: "\n\n"))

Question: \(userQuestion)
"""
```

### 3. Duplicate Detection

Find duplicate or near-duplicate content:

```swift
let threshold: Float = 0.95

for (i, doc1) in documents.enumerated() {
    for doc2 in documents.dropFirst(i + 1) {
        let emb1 = try await swiftLlama.extractEmbedding(for: doc1.text)
        let emb2 = try await swiftLlama.extractEmbedding(for: doc2.text)
        
        let similarity = zip(emb1, emb2).reduce(0) { $0 + $1.0 * $1.1 }
        
        if similarity > threshold {
            print("Potential duplicate found: \(doc1.id) and \(doc2.id)")
        }
    }
}
```

### 4. Text Clustering

Group similar texts together:

```swift
// Simple k-means style clustering
func cluster(texts: [String], k: Int) async throws -> [[String]] {
    // Extract embeddings
    let embeddings = try await texts.asyncMap { text in
        try await swiftLlama.extractEmbedding(for: text)
    }
    
    // TODO: Implement k-means or hierarchical clustering
    // For production, use a proper clustering library
    
    return [[]] // Placeholder
}
```

## Performance Tips

### 1. Batch Processing

Process multiple texts sequentially:

```swift
// ✅ Good: Sequential processing
let embeddings = try await texts.asyncMap { text in
    try await swiftLlama.extractEmbedding(for: text)
}

// ❌ Don't: Create multiple SwiftLlama instances
// This wastes memory and is slower
```

### 2. Caching

Cache embeddings for frequently used texts:

```swift
actor EmbeddingCache {
    private var cache: [String: [Float]] = [:]
    private let swiftLlama: SwiftLlama
    
    init(swiftLlama: SwiftLlama) {
        self.swiftLlama = swiftLlama
    }
    
    func getEmbedding(for text: String) async throws -> [Float] {
        if let cached = cache[text] {
            return cached
        }
        
        let embedding = try await swiftLlama.extractEmbedding(for: text)
        cache[text] = embedding
        return embedding
    }
}
```

### 3. Text Preprocessing

Optimize text before embedding:

```swift
func preprocess(_ text: String) -> String {
    return text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .lowercased() // Optional: may improve similarity matching
}

let embedding = try await swiftLlama.extractEmbedding(for: preprocess(text))
```

### 4. Memory Management

For large batches, process in chunks:

```swift
let chunkSize = 100

for chunk in texts.chunked(into: chunkSize) {
    let embeddings = try await chunk.asyncMap { text in
        try await swiftLlama.extractEmbedding(for: text)
    }
    
    // Process embeddings (save to disk, etc.)
    await storage.save(embeddings)
}
```

## Troubleshooting

### Issue: "Invalid embedding dimension" error

**Cause**: Model doesn't support embedding extraction (e.g., loaded a chat model instead)

**Solution**: Use an embedding-specific model like nomic-embed-text-v1.5

```swift
// ❌ Wrong: Using chat model
let model = "llama-3-8b-instruct.Q4_K_M.gguf"

// ✅ Correct: Using embedding model
let model = "nomic-embed-text-v1.5.Q8_0.gguf"
```

### Issue: Low similarity for semantically similar texts

**Cause**: Model not optimized for your domain, or text preprocessing needed

**Solution**: Try different models or preprocess text

```swift
// Normalize text before embedding
func normalize(_ text: String) -> String {
    return text
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
```

### Issue: Slow embedding extraction

**Cause**: Model too large, or device constraints

**Solution**: Use smaller quantization (Q4_K_M) or lighter model

```swift
// For mobile devices, use smaller quantization
let model = "nomic-embed-text-v1.5.Q4_K_M.gguf" // Faster, less memory
```

### Issue: Different embedding dimensions than expected

**Cause**: Different model loaded than expected

**Solution**: Verify model dimension matches your expectations

```swift
let embedding = try await swiftLlama.extractEmbedding(for: "test")
print("Actual dimension: \(embedding.count)")
// Expected: 384 for nomic-embed, 768 for BERT-base, etc.
```

## Advanced Topics

### Custom Similarity Metrics

While cosine similarity (dot product for normalized vectors) is most common, you can implement other metrics:

```swift
// Euclidean distance
func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
    sqrt(zip(a, b).reduce(0) { $0 + pow($1.0 - $1.1, 2) })
}

// Manhattan distance
func manhattanDistance(_ a: [Float], _ b: [Float]) -> Float {
    zip(a, b).reduce(0) { $0 + abs($1.0 - $1.1) }
}
```

### Vector Database Integration

For large-scale applications, consider vector databases:

- **Pinecone**: Cloud-hosted vector search
- **Weaviate**: Open-source vector database
- **FAISS**: Facebook's similarity search library
- **Qdrant**: High-performance vector search engine

Example integration pattern:

```swift
// 1. Extract embeddings with SwiftLlama
let embedding = try await swiftLlama.extractEmbedding(for: text)

// 2. Store in vector database
await vectorDB.upsert(id: documentId, vector: embedding, metadata: metadata)

// 3. Search for similar vectors
let results = await vectorDB.search(queryVector: queryEmbedding, topK: 10)
```

## Testing

Run the included tests to verify your setup:

```bash
# Set environment variable with model path
export EMBEDDING_MODEL_PATH="/path/to/nomic-embed-text-v1.5.Q8_0.gguf"

# Run tests
swift test
```

Or use the example command-line tool:

```bash
swift run test-embedding /path/to/nomic-embed-text-v1.5.Q8_0.gguf
```

## Further Reading

- [nomic-embed-text-v1.5 Paper](https://arxiv.org/abs/2402.01613)
- [Sentence Transformers Documentation](https://www.sbert.net/)
- [llama.cpp Embedding Documentation](https://github.com/ggerganov/llama.cpp/tree/master/examples/embedding)
- [Vector Search Best Practices](https://www.pinecone.io/learn/vector-search/)

## Contributing

Found a bug or have a feature request? Please open an issue on GitHub!

---

**Need help?** Open an issue or discussion on the SwiftLlama GitHub repository.

