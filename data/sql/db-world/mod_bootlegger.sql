-- mod-bootlegger Phase 0: Fizzik Underbarrel — Stormwind spawn only (Phase 5 adds all cities).
--
-- Derived values (acore_world via MOD_UAC_WORLD_DATABASE_INFO, 2026-07-09):
--   @ENTRY 3460604  — MAX(creature_template.entry)+1, COUNT=0 confirmed
--   @MODEL 7179     — creature_template_model WHERE CreatureID=2685 ORDER BY Idx LIMIT 1
--   @GUID 6000026   — MAX(creature.guid)+1, COUNT=0 confirmed
--   @TEXT_ID 3460700 — custom npc_text band (paired with module entry range)

SET @ENTRY   := 3460604;
SET @MODEL   := 7179;
SET @GUID    := 6000026;
SET @TEXT_ID := 3460700;

-- Greeting (§9.1)
DELETE FROM `npc_text` WHERE `ID` = @TEXT_ID;
INSERT INTO `npc_text` (`ID`, `text0_0`, `lang0`, `Probability0`, `VerifiedBuild`) VALUES
(@TEXT_ID,
 'Psst — over here, friend. You didn''t hear it from me, but ol'' Fizzik can sort out just about any little... inconvenience. For the right price, ''course. Whaddya need?',
 0, 1, 0);

DELETE FROM `creature_template` WHERE `entry` = @ENTRY;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `ScriptName`) VALUES
(@ENTRY, 'Fizzik Underbarrel', 'Bootleg Services', 'Speak', 80, 80, 35, 1, 1, 2, 7, 0, 'npc_bootlegger');

DELETE FROM `creature_template_model` WHERE `CreatureID` = @ENTRY;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(@ENTRY, 0, @MODEL, 1, 1);

DELETE FROM `creature` WHERE `guid` = @GUID;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `Comment`, `VerifiedBuild`) VALUES
(@GUID, @ENTRY, 0, 0, 0, 1, 1, 0, -8824.65, 649.467, 94.5585, 4.47955, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', 'mod-bootlegger Stormwind (placeholder coords — owner to .gps before commit)', 0);
