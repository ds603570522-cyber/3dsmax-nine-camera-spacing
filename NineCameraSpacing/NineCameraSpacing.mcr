macroScript NineCameraSpacing
category:"NakedEye3D"
buttonText:"九机位间距"
toolTip:"裸眼3D九摄影机间距（目标点固定）"
autoUndoEnabled:false
(
    on execute do
    (
        local scriptPath = (getDir #userScripts) + "/NakedEye9/NineCameraSpacing.ms"
        if doesFileExist scriptPath then fileIn scriptPath
        else messageBox "未找到九机位间距脚本，请重新运行 Install.ms。" title:"九机位间距"
    )
)
