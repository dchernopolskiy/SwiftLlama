import Foundation
import SwiftLlama

/// Example usage of the embedding extraction feature
/// 
/// Usage:
///   swift run test-embedding path/to/nomic-embed-text-v1.5.Q8_0.gguf
///
@main
struct EmbeddingTest {
    static func main() async {
        guard CommandLine.arguments.count > 1 else {
            print("Usage: test-embedding <model_path>")
            print("Example: test-embedding ~/models/nomic-embed-text-v1.5.Q8_0.gguf")
            return
        }
        
        let modelPath = CommandLine.arguments[1]
        
        do {
            print("Loading model from: \(modelPath)")
            let swiftLlama = try SwiftLlama(modelPath: modelPath)
            
            // Test 1: Extract a single embedding
            print("\n=== Test 1: Single Embedding ===")
            let text1 = "Hello, world!"
            let embedding1 = try await swiftLlama.extractEmbedding(for: text1)
            
            print("Text: \"\(text1)\"")
            print("Embedding dimension: \(embedding1.count)")
            print("First 5 values: \(embedding1.prefix(5).map { String(format: "%.4f", $0) }.joined(separator: ", "))")
            
            // Check normalization (magnitude should be ~1.0)
            let magnitude1 = sqrt(embedding1.reduce(0) { $0 + $1 * $1 })
            print("Vector magnitude: \(String(format: "%.6f", magnitude1)) (should be ~1.0)")
            
            // Test 2: Extract embeddings for similar texts
            print("\n=== Test 2: Similar Texts ===")
            let text2a = "The cat sat on the mat"
            let text2b = "A feline rested on the rug"
            
            let embedding2a = try await swiftLlama.extractEmbedding(for: text2a)
            let embedding2b = try await swiftLlama.extractEmbedding(for: text2b)
            
            let similarity1 = cosineSimilarity(embedding2a, embedding2b)
            print("Text A: \"\(text2a)\"")
            print("Text B: \"\(text2b)\"")
            print("Cosine similarity: \(String(format: "%.4f", similarity1)) (should be high, ~0.7-0.9)")
            
            // Test 3: Extract embeddings for different texts
            print("\n=== Test 3: Different Texts ===")
            let text3a = "The weather is sunny today"
            let text3b = "Quantum computers use qubits"
            
            let embedding3a = try await swiftLlama.extractEmbedding(for: text3a)
            let embedding3b = try await swiftLlama.extractEmbedding(for: text3b)
            
            let similarity2 = cosineSimilarity(embedding3a, embedding3b)
            print("Text A: \"\(text3a)\"")
            print("Text B: \"\(text3b)\"")
            print("Cosine similarity: \(String(format: "%.4f", similarity2)) (should be low, ~0.0-0.3)")
            
            print("\n✅ All tests completed successfully!")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Calculate cosine similarity between two normalized vectors
    /// Since vectors are already normalized (magnitude = 1), the dot product equals cosine similarity
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        return zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }
}

