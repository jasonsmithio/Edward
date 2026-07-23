<div align="center">
    <img src="Edward/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width=200 height=200>
    <h1>Edward</h1>
</div>

Edward is a powerful menu bar management tool for macOS — it hides and shows menu bar
items, and aims to be one of the most versatile menu bar tools available.

Edward is a personal fork of [Ice](https://github.com/jordanbaird/Ice) by Jordan Baird,
rebranded and customized for my own use. All credit for the original work goes to Jordan
and Ice's contributors. Like Ice, Edward is released under the GPL-3.0 license.

> [!TIP]
> **You don't need to build Edward yourself.** Download the notarized app from
> **[theedward.app](https://theedward.app)** ([direct link](https://theedward.app/download)),
> unzip, and drag `Edward.app` to Applications. It updates itself via Sparkle.
> Building from source remains fully supported — see [Build](#build-from-source) below.

Edward is based on Ice's `macos-26` branch, so it works on macOS 26 (Tahoe). It installs
alongside Ice with its own bundle identifier (`io.jasonsmith.Edward`), so existing Ice
settings are untouched.

## Why this fork exists

Upstream Ice's last stable release (0.11.12) is broken on macOS 26 (Tahoe): the menu bar
layout pane shows up empty and items can't be displayed. The fixes live on Ice's unreleased
`macos-26` branch. Edward is based on that branch, plus a patch
([pdurlej](https://github.com/pdurlej/Ice)) that lets the menu-bar-reading XPC service talk
to **ad-hoc / personally-signed builds** — without it, a self-built copy silently rejects
its own helper and the layout pane spins forever.

## Install

Download the latest notarized release from **[theedward.app](https://theedward.app)**,
unzip, and drag `Edward.app` to Applications. Updates arrive automatically via Sparkle
(feed: `https://theedward.app/appcast.xml`).

## Build from source

Building it yourself is entirely optional:

1. Open `Edward.xcodeproj` in Xcode.
2. For both the `Edward` and `MenuBarItemService` targets → **Signing & Capabilities** → choose your Team
   (or build unsigned: `xcodebuild -scheme Edward CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" build` —
   ad-hoc builds work thanks to the XPC patch).
3. Build & run the `Edward` scheme (⌘R). The app lives in the menu bar.

If you fork Edward and distribute your own builds, replace `SUFeedURL` and `SUPublicEDKey`
in `Edward/Resources/Info.plist` with your own so your users never update into my binary.

## Architecture note

Edward reads menu bar item owners through a small embedded XPC helper
(`MenuBarItemService.xpc`, bundle id `io.jasonsmith.Edward.MenuBarItemService`). The app
and helper agree on a shared mach-service name defined in
`Shared/Services/MenuBarItemService.swift`.

## Features

- Hide / show menu bar items, with an "always-hidden" section
- Show hidden items on hover, click, or scroll
- Automatic rehide
- Drag-and-drop layout editor
- Separate "Edward Bar" for hidden items (great for notched MacBooks)
- Menu bar item search and spacing
- Custom menu bar appearance (tint, shadow, border, shapes)
- Configurable hotkeys; launch at login

## Requirements

macOS 14 (Sonoma) or later; the Tahoe fixes target macOS 26.

## Credit

Edward is a fork of [Ice](https://github.com/jordanbaird/Ice). The original project, its
design, and the overwhelming majority of this code are the work of
[Jordan Baird](https://github.com/jordanbaird) and the Ice contributors, with the macOS 26
XPC fix by [Piotr Durlej](https://github.com/pdurlej). If you find Edward useful, please
consider [supporting the original project](https://icemenubar.app).

## License

Edward is available under the [GPL-3.0 license](LICENSE), the same license as Ice.
