import Foundation
import CoreData
import SwiftUI

// MARK: - Extensions pour les entités CoreData

extension DeckEntity {
    func toModel() -> Deck {
        return Deck(
            id: id ?? UUID(),
            name: name,
            description: desc,
            icon: icon,
            colorName: colorName,
            tags: tags,
            cardCount: Int(cardCount),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func update(from model: Deck) {
        id = model.id
        name = model.name
        desc = model.description
        icon = model.icon
        colorName = model.colorName
        tags = model.tags
        cardCount = Int32(model.cardCount)
        updatedAt = model.updatedAt
    }
}

extension CardEntity {
    func toModel() -> Card {
        return Card(
            id: id ?? UUID(),
            deckID: deckID ?? UUID(),
            question: question,
            answer: answer,
            additionalInfo: additionalInfo,
            tags: tags,
            masteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(masteryLevel)) ?? .novice,
            interval: Int(interval),
            ease: ease,
            reviewCount: Int(reviewCount),
            correctCount: Int(correctCount),
            incorrectCount: Int(incorrectCount),
            lastReviewedAt: lastReviewedAt,
            nextReviewDate: nextReviewDate,
            isFlagged: isFlagged,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func update(from model: Card) {
        id = model.id
        deckID = model.deckID
        question = model.question
        answer = model.answer
        additionalInfo = model.additionalInfo
        tags = model.tags
        masteryLevel = Int16(model.masteryLevel.rawValue)
        interval = Int16(model.interval)
        ease = model.ease
        reviewCount = Int16(model.reviewCount)
        correctCount = Int16(model.correctCount)
        incorrectCount = Int16(model.incorrectCount)
        lastReviewedAt = model.lastReviewedAt
        nextReviewDate = model.nextReviewDate
        isFlagged = model.isFlagged
        updatedAt = model.updatedAt
    }
}

extension CardReviewEntity {
    func toModel() -> CardReview {
        return CardReview(
            id: id ?? UUID(),
            cardID: card?.id ?? UUID(),
            sessionID: session?.id,
            timestamp: timestamp,
            rating: Core.Common.ReviewRating(rawValue: Int(rating) ?? 0) ?? .again,
            responseTime: responseTime,
            newInterval: Int(newInterval),
            newEase: newEase,
            newMasteryLevel: Core.Models.Common.MasteryLevel(rawValue: Int(newMasteryLevel)) ?? .novice
        )
    }
    
    func update(from model: CardReview) {
        id = model.id
        timestamp = model.timestamp
        responseTime = model.responseTime
        rating = String(model.rating.rawValue)
        newInterval = Int16(model.newInterval)
        newEase = model.newEase
        newMasteryLevel = Int16(model.newMasteryLevel.rawValue)
    }
}

extension StudySessionEntity {
    func toModel() -> StudySession {
        return StudySession(
            id: id ?? UUID(),
            deckID: deckID ?? UUID(),
            startDate: startTime ?? Date(),
            endDate: endTime,
            scheduledCards: Array(reviews.compactMap { $0.card?.id }),
            reviewedCards: Array(reviews.compactMap { $0.card?.id }),
            correctCount: Int(totalCorrect),
            incorrectCount: Int(totalIncorrect),
            includeSubdecks: includeSubdecks,
            reviewLimit: reviewLimit > 0 ? Int(reviewLimit) : nil,
            totalStudyTime: totalTime
        )
    }
    
    func update(from model: StudySession) {
        id = model.id
        deckID = model.deckID
        startTime = model.startDate
        endTime = model.endDate
        includeSubdecks = model.includeSubdecks
        reviewLimit = model.reviewLimit != nil ? Int32(model.reviewLimit!) : 0
        totalCorrect = Int32(model.correctCount)
        totalIncorrect = Int32(model.incorrectCount)
        totalTime = model.totalStudyTime
    }
}

// MARK: - Méthodes utilitaires

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
} 