//
//  Bundle-Decodable.swift
//  QuickFix
//
//  Created by christian on 4/7/23.
//

import Foundation

extension Bundle {
    // Decode a JSON file from the app bundle
    func decode<T: Decodable>(
        // Filename parameter
        _ file: String,
        // Type parameter, which can be inferred from context if not explicitly provided
        as type: T.Type = T.self,
        // Optional parameter for date decoding strategy, default value is .deferredToDate
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        // Optional parameter for key decoding strategy, default value is .useDefaultKeys
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> T {
        // Ensure file exists in App Bundle
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate\(file) in bundle.")
        }
        // Ensure file loads from App Bundle
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        
        // Create a JSONDecoder instance
        let decoder = JSONDecoder()
        // Set the provided date decoding strategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        // Set the provided key decoding strategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        do {
            // Attempt to decode the data into the provided type using the JSONDecoder
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            // Handle decoding error for missing key
            fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' - \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            // Handle decoding error for type mismatch
            fatalError("Failed to decode \(file) from bundle due to type mismatch - \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            // Handle decoding error for missing value
            fatalError("Failed to decode \(file) from bundle due to missing \(type) value = \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(_) {
            // Handle decoding error for corrupted data
            fatalError("Failed to decode \(file) from bundle because it appears to be invalid JSON.")
        } catch {
            // Handle any other decoding errors
            fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
    }
}
