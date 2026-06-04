//
//  Alea.swift
//  KaifangSpacedRepetition
//
//  Created by Brendan Chen on 2026.06.03.
//

import Foundation

/// A seeded, deterministic pseudo-random generator producing `[0, 1)` doubles.
///
/// This is the "Alea" generator (Johannes Baagøe / David Bau) that FSRS uses
/// for interval fuzzing. It is reproduced here so fuzzed intervals are
/// reproducible: the same seed always yields the same stream. The integer
/// idioms from the original JavaScript (`x >>> 0`, `t | 0`) are reproduced with
/// fixed-width truncation so the output matches the reference exactly.
struct Alea {
    private var s0: Double
    private var s1: Double
    private var s2: Double
    private var c: Double

    /// Seeds the generator. An empty seed falls back to the wall clock, which
    /// sacrifices determinism — callers that need reproducibility must pass a
    /// non-empty seed.
    init(seed: String) {
        var mash = Mash()
        c = 1.0
        // Drain three space mashes first; the shared Mash state means each
        // fresh generator starts from the same triple before the seed mixes in.
        s0 = mash.mash(" ")
        s1 = mash.mash(" ")
        s2 = mash.mash(" ")

        let key = seed.isEmpty ? String(Date().timeIntervalSince1970) : seed
        s0 -= mash.mash(key); if s0 < 0 { s0 += 1 }
        s1 -= mash.mash(key); if s1 < 0 { s1 += 1 }
        s2 -= mash.mash(key); if s2 < 0 { s2 += 1 }
    }

    /// Advances the state and returns the next `[0, 1)` value.
    mutating func next() -> Double {
        let t = 2_091_639.0 * s0 + c * twoPowMinus32
        s0 = s1
        s1 = s2
        c = Double(Int32(truncatingIfNeeded: Int64(t)))  // `t | 0`
        s2 = t - c
        return s2
    }

    /// Advances the state and returns the next value as a signed 32-bit integer
    /// (mirrors the reference `int32`, including negative results).
    mutating func int32() -> Int32 {
        Int32(truncatingIfNeeded: Int64(next() * twoPow32))
    }
}

/// String-hashing helper used by ``Alea`` to derive its initial state from a
/// seed. The internal accumulator persists across calls, so the order of
/// `mash` invocations matters.
private struct Mash {
    private var n = Double(UInt32(0xefc8_249d))

    mutating func mash(_ data: String) -> Double {
        for code in data.utf16 {
            n += Double(code)
            var h = 0.02519603282416938 * n
            n = Double(UInt32(truncatingIfNeeded: Int64(h)))  // `h >>> 0`
            h -= n
            h *= n
            n = Double(UInt32(truncatingIfNeeded: Int64(h)))  // `h >>> 0`
            h -= n
            n += h * twoPow32
        }
        return Double(UInt32(truncatingIfNeeded: Int64(n))) * twoPowMinus32
    }
}

private let twoPow32 = 4_294_967_296.0          // 2^32
private let twoPowMinus32 = 2.3283064365386963e-10  // 2^-32
