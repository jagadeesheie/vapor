import XCTest
@testable import Vapor
import HTTP
import Transport

class ProviderTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testPrecedence", testPrecedence),
        ("testOverride", testOverride),
        ("testInitialized", testInitialized),
        ("testProviderRepository", testProviderRepository),
        ("testCheckoutsDirectory", testCheckoutsDirectory),
    ]

    func testBasic() throws {
        var config = Config([:])
        try config.addProvider(FastServerProvider.self)
        let drop = try Droplet(config)

        XCTAssert(type(of: drop.server) is ServerFactory<FastServer>.Type)
    }

    func testPrecedence() throws {
        var config = Config([:])
        config.override(console: DebugConsole())
        try config.addProvider(FastServerProvider.self)
        
        let drop = try Droplet(config)
        XCTAssert(type(of: drop.server) is ServerFactory<FastServer>.Type)
    }

    func testOverride() throws {
        var config = Config([:])
        config.override(console: DebugConsole())
        try config.addProvider(SlowServerProvider.self)
        try config.addProvider(FastServerProvider.self)
        
        let drop = try Droplet(config)
        XCTAssert(type(of: drop.server) is ServerFactory<FastServer>.Type)
    }

    func testInitialized() throws {
        var config = Config([:])
        let fast = try FastServerProvider(config: &config)
        let slow = try SlowServerProvider(config: &config)

        config.arguments = ["vapor", "serve"]
        try config.addProvider(fast)
        try config.addProvider(slow)
        config.override(console: DebugConsole())
        let drop = try Droplet(config)
        
        XCTAssert(type(of: drop.server) is ServerFactory<SlowServer>.Type)

        XCTAssertEqual(fast.beforeRunFlag, false)
        XCTAssertEqual(slow.beforeRunFlag, false)

        background {
            try! drop.runCommands()
        }

        drop.console.wait(seconds: 1)
        XCTAssertEqual(slow.beforeRunFlag, true)
        XCTAssertEqual(fast.beforeRunFlag, true)
    }

    func testProviderRepository() {
        XCTAssertEqual(FastServerProvider.repositoryName, "tests-provider")
    }

    func testCheckoutsDirectory() {
        XCTAssertNil(FastServerProvider.resourcesDir)
        XCTAssertNil(FastServerProvider.viewsDir)
    }
    
    func testDoubleBoot() throws {
        var config = Config([:])
        try config.addProvider(SlowServerProvider.self)
        try config.addProvider(FastServerProvider.self)
        try config.addProvider(FastServerProvider.self)
        
        let drop = try Droplet(config)
        XCTAssertEqual(drop.config.providers.count, 2)
        XCTAssert(type(of: drop.server) is ServerFactory<FastServer>.Type)
    }
}

// MARK: Utility

// Fast

private final class FastServer: ServerProtocol {
    var host: String
    var port: Int
    var securityLayer: SecurityLayer


    init(hostname: String, port: Transport.Port, _ securityLayer: SecurityLayer) throws {
        host = hostname
        self.port = Int(port)
        self.securityLayer = securityLayer
    }

    func start(
        _ responder: Responder,
        errors: @escaping ServerErrorHandler
    ) throws {
        while true { }
    }
}

private final class FastServerProvider: Provider {
    var beforeRunFlag = false

    init(config: inout Configs.Config) throws {
    }
    
    func boot(_ config: inout Config) throws {
        config.override(server: ServerFactory<FastServer>())
    }

    func beforeRun(_ drop: Droplet) {
        beforeRunFlag = true
    }

    func boot(_ drop: Droplet) {

    }
}

// Slow

private final class SlowServer: ServerProtocol {
    var host: String
    var port: Int
    var securityLayer: SecurityLayer


    init(hostname: String, port: Transport.Port, _ securityLayer: SecurityLayer) throws {
        host = hostname
        self.port = Int(port)
        self.securityLayer = securityLayer
    }

    func start(
        _ responder: Responder,
        errors: @escaping ServerErrorHandler
    ) throws {
        while true { }
    }
}

private final class SlowServerProvider: Provider {
    var afterInitFlag = false
    var beforeRunFlag = false

    init(config: inout Configs.Config) throws {
        
    }

    func afterInit(_ drop: Droplet) {
        afterInitFlag = true
    }

    func beforeRun(_ drop: Droplet) {
        beforeRunFlag = true
    }
    
    func boot(_ config: inout Config) throws {
        config.override(server: ServerFactory<SlowServer>())
    }

    func boot(_ drop: Droplet) {
        
    }
}
