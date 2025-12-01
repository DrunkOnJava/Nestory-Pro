//
//  XCTestCase+PerformanceMonitor.swift
//  Nestory-ProTests
//
//  Created by Claude Code on 2025-01-30.
//

import XCTest

extension XCTestCase {
    /// Execute test block with timeout enforcement based on tags
    ///
    /// Automatically fails test if execution exceeds expected duration.
    /// Uses `expectedDuration` from tags, or custom timeout if provided.
    ///
    /// - Parameters:
    ///   - customTimeout: Optional override for expected duration
    ///   - file: Source file (auto-captured)
    ///   - line: Source line (auto-captured)
    ///   - block: Test code to execute
    func testWithTimeout(
        _ customTimeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () throws -> Void
    ) rethrows {
        let timeout = customTimeout ?? expectedDuration
        let start = Date()

        try block()

        let elapsed = Date().timeIntervalSince(start)

        if elapsed > timeout {
            XCTFail(
                """
                Test exceeded \(String(format: "%.2f", timeout))s timeout \
                (took \(String(format: "%.3f", elapsed))s). \
                Tags: \(tagDescription)
                """,
                file: file,
                line: line
            )
        }
    }

    /// Execute async test block with timeout enforcement
    ///
    /// Async variant of `testWithTimeout` for Swift concurrency.
    ///
    /// - Parameters:
    ///   - customTimeout: Optional override for expected duration
    ///   - file: Source file (auto-captured)
    ///   - line: Source line (auto-captured)
    ///   - block: Async test code to execute
    @MainActor
    func testWithTimeoutAsync(
        _ customTimeout: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () async throws -> Void
    ) async rethrows {
        let timeout = customTimeout ?? expectedDuration
        let start = Date()

        try await block()

        let elapsed = Date().timeIntervalSince(start)

        if elapsed > timeout {
            XCTFail(
                """
                Test exceeded \(String(format: "%.2f", timeout))s timeout \
                (took \(String(format: "%.3f", elapsed))s). \
                Tags: \(tagDescription)
                """,
                file: file,
                line: line
            )
        }
    }

    /// Measure block execution and report if exceeds expected duration
    ///
    /// Does NOT fail test, only reports warning. Useful for performance monitoring.
    ///
    /// - Parameters:
    ///   - name: Description of operation being measured
    ///   - block: Code to measure
    /// - Returns: Elapsed time in seconds
    @discardableResult
    func measureExecution(
        of name: String = "Operation",
        _ block: () throws -> Void
    ) rethrows -> TimeInterval {
        let start = Date()
        try block()
        let elapsed = Date().timeIntervalSince(start)

        let threshold = expectedDuration
        if elapsed > threshold {
            print(
                """
                ⚠️ \(name) exceeded expected \(String(format: "%.2f", threshold))s \
                (took \(String(format: "%.3f", elapsed))s)
                """
            )
        }

        return elapsed
    }

    /// Measure async block execution
    @MainActor
    @discardableResult
    func measureExecutionAsync(
        of name: String = "Operation",
        _ block: () async throws -> Void
    ) async rethrows -> TimeInterval {
        let start = Date()
        try await block()
        let elapsed = Date().timeIntervalSince(start)

        let threshold = expectedDuration
        if elapsed > threshold {
            print(
                """
                ⚠️ \(name) exceeded expected \(String(format: "%.2f", threshold))s \
                (took \(String(format: "%.3f", elapsed))s)
                """
            )
        }

        return elapsed
    }
}

// MARK: - Performance Assertions

extension XCTestCase {
    /// Assert operation completes within expected duration
    ///
    /// Fails test if execution exceeds threshold.
    ///
    /// - Parameters:
    ///   - threshold: Maximum allowed duration
    ///   - name: Description for failure message
    ///   - file: Source file (auto-captured)
    ///   - line: Source line (auto-captured)
    ///   - block: Code to measure
    func assertPerformance(
        lessThan threshold: TimeInterval,
        named name: String = "Operation",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () throws -> Void
    ) rethrows {
        let start = Date()
        try block()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(
            elapsed,
            threshold,
            "\(name) took \(String(format: "%.3f", elapsed))s (expected <\(String(format: "%.2f", threshold))s)",
            file: file,
            line: line
        )
    }

    /// Assert async operation completes within expected duration
    @MainActor
    func assertPerformanceAsync(
        lessThan threshold: TimeInterval,
        named name: String = "Operation",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () async throws -> Void
    ) async rethrows {
        let start = Date()
        try await block()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(
            elapsed,
            threshold,
            "\(name) took \(String(format: "%.3f", elapsed))s (expected <\(String(format: "%.2f", threshold))s)",
            file: file,
            line: line
        )
    }
}
