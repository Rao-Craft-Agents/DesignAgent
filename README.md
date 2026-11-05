# DesignAgent

Give an app a design system its views can read from the first screen. Say the brand's colours, the roles they play,
its spacing, corners, type and fonts the way you would jot them down, and `design` writes them as Swift in the shape
[Loom](https://github.com/riteshpakala/Loom) keeps its design. Colours switch with light and dark, every type style
follows Dynamic Type, and the code builds for iOS 17 and macOS 14 in Swift 5 and Swift 6.

## What you can ask

```
$design the recipe app's look: a cream page, ink text, basil for the accent and tomato for danger
$design a serif large title, rounded cards, and the card and section styles
$design the fonts in Resources/Fonts, with a bold title and a monospaced code style
$design the colours from the asset catalog, and a sunrise gradient from saffron to tomato
```

Craft's model writes the lines; the call shows on Craft's agent map, and the files it names are built and tested with
the turn.

## What you get

- **Brand colours and the roles views read.** `Brand.Colors.cream` for each colour, and `Color.background`,
  `Color.foreground`, `Color.accent`, `Color.danger` and the other roles, each switching with the appearance.
- **Spacing, corners and depth.** Spacing layers (`.padding(.layer4)`), radii, strokes, shadows that are darker in
  dark, motion durations and Mac window sizes.
- **A type scale.** `.font(.brandTitle)` and the rest of the scale, each following Dynamic Type, without hiding
  SwiftUI's own `Font.title`.
- **Your fonts, ready to use.** Font files copied into the app, registered from its bundle on first use, and each
  weight drawn by the nearest face; with no files, the system's face in the style's design.
- **Card and section styles.** `.cardStyle()`, `.sectionStyle()` and `.brandBackground()`, when asked.

## How it works

- It writes from your lines alone, with no model, so the same lines make the same files every time.
- A colour role you leave out reads the asset catalog's colour set of its name, then the palette colour of its name,
  then the platform's own colour.
- It reads the project first so the code builds the first time: a role Xcode already writes from an `AccentColor` set
  is left to Xcode, and another file that declares the same names is named in a note.
- Every file is parsed before it lands, and they land together or not at all. A line it cannot read, or a colour set or
  font file it cannot find, is refused with every reason at once, and nothing is written.

## Works well with

`granite` is where an app starts, and the other Rao Craft Agents fill it in. `design` and `loom` give it its look,
`design` the tokens every view reads. `assets` draws the icon and the colour sets in the asset catalog, and a palette
line or a colour role can read those sets by name. `screenshots` then captures the pages in the look they gave them.

## Get it

In Craft, install Design from the Agent Store, or run
`craft agents add https://github.com/Rao-Craft-Agents/DesignAgent.git`, then say `$design` in a request.

## Requirements

- A Mac on macOS 14 or later.
- The code it writes targets iOS 17 and macOS 14, and builds in Swift 5 and Swift 6.
- Font files, when you bring your own, as .ttf, .otf or .ttc.
- MIT licensed.

## For developers

What a call takes and answers, the lines it reads and what each file holds are in the [reference](Docs/Reference.md).
The agent standard it follows is Granite's
[granite-agent/1](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md), and how it is tested is
[TESTING.md](TESTING.md).
