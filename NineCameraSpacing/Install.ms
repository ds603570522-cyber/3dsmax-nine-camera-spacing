(
    local sourceDir = getFilenamePath (getSourceFileName())
    local installDir = (getDir #userScripts) + "/NakedEye9/"
    local macroFile = (getDir #userMacros) + "/NakedEye3D-NineCameraSpacing.mcr"
    makeDir installDir all:true
    local sourceScript = sourceDir + "NineCameraSpacing.ms"
    local sourceMacro = sourceDir + "NineCameraSpacing.mcr"
    if not doesFileExist sourceScript or not doesFileExist sourceMacro do throw "安装文件不完整。"
    local installedScript = installDir + "NineCameraSpacing.ms"
    if doesFileExist installedScript do deleteFile installedScript
    if not copyFile sourceScript installedScript do throw "无法复制主脚本。"
    if doesFileExist macroFile do deleteFile macroFile
    if not copyFile sourceMacro macroFile do throw "无法复制工具栏宏。"
    fileIn macroFile
    fileIn installedScript
    format "九机位间距已安装：%\n工具栏分类：NakedEye3D\n" installDir
)
