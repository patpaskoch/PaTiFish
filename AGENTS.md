# AGENTS.md — PaTiFish

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: a simple fishing helper (owner 2026-11-20). **One click = exactly one action.** It never casts, reels in,
  equips or applies anything by itself; WoW does not tell an addon when a fish bites, and catching it stays the
  player's click (or WoW's own "Interact with Target" key).
- Files: `Logic.lua` (settings, migration, lures, skill, cast timing, sound plan, weapon swap; pure, tested) ·
  `PaTiFish.lua` (adapters for skill, bags, weapons, cast, CVars; window, secure buttons, settings, commands,
  events) · `Bindings.xml` (optional keys for the buttons; never bound by the addon) · `Locales/` · `Shared/`
  (PaTiShared, synced — never edit).
- Secure buttons (changed only out of combat): `PaTiFishCast` (type spell, Fishing), `PaTiFishLure` (macro
  `/use item:<lure>` + `/use 16`), `PaTiFishGear` (macro `/equip` the pole, or the saved weapons back).
- Sound: while fishing (setting "Louder splash") effects go to 100 %, music and ambience to 0; the player's values are
  saved in `DB.soundBackup` first and restored 15 s after the last cast and on the next login.
- SavedVariables: `PaTiFishDB` (per character), schema 1 — see `Logic.DEFAULTS`; plus `soundBackup` (cvar → string)
  and `weapons` ({ main, off } item IDs from before the pole). Any shape change: bump `Logic.SCHEMA`, add a migration
  step and a test.
- Slash commands: `/pfish`, `/patifish`. Test mode with example data.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `INGAME_TESTING.md`.
