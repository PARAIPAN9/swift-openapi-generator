//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
@testable import _OpenAPIGeneratorCore

final class Test_TextBasedRenderer: XCTestCase {

    func testComment() throws {
        try _test(
            .inline(
                #"""
                Generated by foo

                Also, bar
                """#
            ),
            renderedBy: TextBasedRenderer.renderComment,
            rendersAs: #"""
                // Generated by foo
                //
                // Also, bar
                """#
        )
        try _test(
            .doc(
                #"""
                Generated by foo

                Also, bar
                """#
            ),
            renderedBy: TextBasedRenderer.renderComment,
            rendersAs: #"""
                /// Generated by foo
                ///
                /// Also, bar
                """#
        )
        try _test(
            .mark("Lorem ipsum", sectionBreak: false),
            renderedBy: TextBasedRenderer.renderComment,
            rendersAs: #"""
                // MARK: Lorem ipsum
                """#
        )
        try _test(
            .mark("Lorem ipsum", sectionBreak: true),
            renderedBy: TextBasedRenderer.renderComment,
            rendersAs: #"""
                // MARK: - Lorem ipsum
                """#
        )
        try _test(
            .inline(
                """
                Generated by foo\r\nAlso, bar
                """
            ),
            renderedBy: TextBasedRenderer.renderComment,
            rendersAs: #"""
                // Generated by foo
                // Also, bar
                """#
        )
    }

    func testImports() throws {
        try _test(nil, renderedBy: TextBasedRenderer.renderImports, rendersAs: "")
        try _test(
            [ImportDescription(moduleName: "Foo"), ImportDescription(moduleName: "Bar")],
            renderedBy: TextBasedRenderer.renderImports,
            rendersAs: #"""
                import Foo
                import Bar
                """#
        )
        try _test(
            [ImportDescription(moduleName: "Foo", spi: "Secret")],
            renderedBy: TextBasedRenderer.renderImports,
            rendersAs: #"""
                @_spi(Secret) import Foo
                """#
        )
        try _test(
            [ImportDescription(moduleName: "Foo", preconcurrency: .onOS(["Bar", "Baz"]))],
            renderedBy: TextBasedRenderer.renderImports,
            rendersAs: #"""
                #if os(Bar) || os(Baz)
                @preconcurrency import Foo
                #else
                import Foo
                #endif
                """#
        )
        try _test(
            [
                ImportDescription(moduleName: "Foo", preconcurrency: .always),
                ImportDescription(moduleName: "Bar", spi: "Secret", preconcurrency: .always),
            ],
            renderedBy: TextBasedRenderer.renderImports,
            rendersAs: #"""
                @preconcurrency import Foo
                @preconcurrency @_spi(Secret) import Bar
                """#
        )
    }

    func testAccessModifiers() throws {
        try _test(
            .public,
            renderedBy: TextBasedRenderer.renderedAccessModifier,
            rendersAs: #"""
                public
                """#
        )
        try _test(
            .internal,
            renderedBy: TextBasedRenderer.renderedAccessModifier,
            rendersAs: #"""
                internal
                """#
        )
        try _test(
            .fileprivate,
            renderedBy: TextBasedRenderer.renderedAccessModifier,
            rendersAs: #"""
                fileprivate
                """#
        )
        try _test(
            .private,
            renderedBy: TextBasedRenderer.renderedAccessModifier,
            rendersAs: #"""
                private
                """#
        )
    }

    func testLiterals() throws {
        try _test(
            .string("hi"),
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                "hi"
                """#
        )
        try _test(
            .string("this string: \"foo\""),
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                #"this string: "foo""#
                """#
        )
        try _test(
            .nil,
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                nil
                """#
        )
        try _test(
            .array([]),
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                []
                """#
        )
        try _test(
            .array([.literal(.nil)]),
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                [nil]
                """#
        )
        try _test(
            .array([.literal(.nil), .literal(.nil)]),
            renderedBy: TextBasedRenderer.renderLiteral,
            rendersAs: #"""
                [nil, nil]
                """#
        )
    }

    func testExpression() throws {
        try _test(
            .literal(.nil),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                nil
                """#
        )
        try _test(
            .identifierPattern("foo"),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                foo
                """#
        )
        try _test(
            .memberAccess(.init(left: .identifierPattern("foo"), right: "bar")),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                foo.bar
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifierPattern("callee"),
                    arguments: [.init(label: nil, expression: .identifierPattern("foo"))]
                )
            ),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                callee(foo)
                """#
        )
    }

    func testDeclaration() throws {
        try _test(
            .variable(.init(kind: .let, left: "foo")),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                let foo
                """#
        )
        try _test(
            .extension(.init(onType: "String", declarations: [])),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                extension String {
                }
                """#
        )
        try _test(
            .struct(.init(name: "Foo")),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                struct Foo {}
                """#
        )
        try _test(
            .protocol(.init(name: "Foo")),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                protocol Foo {}
                """#
        )
        try _test(
            .enum(.init(name: "Foo")),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                enum Foo {}
                """#
        )
        try _test(
            .typealias(.init(name: "foo", existingType: .member(["Foo", "Bar"]))),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                typealias foo = Foo.Bar
                """#
        )
        try _test(
            .function(FunctionDescription.init(kind: .function(name: "foo"), body: [])),
            renderedBy: TextBasedRenderer.renderDeclaration,
            rendersAs: #"""
                func foo() {}
                """#
        )
    }

    func testFunctionKind() throws {
        try _test(
            .initializer,
            renderedBy: TextBasedRenderer.renderedFunctionKind,
            rendersAs: #"""
                init
                """#
        )
        try _test(
            .function(name: "funky"),
            renderedBy: TextBasedRenderer.renderedFunctionKind,
            rendersAs: #"""
                func funky
                """#
        )
        try _test(
            .function(name: "funky", isStatic: true),
            renderedBy: TextBasedRenderer.renderedFunctionKind,
            rendersAs: #"""
                static func funky
                """#
        )
    }

    func testFunctionKeyword() throws {
        try _test(
            .throws,
            renderedBy: TextBasedRenderer.renderedFunctionKeyword,
            rendersAs: #"""
                throws
                """#
        )
        try _test(
            .async,
            renderedBy: TextBasedRenderer.renderedFunctionKeyword,
            rendersAs: #"""
                async
                """#
        )
    }

    func testParameter() throws {
        try _test(
            .init(label: "l", name: "n", type: .member("T"), defaultValue: .literal(.nil)),
            renderedBy: TextBasedRenderer.renderParameter,
            rendersAs: #"""
                l n: T = nil
                """#
        )
        try _test(
            .init(label: nil, name: "n", type: .member("T"), defaultValue: .literal(.nil)),
            renderedBy: TextBasedRenderer.renderParameter,
            rendersAs: #"""
                _ n: T = nil
                """#
        )
        try _test(
            .init(label: "l", name: nil, type: .member("T"), defaultValue: .literal(.nil)),
            renderedBy: TextBasedRenderer.renderParameter,
            rendersAs: #"""
                l: T = nil
                """#
        )
        try _test(
            .init(label: nil, name: nil, type: .member("T"), defaultValue: .literal(.nil)),
            renderedBy: TextBasedRenderer.renderParameter,
            rendersAs: #"""
                _: T = nil
                """#
        )
        try _test(
            .init(label: nil, name: nil, type: .member("T"), defaultValue: nil),
            renderedBy: TextBasedRenderer.renderParameter,
            rendersAs: #"""
                _: T
                """#
        )
    }

    func testFunction() throws {
        try _test(
            .init(accessModifier: .public, kind: .function(name: "f"), parameters: [], body: []),
            renderedBy: TextBasedRenderer.renderFunction,
            rendersAs: #"""
                public func f() {}
                """#
        )
        try _test(
            .init(
                accessModifier: .public,
                kind: .function(name: "f"),
                parameters: [.init(label: "a", name: "b", type: .member("C"), defaultValue: nil)],
                body: []
            ),
            renderedBy: TextBasedRenderer.renderFunction,
            rendersAs: #"""
                public func f(a b: C) {}
                """#
        )
        try _test(
            .init(
                accessModifier: .public,
                kind: .function(name: "f"),
                parameters: [
                    .init(label: "a", name: "b", type: .member("C"), defaultValue: nil),
                    .init(label: nil, name: "d", type: .member("E"), defaultValue: .literal(.string("f"))),
                ],
                body: []
            ),
            renderedBy: TextBasedRenderer.renderFunction,
            rendersAs: #"""
                public func f(
                    a b: C,
                    _ d: E = "f"
                ) {}
                """#
        )
        try _test(
            .init(
                kind: .function(name: "f"),
                parameters: [],
                keywords: [.async, .throws],
                returnType: .identifierType(TypeName.string)
            ),
            renderedBy: TextBasedRenderer.renderFunction,
            rendersAs: #"""
                func f() async throws -> Swift.String
                """#
        )
    }

    func testIdentifiers() throws {
        try _test(
            .pattern("foo"),
            renderedBy: TextBasedRenderer.renderedIdentifier,
            rendersAs: #"""
                foo
                """#
        )
    }

    func testMemberAccess() throws {
        try _test(
            .init(left: .identifierPattern("foo"), right: "bar"),
            renderedBy: TextBasedRenderer.renderMemberAccess,
            rendersAs: #"""
                foo.bar
                """#
        )
        try _test(
            .init(left: nil, right: "bar"),
            renderedBy: TextBasedRenderer.renderMemberAccess,
            rendersAs: #"""
                .bar
                """#
        )
    }

    func testFunctionCallArgument() throws {
        try _test(
            .init(label: "foo", expression: .identifierPattern("bar")),
            renderedBy: TextBasedRenderer.renderFunctionCallArgument,
            rendersAs: #"""
                foo: bar
                """#
        )
        try _test(
            .init(label: nil, expression: .identifierPattern("bar")),
            renderedBy: TextBasedRenderer.renderFunctionCallArgument,
            rendersAs: #"""
                bar
                """#
        )
    }

    func testFunctionCall() throws {
        try _test(
            .functionCall(.init(calledExpression: .identifierPattern("callee"))),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                callee()
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifierPattern("callee"),
                    arguments: [.init(label: "foo", expression: .identifierPattern("bar"))]
                )
            ),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                callee(foo: bar)
                """#
        )
        try _test(
            .functionCall(
                .init(
                    calledExpression: .identifierPattern("callee"),
                    arguments: [
                        .init(label: "foo", expression: .identifierPattern("bar")),
                        .init(label: "baz", expression: .identifierPattern("boo")),
                    ]
                )
            ),
            renderedBy: TextBasedRenderer.renderExpression,
            rendersAs: #"""
                callee(
                    foo: bar,
                    baz: boo
                )
                """#
        )
    }

    func testExtension() throws {
        try _test(
            .init(
                accessModifier: .public,
                onType: "Info",
                declarations: [.variable(.init(kind: .let, left: "foo", type: .member("Int")))]
            ),
            renderedBy: TextBasedRenderer.renderExtension,
            rendersAs: #"""
                public extension Info {
                    let foo: Int
                }
                """#
        )
    }

    func testDeprecation() throws {
        try _test(
            .init(),
            renderedBy: TextBasedRenderer.renderDeprecation,
            rendersAs: #"""
                @available(*, deprecated)
                """#
        )
        try _test(
            .init(message: "some message"),
            renderedBy: TextBasedRenderer.renderDeprecation,
            rendersAs: #"""
                @available(*, deprecated, message: "some message")
                """#
        )
        try _test(
            .init(renamed: "newSymbol(param:)"),
            renderedBy: TextBasedRenderer.renderDeprecation,
            rendersAs: #"""
                @available(*, deprecated, renamed: "newSymbol(param:)")
                """#
        )
        try _test(
            .init(message: "some message", renamed: "newSymbol(param:)"),
            renderedBy: TextBasedRenderer.renderDeprecation,
            rendersAs: #"""
                @available(*, deprecated, message: "some message", renamed: "newSymbol(param:)")
                """#
        )
    }

    func testBindingKind() throws {
        try _test(
            .var,
            renderedBy: TextBasedRenderer.renderedBindingKind,
            rendersAs: #"""
                var
                """#
        )
        try _test(
            .let,
            renderedBy: TextBasedRenderer.renderedBindingKind,
            rendersAs: #"""
                let
                """#
        )
    }

    func testVariable() throws {
        try _test(
            .init(
                accessModifier: .public,
                isStatic: true,
                kind: .let,
                left: "foo",
                type: .init(TypeName.string),
                right: .literal(.string("bar"))
            ),
            renderedBy: TextBasedRenderer.renderVariable,
            rendersAs: #"""
                public static let foo: Swift.String = "bar"
                """#
        )
        try _test(
            .init(accessModifier: .internal, isStatic: false, kind: .var, left: "foo", type: nil, right: nil),
            renderedBy: TextBasedRenderer.renderVariable,
            rendersAs: #"""
                internal var foo
                """#
        )
        try _test(
            .init(
                kind: .var,
                left: "foo",
                type: .init(TypeName.int),
                getter: [CodeBlock.expression(.literal(.int(42)))]
            ),
            renderedBy: TextBasedRenderer.renderVariable,
            rendersAs: #"""
                var foo: Swift.Int {
                    42
                }
                """#
        )
        try _test(
            .init(
                kind: .var,
                left: "foo",
                type: .init(TypeName.int),
                getter: [CodeBlock.expression(.literal(.int(42)))],
                getterEffects: [.throws]
            ),
            renderedBy: TextBasedRenderer.renderVariable,
            rendersAs: #"""
                var foo: Swift.Int {
                    get throws {
                        42
                    }
                }
                """#
        )
    }

    func testStruct() throws {
        try _test(
            .init(name: "Structy"),
            renderedBy: TextBasedRenderer.renderStruct,
            rendersAs: #"""
                struct Structy {}
                """#
        )
    }

    func testProtocol() throws {
        try _test(
            .init(name: "Protocoly"),
            renderedBy: TextBasedRenderer.renderProtocol,
            rendersAs: #"""
                protocol Protocoly {}
                """#
        )
    }

    func testEnum() throws {
        try _test(
            .init(name: "Enumy"),
            renderedBy: TextBasedRenderer.renderEnum,
            rendersAs: #"""
                enum Enumy {}
                """#
        )
    }

    func testCodeBlockItem() throws {
        try _test(
            .declaration(.variable(.init(kind: .let, left: "foo"))),
            renderedBy: TextBasedRenderer.renderCodeBlockItem,
            rendersAs: #"""
                let foo
                """#
        )
        try _test(
            .expression(.literal(.nil)),
            renderedBy: TextBasedRenderer.renderCodeBlockItem,
            rendersAs: #"""
                nil
                """#
        )
    }

    func testCodeBlock() throws {
        try _test(
            .init(comment: .inline("- MARK: Section"), item: .declaration(.variable(.init(kind: .let, left: "foo")))),
            renderedBy: TextBasedRenderer.renderCodeBlock,
            rendersAs: #"""
                // - MARK: Section
                let foo
                """#
        )
        try _test(
            .init(comment: nil, item: .declaration(.variable(.init(kind: .let, left: "foo")))),
            renderedBy: TextBasedRenderer.renderCodeBlock,
            rendersAs: #"""
                let foo
                """#
        )
    }

    func testTypealias() throws {
        try _test(
            .init(name: "inty", existingType: .member("Int")),
            renderedBy: TextBasedRenderer.renderTypealias,
            rendersAs: #"""
                typealias inty = Int
                """#
        )
        try _test(
            .init(accessModifier: .private, name: "inty", existingType: .member("Int")),
            renderedBy: TextBasedRenderer.renderTypealias,
            rendersAs: #"""
                private typealias inty = Int
                """#
        )
    }

    func testFile() throws {
        try _test(
            .init(
                topComment: .inline("hi"),
                imports: [.init(moduleName: "Foo")],
                codeBlocks: [.init(comment: nil, item: .declaration(.struct(.init(name: "Bar"))))]
            ),
            renderedBy: TextBasedRenderer.renderFile,
            rendersAs: #"""
                // hi
                import Foo
                struct Bar {}

                """#
        )
    }
}

extension Test_TextBasedRenderer {

    func _test<Input>(
        _ input: Input,
        renderedBy renderClosure: (TextBasedRenderer) -> ((Input) -> String),
        rendersAs output: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let renderer = TextBasedRenderer.default
        XCTAssertEqual(renderClosure(renderer)(input), output, file: file, line: line)
    }

    func _test<Input>(
        _ input: Input,
        renderedBy renderClosure: (TextBasedRenderer) -> ((Input) -> Void),
        rendersAs output: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try _test(
            input,
            renderedBy: { renderer in let closure = renderClosure(renderer)
                return { input in closure(input)
                    return renderer.renderedContents()
                }
            },
            rendersAs: output
        )
    }
}
