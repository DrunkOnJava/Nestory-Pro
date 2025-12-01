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
            GetBuild.self
        ]
    )
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
            abstract: "Create a new Xcode Cloud workflow"
        )

        @Option(name: .long, help: "Product ID")
        var product: String

        @Option(name: .long, help: "Workflow name")
        var name: String

        @Option(name: .long, help: "Workflow description")
        var description: String?

        @Flag(name: .long, help: "Enable workflow immediately")
        var enabled = true

        func run() async throws {
            let client = try AppStoreConnectClient()

            print("Creating workflow '\(name)' for product \(product)...")
            print("Note: Full workflow configuration requires additional API calls.")
            print("Use the App Store Connect API documentation for complete workflow setup.")

            // This is a simplified example - real workflow creation requires
            // relationships to repository, macOS version, Xcode version, etc.
            throw ValidationError("Workflow creation requires additional implementation. Use curl examples in docs/XCODE_CLOUD_CLI_SETUP.md")
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
            abstract: "Get build status"
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
            } else {
                let decoded = try JSONDecoder().decode(BuildRunResponse.self, from: buildData)
                let build = decoded.data

                print("Build \(build.id):")
                print("=================")
                print("Status: \(build.attributes.executionProgress)")
                print("Created: \(build.attributes.createdDate)")
                if let started = build.attributes.startedDate {
                    print("Started: \(started)")
                }
                if let finished = build.attributes.finishedDate {
                    print("Finished: \(finished)")
                }
            }
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
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
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

// MARK: - Base64 URL Encoding

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
