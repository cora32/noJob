#include "include/snapshot_system/snapshot_system_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "snapshot_system_plugin.h"

void SnapshotSystemPluginCApiRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar) {
    snapshot_system::SnapshotSystemPlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarManager::GetInstance()
                    ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
