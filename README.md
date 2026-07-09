# mod-bootlegger

Paid convenience services NPC for AzerothCore 3.3.5a (WotLK): character utilities,
sequential profession tier upgrades, and instance lock reset. Gossip-only, no vending.

## Status

| Phase | Description | Status |
|---|---|---|
| 0 | Scaffold | In progress |
| 1 | Domain core | Pending |
| 2 | Utilities | Pending |
| 3 | Professions | Pending |
| 4 | Instance reset | Pending |
| 5 | Full SQL + docs | Pending |
| 6 | Integration audit | Pending |

See [docs/mod-bootlegger-spec.md](docs/mod-bootlegger-spec.md) for the full contract.

## Install

1. Link or clone this repo into your AzerothCore `modules/` directory as `mod-bootlegger`.
2. Re-run CMake and build (`MODULES=static`, C++14).
3. Copy `conf/mod_bootlegger.conf.dist` into your server config path.
4. Start worldserver — SQL under `data/sql/db-world/` is applied automatically.

## NPC (Phase 0)

| Field | Value |
|---|---|
| Entry | `3460604` |
| Gossip text ID | `3460700` |
| Model | Display `7179` (borrowed from creature 2685) |
| Spawn GUID | `6000026` (Stormwind, placeholder coords) |
| Script | `npc_bootlegger` |

## Uninstall

Run `data/sql/uninstall/mod_bootlegger_uninstall.sql` against the world database manually.

## Compatibility

- Stock [azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) master
- [liyunfan1223/mod-playerbots](https://github.com/liyunfan1223/mod-playerbots) (GPLv2)

## License

GPLv2 (see [LICENSE](LICENSE)). Combined with AzerothCore, distribution inherits GPLv2 copyleft.
