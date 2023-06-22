import SwiftCompilerPlugin
import AppKit
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// importing SwiftSyntax helps us manipulate source code.
// SwiftSyntax generates source code as syntax tree
// https://swift-ast-explorer.com/ for understanding syntax tree better

// Generates Custom errors
enum SFSymbolDiagnostic: DiagnosticMessage {
    case notEnum
    case notValidSymbol(symbol: String)
    case notStringRawValue
    
    var severity: DiagnosticSeverity { return .error }
    
    var message: String {
        switch self {
        case .notEnum:
            "@SFSymbol can only be applied on enum"
        case .notStringRawValue:
            "Enum should have String raw values"
        case .notValidSymbol(let symbol):
            "\"\(symbol)\" is not a valid SFSymbol."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "SFSymbolMacro", id: self.message)
    }
}

public struct SFSymbol: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // Check if declaration is enum
        // If not throw custom error
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                .init(node: Syntax(node), message: SFSymbolDiagnostic.notEnum)
            ])
        }
        // Check that enum's raw value is String
        // If not throw custom error
        guard enumDecl.inheritanceClause?.inheritedTypeCollection.contains(where: {
            $0.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "String"
        }) ?? false else {
            throw DiagnosticsError(diagnostics: [
                .init(node: Syntax(enumDecl.identifier), message: SFSymbolDiagnostic.notStringRawValue)
            ])
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecl = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecl.flatMap { $0.elements }
        
        // element is every case in syntax tree
        for element in elements {
            let segment = element.rawValue?.value.as(StringLiteralExprSyntax.self)?.segments.first
            // If enum has raw value use it, if not use it's title
            let value = segment?.as(StringSegmentSyntax.self)?.content.text ?? element.identifier.text
            // Check if there is SF symbol of given name
            // If not throw custom error
            guard let _ = NSImage(systemSymbolName: value, accessibilityDescription: nil) else {
                throw DiagnosticsError(diagnostics: [
                    .init(node: Syntax(element), message: SFSymbolDiagnostic.notValidSymbol(symbol: element.identifier.text))
                ])
            }
        }
        return ["""
                var image: Image {
                    Image(systemName: self.rawValue)
                }
                """,
                """
                var title: String {
                    self.rawValue
                }
                """]
    }
}

@main
struct SFSymbolPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SFSymbol.self,
    ]
}
