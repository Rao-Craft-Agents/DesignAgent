# DesignAgent reference

How the `design` agent is found, what a call takes and answers, the lines it reads, how each file is made, and how to
test it. What it is for is in the [README](../README.md); the agent standard it follows is Granite's
[granite-agent/1](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md).

## How an app finds it

DesignAgent is a `GraniteAgentPackage`, and it carries a record in its binary:

```swift
@used @section("__DATA_CONST,__granite")
let designRecord: GraniteRoster.Record = { GraniteRoster.record(DesignAgent.self) }
```

In [Craft](https://github.com/riteshpakala/Craft), install it from the Agent Store or with
`craft agents add https://github.com/Rao-Craft-Agents/DesignAgent.git`, then say `$design` in a request:

```
$design the recipe app's look: a cream page, ink text, basil for the accent and tomato for danger,
a serif large title, rounded cards, and the card and section styles
```

The model writes the lines; the call shows on Craft's agent map as `design-1`, and the files it names are built and
tested with the turn.

## What a call takes and answers

| Field | | |
|---|---|---|
| `into` | optional | the folder, relative to the project; `Shared/Design` when left out |
| `name` | optional | the brand's name; the project's when left out |
| `palette` | optional | one line a colour: `cream: #FBF7F0/#1A1714`, `saffron: #E8A33D`, `ink: brandInk` (a colour set) |
| `roles` | optional | one line a role: `background = cream`, `secondaryForeground = ink 60%`, `highlight = saffron` |
| `spacing` | optional | the layers in points, smallest first; Loom's `[4, 8, 12, 16, 24, 32]` when left out |
| `radii` | optional | one line a radius: `card: 14` |
| `type` | optional | one line a style: `title: 28 bold rounded`, `code: 13 medium monospaced footnote` |
| `fonts` | optional | font files or folders of them (.ttf, .otf, .ttc), relative to the project |
| `gradients` | optional | one line a gradient: `sunrise: saffron tomato`, `dusk: #2B2522 #6B4E71 vertical` |
| `modifiers` | optional | true to also write `.cardStyle()`, `.sectionStyle()` and `.brandBackground()` |
| `directory` | the host's | the folder the host works in; a host fills it and does not show it to a model |

The answer is a `DesignResult`: every file written (`path`, `paths`, absolute, the copied fonts included), the names
views write (`colors`, `roles` with what each reads, `layers`, `radii`, `type`, `gradients`), the font `faces`, and a
sentence for anything the call should know.

## The lines

```
palette    cream: #FBF7F0/#1A1714          light/dark
           saffron "the spice jar": #E8A33D   one for both, with a doc
           ink: brandInk                     a colour set of the project's asset catalogs
           scrim: #000000 40%                any of them, less opaque
roles      background = cream
           secondaryForeground = ink 60%
           accent = #3F7D58/#6FBF8E
           highlight = saffron "a recipe someone starred"
type       title: 28 bold rounded            size, weight, design, `italic`, text style, in any order
           display: 44 heavy                 scales with the style nearest its size (largeTitle)
radii      card: 14
gradients  sunrise: saffron tomato vertical
```

- A name is said as a person says it (`brand blue`, `brand-blue`) and written as Swift says it (`brandBlue`); `:` and
  `=` read the same.
- A role left out reads, in order, the asset catalog's colour set of its name (`colors/background`, namespaces kept;
  `AccentColor` is the accent, as Xcode names it), the palette colour of its name, then the platform's own
  (`systemBackground` on iOS, `windowBackgroundColor` on macOS). The roles every design has: `background`,
  `secondaryBackground`, `tertiaryBackground`, `alternateBackground`, `foreground`, `secondaryForeground`, `accent`,
  `separator`, `success`, `warning`, `danger`.
- Radii and the type scale start from four radii (small 4, medium 8, card 12, large 16) and Apple's text styles; a line
  of a name they have changes it, any other adds to them.
- A line it cannot read, a colour set or a font file it cannot find, is refused with the reason, every one at once,
  and nothing is written.

## How the files are made

| File | What |
|---|---|
| `Brand.swift` | `enum Brand`: the name, `Brand.Colors`, `Brand.Gradients`, and `Brand.color(_:)` / `Brand.color(light:dark:)`: hex written as its value, a light/dark pair as a dynamic UIColor or NSColor picked as the system draws |
| `Brand.Color.swift` | the roles as `Color` members, each reading the palette, the asset catalog or the platform |
| `Style.swift` | `.layer1…` on `CGFloat`; `Brand.Radius`, `Brand.Stroke`, `Brand.Shadow` (darker in dark), `Brand.Motion`, `Brand.Metrics` (`#if os(macOS)` sidebar and window sizes); the type scale as `Font.brandTitle…`, never hiding SwiftUI's `Font.title` |
| `Fonts/Fonts.swift` | `Font.brand(_:size:relativeTo:)`. With font files: they are read with CoreText for their real PostScript names and weights, copied beside it, registered from the app's bundle on first use (`CTFontManagerRegisterFontsForURL`), and each weight drawn by the nearest face as CSS matches weights, a `serif` or `monospaced` style by a family of that kind. Without: the system's face in the style's design, at the text style's size |
| `View+Style.swift` | when asked, in the `Extensions` folder beside the design's: `.cardStyle()`, `.sectionStyle()`, `.brandBackground()` from the tokens |
| Check | every file staged, parsed with `swiftc -parse`, then moved into the project with the font files, whole or nothing |

Two things it reads of the project so the code builds the first time: when an Xcode project turns on Swift asset symbol
extensions, Xcode writes `Color.accent` from an `AccentColor` set itself, so that role is left to it (a line against it
is refused); and another file that declares `Brand`, a `.layer`, a role or `Font.brand` is named in a note.

No model is asked: the same lines make the same files every time.

## Testing

```
swift test                    # the record, the schema, the lines, the files, the project read, a call through the roster
DESIGN_BUILD=1 swift test     # three designs (hex with fonts, an asset catalog, Xcode's asset symbols) built for macOS
                              # and the iOS simulator in Swift 6 and 5, and run: each colour drawn in light and dark,
                              # the fonts registered from the bundle
```
