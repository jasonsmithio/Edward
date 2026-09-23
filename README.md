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

Edward is based on Ice's `macos-26` branch and supports **macOS 26 (Tahoe) and macOS 27**.
It installs alongside Ice with its own bundle identifier (`io.jasonsmith.Edward`), so
existing Ice settings are untouched.

## Why this fork exists

Upstream Ice's last stable release (0.11.12) is broken on macOS 26 (Tahoe): the menu bar
layout pane shows up empty and items can't be displayed. The fixes live on Ice's unreleased
`macos-26` branch. Edward is based on that branch, plus a patch
([pdurlej](https://github.com/pdurlej/Ice)) that lets the menu-bar-reading XPC service talk
to **ad-hoc / personally-signed builds** — without it, a self-built copy silently rejects
its own helper and the layout pane spins forever.

**macOS 27 broke it again, differently.** macOS 27 moved every status item into
`MenuBarAgent`: there are no per-item windows any more, and an oversized status item (the
divider Ice used to push items off screen) is discarded rather than honored. Hiding, the
Menu Bar Layout editor, and the Edward Bar all stopped working. Edward 1.1.0 restores them
by incorporating the macOS 27 support from
[Ice PR #995](https://github.com/jordanbaird/Ice/pull/995) by
[Yevhenii Rabenko](https://github.com/RabenkoYevhenii) — the new code lives under
`Edward/MenuBar/MacOS27/` and is gated on `#available(macOS 27.0, *)`, so macOS 26 and
earlier behave exactly as before.

> [!NOTE]
> Upstream Ice has not been updated since September 2025 and none of the community macOS 27
> pull requests have been merged there. Edward therefore tracks its own line rather than
> waiting for upstream. macOS 27 support is newer and less battle-tested than the rest of
> the app — please [open an issue](https://github.com/jasonsmithio/Edward/issues) if you hit
> trouble, especially with multiple displays or fullscreen.

## Install

Download the latest notarized release from **[theedward.app](https://theedward.app)**,
unzip it by double-clicking in Finder, and drag `Edward.app` to Applications. Updates
arrive automatically via Sparkle (feed: `https://theedward.app/appcast.xml`).

### First launch on macOS

Edward is signed with a Developer ID and notarized by Apple. Because it's distributed
outside the Mac App Store, macOS (Sequoia and later) shows a one-time prompt the first
time you open it — *"Apple could not verify Edward is free of malware."* This is expected
for notarized non-App-Store apps. To open it:

1. Try to open Edward once, then dismiss the prompt.
2. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
3. Confirm. Edward opens and won't prompt again.

> **Unzip with Finder.** Double-click the `.zip` (Apple's Archive Utility). Some
> third-party unarchivers rewrite the app's embedded-framework symlinks as real files,
> which breaks the code signature and causes a `rejected (unsealed contents present in
> the root directory of an embedded framework)` error. If you hit that, re-download and
> unzip with Finder.

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

## Privacy

Edward is a local menu bar utility. It contains **no analytics, telemetry, or crash
reporting**, and collects nothing about you, your menu bar, or your Mac.

The app makes exactly one kind of outbound connection: its **Sparkle software-update
check**, which contacts **`theedward.app`** only — the update feed
(`https://theedward.app/appcast.xml`) and, if you accept an update, the release archive.
No information about you or your usage is transmitted.

- The embedded `MenuBarItemService.xpc` helper does no networking whatsoever.
- The only other URLs in the app are click-only browser links (this repo, Ice's donate
  page); nothing is fetched unless you click.
- Want zero outbound traffic? Disable automatic update checks in **Settings**. Since
  Edward is open source (GPL-3.0), you can verify all of this yourself.

## Credit

Edward is a fork of [Ice](https://github.com/jordanbaird/Ice). The original project, its
design, and the overwhelming majority of this code are the work of
[Jordan Baird](https://github.com/jordanbaird) and the Ice contributors.

Edward additionally incorporates community work, used under the GPL-3.0:

- **macOS 26 XPC fix** — [Piotr Durlej](https://github.com/pdurlej/Ice), which lets the
  menu-bar-reading XPC service talk to ad-hoc / personally-signed builds.
- **macOS 27 support** — [Yevhenii Rabenko](https://github.com/RabenkoYevhenii), from
  [Ice PR #995](https://github.com/jordanbaird/Ice/pull/995). Edward 1.1.0 ports that work
  (with Sparkle held at 2.9.5 and Edward-specific cache/logging identifiers); the design
  and implementation of the macOS 27 menu bar provider, concealer, and section layout are
  theirs.

If you find Edward useful, please consider
[supporting the original project](https://icemenubar.app).

## License

Edward is available under the [GPL-3.0 license](LICENSE), the same license as Ice.
