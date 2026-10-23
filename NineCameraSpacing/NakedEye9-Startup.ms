/* Native menus load through ApplicationPlugins; this only migrates old toolbar entries. */
(
    global NE9_RemoveLegacyToolbar
    local migrationPath = (getDir #userScripts) + "/NakedEye9/ToolbarMigration.ms"
    if doesFileExist migrationPath do
    (
        fileIn migrationPath
        NE9_RemoveLegacyToolbar()
    )
)
