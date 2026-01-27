//
//  QueryHelper.swift
//  CbliteSwiftJsLib
//

import Foundation
import CouchbaseLiteSwift

enum QueryError: Error {
    case invalidParameter(message: String)
    case unknownError(message: String)
}

public struct QueryHelper {

    public static func getParamatersFromJson(_ data: [String: Any])
       throws -> Parameters? {
        let parameters = Parameters()
        for (key, value) in data {
            // Ensure the value is a dictionary
            guard let innerDictionary = value as? [String: Any] else {
                continue
            }

            // Extract type and value from the inner dictionary
            if let type = innerDictionary["type"] as? String,
               let value = innerDictionary["value"] {

                // switch through types adding the parameters
                switch type {
                case "string":
                    if let stringValue = value as? String {
                        parameters.setString(stringValue, forName: key)
                    }
                case "float":
                    if let floatValue = value as? Float {
                        parameters.setFloat(floatValue, forName: key)
                    }
                case "boolean":
                    if let booleanValue = value as? Bool {
                        parameters.setBoolean(booleanValue, forName: key)
                    }
                case "double":
                    if let doubleValue = value as? Double {
                        parameters.setDouble(doubleValue, forName: key)
                    }
                case "date":
                    if let dateValue = value as? String {
                        //convert the date
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        let date = dateFormatter.date(from: dateValue)
                        parameters.setDate(date, forName: key)
                    }
                case "int":
                    if let intValue = value as? Int {
                        parameters.setInt(intValue, forName: key)
                    }
                case "long":
                    if let int64Value = value as? Int64 {
                        parameters.setInt64(int64Value, forName: key)
                    }
                case "vector":
                    if let vectorValue = value as? [Double] {
                        parameters.setArray(vectorValue, forName: key)
                    } else if let vectorValue = value as? [NSNumber] {
                        let doubleArray = vectorValue.map { $0.doubleValue }
                        parameters.setArray(doubleArray, forName: key)
                    } else if let vectorValue = value as? [Float] {
                        let doubleArray = vectorValue.map { Double($0) }
                        parameters.setArray(doubleArray, forName: key)
                    } else if let vectorValue = value as? [Any] {
                        let doubleArray = vectorValue.compactMap { element -> Double? in
                            if let num = element as? NSNumber {
                                return num.doubleValue
                            } else if let num = element as? Double {
                                return num
                            } else if let num = element as? Float {
                                return Double(num)
                            } else if let num = element as? Int {
                                return Double(num)
                            }
                            return nil
                        }
                        if doubleArray.count == vectorValue.count {
                            parameters.setArray(doubleArray, forName: key)
                        }
                    }
                case "value":
                        parameters.setValue(value, forName: key)
                default:
                    throw QueryError.invalidParameter(message: type)
                }
            }
        }
        return parameters
    }
}
