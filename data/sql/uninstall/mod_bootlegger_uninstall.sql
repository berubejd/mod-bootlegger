-- mod-bootlegger uninstall — removes creature spawns, template, and gossip text.

SET @ENTRY   := 3460604;
SET @GUID    := 7000026;
SET @TEXT_ID := 3460700;

DELETE FROM `creature` WHERE `guid` BETWEEN @GUID AND @GUID + 9;
DELETE FROM `creature_template_model` WHERE `CreatureID` = @ENTRY;
DELETE FROM `creature_template` WHERE `entry` = @ENTRY;
DELETE FROM `npc_text` WHERE `ID` = @TEXT_ID;
