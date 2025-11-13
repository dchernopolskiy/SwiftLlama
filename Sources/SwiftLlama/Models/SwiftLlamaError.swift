import Foundation

public enum SwiftLlamaError: Error {
    case decodeError
    case modelNotLoaded
    case tokenizationFailed
    case embeddingExtractionFailed(String)
    case invalidEmbeddingDimension
    case others(String)
}
