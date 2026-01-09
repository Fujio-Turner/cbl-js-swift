//
//  IndexHelper.swift
//  CbliteSwiftJsLib
//

import Foundation
import CouchbaseLiteSwift

public struct IndexHelper {

    public static func makeValueIndexItems(_ items: [Any]) -> [ValueIndexItem] {
        var valueItems = [ValueIndexItem]()
        for item in items {
            if let entry = item as? [Any], let strEntry = entry.first as? String {
                let propName = String(strEntry[strEntry.index(after: strEntry.startIndex)...])
                let valueItem = ValueIndexItem.property(propName)
                valueItems.append(valueItem)
            }
        }
        return valueItems
    }

    public static func makeFullTextIndexItems(_ items: [Any]) -> [FullTextIndexItem] {
        var fullTextItems = [FullTextIndexItem]()
        for item in items {
            if let entry = item as? [Any], let strEntry = entry.first as? String {
                let propName = String(strEntry[strEntry.index(after: strEntry.startIndex)...])
                let fullTextItem = FullTextIndexItem.property(propName)
                fullTextItems.append(fullTextItem)
            }
        }
        return fullTextItems
    }
    
    // MARK: - Vector Index Configuration
    
    /// Creates a VectorIndexConfiguration from a dictionary of parameters.
    /// - Parameter config: Dictionary containing vector index configuration
    /// - Returns: VectorIndexConfiguration object
    /// - Throws: Error if required parameters are missing or invalid
    public static func makeVectorIndexConfiguration(_ config: [String: Any]) throws -> VectorIndexConfiguration {
        guard let expression = config["expression"] as? String else {
            throw VectorIndexError.missingRequiredParameter("expression")
        }
        
        guard let dimensions = config["dimensions"] as? Int else {
            throw VectorIndexError.missingRequiredParameter("dimensions")
        }
        
        guard let centroids = config["centroids"] as? Int else {
            throw VectorIndexError.missingRequiredParameter("centroids")
        }
        
        // Validate dimensions range (2-4096)
        guard dimensions >= 2 && dimensions <= 4096 else {
            throw VectorIndexError.invalidParameter("dimensions must be between 2 and 4096")
        }
        
        // Validate centroids range (1-64000)
        guard centroids >= 1 && centroids <= 64000 else {
            throw VectorIndexError.invalidParameter("centroids must be between 1 and 64000")
        }
        
        // Create configuration
        var vectorConfig = VectorIndexConfiguration(
            expression: expression,
            dimensions: UInt32(dimensions),
            centroids: UInt32(centroids)
        )
        
        // Set optional distance metric
        if let metricString = config["metric"] as? String {
            vectorConfig.metric = parseDistanceMetric(metricString)
        }
        
        // Set optional encoding
        if let encodingDict = config["encoding"] as? [String: Any] {
            vectorConfig.encoding = try parseVectorEncoding(encodingDict)
        }
        
        // Set optional training sizes
        if let minTrainingSize = config["minTrainingSize"] as? Int, minTrainingSize > 0 {
            vectorConfig.minTrainingSize = UInt32(minTrainingSize)
        }
        
        if let maxTrainingSize = config["maxTrainingSize"] as? Int, maxTrainingSize > 0 {
            vectorConfig.maxTrainingSize = UInt32(maxTrainingSize)
        }
        
        // Set optional numProbes
        if let numProbes = config["numProbes"] as? Int, numProbes > 0 {
            vectorConfig.numProbes = UInt32(numProbes)
        }
        
        // Set optional isLazy
        if let isLazy = config["isLazy"] as? Bool {
            vectorConfig.isLazy = isLazy
        }
        
        return vectorConfig
    }
    
    /// Parses a distance metric string to the corresponding enum value.
    private static func parseDistanceMetric(_ metric: String) -> DistanceMetric {
        switch metric.lowercased() {
        case "euclidean", "l2":
            return .euclidean
        case "euclideansquared", "l2squared", "l2_squared":
            return .euclideanSquared
        case "cosine":
            return .cosine
        case "dot":
            return .dot
        default:
            return .euclideanSquared
        }
    }
    
    /// Parses a vector encoding dictionary to the corresponding encoding type.
    private static func parseVectorEncoding(_ encoding: [String: Any]) throws -> VectorEncoding {
        guard let type = encoding["type"] as? String else {
            return .scalarQuantizer(type: .SQ8)
        }
        
        switch type.uppercased() {
        case "NONE":
            return .none
            
        case "SQ", "SCALARQUANTIZER":
            let bits = encoding["bits"] as? Int ?? 8
            switch bits {
            case 4:
                return .scalarQuantizer(type: .SQ4)
            case 6:
                return .scalarQuantizer(type: .SQ6)
            case 8:
                return .scalarQuantizer(type: .SQ8)
            default:
                throw VectorIndexError.invalidParameter("Scalar quantizer bits must be 4, 6, or 8")
            }
            
        case "PQ", "PRODUCTQUANTIZER":
            guard let subquantizers = encoding["subquantizers"] as? Int else {
                throw VectorIndexError.missingRequiredParameter("subquantizers for PQ encoding")
            }
            let bits = encoding["bits"] as? Int ?? 8
            return .productQuantizer(subquantizers: UInt32(subquantizers), bits: UInt32(bits))
            
        default:
            return .scalarQuantizer(type: .SQ8)
        }
    }
}

// MARK: - Vector Index Errors

public enum VectorIndexError: Error {
    case missingRequiredParameter(_ parameter: String)
    case invalidParameter(_ message: String)
    case indexCreationFailed(_ message: String)
    case updaterError(_ message: String)
}
