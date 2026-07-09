#include "BootlegGossip.h"

#include "BootlegConfig.h"

BootlegCreatureScript::BootlegCreatureScript()
    : CreatureScript("npc_bootlegger")
{
}

bool BootlegCreatureScript::OnGossipHello(Player* player, Creature* creature)
{
    ClearGossipMenuFor(player);

    // Phase 0: empty service menu. Phase 1+ adds registry-driven root entries when enabled.
    if (!BootlegConfig::instance().IsEnabled())
    {
        SendGossipMenuFor(player, BOOTLEG_NPC_TEXT_GREETING, creature->GetGUID());
        return true;
    }

    SendGossipMenuFor(player, BOOTLEG_NPC_TEXT_GREETING, creature->GetGUID());
    return true;
}

bool BootlegCreatureScript::OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 /*action*/)
{
    if (sender != GOSSIP_SENDER_MAIN)
    {
        return true;
    }

    OnGossipHello(player, creature);
    return true;
}
