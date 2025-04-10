import Foundation
import CoreData

/// Utilitaire pour une conversion thread-safe des entités Core Data en modèles Sendable
public struct CoreDataConversionUtils {
    /// Convertit une entité Core Data en un modèle Sendable de manière thread-safe
    /// - Parameters:
    ///   - entity: L'entité Core Data à convertir
    ///   - converter: La fonction de conversion qui produit un objet Sendable à partir de l'entité
    /// - Returns: L'objet converti
    nonisolated
    public static func convertToModel<T: NSManagedObject, R: Sendable>(
        entity: T,
        converter: @escaping @Sendable (T) -> R
    ) -> R {
        return converter(entity)
    }
    
    /// Convertit plusieurs entités Core Data en modèles Sendable de manière thread-safe
    /// - Parameters:
    ///   - entities: Les entités Core Data à convertir
    ///   - converter: La fonction de conversion qui produit des objets Sendable à partir des entités
    /// - Returns: Les objets convertis
    nonisolated
    public static func convertToModels<T: NSManagedObject, R: Sendable>(
        entities: [T],
        converter: @escaping @Sendable (T) -> R?
    ) -> [R] {
        return entities.compactMap { converter($0) }
    }
    
    /// Exécute une opération Core Data dans un contexte de fond et convertit les résultats en objets Sendable
    /// - Parameters:
    ///   - context: Le contexte Core Data à utiliser
    ///   - operation: L'opération à exécuter qui retourne des entités Core Data
    ///   - converter: La fonction de conversion qui produit des objets Sendable à partir des entités
    /// - Returns: Les objets convertis
    /// - Throws: Toute erreur survenue pendant l'opération
    @MainActor
    public static func executeAndConvert<T: NSManagedObject, R: Sendable>(
        context: NSManagedObjectContext,
        operation: @escaping () throws -> [T],
        converter: @escaping @Sendable (T) -> R?
    ) async throws -> [R] {
        let entities = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[T], Error>) in
            context.perform {
                do {
                    let results = try operation()
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Capture le convertisseur dans un closure @escaping
        let capturedConverter = converter
        return await Task.detached {
            return entities.compactMap(capturedConverter)
        }.value
    }
    
    /// Exécute une opération Core Data dans un contexte de fond et convertit le résultat en objet Sendable
    /// - Parameters:
    ///   - context: Le contexte Core Data à utiliser
    ///   - operation: L'opération à exécuter qui retourne une entité Core Data
    ///   - converter: La fonction de conversion qui produit un objet Sendable à partir de l'entité
    ///   - notFoundError: L'erreur à lancer si aucune entité n'est trouvée
    /// - Returns: L'objet converti
    /// - Throws: L'erreur notFoundError si aucune entité n'est trouvée, ou toute autre erreur survenue pendant l'opération
    @MainActor
    public static func executeAndConvertSingle<T: NSManagedObject, R: Sendable, E: Error>(
        context: NSManagedObjectContext,
        operation: @escaping () throws -> T?,
        converter: @escaping @Sendable (T) -> R,
        notFoundError: E
    ) async throws -> R {
        let entity = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            context.perform {
                do {
                    guard let result = try operation() else {
                        continuation.resume(throwing: notFoundError)
                        return
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Capture le convertisseur dans un closure @escaping
        let capturedConverter = converter
        return await Task.detached {
            return capturedConverter(entity)
        }.value
    }
} 