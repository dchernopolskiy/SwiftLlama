# SwiftLlama

SwiftLlama is a wrapper for the [llama.cpp](https://github.com/ggerganov/llama.cpp.git) library, designed to provide a Swift-native API for developers on iOS, macOS, watchOS, tvOS, and visionOS. It supports both text generation (Llama 3, CodeLlama, etc.) and embedding extraction (Nomic, BERT, etc.).

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/graemerycyk/SwiftLlama.git", from: "0.7.0")
]
```

## Usage

### 1. Initialization

Initialize `SwiftLlama` with the path to your GGUF model file.

```swift
let swiftLlama = try SwiftLlama(modelPath: path)
```

### 2. Text Generation

#### Call without streaming

```swift
let response: String = try await swiftLlama.start(for: prompt)
```

#### Using AsyncStream for streaming

```swift
for try await value in await swiftLlama.start(for: prompt) {
    result += value
}
```

#### Using Combine publisher for streaming

```swift
await swiftLlama.start(for: prompt)
    .sink { _ in
    } receiveValue: {[weak self] value in
        self?.result += value
    }.store(in: &cancallable)
```

### 3. Embedding Extraction

Extract semantic embeddings from text for similarity search, RAG, and other ML tasks.

#### Quick Start

1.  **Download a Model**: We recommend `nomic-embed-text-v1.5.Q8_0.gguf` for the best balance of quality and performance.
    ```bash
    wget https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf
    ```
2.  **Extract**:
    ```swift
    // Initialize with embedding model
    let swiftLlama = try SwiftLlama(modelPath: "path/to/nomic-embed-text-v1.5.Q8_0.gguf")

    // Extract embedding
    let embedding = try await swiftLlama.extractEmbedding(for: "Hello, world!")

    print("Dimension: \(embedding.count)") // e.g., 384
    print("Magnitude: \(sqrt(embedding.reduce(0) { $0 + $1 * $1 }))") // ~1.0 (Normalized)
    ```

#### API Reference

`extractEmbedding(for:)` extracts a normalized embedding vector from input text.

```swift
@SwiftLlamaActor
public func extractEmbedding(for text: String) async throws -> [Float]
```

*   **Returns**: Normalized `[Float]` array (L2 norm ≈ 1.0).
*   **Throws**: `modelNotLoaded`, `tokenizationFailed`, `invalidEmbeddingDimension`, `embeddingExtractionFailed`.

#### Use Cases

**Semantic Search**
Find documents similar to a query by comparing their embeddings.

```swift
let queryEmb = try await swiftLlama.extractEmbedding(for: "I forgot my password")
let docEmb = try await swiftLlama.extractEmbedding(for: "How to reset password")

// Calculate Cosine Similarity (Dot product of normalized vectors)
let similarity = zip(queryEmb, docEmb).reduce(0) { $0 + $1.0 * $1.1 }
print("Similarity: \(similarity)") // High value (0.7-1.0) indicates similarity
```

**Duplicate Detection**
Identify duplicate content by checking for extremely high similarity (>0.95).

#### Recommended Models

*   **nomic-embed-text-v1.5** (384 dimensions): [Download](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF). Best for general use.
*   **all-MiniLM-L6-v2** (384 dimensions): [Download](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2). Very fast and lightweight.

#### Performance Tips
1.  **Batch Processing**: Process texts sequentially in a loop or `asyncMap`. The model is thread-safe via Actor isolation.
2.  **Caching**: Cache embeddings for static content to avoid re-computation.
3.  **Preprocessing**: Trim whitespace and lowercase text for better matching consistency.
4.  **Quantization**: Use `Q4_K_M` quantization for mobile devices to reduce memory usage with minimal quality loss.

#### Troubleshooting
*   **"Invalid embedding dimension"**: Ensure you loaded an embedding model (e.g., nomic), not a generative chat model (e.g., Llama-3-Instruct).
*   **Low similarity**: Try preprocessing your text (lowercasing, removing special characters) or using a domain-specific model.

## Supported Models

SwiftLlama supports models compatible with `llama.cpp`.

*   **Text Generation**: Llama 3, CodeLlama, Mistral, etc.
    *   Quick test: [codellama-7b-instruct.Q4_K_S.gguf](https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_S.gguf?download=true)
*   **Embeddings**: Nomic, BERT, etc.

## Test Projects

Refer to the `TestProjects` folder for iOS/macOS examples.
*   **CLI Tool**: `TestProjects/TestApp-Commandline` contains examples for both text generation and embeddings.
    ```bash
    swift run test-embedding /path/to/model.gguf
    ```

## Technical Details

**llama.cpp Integration**:
*   Uses `llama_n_embd`, `llama_set_embeddings`, `llama_decode`, and `llama_get_embeddings`.
*   Embeddings are L2-normalized automatically before returning.
*   Thread-safe access is managed via `@SwiftLlamaActor`.
*   Includes `ggml` backend support for Metal (GPU) and Accelerate (CPU) for optimal performance on Apple Silicon.

## Contributing & Testing

### Running Unit Tests

To run the embedding tests, you need to provide a path to a valid embedding model via an environment variable.

```bash
export EMBEDDING_MODEL_PATH="/path/to/nomic-embed-text-v1.5.Q8_0.gguf"
swift test
```

### Manual Verification
1.  **Build**: `swift build`
2.  **Test Tool**: `swift run test-embedding /path/to/model.gguf`
3.  **Checklist**:
    *   ✅ Unit tests pass (`testEmbeddingNormalization`, `testSimilarTextSimilarity`).
    *   ✅ Manual testing with `test-embedding` tool confirms reasonable cosine similarity values.
    *   ✅ Memory usage is stable during batch processing.

## License

MIT
