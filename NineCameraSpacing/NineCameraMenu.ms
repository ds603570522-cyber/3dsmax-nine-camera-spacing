/* 3ds Max 2026 native menu extension, loaded before menu registration. */
global NE_PluginsMenuId = "bc206b8c-d20e-477d-b837-521ade67b012"
global NE9_MenuItemId = "1201d486-db2a-4e6f-82a3-41c4324a7173"
global NE9_RegisterPluginMenu

fn NE9_RegisterPluginMenu =
(
    local menuMgr = callbacks.notificationParam()
    local pluginsMenu = menuMgr.GetMenuById NE_PluginsMenuId
    if pluginsMenu == undefined do
        pluginsMenu = menuMgr.mainMenuBar.CreateSubMenu NE_PluginsMenuId "插件"
    if (menuMgr.GetMenuItemById NE9_MenuItemId) == undefined do
        pluginsMenu.CreateMacroScriptAction NE9_MenuItemId "NineCameraSpacing" "NakedEye3D" title:"九机位间距"
)

callbacks.removeScripts id:#NE9_PluginsMenu
callbacks.addScript #cuiRegisterMenus NE9_RegisterPluginMenu id:#NE9_PluginsMenu persistent:false
