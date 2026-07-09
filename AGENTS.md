# AGENTS.md

Working guide for AI coding assistants on **mod-bootlegger**. Humans: read
[README.md](README.md) first. [CLAUDE.md](CLAUDE.md) points here; everything in
this file applies to every agent.

The behavior contract is [docs/mod-bootlegger-spec.md](docs/mod-bootlegger-spec.md).
Where this file and the spec disagree, **this file wins** — it records
owner-approved decisions made after the spec was frozen (see "Post-spec
decisions" below).

---

## What this module is

A single goblin gossip NPC ("Fizzik Underbarrel", script `npc_bootlegger`)
spawned in the ten capitals, selling three paid gold-sink services:

1. **Utilities** — set at-login flags for name / appearance / race / faction change.
2. **Professions** — raise an existing profession's skill cap exactly one tier
   per purchase (Journeyman → … → Grand Master), server-authoritative.
3. **Instance reset** — bulk-clear saved heroic dungeon or raid locks, solo or
   for the whole group.

No vending, no chat commands, no client addon. Must compile warnings-clean on
stock `azerothcore/azerothcore-wotlk` master **and** `liyunfan1223/mod-playerbots`
at `-std=c++14`.

**Clean-room rule:** never copy code, strings, or data from `mod-assistant` or
any other reference module.

---

## Current state (update this section as work lands)

| Phase | Scope | Status |
|---|---|---|
| 0–5 | Scaffold, domain core, all three services, SQL (10 capitals), conf, docs | Done |
| 6 | Integration audit on deploy server (spec §13 invariants + §15 test matrix) | **In progress** |

Outstanding items:

- **Profession grant verification** — in-game testing showed `SetSkill` alone
  was insufficient (trainer kept offering the purchased tier; value filled to
  the new cap instead of the old one). The grant now learns the trainer rank
  spell first, then fills the value to the previous cap only (spec §6.2,
  amended). Owner to re-verify: correct value/cap after purchase, trainer
  recognizes the rank, cap persists across relog.
- **Spawn coordinates** — all ten spawns in the install SQL are placeholders;
  owner replaces them via `.gps` before production.
- **Cost tuning** — conf defaults are placeholders; owner tunes.

---

## Architecture

### Control flow

```
Player clicks NPC
  └─ BootlegGossip::OnGossipHello
       ├─ master disabled → greeting only (npc_text 3460700), no entries
       └─ BootlegRegistry::AddRootEntries → each enabled+available service
          draws its root line
Player clicks an option
  └─ BootlegGossip::OnGossipSelect
       ├─ sender != GOSSIP_SENDER_MAIN → reject (return true, do nothing)
       ├─ action == BOOTLEG_ROOT_REFRESH (1) → redraw root
       └─ BootlegRegistry::HandleAction → service owning the action block
            └─ service submenu / purchase
                 └─ BootlegPurchase (THE only place money is taken)
                      validate stillEligible() → HasEnoughMoney → ModifyMoney(-) → grant()
```

`OnGossipSelect` always returns `true`, so the core's own gossip money path
(`Player::OnGossipSelect`, which charges `BoxMoney`) **never runs** for this
NPC. `BoxMoney` on our items is display-only; all charging is `BootlegPurchase`.

### HandleAction return contract

`true` = redraw the root menu (window stays open). Services that call
`CloseGossipMenuFor` **must return `false`** or the menu instantly reopens.
Current behavior: professions return `true` (root redraws so the next tier is
immediately purchasable); utilities and instance reset close the window and
return `false`.

### File map

| Path | Responsibility |
|---|---|
| `src/mod_bootlegger.cpp` | `Addmod_bootleggerScripts()` — registers the two scripts |
| `src/BootlegWorldScript.*` | `OnAfterConfigLoad` → `BootlegConfig::Load()` (supports `.reload config`) |
| `src/BootlegGossip.*` | `CreatureScript` gossip hooks; sender check; root refresh; `BOOTLEG_NPC_TEXT_GREETING = 3460700` |
| `src/BootlegConfig.*` | Meyers singleton; all config keys; gold→copper once at load (`GoldToCopper`, clamps at 21474 gold) |
| `src/BootlegActions.h` | Action-ID blocks (see below) |
| `src/BootlegService.h/.cpp` | Abstract service contract + default `OwnsAction` range check |
| `src/BootlegRegistry.*` | Owns the three service instances; routes actions by block |
| `src/BootlegPurchase.*` | The purchase primitive — **sole `ModifyMoney(-)` call site** |
| `src/BootlegGossipUtil.*` | Insufficient-funds notifier (`SendBuyError`) + paid-gossip-item builder (coin icons, hybrid confirm) |
| `src/BootlegProfessionData.*` | 14-profession table + tier ladder + next-tier derivation |
| `src/BootlegStrings.h` | All v1 user-facing strings (`static char const* const`) |
| `src/services/UtilitiesService.*` | At-login flag purchases |
| `src/services/ProfessionsService.*` | Sequential tier advancement via `SetSkill` |
| `src/services/InstanceResetService.*` | Bulk heroic/raid lock reset, solo/group |

### Action-ID allocation

```
BOOTLEG_ROOT_REFRESH   = 1
BOOTLEG_BLOCK_SIZE     = 100
BOOTLEG_UTILITIES_BASE = 1000   // 1000..1099
BOOTLEG_PROFESSIONS_BASE = 1100 // 1100..1199 (menu=1100, purchases=1101..1114)
BOOTLEG_INSTANCES_BASE = 1200   // 1200..1299
```

Profession purchase actions encode **only the profession index**
(`base+1+index`), never the tier — the tier is re-derived server-side on grant,
so crafted packets cannot skip tiers.

### Adding a new service

1. Reserve the next 100-wide block in `BootlegActions.h`.
2. Subclass `BootlegService` under `src/services/`.
3. Add an instance + slot in `BootlegRegistry` (bump `_services` array size).
4. Add config keys to `BootlegConfig` and `conf/mod_bootlegger.conf.dist` (1:1).
5. Route every charge through `BootlegPurchase`; add strings to `BootlegStrings.h`.

---

## Money display & purchase UX (post-spec, owner-approved)

Implemented in `BootlegGossipUtil.cpp`; do not regress these without owner sign-off:

- **Inline prices:** every paid gossip line gets a suffix of amount + coin icon
  built from `|cff` color + `|TInterface\MoneyFrame\UI-*Icon:12|t` textures.
  Only non-zero denominations render; groups concatenate without separators
  (native MoneyFrame style); one space between an amount and its coin.
- **Affordance colors:** amounts render `C8A800` (dim gold) when affordable,
  `CC3333` (soft red) when not. Base label text is never modified.
- **Hybrid confirm:**
  - *Affordable* → item carries `BoxMoney` + the Fizzik confirm popup
    (`BOOTLEG_CONFIRM_TRANSACTION`); Accept → server → `BootlegPurchase`.
  - *Unaffordable* → item has **no popup**; the click reaches `BootlegPurchase`,
    which fails the funds check and sends the native red
    "You don't have enough money." via `SendBuyError(BUY_ERR_NOT_ENOUGHT_MONEY)`.
- **No font control exists** in gossip strings — digits always render in the
  client's gossip font. Only color, textures, and spacing are tunable. Don't
  chase NumberFont; it requires client-side changes.

---

## Invariants (spec §13, amended — verify before claiming a phase done)

1. The only `ModifyMoney` call site is inside `BootlegPurchase`.
2. Charge precedes grant everywhere.
3. `HasEnoughMoney` gates every charging path; insufficient funds → native
   client buy error (`SendBuyError`), **no chat message**, no state change.
4. Eligibility is re-validated on the grant path from live state (professions
   re-derive next tier; utilities re-check pending flags; instances re-check
   saves + enable).
5. Professions advance exactly one tier per transaction; the tier is never
   taken from the client; a disabled tier **blocks** progression (no skipping
   to a higher enabled tier).
6. Non-`GOSSIP_SENDER_MAIN` senders are rejected; each service handles only its
   own action block.
7. No playerbot symbols in `src/` — a grep must return nothing. Group iteration
   uses only stock checks (`member && member->GetSession() && member->IsInWorld()`).
8. All runtime money is copper; gold→copper happens once at config load with
   the overflow clamp.
9. Install SQL is idempotent (DELETE-before-INSERT); uninstall removes the full
   DB footprint; creature 2685 is read-only (model donor).
10. `.reload config` re-populates config without restart.
11. Warnings-clean at `-std=c++14`; no C++17-only features
    (`string_view`, structured bindings, `if constexpr`, inline variables,
    `std::optional`, fold expressions).

---

## Landmines (things that have actually bitten this codebase)

- **fmt, not printf.** `ChatHandler::PSendSysMessage` formats with
  `Acore::StringFormat` (fmtlib). Placeholders are `{}`; `%u`/`%s` pass through
  as literal text. Same for `Acore::StringFormat` in labels.
- **Close vs redraw.** Returning `true` from `HandleAction` after
  `CloseGossipMenuFor` reopens the window. See the contract above.
- **Iterator invalidation.** `PlayerUnbindInstance` mutates the bound-instances
  map — collect map IDs first, then unbind (see `InstanceResetService::ResetInstances`).
- **`AddGossipItemFor` overloads.** The 5-arg form = plain item; the 8-arg form
  (popupText, boxMoney, coded) = confirm popup. `BootlegAddPaidGossipItem`
  chooses between them — use it for anything priced.
- **`SetSkill` doesn't grant profession ranks.** Trainer rank recognition,
  relog persistence, and the native cap raise all key off the **rank spell**
  ("Journeyman Tailor" etc.). Grants must `learnSpell(rankSpellId)` first; the
  map in `BootlegProfessionData.cpp` was derived from world-DB `spell_ranks`
  chains (the `trainer_spell` rows are teach-wrappers, not the rank spells).
- **No local builds.** This dev tree is reference-only. The maintainer compiles
  and tests on a deploy server. Verify API signatures against the neighboring
  `azerothcore-wotlk/` sources on disk instead of memory.
- **DB values are derived, not guessed.** Entry `3460604`, model `7179` (from
  creature 2685), GUIDs `7000026–7000035`, npc_text `3460700` were derived from
  the live world DB (DSN in `MOD_UAC_WORLD_DATABASE_INFO` — never commit
  credentials). Any new baked value needs a derivation comment in the SQL.

---

## Build environment & resources

- `MOD_UAC_WORLD_DATABASE_INFO` — world DB DSN (`host;port;user;pass;dbname`).
  Treat the password as a secret.
- `data/client-data-v19.zip` — v19 DBCs (`SkillLineAbility.dbc`, `SkillLine.dbc`,
  `Spell.dbc`) for the profession rank-spell fallback if cap persistence fails.
- Neighboring sources: `../azerothcore-wotlk/` for core API ground truth;
  other modules for conventions. **Do not copy from `mod-assistant`.**
- `CMakeLists.txt` is intentionally a stub — AzerothCore's parent module glob
  collects `src/**/*.cpp` (including `src/services/`). Verified building on the
  deploy server; don't add build logic without need.

---

## Workflow

- Each change set: implement → run the Bugbot review loop until clean →
  hand the owner a commit message → owner deploys and verifies in-game.
- **Never run git on the maintainer's behalf.** Provide one-line
  [Conventional Commit](https://www.conventionalcommits.org) messages:
  types `feat|fix|docs|refactor|test|chore|build|ci`; scope = phase id `0`–`6`
  or `bootlegger` for cross-cutting work; imperative mood; no trailing period.
- Regenerated SQL belongs in the same commit as the code that produced it.
- Plans are proposals — pivot with owner approval if stock AC data suggests a
  simpler shape.

---

## Post-spec decisions (chronological; spec sections amended in place)

| Decision | Supersedes |
|---|---|
| Insufficient funds → `SendBuyError` native error, not a chat message | spec §5.3 sample code |
| Hybrid confirm: popup only when affordable | spec §7 "every charging action uses a confirm popup" |
| Inline coin-icon prices with affordance colors (`C8A800`/`CC3333`, icon height 12) | not in spec |
| Utilities/instances close the window after purchase; professions redraw root | spec §7 (silent) |
| CMake stub relying on the parent module glob is acceptable | spec §10 "real CMakeLists" |
