(
    global NE9_RemoveLegacyToolbar, NE9_MenuItemId
    local sourceDir = getFilenamePath (getSourceFileName())
    local installDir = (getDir #userScripts) + "/NakedEye9/"
    local bundleDir = (getDir #privateExchangeStoreInstallPath) + "/NakedEye3D-NineCameraSpacing2026.bundle/"
    local sourceNames = #("NineCameraSpacing.ms", "NineCameraSpacing.mcr", "NineCameraMenu.ms", "ToolbarMigration.ms", "NakedEye9-Startup.ms", "PackageContents.xml")
    for name in sourceNames do
        if not doesFileExist (sourceDir + name) do throw ("安装文件不完整：" + name)
    fn ne9CopyFile sourceFile targetFile =
    (
        if doesFileExist targetFile do deleteFile targetFile
        if not copyFile sourceFile targetFile do throw ("无法安装文件：" + targetFile)
    )
    makeDir installDir all:true
    makeDir bundleDir all:true
    ne9CopyFile (sourceDir + "NineCameraSpacing.ms") (installDir + "NineCameraSpacing.ms")
    ne9CopyFile (sourceDir + "ToolbarMigration.ms") (installDir + "ToolbarMigration.ms")
    for name in #("NineCameraSpacing.mcr", "NineCameraMenu.ms", "PackageContents.xml") do
        ne9CopyFile (sourceDir + name) (bundleDir + name)
    local startupDir = getDir #userStartupScripts
    makeDir startupDir all:true
    ne9CopyFile (sourceDir + "NakedEye9-Startup.ms") (startupDir + "/NakedEye9-Startup.ms")
    local legacyToolbar = installDir + "NineCameraToolbar.ms"
    if doesFileExist legacyToolbar do
    (
        if not doesFileExist (installDir + "LegacyToolbar.ms.bak") do copyFile legacyToolbar (installDir + "LegacyToolbar.ms.bak")
        deleteFile legacyToolbar
    )
    fileIn (bundleDir + "NineCameraSpacing.mcr")
    fileIn (bundleDir + "NineCameraMenu.ms")
    fileIn (installDir + "ToolbarMigration.ms")
    NE9_RemoveLegacyToolbar()
    local menuMgr = maxOps.GetICuiMenuMgr()
    if not (menuMgr.LoadConfiguration (menuMgr.GetCurrentConfiguration())) do throw "无法刷新插件菜单。"
    if (menuMgr.GetMenuItemById NE9_MenuItemId) == undefined do throw "插件菜单注册失败。"
    fileIn (installDir + "NineCameraSpacing.ms")
    format "已安装：插件 > 九机位间距。菜单扩展：%\n" bundleDir
)
