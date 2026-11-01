import Foundation
@testable import DesignAgent

/// A package around a design, the way an app holds one: the design in Shared/Design, the modifiers in
/// Shared/Extensions, a view in Shared/Views that uses every token the design has, and a program that checks on macOS
/// what the colours and fonts do. Built with `swift build` for macOS and `xcodebuild` for the iOS simulator.
struct SamplePackage {
    let folder: URL
    /// What the target ships besides its Swift: the font files, the asset catalog.
    var resources: [String] = []
    /// The Swift language mode the target builds in: 5 or 6.
    var mode = 6

    init(folder: URL) { self.folder = folder }

    /// Writes Package.swift for `mode`.
    func writeManifest() throws {
        let listed = resources.map { #".process("\#($0)")"# }.joined(separator: ", ")
        try Fixture.write("""
            // swift-tools-version:6.0
            import PackageDescription

            let package = Package(
                name: "Sample",
                platforms: [.macOS(.v14), .iOS(.v17)],
                products: [.library(name: "Sample", targets: ["Sample"])],
                targets: [
                    .target(name: "Sample", path: "Shared", resources: [\(listed)],
                            swiftSettings: [.swiftLanguageMode(.v\(mode))]),
                    .executableTarget(name: "Check", dependencies: ["Sample"], path: "Check",
                                      swiftSettings: [.swiftLanguageMode(.v\(mode))]),
                ]
            )
            """, to: folder.appendingPathComponent("Package.swift"))
    }

    /// Shared/Views/DesignGallery.swift: a view that uses every token `result` names, and the ones every design has.
    func writeGallery(_ result: DesignResult, modifiers: Bool, fonts: Bool) throws {
        let roles = result.roles.map { String($0.prefix { $0 != " " }) }
        var rows: [String] = []
        rows.append("Text(Brand.name).font(.brandLargeTitle)")
        rows.append("HStack(spacing: .layer1) {\n" + roles.map { "                    swatch(Color.\($0))" }.joined(separator: "\n") + "\n                }")
        if !result.colors.isEmpty {
            rows.append("HStack(spacing: .layer2) {\n" + result.colors.map { "                    swatch(Brand.Colors.\($0))" }.joined(separator: "\n") + "\n                }")
        }
        for gradient in result.gradients {
            rows.append("Rectangle().fill(Brand.Gradients.\(gradient)).frame(height: .layer\(result.layers.count))")
        }
        for (index, style) in result.type.enumerated() {
            rows.append("Text(\"The quick brown fox, \(index)\").font(.\(style))")
        }
        rows.append("Text(\"Spice\").font(.brand(.semibold, size: 15, relativeTo: .subheadline, design: .monospaced, italic: true))")
        for radius in result.radii {
            rows.append("RoundedRectangle(cornerRadius: Brand.Radius.\(radius), style: .continuous).stroke(Color.separator, lineWidth: Brand.Stroke.regular).frame(height: .layer\(result.layers.count))")
        }
        rows.append("Divider().frame(height: Brand.Stroke.hairline).overlay(Color.separator)")
        rows.append("Capsule().strokeBorder(Color.accent, lineWidth: Brand.Stroke.bold).frame(width: Brand.Metrics.sidebarWidth, height: .layer5)")
        rows.append("Text(\"Lifted\").padding(.layer3).background(Color.secondaryBackground).shadow(Brand.Shadow.card).shadow(Brand.Shadow.raised)")
        rows.append("Button(\"Show more\") { expanded.toggle() }.foregroundStyle(Color.accent)")
        rows.append("Image(systemName: \"star.fill\").foregroundStyle(Color.highlightOrAccent).accessibilityLabel(Text(\"Starred\"))")
        if modifiers {
            rows.append("Text(\"A card\").cardStyle()")
            rows.append("Text(\"A section\").sectionStyle()")
        }
        for index in result.layers.indices { rows.append("Color.clear.frame(height: .layer\(index + 1))") }
        let highlight = roles.contains("highlight") ? "highlight" : "accent"
        try Fixture.write("""
            import SwiftUI

            /// Every token of the design on one page, in the light and the dark appearance.
            struct DesignGallery: View {
                @State private var expanded = false

                var body: some View {
                    ScrollView {
                        VStack(alignment: .leading, spacing: .layer4) {
                            \(rows.joined(separator: "\n                "))
                        }
                        .padding(.layer4)
                        .frame(maxWidth: Brand.Metrics.readableWidth)
                        .foregroundStyle(Color.foreground)
                    }
                    .\(modifiers ? "brandBackground()" : "background(Color.background)")
                    .animation(.easeInOut(duration: expanded ? Brand.Motion.standard : Brand.Motion.quick), value: expanded)
                    .transaction { $0.animation = $0.animation ?? .easeOut(duration: Brand.Motion.slow) }
                    #if os(macOS)
                    .frame(minWidth: Brand.Metrics.minWindowWidth, minHeight: Brand.Metrics.minWindowHeight)
                    #endif
                }

                private func swatch(_ color: Color) -> some View {
                    RoundedRectangle(cornerRadius: Brand.Radius.small, style: .continuous)
                        .fill(color)
                        .frame(width: .layer\(result.layers.count), height: .layer\(result.layers.count))
                }
            }

            /// Both appearances side by side.
            struct DesignGalleryPair: View {
                var body: some View {
                    HStack(spacing: 0) {
                        DesignGallery().environment(\\.colorScheme, .light)
                        DesignGallery().environment(\\.colorScheme, .dark)
                    }
                }
            }

            extension Color {
                /// The gallery's star: the design's highlight, or its accent.
                static var highlightOrAccent: Color { Color.\(highlight) }
            }
            """ + (fonts ? "\n\n/// The fonts, registered at launch as an app would.\nenum GalleryLaunch {\n    static func start() { Fonts.register() }\n}\n" : "\n"),
            to: folder.appendingPathComponent("Shared/Views/DesignGallery.swift"))
    }

    /// Check/main.swift: `body`, then `ok`.
    func writeCheck(_ body: String) throws {
        try Fixture.write("""
            import AppKit
            import SwiftUI
            @testable import Sample

            /// `color` as the system draws it in `appearance`: `#RRGGBB`, and the alpha when it is not opaque.
            func drawn(_ color: Color, _ appearance: NSAppearance.Name) -> String {
                var text = ""
                NSAppearance(named: appearance)!.performAsCurrentDrawingAppearance {
                    let resolved = NSColor(color).usingColorSpace(.sRGB)!
                    func byte(_ value: CGFloat) -> Int { Int((value * 255).rounded()) }
                    text = String(format: "#%02X%02X%02X", byte(resolved.redComponent), byte(resolved.greenComponent), byte(resolved.blueComponent))
                    if resolved.alphaComponent < 0.999 { text += String(format: " %.2f", resolved.alphaComponent) }
                }
                return text
            }

            /// `color` as SwiftUI resolves it in an environment of `scheme`.
            func resolved(_ color: Color, _ scheme: ColorScheme) -> String {
                var environment = EnvironmentValues()
                environment.colorScheme = scheme
                let value = color.resolve(in: environment)
                func byte(_ value: Float) -> Int { Int((value * 255).rounded()) }
                var text = String(format: "#%02X%02X%02X", byte(value.red), byte(value.green), byte(value.blue))
                if value.opacity < 0.999 { text += String(format: " %.2f", value.opacity) }
                return text
            }

            func expect(_ value: String, _ wanted: String, _ what: String) {
                if value != wanted { print("FAIL \\(what): \\(value), not \\(wanted)"); exit(1) }
            }

            \(body)
            print("ok")
            """, to: folder.appendingPathComponent("Check/main.swift"))
    }

    /// `swift build` for macOS: the log, and whether it built.
    func buildForMac() throws -> (Bool, String) {
        try Self.run(["swift", "build", "--package-path", folder.path], in: folder)
    }

    /// `swift run Check`: the log, and whether it printed `ok` last.
    func runCheck() throws -> (Bool, String) {
        let (built, log) = try Self.run(["swift", "run", "--package-path", folder.path, "Check"], in: folder)
        return (built && log.hasSuffix("ok\n"), log)
    }

    /// `xcodebuild` for `destination`, with `settings` on the command line.
    func xcodebuild(_ destination: String, settings: [String] = [], derived: String) throws -> (Bool, String) {
        try Self.run(["xcodebuild", "-scheme", "Sample", "-destination", destination, "-derivedDataPath", folder.appendingPathComponent(derived).path,
                      "-skipPackagePluginValidation", "-skipMacroValidation", "CODE_SIGNING_ALLOWED=NO"] + settings + ["build"], in: folder)
    }

    /// Runs `arguments` in `folder`: whether it exited 0, and what it said (the last lines, when long).
    static func run(_ arguments: [String], in folder: URL) throws -> (Bool, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = folder
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let log = String(decoding: data, as: UTF8.self)
        let errors = log.split(separator: "\n").filter { $0.contains("error:") }.prefix(20).joined(separator: "\n")
        return (process.terminationStatus == 0, errors.isEmpty ? String(log.suffix(3_000)) : errors + "\n" + String(log.suffix(1_500)))
    }
}
