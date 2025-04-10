import Combine


/// Erreur personnalisée pour indiquer qu'un publisher s'est terminé sans émettre de valeur attendue.
struct PublisherDidNotEmitValueError: Error {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Output: Sendable, Failure: Error {
    
    /// Convertit un Publisher en une valeur asynchrone.
    ///
    /// Cette méthode attend la première valeur émise par le Publisher ou sa complétion.
    /// Si le Publisher se termine avec une erreur, cette erreur est levée.
    /// Si le Publisher se termine sans émettre de valeur (et que Output n'est pas Void), une erreur `PublisherDidNotEmitValueError` est levée.
    /// Si Output est Void, la fonction retourne avec succès lorsque le Publisher se termine sans erreur.
    ///
    /// - Returns: La première valeur émise par le Publisher.
    /// - Throws: L'erreur du Publisher (`Self.Failure`) ou `PublisherDidNotEmitValueError`.
    func async() async throws -> Output {
        // Cas spécial pour Void : on attend juste la complétion sans erreur.
        if Output.self == Void.self {
            return try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                cancellable = self.sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Pour Void, on peut retourner une instance vide (représentée par () en Swift)
                        // On doit caster car le type générique Output est Void.
                        continuation.resume(returning: () as! Output)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel() // Nettoyer l'abonnement
                }, receiveValue: { _ in
                    // Ignorer les valeurs pour un Publisher<Void, Failure>
                })
            }
        }
        
        // Cas général pour les Output non-Void qui sont Sendable
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var didEmitValue = false // Indicateur pour gérer la complétion sans valeur
            
            cancellable = self.first() // On ne s'intéresse qu'à la première valeur
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Si la complétion arrive AVANT qu'une valeur ait été reçue
                        if !didEmitValue {
                            continuation.resume(throwing: PublisherDidNotEmitValueError())
                        }
                        // Si une valeur a déjà été reçue, la continuation a déjà été résolue.
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel() // Nettoyer l'abonnement
                }, receiveValue: { value in
                    didEmitValue = true
                    // Comme Output est contraint à Sendable, on peut passer la valeur en toute sécurité
                    continuation.resume(returning: value)
                })
        }
    }
}
