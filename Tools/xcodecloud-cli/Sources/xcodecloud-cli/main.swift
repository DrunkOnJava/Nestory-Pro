//
//  main.swift
//  xcodecloud-cli
//
//  CLI tool for managing Xcode Cloud via App Store Connect API
//

import Foundation
import ArgumentParser
import Crypto

// MARK: - Main Command

@main
struct XcodeCloudCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcodecloud-cli",
        abstract: "Manage Xcode Cloud workflows via App Store Connect API",
        version: "1.0.0",
        subcommands: [
            ListProducts.self,
            ListWorkflows.self,
            CreateWorkflow.self,
            TriggerBuild.self,
            GetBuild.self,
            GetIssues.self,
            GetWorkflow.self,
            ListTestDestinations.self,
            MonitorBuild.self,
            ListBuilds.self,
            OpenBuild.self
        ]
    )
}

// MARK: - Workflow Configuration Models

enum WorkflowType: String {
    case pullRequest = "pr"
    case branch = "branch"
    case tag = "tag"
}

enum WorkflowActionType: String {
    case test = "TEST"
    case archive = "ARCHIVE"
    case analyze = "ANALYZE"
}

// MARK: - List Products

extension XcodeCloudCLI {
    struct ListProducts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all Xcode Cloud products"
        )

        @Flag(name: .long, help: "Output raw JSON")
        var json = false

        func run() async throws {
            let client = try AppStoreConnectClient()
            let products = try await client.listProducts()

            if json {
                print(String(data: products, encoding: .utf8) ?? "")
            } else {
                let decoded = try JSONDecoder().decode(ProductsResponse.self, from: products)
                print("Xcode Cloud Products:")
                print("====================")
                for product in decoded.data {
                    print("ID: \(product.id)")
                    print("Name: \(product.attributes.name)")
                    print("Type: \(product.attributes.productType)")
                    print("---")
                }
            }
        }
    }
}

// MARK: - List Workflows

extension XcodeCloudCLI {
    struct ListWorkflows: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List workflows for a product"
        )

        @Option(name: .long, help: "Product ID")
        var product: String

        @Flag(name: .long, help: "Output raw JSON")
        var json = false

        func run() async throws {
            let client = try AppStoreConnectClient()
            let workflows = try await client.listWorkflows(productID: product)

            if json {
                print(String(data: workflows, encoding: .utf8) ?? "")
            } else {
                let decoded = try JSONDecoder().decode(WorkflowsResponse.self, from: workflows)
                print("Workflows for product \(product):")
                print("================================")
                for workflow in decoded.data {
                    print("ID: \(workflow.id)")
                    print("Name: \(workflow.attributes.name)")
                    print("Enabled: \(workflow.attributes.isEnabled)")
                    if let desc = workflow.attributes.description {
                        print("Description: \(desc)")
                    }
                    print("---")
                }
            }
        }
    }
}

// MARK: - Create Workflow

extension XcodeCloudCLI {
    struct CreateWorkflow: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Create a new Xcode Cloud workflow",
            discussion: """
                Create workflows for different CI/CD scenarios:

                PR Validation:
                  --type pr --scheme Nestory-Pro

                Main Branch with TestFlight:
                  --type branch --branch main --action test --action archive --scheme Nestory-Pro-Beta

                Release Tag:
                  --type tag --tag-pattern "v*" --action test --action archive --scheme Nestory-Pro-Release
                """
        )

        @Option(name: .long, help: "Product ID")
        var product: String

        @Option(name: .long, help: "Workflow name")
        var name: String

        @Option(name: .long, help: "Workflow type: pr, branch, or tag")
        var type: String = "pr"

        @Option(name: .long, help: "Action types: test, archive, analyze")
        var action: [String] = ["test"]

        @Option(name: .long, help: "Xcode scheme to build")
        var scheme: String

        @Option(name: .long, help: "Branch pattern (for branch workflows)")
        var branch: String?

        @Option(name: .long, help: "Tag pattern (for tag workflows)")
        var tagPattern: String?

        @Option(name: .long, help: "Description")
        var description: String?

        @Flag(name: .long, help: "Enable immediately")
        var enabled = true

        @Flag(name: .long, help: "Verbose output")
        var verbose = false

        func run() async throws {
            let client = try AppStoreConnectClient()
            let isDryRun = ProcessInfo.processInfo.environment["XC_CLOUD_DRY_RUN"] != nil

            // Validate workflow type
            guard let workflowType = WorkflowType(rawValue: type) else {
                throw ValidationError("Invalid workflow type '\(type)'. Use: pr, branch, or tag")
            }

            // Validate actions
            let actionTypes = try action.map { actionStr -> WorkflowActionType in
                guard let actionType = WorkflowActionType(rawValue: actionStr.uppercased()) else {
                    throw ValidationError("Invalid action '\(actionStr)'. Use: test, archive, or analyze")
                }
                return actionType
            }

            guard !actionTypes.isEmpty else {
                throw ValidationError("At least one action required")
            }

            // Validate workflow-specific requirements
            if workflowType == .branch && branch == nil {
                throw ValidationError("--branch required for branch workflows")
            }
            if workflowType == .tag && tagPattern == nil {
                throw ValidationError("--tag-pattern required for tag workflows")
            }

            print("Creating workflow '\(name)' for product \(product)...")

            // Use mock IDs for dry run
            let repositoryID: String
            let macOSVersionID: String
            let macOSVersionName: String
            let xcodeVersionID: String
            let xcodeVersionName: String

            if isDryRun {
                repositoryID = "mock-repository-id"
                macOSVersionID = "mock-macos-id"
                macOSVersionName = "macOS 15 (Sequoia)"
                xcodeVersionID = "mock-xcode-id"
                xcodeVersionName = "Xcode 16.2"
                if verbose {
                    print("→ Using mock IDs for dry run")
                    print("  Repository ID: \(repositoryID)")
                    print("  Using: \(macOSVersionName)")
                    print("  Using: \(xcodeVersionName)")
                }
            } else {
                // Fetch repository
                if verbose { print("→ Fetching repository...") }
                let repoData = try await client.getRepositories(productID: product)
                let repoResponse = try JSONDecoder().decode(RepositoriesResponse.self, from: repoData)
                guard let repo = repoResponse.data.first else {
                    throw ValidationError("No repository found. Ensure GitHub repo is linked in App Store Connect.")
                }
                repositoryID = repo.id
                if verbose { print("  Repository ID: \(repositoryID)") }

                // Fetch macOS version
                if verbose { print("→ Fetching macOS versions...") }
                let macOSData = try await client.getMacOSVersions()
                let macOSResponse = try JSONDecoder().decode(MacOSVersionsResponse.self, from: macOSData)
                guard let macOSVersion = macOSResponse.data.first else {
                    throw ValidationError("No macOS versions available")
                }
                macOSVersionID = macOSVersion.id
                macOSVersionName = "\(macOSVersion.attributes.name) (\(macOSVersion.attributes.version))"
                if verbose { print("  Using: \(macOSVersionName)") }

                // Fetch Xcode version
                if verbose { print("→ Fetching Xcode versions...") }
                let xcodeData = try await client.getXcodeVersions()
                let xcodeResponse = try JSONDecoder().decode(XcodeVersionsResponse.self, from: xcodeData)
                guard let xcodeVersion = xcodeResponse.data.first else {
                    throw ValidationError("No Xcode versions available")
                }
                xcodeVersionID = xcodeVersion.id
                xcodeVersionName = "\(xcodeVersion.attributes.name) (\(xcodeVersion.attributes.version))"
                if verbose { print("  Using: \(xcodeVersionName)") }
            }

            // Build payload
            let builder = WorkflowPayloadBuilder(
                name: name,
                description: description,
                productID: product,
                repositoryID: repositoryID,
                macOSVersionID: macOSVersionID,
                xcodeVersionID: xcodeVersionID,
                scheme: scheme,
                workflowType: workflowType,
                actionTypes: actionTypes,
                branchPattern: branch,
                tagPattern: tagPattern,
                enabled: enabled
            )

            let payload = builder.buildPayload()

            if verbose || isDryRun {
                print("→ Payload:")
                if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            }

            if isDryRun {
                print("\n[DRY RUN] Workflow creation skipped")
                return
            }

            // Create workflow
            print("→ Creating workflow via API...")
            let bodyData = try JSONSerialization.data(withJSONObject: payload)
            let workflowData = try await client.request(endpoint: "/v1/ciWorkflows", method: "POST", body: bodyData)

            let workflowResponse = try JSONDecoder().decode(WorkflowResponse.self, from: workflowData)
            let workflowID = workflowResponse.data.id

            print("\n✅ Workflow '\(name)' created successfully!")
            print("Workflow ID: \(workflowID)")
            print("\nVerify in: App Store Connect → Apps → Nestory-Pro → Xcode Cloud")
        }
    }
}

// MARK: - Trigger Build

extension XcodeCloudCLI {
    struct TriggerBuild: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Trigger a build for a workflow"
        )

        @Option(name: .long, help: "Workflow ID")
        var workflow: String

        @Option(name: .long, help: "Git branch (e.g., main)")
        var branch: String?

        @Option(name: .long, help: "Git tag (e.g., v1.0.0)")
        var tag: String?

        func run() async throws {
            guard branch != nil || tag != nil else {
                throw ValidationError("Must specify either --branch or --tag")
            }

            let client = try AppStoreConnectClient()
            let gitRef = branch.map { "refs/heads/\($0)" } ?? tag.map { "refs/tags/\($0)" }!

            print("Triggering build for workflow \(workflow) on \(gitRef)...")

            let buildRun = try await client.triggerBuild(workflowID: workflow, gitReference: gitRef)
            let decoded = try JSONDecoder().decode(BuildRunResponse.self, from: buildRun)

            print("✅ Build triggered successfully!")
            print("Build ID: \(decoded.data.id)")
            print("View in Xcode: Product → Xcode Cloud → Builds")
        }
    }
}

// MARK: - Get Build

extension XcodeCloudCLI {
    struct GetBuild: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get build status with action details"
        )

        @Option(name: .long, help: "Build ID")
        var build: String

        @Flag(name: .long, help: "Output raw JSON")
        var json = false

        func run() async throws {
            let client = try AppStoreConnectClient()
            let buildData = try await client.getBuild(buildID: build)

            if json {
                print(String(data: buildData, encoding: .utf8) ?? "")
                return
            }

            // Parse build info
            guard let buildJson = try? JSONSerialization.jsonObject(with: buildData) as? [String: Any],
                  let data = buildJson["data"] as? [String: Any],
                  let attributes = data["attributes"] as? [String: Any] else {
                print("Failed to parse build data")
                return
            }

            let buildId = data["id"] as? String ?? build
            let progress = attributes["executionProgress"] as? String ?? "UNKNOWN"
            let completion = attributes["completionStatus"] as? String ?? "-"
            let created = attributes["createdDate"] as? String ?? "N/A"
            let started = attributes["startedDate"] as? String ?? "N/A"
            let finished = attributes["finishedDate"] as? String ?? "N/A"

            // Format result
            let resultIcon: String
            switch completion {
            case "SUCCEEDED": resultIcon = "✅"
            case "FAILED": resultIcon = "❌"
            case "CANCELED": resultIcon = "⏹️"
            default: resultIcon = "⏳"
            }

            print("Build: \(buildId)")
            print(String(repeating: "=", count: 60))
            print("Progress: \(progress)")
            print("Result:   \(resultIcon) \(completion)")
            print("Created:  \(created)")
            print("Started:  \(started)")
            print("Finished: \(finished)")

            // Fetch and show build actions
            print("\n📋 Build Actions:")
            print(String(repeating: "-", count: 60))

            let actionsData = try await client.request(
                endpoint: "/v1/ciBuildRuns/\(build)/actions",
                method: "GET"
            )

            if let actionsJson = try? JSONSerialization.jsonObject(with: actionsData) as? [String: Any],
               let actionsArray = actionsJson["data"] as? [[String: Any]] {

                if actionsArray.isEmpty {
                    print("No actions found")
                } else {
                    for action in actionsArray {
                        if let actionAttrs = action["attributes"] as? [String: Any] {
                            let actionName = actionAttrs["name"] as? String ?? "Unknown"
                            let actionType = actionAttrs["actionType"] as? String ?? "?"
                            let actionResult = actionAttrs["completionStatus"] as? String ?? "-"

                            let actionIcon: String
                            switch actionResult {
                            case "SUCCEEDED": actionIcon = "✅"
                            case "FAILED": actionIcon = "❌"
                            case "CANCELED": actionIcon = "⏹️"
                            default: actionIcon = "⏳"
                            }

                            print("\(actionIcon) [\(actionType)] \(actionName): \(actionResult)")

                            // Show issues if any
                            if let issues = actionAttrs["issueCounts"] as? [String: Any] {
                                let errors = issues["errorCount"] as? Int ?? 0
                                let warnings = issues["warningCount"] as? Int ?? 0
                                let testFailures = issues["testFailureCount"] as? Int ?? 0

                                if errors > 0 || warnings > 0 || testFailures > 0 {
                                    var issueStrs: [String] = []
                                    if errors > 0 { issueStrs.append("\(errors) errors") }
                                    if warnings > 0 { issueStrs.append("\(warnings) warnings") }
                                    if testFailures > 0 { issueStrs.append("\(testFailures) test failures") }
                                    print("   Issues: \(issueStrs.joined(separator: ", "))")
                                }
                            }
                        }
                    }
                }
            } else {
                print("Failed to fetch actions")
            }

            // Provide App Store Connect link
            print("\n🌐 View in App Store Connect:")
            print("https://appstoreconnect.apple.com → Apps → Nestory-Pro → Xcode Cloud")
        }
    }

    // MARK: - Get Issues

    struct GetIssues: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get build issues (errors, warnings, test failures)"
        )

        @Option(name: .long, help: "Build ID")
        var build: String

        @Flag(name: .long, help: "Show only errors")
        var errorsOnly = false

        func run() async throws {
            let client = try AppStoreConnectClient()

            print("🔍 Fetching issues for build \(build)...")
            print(String(repeating: "=", count: 60))

            // First get the build actions to find action IDs
            let actionsData = try await client.request(
                endpoint: "/v1/ciBuildRuns/\(build)/actions",
                method: "GET"
            )

            guard let actionsJson = try? JSONSerialization.jsonObject(with: actionsData) as? [String: Any],
                  let actionsArray = actionsJson["data"] as? [[String: Any]] else {
                print("Failed to fetch build actions")
                return
            }

            if actionsArray.isEmpty {
                print("No actions found for this build")
                return
            }

            var totalErrors = 0
            var totalWarnings = 0
            var totalTestFailures = 0

            for action in actionsArray {
                guard let actionId = action["id"] as? String,
                      let actionAttrs = action["attributes"] as? [String: Any] else {
                    continue
                }

                let actionName = actionAttrs["name"] as? String ?? "Unknown"
                let actionResult = actionAttrs["completionStatus"] as? String ?? "-"

                print("\n📋 Action: \(actionName) (\(actionResult))")
                print(String(repeating: "-", count: 50))

                // Fetch issues for this action
                let issuesData = try await client.request(
                    endpoint: "/v1/ciBuildActions/\(actionId)/issues",
                    method: "GET"
                )

                guard let issuesJson = try? JSONSerialization.jsonObject(with: issuesData) as? [String: Any],
                      let issuesArray = issuesJson["data"] as? [[String: Any]] else {
                    print("  No issues data available")
                    continue
                }

                if issuesArray.isEmpty {
                    print("  ✅ No issues")
                    continue
                }

                for issue in issuesArray {
                    guard let issueAttrs = issue["attributes"] as? [String: Any] else {
                        continue
                    }

                    let category = issueAttrs["category"] as? String ?? "UNKNOWN"
                    let message = issueAttrs["message"] as? String ?? "No message"
                    let fileSource = issueAttrs["fileSource"] as? [String: Any]
                    let filePath = fileSource?["path"] as? String
                    let lineNumber = fileSource?["lineNumber"] as? Int

                    // Filter by errors only if flag set
                    if errorsOnly && category != "ERROR" {
                        continue
                    }

                    let icon: String
                    switch category {
                    case "ERROR":
                        icon = "❌"
                        totalErrors += 1
                    case "WARNING":
                        icon = "⚠️"
                        totalWarnings += 1
                    case "TEST_FAILURE":
                        icon = "🔴"
                        totalTestFailures += 1
                    default:
                        icon = "ℹ️"
                    }

                    print("  \(icon) [\(category)]")
                    print("     \(message)")
                    if let path = filePath {
                        var location = "     📁 \(path)"
                        if let line = lineNumber {
                            location += ":\(line)"
                        }
                        print(location)
                    }
                    print("")
                }
            }

            // Summary
            print("\n" + String(repeating: "=", count: 60))
            print("📊 Summary:")
            print("   Errors: \(totalErrors)")
            print("   Warnings: \(totalWarnings)")
            print("   Test Failures: \(totalTestFailures)")
        }
    }

    struct GetWorkflow: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get workflow details (for debugging)"
        )

        @Option(name: .long, help: "Workflow ID")
        var workflow: String

        func run() async throws {
            let client = try AppStoreConnectClient()
            let data = try await client.request(endpoint: "/v1/ciWorkflows/\(workflow)", method: "GET")

            // Pretty print JSON
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print(prettyString)
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }
    }

    struct ListTestDestinations: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List available test destinations for Xcode Cloud"
        )

        func run() async throws {
            let client = try AppStoreConnectClient()
            let data = try await client.request(
                endpoint: "/v1/ciTestDestinations",
                method: "GET"
            )

            // Pretty print JSON
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print(prettyString)
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }
    }

    // MARK: - Monitor Build

    struct MonitorBuild: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Monitor a build in real-time"
        )

        @Option(name: .long, help: "Build ID to monitor")
        var build: String

        @Flag(name: .long, help: "Follow build until completion")
        var follow: Bool = false

        func run() async throws {
            let client = try AppStoreConnectClient()

            if follow {
                print("Monitoring build \(build)...\n")

                var lastStatus = ""
                repeat {
                    let data = try await client.request(
                        endpoint: "/v1/ciBuildRuns/\(build)",
                        method: "GET"
                    )

                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataObj = json["data"] as? [String: Any],
                       let attributes = dataObj["attributes"] as? [String: Any],
                       let status = attributes["executionProgress"] as? String {

                        if status != lastStatus {
                            let timestamp = ISO8601DateFormatter().string(from: Date())
                            print("[\(timestamp)] Status: \(status)")
                            lastStatus = status
                        }

                        // Exit conditions
                        if status == "COMPLETE" {
                            if let result = attributes["completionStatus"] as? String {
                                print("\n✅ Build finished: \(result)")
                                if result != "SUCCEEDED" {
                                    throw ExitCode(1)
                                }
                            }
                            break
                        } else if status == "ERROR" {
                            print("\n❌ Build failed")
                            throw ExitCode(1)
                        }
                    }

                    // Poll every 15 seconds
                    try await Task.sleep(nanoseconds: 15_000_000_000)
                } while true
            } else {
                // Single status check
                let data = try await client.request(
                    endpoint: "/v1/ciBuildRuns/\(build)",
                    method: "GET"
                )

                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    print(prettyString)
                } else {
                    print(String(data: data, encoding: .utf8) ?? "")
                }
            }
        }
    }

    // MARK: - List Builds

    struct ListBuilds: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List recent builds for a workflow"
        )

        @Option(name: .long, help: "Workflow ID")
        var workflow: String

        @Option(name: .long, help: "Number of builds to show")
        var limit: Int = 10

        func run() async throws {
            let client = try AppStoreConnectClient()

            print("Recent builds for workflow \(workflow):")
            print(String(repeating: "=", count: 80))

            let data = try await client.request(
                endpoint: "/v1/ciWorkflows/\(workflow)/buildRuns?limit=\(limit)",
                method: "GET"
            )

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {

                if dataArray.isEmpty {
                    print("No builds found")
                    return
                }

                // Print table header
                print("Build ID".padding(toLength: 40, withPad: " ", startingAt: 0) +
                      "Progress".padding(toLength: 12, withPad: " ", startingAt: 0) +
                      "Result".padding(toLength: 12, withPad: " ", startingAt: 0) +
                      "Started".padding(toLength: 22, withPad: " ", startingAt: 0) +
                      "Commit")
                print(String(repeating: "-", count: 100))

                for buildData in dataArray {
                    let id = buildData["id"] as? String ?? "N/A"
                    if let attributes = buildData["attributes"] as? [String: Any] {
                        let progress = attributes["executionProgress"] as? String ?? "UNKNOWN"
                        let completion = attributes["completionStatus"] as? String ?? "-"
                        let sourceRef = (attributes["sourceCommit"] as? [String: Any])?["commitSha"] as? String ?? "N/A"
                        let started = attributes["startedDate"] as? String ?? "N/A"

                        // Use full build ID for API compatibility (truncated IDs don't work)
                        let shortRef = String(sourceRef.prefix(7))
                        let shortStarted = String(started.prefix(19)).replacingOccurrences(of: "T", with: " ")

                        // Format result with emoji indicator
                        let resultDisplay: String
                        switch completion {
                        case "SUCCEEDED":
                            resultDisplay = "✅ PASS"
                        case "FAILED":
                            resultDisplay = "❌ FAIL"
                        case "CANCELED":
                            resultDisplay = "⏹️ CANCEL"
                        case "-":
                            resultDisplay = "⏳ ..."
                        default:
                            resultDisplay = completion
                        }

                        print(id.padding(toLength: 40, withPad: " ", startingAt: 0) +
                              progress.padding(toLength: 12, withPad: " ", startingAt: 0) +
                              resultDisplay.padding(toLength: 12, withPad: " ", startingAt: 0) +
                              shortStarted.padding(toLength: 22, withPad: " ", startingAt: 0) +
                              shortRef)
                    }
                }
            } else {
                print("Failed to parse builds")
            }
        }
    }

    // MARK: - Open Build

    struct OpenBuild: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print App Store Connect URL for a build"
        )

        @Option(name: .long, help: "Build ID")
        var build: String

        func run() async throws {
            // App Store Connect URL format:
            // https://appstoreconnect.apple.com/teams/<TEAM_ID>/apps/<APP_ID>/ci/builds/<BUILD_ID>
            //
            // For now, we'll use the workflow URL format which is more reliable
            print("🌐 Opening build in App Store Connect...")
            print("")
            print("Build ID: \(build)")
            print("")
            print("View in App Store Connect:")
            print("https://appstoreconnect.apple.com")
            print("")
            print("Note: Navigate to your app → Xcode Cloud to find this build")
            print("Or search for build ID: \(build)")
        }
    }
}

// MARK: - App Store Connect API Client

struct AppStoreConnectClient {
    let keyID: String
    let issuerID: String
    let privateKey: String

    init() throws {
        // Try environment variables first
        if let keyID = ProcessInfo.processInfo.environment["ASC_KEY_ID"],
           let issuerID = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"] {
            self.keyID = keyID
            self.issuerID = issuerID

            // Private key can be content or path
            if let privateKeyContent = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY"] {
                self.privateKey = privateKeyContent
            } else if let privateKeyPath = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY_PATH"] {
                self.privateKey = try String(contentsOfFile: privateKeyPath)
            } else {
                throw AppStoreConnectError.missingCredentials("ASC_PRIVATE_KEY or ASC_PRIVATE_KEY_PATH")
            }
        } else {
            // Try macOS Keychain
            self.keyID = try Self.getFromKeychain(service: "ASC_API_KEY_ID")
            self.issuerID = try Self.getFromKeychain(service: "ASC_ISSUER_ID")
            let base64Key = try Self.getFromKeychain(service: "ASC_PRIVATE_KEY")

            guard let decodedKey = Data(base64Encoded: base64Key),
                  let keyString = String(data: decodedKey, encoding: .utf8) else {
                throw AppStoreConnectError.invalidPrivateKey
            }
            self.privateKey = keyString
        }
    }

    private static func getFromKeychain(service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: NSUserName(),
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw AppStoreConnectError.keychainError(service)
        }

        return value
    }

    func generateJWT() throws -> String {
        let header = Header(alg: "ES256", kid: keyID, typ: "JWT")
        let now = Int(Date().timeIntervalSince1970)
        let payload = Payload(
            iss: issuerID,
            iat: now,
            exp: now + 1200, // 20 minutes
            aud: "appstoreconnect-v1"
        )

        let headerData = try JSONEncoder().encode(header)
        let payloadData = try JSONEncoder().encode(payload)

        let headerB64 = headerData.base64URLEncoded()
        let payloadB64 = payloadData.base64URLEncoded()

        let message = "\(headerB64).\(payloadB64)"

        // Sign with ES256
        let privateKeyPEM = privateKey
        let signature = try signES256(message: message, privateKeyPEM: privateKeyPEM)
        let signatureB64 = signature.base64URLEncoded()

        return "\(message).\(signatureB64)"
    }

    private func signES256(message: String, privateKeyPEM: String) throws -> Data {
        // Parse PEM private key
        let key = try P256.Signing.PrivateKey(pemRepresentation: privateKeyPEM)

        // Sign message
        let messageData = Data(message.utf8)
        let signature = try key.signature(for: messageData)

        return signature.rawRepresentation
    }

    func request(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        let jwt = try generateJWT()
        let url = URL(string: "https://api.appstoreconnect.apple.com\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        // Dry run mode
        if ProcessInfo.processInfo.environment["XC_CLOUD_DRY_RUN"] != nil {
            print("[DRY RUN] \(method) \(url)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                print("Body: \(bodyString)")
            }
            return Data()
        }

        // Verbose mode
        if ProcessInfo.processInfo.environment["XC_CLOUD_VERBOSE"] != nil {
            print("[REQUEST] \(method) \(url)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreConnectError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = AppStoreConnectError.parseAPIError(from: data)
            throw AppStoreConnectError.httpError(httpResponse.statusCode, errorMsg)
        }

        return data
    }

    // API Methods

    func listProducts() async throws -> Data {
        try await request(endpoint: "/v1/ciProducts")
    }

    func listWorkflows(productID: String) async throws -> Data {
        try await request(endpoint: "/v1/ciProducts/\(productID)/workflows")
    }

    func triggerBuild(workflowID: String, gitReference: String) async throws -> Data {
        let body: [String: Any] = [
            "data": [
                "type": "ciBuildRuns",
                "relationships": [
                    "workflow": [
                        "data": [
                            "type": "ciWorkflows",
                            "id": workflowID
                        ]
                    ],
                    "sourceBranchOrTag": [
                        "data": [
                            "type": "scmGitReferences",
                            "id": gitReference
                        ]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        return try await request(endpoint: "/v1/ciBuildRuns", method: "POST", body: jsonData)
    }

    func getBuild(buildID: String) async throws -> Data {
        try await request(endpoint: "/v1/ciBuildRuns/\(buildID)")
    }

    func getRepositories(productID: String) async throws -> Data {
        try await request(endpoint: "/v1/ciProducts/\(productID)/relationships/primaryRepositories")
    }

    func getMacOSVersions() async throws -> Data {
        try await request(endpoint: "/v1/ciMacOsVersions")
    }

    func getXcodeVersions() async throws -> Data {
        try await request(endpoint: "/v1/ciXcodeVersions")
    }
}

// MARK: - JWT Models

struct Header: Codable {
    let alg: String
    let kid: String
    let typ: String
}

struct Payload: Codable {
    let iss: String
    let iat: Int
    let exp: Int
    let aud: String
}

// MARK: - API Response Models

struct ProductsResponse: Codable {
    let data: [Product]
}

struct Product: Codable {
    let id: String
    let type: String
    let attributes: ProductAttributes
}

struct ProductAttributes: Codable {
    let name: String
    let productType: String
}

struct WorkflowsResponse: Codable {
    let data: [Workflow]
}

struct Workflow: Codable {
    let id: String
    let type: String
    let attributes: WorkflowAttributes
}

struct WorkflowAttributes: Codable {
    let name: String
    let description: String?
    let isEnabled: Bool
}

struct BuildRunResponse: Codable {
    let data: BuildRun
}

struct BuildRun: Codable {
    let id: String
    let type: String
    let attributes: BuildRunAttributes
}

struct BuildRunAttributes: Codable {
    let executionProgress: String
    let createdDate: String
    let startedDate: String?
    let finishedDate: String?
}

struct RepositoriesResponse: Codable {
    let data: [Repository]
}

struct Repository: Codable {
    let id: String
    let type: String
}

struct MacOSVersionsResponse: Codable {
    let data: [MacOSVersion]
}

struct MacOSVersion: Codable {
    let id: String
    let type: String
    let attributes: MacOSVersionAttributes
}

struct MacOSVersionAttributes: Codable {
    let name: String
    let version: String
}

struct XcodeVersionsResponse: Codable {
    let data: [XcodeVersion]
}

struct XcodeVersion: Codable {
    let id: String
    let type: String
    let attributes: XcodeVersionAttributes
}

struct XcodeVersionAttributes: Codable {
    let name: String
    let version: String
}

struct WorkflowResponse: Codable {
    let data: WorkflowData
}

struct WorkflowData: Codable {
    let id: String
    let type: String
    let attributes: WorkflowAttributes
}

// MARK: - Errors

enum AppStoreConnectError: LocalizedError {
    case missingCredentials(String)
    case keychainError(String)
    case invalidPrivateKey
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials(let key):
            return "Missing required credential: \(key). Set environment variable or store in Keychain."
        case .keychainError(let service):
            return "Failed to retrieve '\(service)' from Keychain"
        case .invalidPrivateKey:
            return "Invalid private key format"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

struct ValidationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

// MARK: - Workflow Payload Builder

struct WorkflowPayloadBuilder {
    let name: String
    let description: String?
    let productID: String
    let repositoryID: String
    let macOSVersionID: String
    let xcodeVersionID: String
    let scheme: String
    let workflowType: WorkflowType
    let actionTypes: [WorkflowActionType]
    let branchPattern: String?
    let tagPattern: String?
    let enabled: Bool

    func buildPayload() -> [String: Any] {
        var attributes: [String: Any] = [
            "name": name,
            "description": description ?? "",
            "isEnabled": enabled,
            "isLockedForEditing": false,
            "clean": true,
            "containerFilePath": "Nestory-Pro.xcodeproj",
            "actions": buildActions()
        ]

        // Add start condition based on workflow type
        switch workflowType {
        case .pullRequest:
            attributes["pullRequestStartCondition"] = [
                "source": ["isAllMatch": true, "patterns": []],
                "autoCancel": true
            ]
        case .branch:
            attributes["branchStartCondition"] = [
                "source": [
                    "isAllMatch": false,
                    "patterns": [["pattern": branchPattern ?? "main", "isPrefix": false]]
                ],
                "filesAndFoldersRule": ["mode": "START_IF_ANY_FILE_MATCHES", "matchers": []],
                "autoCancel": true
            ]
        case .tag:
            let pattern = tagPattern ?? "v*"
            attributes["tagStartCondition"] = [
                "source": [
                    "isAllMatch": false,
                    "patterns": [["pattern": pattern, "isPrefix": pattern.hasSuffix("*")]]
                ],
                "autoCancel": true
            ]
        }

        return [
            "data": [
                "type": "ciWorkflows",
                "attributes": attributes,
                "relationships": [
                    "product": ["data": ["type": "ciProducts", "id": productID]],
                    "repository": ["data": ["type": "scmRepositories", "id": repositoryID]],
                    "macOsVersion": ["data": ["type": "ciMacOsVersions", "id": macOSVersionID]],
                    "xcodeVersion": ["data": ["type": "ciXcodeVersions", "id": xcodeVersionID]]
                ]
            ]
        ]
    }

    private func buildActions() -> [[String: Any]] {
        actionTypes.map { actionType in
            switch actionType {
            case .test:
                // Canonical test destination from golden workflow
                // Using "default" runtime = latest Xcode version
                let testDestination: [String: Any] = [
                    "kind": "SIMULATOR",
                    "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
                    "deviceTypeName": "iPhone 17 Pro Max",
                    "runtimeIdentifier": "default",
                    "runtimeName": "Latest from Selected Xcode (iOS 26.1)"
                ]

                return [
                    "name": "Test - iOS",
                    "actionType": "TEST",
                    "scheme": scheme,
                    "platform": "IOS",
                    "isRequiredToPass": true,
                    "testConfiguration": [
                        "kind": "USE_SCHEME_SETTINGS",
                        "testDestinations": [testDestination]
                    ] as [String: Any]
                ]
            case .archive:
                return [
                    "name": "Archive - iOS",
                    "actionType": "ARCHIVE",
                    "scheme": scheme,
                    "platform": "IOS",
                    "isRequiredToPass": true
                ]
            case .analyze:
                return [
                    "name": "Analyze",
                    "actionType": "ANALYZE",
                    "scheme": scheme,
                    "platform": "IOS",
                    "isRequiredToPass": false
                ]
            }
        }
    }
}

// MARK: - API Error Parsing

struct APIError: Codable {
    let errors: [ErrorDetail]

    struct ErrorDetail: Codable {
        let code: String
        let detail: String
        let source: Source?

        struct Source: Codable {
            let pointer: String?
        }
    }
}

extension AppStoreConnectError {
    static func parseAPIError(from data: Data) -> String {
        guard let apiError = try? JSONDecoder().decode(APIError.self, from: data) else {
            return String(data: data, encoding: .utf8) ?? "Unknown error"
        }

        return apiError.errors.map { error in
            var msg = "[\(error.code)] \(error.detail)"
            if let pointer = error.source?.pointer {
                msg += " (at \(pointer))"
            }
            return msg
        }.joined(separator: "\n")
    }
}

// MARK: - Base64 URL Encoding

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
