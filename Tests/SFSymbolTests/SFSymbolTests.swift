import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SFSymbolMacros

let testMacros: [String: Macro.Type] = [
    "SFSymbol": SFSymbol.self,
]

final class SFSymbolTests: XCTestCase {
    // Tests right sf symbol
    func testMacro() {
        assertMacroExpansion(
            """
            @SFSymbol
            enum Symbol: String {
                case heartFull = "heart.fill"
            }
            """,
            expandedSource: """
            enum Symbol: String {
                case heartFull = "heart.fill"
                var image: Image {
                    Image(systemName: self.rawValue)
                }
                var title: String {
                    self.rawValue
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // test invalid macro conformance type
    func testInvalidType() {
        assertMacroExpansion(
            """
            @SFSymbol
            struct Symbol {
                let dog = "dog"
            }
            """,
            expandedSource:
            """
            struct Symbol {
                let dog = "dog"
            }
            """,
            diagnostics: [
                .init(message: "@SFSymbol can only be applied on enum",
                      line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    // tests symbol that is not sf symbol
    func testInvalidSymbol() {
        assertMacroExpansion(
            """
            @SFSymbol
            enum Symbol: String {
                case profile
            }
            """,
            expandedSource:
            """
            enum Symbol: String {
                case profile
            }
            """,
            diagnostics: [
                .init(message: "\"profile\" is not a valid SFSymbol.",
                      line: 3, column: 10)
            ],
            macros: testMacros
        )
    }
    
    // tests that enum's raw value is String
    func testInvalidRawValue() {
        assertMacroExpansion(
            """
            @SFSymbol
            enum Symbol: Int {
                case profile
            }
            """,
            expandedSource:
            """
            enum Symbol: Int {
                case profile
            }
            """,
            diagnostics: [
                .init(message: "Enum should have String raw values",
                      line: 2, column: 6)
            ],
            macros: testMacros
        )
    }
}
