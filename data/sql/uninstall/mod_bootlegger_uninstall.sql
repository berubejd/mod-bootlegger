-- mod-bootlegger uninstall — removes Phase 0 footprint (Stormwind spawn).
-- Phase 5 expands GUID range to @GUID … @GUID+9; update this file accordingly.

SET @ENTRY   := 3460604;
SET @GUID    := 6000026;
SET @TEXT_ID := 3460700;

DELETE FROM `creature` WHERE `guid` = @GUID;
DELETE FROM `creature_template_model` WHERE `CreatureID` = @ENTRY;
DELETE FROM `creature_template` WHERE `entry` = @ENTRY;
DELETE FROM `npc_text` WHERE `ID` = @TEXT_ID;
