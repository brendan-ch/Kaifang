//
//  FlashcardProvider+Scheduler.swift
//  KaifangShared
//
//  Created by Brendan Chen on 2026.06.03.
//

public extension FlashcardProvider {
    protocol FlashcardScheduler {
        var maximumInterval: Double { get }
        
        func initialDifficulty(_ grade: ReviewRating) -> Double
        func initialStability(_ grade: ReviewRating) -> Double
        
        func retrievability(elapsedDays: Double, stability: Double) -> Double
        func nextDifficulty(_ difficulty: Double, _ grade: ReviewRating) -> Double
        
        func shortTermStability(stability: Double, grade: ReviewRating) -> Double  // same-day (elapsed < 1)
        func stabilityAfterLapse(difficulty: Double, stability: Double, retrievability: Double) -> Double  // grade == .again
        func stabilityAfterRecall(difficulty: Double, stability: Double, retrievability: Double, grade: ReviewRating) -> Double  // pass
        
        // Interval from stability
        func interval(stability: Double) -> Double
    }
}
