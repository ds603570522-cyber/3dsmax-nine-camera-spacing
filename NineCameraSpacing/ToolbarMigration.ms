/* Remove only the older NineCameraSpacing toolbar entry; keep the shared Plugins menu. */
global NE9_PersistentToolbar
global NE9_EnsureToolbar
global NE9_RemoveLegacyToolbar
callbacks.removeScripts id:#NE9_PersistentToolbarStartup
NE9_EnsureToolbar = undefined
if NE9_PersistentToolbar != undefined do
(
    try (cui.UnRegisterDialogBar NE9_PersistentToolbar) catch ()
    try (destroyDialog NE9_PersistentToolbar) catch ()
)
NE9_PersistentToolbar = undefined

fn NE9_RemoveLegacyToolbar =
(
    local configPath = cui.getConfigFile()
    if not doesFileExist configPath do return false
    cui.saveConfig()
    local xml = dotNetObject "System.Xml.XmlDocument"
    xml.PreserveWhitespace = true
    xml.Load configPath
    local nodes = xml.SelectNodes "//Window[@objectName='Main Toolbar']/Items/Item[@actionID='NineCameraSpacing`NakedEye3D']"
    if nodes.Count > 0 do
    (
        local backupPath = configPath + ".BeforePluginsMenu-backup"
        if not doesFileExist backupPath do copyFile configPath backupPath
        for i = nodes.Count - 1 to 0 by -1 do
        (
            local node = nodes.Item[i]
            node.ParentNode.RemoveChild node
        )
        xml.Save configPath
        cui.loadConfig configPath
        cui.saveConfig()
    )
    true
)
