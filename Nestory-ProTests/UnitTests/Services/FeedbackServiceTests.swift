//
//  FeedbackServiceTests.swift
//  Nestory-ProTests
//
//  Unit tests for FeedbackService (Task P4-07)
//

import XCTest
@testable import Nestory_Pro

final class FeedbackServiceTests: XCTestCase {
    
    private var sut: FeedbackService!
    
    override func setUp() {
        super.setUp()
        sut = FeedbackService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - FeedbackCategory Tests
    
    @MainActor
    func testFeedbackCategory_EmailSubject_ContainsNestoryPrefix() {
        // Assert all categories have correct prefix
        for category in FeedbackCategory.allCases {
            XCTAssertTrue(
                category.emailSubject.hasPrefix("[Nestory]"),
                "Category \(category.rawValue) should have [Nestory] prefix"
            )
        }
    }
    
    @MainActor
    func testFeedbackCategory_General_HasCorrectSubject() {
        // Arrange
        let category = FeedbackCategory.general
        
        // Act
        let subject = category.emailSubject
        
        // Assert
        XCTAssertEqual(subject, "[Nestory] General Feedback")
    }
    
    @MainActor
    func testFeedbackCategory_Bug_HasCorrectSubject() {
        // Arrange
        let category = FeedbackCategory.bug
        
        // Act
        let subject = category.emailSubject
        
        // Assert
        XCTAssertEqual(subject, "[Nestory] Bug Report")
    }
    
    @MainActor
    func testFeedbackCategory_Feature_HasCorrectSubject() {
        // Arrange
        let category = FeedbackCategory.feature
        
        // Act
        let subject = category.emailSubject
        
        // Assert
        XCTAssertEqual(subject, "[Nestory] Feature Request")
    }
    
    @MainActor
    func testFeedbackCategory_Question_HasCorrectSubject() {
        // Arrange
        let category = FeedbackCategory.question
        
        // Act
        let subject = category.emailSubject
        
        // Assert
        XCTAssertEqual(subject, "[Nestory] Question")
    }
    
    @MainActor
    func testFeedbackCategory_AllCasesHaveIcons() {
        // Assert all categories have non-empty icon names
        for category in FeedbackCategory.allCases {
            XCTAssertFalse(
                category.icon.isEmpty,
                "Category \(category.rawValue) should have an icon"
            )
        }
    }
    
    // MARK: - Device Info Tests
    
    @MainActor
    func testGenerateDeviceInfo_ContainsAppVersion() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("App: Nestory Pro v"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_ContainsiOSVersion() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("iOS:"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_ContainsDeviceModel() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("Device:"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_ContainsLocale() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("Locale:"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_ContainsTimezone() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("Timezone:"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_ContainsStorageInfo() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert
        XCTAssertTrue(deviceInfo.contains("Storage Available:"))
    }
    
    @MainActor
    func testGenerateDeviceInfo_HasDelimiters() {
        // Act
        let deviceInfo = sut.generateDeviceInfo()
        
        // Assert - Should have --- at start and end
        XCTAssertTrue(deviceInfo.hasPrefix("---"))
        XCTAssertTrue(deviceInfo.hasSuffix("---"))
    }
    
    // MARK: - Email URL Tests
    
    @MainActor
    func testCreateFeedbackEmailURL_ReturnsValidURL() {
        // Act
        let url = sut.createFeedbackEmailURL(category: .general)
        
        // Assert
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
    }
    
    @MainActor
    func testCreateFeedbackEmailURL_ContainsSupportEmail() {
        // Act
        let url = sut.createFeedbackEmailURL(category: .bug)
        
        // Assert
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains(FeedbackService.supportEmail))
    }
    
    @MainActor
    func testCreateFeedbackEmailURL_ContainsEncodedSubject() {
        // Act
        let url = sut.createFeedbackEmailURL(category: .feature)
        
        // Assert
        XCTAssertNotNil(url)
        // Subject should be URL-encoded
        XCTAssertTrue(url!.absoluteString.contains("subject="))
    }
    
    @MainActor
    func testCreateFeedbackEmailURL_WithContext_IncludesContext() {
        // Arrange
        let context = "Test context message"
        
        // Act
        let url = sut.createFeedbackEmailURL(category: .bug, additionalContext: context)
        
        // Assert
        XCTAssertNotNil(url)
        // Context should be URL-encoded in the body
        XCTAssertTrue(url!.absoluteString.contains("body="))
    }
    
    @MainActor
    func testCreateSupportEmailURL_ReturnsValidURL() {
        // Act
        let url = sut.createSupportEmailURL()
        
        // Assert
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
    }
    
    // MARK: - Support Email Constant
    
    @MainActor
    func testSupportEmail_IsCorrect() {
        XCTAssertEqual(FeedbackService.supportEmail, "support@nestory.app")
    }
}
