import Foundation
import CoreData

extension NSManagedObjectContext {
    /// Exécute une bloc de code asynchrone dans ce contexte et retourne le résultat
    /// - Parameter block: Le bloc de code à exécuter qui peut être asynchrone
    /// - Returns: Le résultat du bloc de code
    func performAsync<T>(_ block: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.perform {
                Task {
                    do {
                        let result = try await block()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
} 