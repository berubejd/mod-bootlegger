#ifndef BOOTLEG_CONFIG_H
#define BOOTLEG_CONFIG_H

class BootlegConfig
{
public:
    static BootlegConfig& instance();

    void Load();

    bool IsEnabled() const { return _enabled; }

private:
    BootlegConfig() = default;

    bool _enabled = true;
};

#endif
