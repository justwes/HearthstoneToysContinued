# Hearthstone Toys Continued

An independent fork of **Hearthstone Toys 1.12.9**, originally created by **Gerlock (Gerlock-ArgentDawn US)** for World of Warcraft Retail. Fork maintenance and compatibility fixes are by **Wes**.

**Current development version: `1.0.0-alpha.1`.** This is a testing build, not a published stable release. Further API migration and in-game testing are required.

Original project: https://www.curseforge.com/wow/addons/hearthstone-toys

Fork repository: https://github.com/justwes/HearthstoneToysContinued

Report fork bugs and feature requests at: https://github.com/justwes/HearthstoneToysContinued/issues

## Independent addon identity

| Setting                                   | This fork                        |
| ----------------------------------------- | -------------------------------- |
| Display name                              | Hearthstone Toys Continued       |
| Installation folder                       | `HearthstoneToysContinued`       |
| Manifest                                  | `HearthstoneToysContinued.toc`   |
| Lua filenames                             | `HearthstoneToysContinued_*.lua` |
| Internal addon name and frame-name prefix | `HearthstoneToysContinued`       |
| Saved variables                           | `HearthstoneToysContinuedDB`     |
| Options command                           | `/hstc`                          |
| Current version                           | `1.0.0-alpha.1`                  |
| Upstream source baseline                  | Hearthstone Toys `1.12.9`        |

The fork uses separate settings, frame names, commands and reset-popup identifiers. It does not read or migrate `HearthstoneToysDB`, claim `/hst`, or overwrite the original addon's folder. Existing positions and selections from the original are not automatically imported. Both addons can remain installed; simultaneous operation still needs an in-game coexistence test.

The original project's maintenance status has not been confirmed with its author. This fork does not claim Gerlock's endorsement or replace the original project's ownership.

## Features and controls

- Left-click the movable main button to show or hide enabled hearthstone entries.
- Click an entry to use it when available.
- Shift-left-click the main button to use a randomly selected enabled entry.
- Right-click the main button, or enter `/hstc`, to open the options.
- Configure included entries, button size, position, mouseover visibility and position presets.
- View cooldown overlays on the main button and individual entries.

Available entries depend on the character's collection, inventory and known spells. Dalaran and Garrison Hearthstones have different destinations and cooldowns from the normal Hearthstone. Combat restrictions apply to interactions.

## Repository layout

Source and documentation are stored together in the repository root:

- `HearthstoneToysContinued.toc` — addon manifest.
- `HearthstoneToysContinued_*.lua` — five addon source modules.
- `README.md` — project overview and development instructions.
- `CHANGELOG.md` — development history, test status and outstanding work.
- `LICENSE` and `NOTICE.md` — licence and original-author attribution.
- `.gitignore` and `.gitattributes` — Git exclusions and text line endings.

Development takes place on Windows. Keep the repository separate from the WoW installation. The initial source import includes the fixes tested before the identity change; it is not untouched upstream source.

## Local testing on Windows

Copy the manifest and five Lua files from the repository root into:

```text
<WoW installation>\_retail_\Interface\AddOns\HearthstoneToysContinued\
```

Include `README.md`, `CHANGELOG.md`, `LICENSE` and `NOTICE.md` with distributed copies. Do not put the Git `.git` directory into the installed addon or release ZIP.

The manifest must be directly inside the installed `HearthstoneToysContinued` folder. Restart WoW fully for the first installation under the new name. For later Lua-only edits, copy the changed files and run `/reload`.

For the first test, disable the original addon in WoW's AddOns list so there is only one visible hearthstone button to assess. Keep its folder and saved settings intact. Then test both enabled to verify the fork's separate identity. A previously modified original installed under `HearthstoneToys` remains a separate copy; this package does not restore or change it.

Use BugGrabber/BugSack to capture errors and clear previous entries before each test. Record fresh errors and the game build. Manual in-game testing is still required; the renamed alpha has not yet been run in WoW.

| Test                                     | Expected result                                                                |
| ---------------------------------------- | ------------------------------------------------------------------------------ |
| First startup with only the fork enabled | New display name appears; button appears without new errors                    |
| `/hstc` and About page                   | Fork options open; version and original-author credit appear                   |
| Left-click main button                   | Hearthstone row opens and closes                                               |
| Click an enabled hearthstone             | Cast begins when usable                                                        |
| Shift-left-click main button             | A valid enabled entry is selected and used when usable                         |
| Use a hearthstone                        | Cooldown display updates                                                       |
| Hover over entries                       | Correct tooltips appear without errors                                         |
| Change included entries                  | Visible buttons reflect the selection                                          |
| Move, resize, save a preset and reload   | Fork settings persist                                                          |
| Enter and leave combat                   | No blocked-action or Lua errors                                                |
| Enable original and fork together        | Separate buttons and settings; `/hst` and `/hstc` open their respective addons |
| Change or reset fork settings            | Original settings remain unchanged                                             |

## Versioning and publication

This fork has its own version history beginning at `1.0.0-alpha.1`, based on upstream `1.12.9`. The manifest and `ADDON_VERSION` in `HearthstoneToysContinued_Main.lua` must match. Use matching release tags, such as `v1.0.0-alpha.1`, when publishing a tested alpha. A version in source does not imply a release has been published.

Record future work under **Unreleased** in the changelog, then move it into the version being released. Record the tested WoW build and update the Interface value only after checking compatibility. The current `120100` Interface value was inherited from upstream and has not been independently certified by this review.

GitHub and CurseForge publication are pending. Add the real fork repository and release-page URLs to this README, `NOTICE.md` and the in-game About/support text once those destinations exist. Never use the original project's issue tracker as the support destination for fork-specific changes.

For CurseForge, package runtime files and documentation inside one top-level `HearthstoneToysContinued/` folder. Exclude `.git` and local editor files. A GitHub source archive is not automatically a correctly packaged addon release.

## Credits and licence

Original addon: **Gerlock**. Independent fork and compatibility fixes: **Wes**.

Distributed under the MIT licence. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md) for the upstream licence provenance and attribution. Preserve these files in release archives.
