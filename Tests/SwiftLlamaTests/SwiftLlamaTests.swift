import XCTest
@testable import SwiftLlama

final class SwiftLlamaTests: XCTestCase {
    
    // MARK: - Embedding Tests
    
    /// Test that embedding extraction returns normalized vectors
    /// Note: This test requires a valid embedding model to be available
    func testEmbeddingNormalization() async throws {
        // Skip test if model path not provided via environment variable
        guard let modelPath = ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"] else {
            throw XCTSkip("EMBEDDING_MODEL_PATH environment variable not set")
        }
        
        let swiftLlama = try SwiftLlama(modelPath: modelPath)
        let embedding = try await swiftLlama.extractEmbedding(for: "Test text")
        
        // Verify embedding is not empty
        XCTAssertGreaterThan(embedding.count, 0, "Embedding should not be empty")
        
        // Verify normalization (magnitude should be ~1.0)
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001, "Embedding should be normalized")
    }
    
    /// Test that similar texts have high cosine similarity
    func testSimilarTextSimilarity() async throws {
        guard let modelPath = ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"] else {
            throw XCTSkip("EMBEDDING_MODEL_PATH environment variable not set")
        }
        
        let swiftLlama = try SwiftLlama(modelPath: modelPath)
        
        let embedding1 = try await swiftLlama.extractEmbedding(for: "The cat sat on the mat")
        let embedding2 = try await swiftLlama.extractEmbedding(for: "A feline rested on the rug")
        
        let similarity = cosineSimilarity(embedding1, embedding2)
        
        // Similar texts should have high similarity (typically > 0.6)
        XCTAssertGreaterThan(similarity, 0.6, "Similar texts should have high cosine similarity")
    }
    
    /// Test that different texts have low cosine similarity
    func testDifferentTextSimilarity() async throws {
        guard let modelPath = ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"] else {
            throw XCTSkip("EMBEDDING_MODEL_PATH environment variable not set")
        }
        
        let swiftLlama = try SwiftLlama(modelPath: modelPath)
        
        let embedding1 = try await swiftLlama.extractEmbedding(for: "The weather is sunny today")
        let embedding2 = try await swiftLlama.extractEmbedding(for: "Quantum computers use qubits")
        
        let similarity = cosineSimilarity(embedding1, embedding2)
        
        // Different texts should have low similarity (typically < 0.4)
        XCTAssertLessThan(similarity, 0.4, "Different texts should have low cosine similarity")
    }
    
    /// Test that empty strings are handled properly
    func testEmptyStringEmbedding() async throws {
        guard let modelPath = ProcessInfo.processInfo.environment["EMBEDDING_MODEL_PATH"] else {
            throw XCTSkip("EMBEDDING_MODEL_PATH environment variable not set")
        }
        
        let swiftLlama = try SwiftLlama(modelPath: modelPath)
        
        // Empty string should either return an embedding or throw tokenizationFailed
        do {
            let embedding = try await swiftLlama.extractEmbedding(for: "")
            // If it doesn't throw, embedding should still be valid
            XCTAssertGreaterThan(embedding.count, 0)
        } catch SwiftLlamaError.tokenizationFailed {
            // This is an acceptable outcome for empty strings
            XCTAssert(true)
        }
    }
    
    // MARK: - Helper Functions
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        return zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }
}
