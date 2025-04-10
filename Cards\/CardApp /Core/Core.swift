// Fichier d'export principal pour le module Core

// Imports système essentiels
import Foundation
import CoreData
import Combine

// Types communs exportés
public typealias CardID = UUID
public typealias DeckID = UUID
public typealias TagID = UUID
public typealias ReviewID = UUID
public typealias SessionID = UUID

// Note: Dans un module Swift, tous les types publics (MasteryLevel, ReviewRating, CardSortOption, etc.)
// sont automatiquement accessibles à travers le module. Il n'est pas nécessaire de les exporter
// explicitement avec des typealias.
//
// Pour simplifier l'importation des types, il est recommandé d'utiliser des imports ciblés 
// dans vos fichiers plutôt que d'importer tout le module Core.
