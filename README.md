#  SwiftLlama

This is basically a wrapper of [llama.cpp](https://github.com/ggerganov/llama.cpp.git) package 
and the purpose of this repo is to provide a swiftier API for Swift developers.

## Install

    .package(url: "https://github.com/ShenghaiWang/SwiftLlama.git", from: "0.4.0")

## Usage

### 1 Initialise swiftLlama using model path.

    let swiftLlama = try SwiftLlama(modelPath: path))
    
### 2 Text Generation

#### Call without streaming

    let response: String = try await swiftLlama.start(for: prompt)

#### Using AsyncStream for streaming

    for try await value in await swiftLlama.start(for: prompt) {
        result += value
    }

#### Using Combine publisher for streaming

    await swiftLlama.start(for: prompt)
        .sink { _ in

        } receiveValue: {[weak self] value in
            self?.result += value
        }.store(in: &cancallable)

### 3 Embedding Extraction

Extract semantic embeddings from text for similarity search, RAG, and other ML tasks:

```swift
// Initialize with an embedding model (e.g., nomic-embed-text-v1.5)
let swiftLlama = try SwiftLlama(modelPath: "path/to/nomic-embed-text-v1.5.Q8_0.gguf")

// Extract normalized embedding vector
let embedding = try await swiftLlama.extractEmbedding(for: "Your text here")

// The embedding is a normalized Float array (magnitude ≈ 1.0)
print("Embedding dimension: \(embedding.count)") // e.g., 384 for nomic-embed
```

#### Example: Calculate Similarity

```swift
let embedding1 = try await swiftLlama.extractEmbedding(for: "The cat sat on the mat")
let embedding2 = try await swiftLlama.extractEmbedding(for: "A feline rested on the rug")

// Calculate cosine similarity (normalized vectors, so dot product = cosine similarity)
let similarity = zip(embedding1, embedding2).reduce(0) { $0 + $1.0 * $1.1 }
print("Similarity: \(similarity)") // High value (0.7-0.9) indicates similar meaning
```

#### Recommended Embedding Models

- **nomic-embed-text-v1.5** (384 dimensions): [Download GGUF](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF)
- Fast inference on iOS/macOS devices
- Excellent for semantic search and RAG applications

## Test projects

[This video](https://youtu.be/w1VEM00cJWo) was the command line app running with Llama 3 model.

For using it in iOS or MacOS app, please refer to the [TestProjects](https://github.com/ShenghaiWang/SwiftLlama/tree/main/TestProjects) folder.


## Supported Models

In theory, it should support all the models that llama.cpp suports. However, the prompt format might need to be updated for some models.

If you want to test it out quickly, please use this model [codellama-7b-instruct.Q4_K_S.gguf](https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_S.gguf?download=true)

## Welcome to contribute!!!



