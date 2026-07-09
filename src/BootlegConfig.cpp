#include "BootlegConfig.h"

#include "Config.h"
#include "Log.h"

BootlegConfig& BootlegConfig::instance()
{
    static BootlegConfig config;
    return config;
}

void BootlegConfig::Load()
{
    _enabled = sConfigMgr->GetOption<bool>("Bootleg.Enable", true);
    LOG_INFO("server.loading", ">> Bootleg: master enable = {}", _enabled ? "yes" : "no");
}
