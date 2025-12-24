import XCTest
@testable import KeyLogger

final class KeyLoggerTests: XCTestCase {
    
    func testKeyCodeMapper() {
        XCTAssertEqual(KeyCodeMapper.keyName(for: 0), "A")
        XCTAssertEqual(KeyCodeMapper.keyName(for: 1), "S")
        XCTAssertEqual(KeyCodeMapper.keyName(for: 36), "Return")
        XCTAssertEqual(KeyCodeMapper.keyName(for: 49), "Space")
    }
    
    func testModifierFlagsDescription() {
        let cmdShift = ModifierFlags([.command, .shift])
        XCTAssertEqual(cmdShift.description, "⇧⌘")
        
        let ctrlOpt = ModifierFlags([.control, .option])
        XCTAssertEqual(ctrlOpt.description, "⌃⌥")
    }
    
    func testModifierFlagsIsShortcut() {
        let cmd = ModifierFlags([.command])
        XCTAssertTrue(cmd.isShortcut)
        
        let shiftOnly = ModifierFlags([.shift])
        XCTAssertFalse(shiftOnly.isShortcut)
    }
    
    func testKeyEventDisplayString() {
        let event = KeyEvent(
            id: nil,
            timestamp: Date(),
            keyCode: 8,
            keyName: "C",
            modifiers: ModifierFlags.command.rawValue,
            isShortcut: true,
            appName: "Finder",
            appBundleId: "com.apple.finder"
        )
        
        XCTAssertEqual(event.displayString, "⌘C")
    }
    
    func testIsModifierKey() {
        XCTAssertTrue(KeyCodeMapper.isModifierKey(55))  // Command
        XCTAssertTrue(KeyCodeMapper.isModifierKey(56))  // Shift
        XCTAssertFalse(KeyCodeMapper.isModifierKey(0))  // A
        XCTAssertFalse(KeyCodeMapper.isModifierKey(36)) // Return
    }
}
