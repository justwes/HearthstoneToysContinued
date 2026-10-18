# Changelog

No unreleased changes.

## 1.0.0 — 18 October 2026

- Promote the initial testing build to the first stable release.
- Remove development-alpha wording from the addon version and About text.
- Add automated release packaging and publishing through GitHub Actions.
- Exclude Git metadata and development files from release ZIPs.
- Retain the compatibility fixes and independent addon identity introduced in the initial build.

The previous build was published on CurseForge as a Release for testing,
despite carrying an alpha version label. No errors or bugs have been
reported since publication.

## Unreleased

No additional changes beyond the development alpha below yet. GitHub and CurseForge publication are pending.

## 1.0.0-alpha.1 — development snapshot, 17 October 2026

Initial independent fork by Wes, based on Gerlock's Hearthstone Toys 1.12.9. This version has been assigned in source but has not been published. The uploaded Windows copy was compared with the original release ZIP on 17 October 2026.

### Fork identity

- Use `HearthstoneToysContinued` for the installation folder, manifest, Lua filenames, runtime identity and generated frame names.
- Display `Hearthstone Toys Continued` with version `1.0.0-alpha.1`.
- Use `HearthstoneToysContinuedDB` for independent saved settings; do not read or migrate the original database.
- Register `/hstc` with its own slash-command key. Namespace the disabled development-only toy commands as `/hstcremovetoy` and `/hstcacquiretoy`.
- Use a separate reset-confirmation popup identifier.
- Identify Wes as fork maintainer and preserve Gerlock's original-author credit in the manifest and About page.
- Remove instructions to report fork bugs to the original project's CurseForge page. Fork publication URLs are pending.
- Match README installation instructions to the flat repository layout and independent addon folder.

### Compatibility fixes retained from the uploaded Windows copy

These changes were verified by source comparison and retained without further API cleanup:

- Three `GetItemCount` calls in Functions now use `C_Item.GetItemCount`.
- `UpdateToyButtonCooldown` uses `C_Item.GetItemSpell` for its item-to-spell lookup.
- OptionsPanel uses `C_Item.GetItemInfo` for item-name lookup and `C_Item.GetItemCount` for default item selection.
- UIFrames uses `C_Item.GetItemCount` during random selection.
- Both item-cooldown checks and both calls in Functions use `C_Item.GetItemCooldown`.

### Manual test history

Before the fork identity change, Wes confirmed in WoW that the repaired original-name copy:

- Shows the main button and expands the hearthstone row.
- Uses an individually selected hearthstone.
- Supports shift-click random selection after its item-count fix.
- Shows a cooldown countdown after its cooldown API fix.
- Opens settings and lists hearthstones without fresh BugSack errors at that checkpoint.

The renamed alpha requires a new in-game test pass. Those earlier results do not establish coexistence with the original, fresh-database behaviour, or complete compatibility. The exact tested WoW build has not yet been recorded.

### Local verification for the fork identity change

- Checked Lua syntax and manifest file references.
- Exercised addon-load identity, separate saved variables and slash-command routing using a stubbed Lua environment; checked frame-name expressions and reset-popup identifiers statically.
- Confirmed the uploaded compatibility fixes remain present and the remaining API cleanup is unchanged.

These checks do not reproduce the WoW client, protected actions or the complete UI.

### Outstanding

- Finish bare `GetItemInfo` references in `HearthstoneToysContinued_Functions.lua` and `HearthstoneToysContinued_UIFrames.lua`, including tooltips and texture retries.
- Migrate legacy `SendChatMessage` calls.
- Review and migrate `IsSpellKnown` calls with equivalent spellbook semantics.
- Migrate legacy `UIDropDownMenu` usage.
- Review guarded legacy spell-cooldown and glow fallbacks.
- Check texture retry logic: it selects APIs by their existence rather than entry type, and its item fallback reads the third `GetItemInfo` return value instead of the texture return value.
- Test fresh fork settings, coexistence, tooltips, presets, sizing, persistence, combat and cooldowns for different destinations.
- Add real GitHub and CurseForge URLs when created, then prepare and test a public release package.

## Upstream 1.12.9

Original release by Gerlock. This baseline is separate from the fork's version history.

Original project: https://www.curseforge.com/wow/addons/hearthstone-toys
