# 3ds Max 九机位间距插件

用于裸眼 3D 多视点机位调校：九台摄影机以中间第 5 台为中心，按统一间距横向展开或合拢，**中心摄影机和所有目标点保持原位**。

目标摄影机继续朝向原目标点，因此机身移动时朝向会自动变化。本插件控制机身的等距排列，不将九台摄影机的光轴强制设为平行。

## 安装

下载 [NineCameraSpacing-1.0.mzp](NineCameraSpacing-1.0.mzp?raw=true)，拖入 3ds Max 窗口运行安装。也可下载并解压 [ZIP 安装包](NineCameraSpacing-1.0.zip?raw=true)，在 3ds Max 中运行其中的 `Install.ms`。

无需重启。插件会安装到当前 3ds Max 用户的脚本和宏目录，不依赖 MCP、Python 或额外第三方插件。

## 使用

1. 打开面板，点击“绑定场景中的 9 台”。如果场景中有更多摄影机，选中需要的九台，再点击“绑定选中的 9 台”。目标点可以包含在选择中，会自动忽略。
2. 调整“相邻间距 (mm)”或百分比滑块，实时展开、合拢。默认使用中心摄影机的本地 X 轴，也可在绑定前选择世界 X、Y、Z。
3. “当前”和列表显示实际间距，单位为毫米，保留五位小数。点击“复制间距记录”可记录每对机位距离及总跨度。

“完全合拢”将机身间距设为零；“100% 等距排列”使用绑定时的平均间距；“恢复绑定时原排列”保留原本的不等距关系，恢复八台侧机的位置。

## 一键打开

在 **自定义 → 自定义用户界面 → 工具栏** 的 `NakedEye3D` 分类中，把“九机位间距”拖到工具栏，并保存工作区。

也可以按 **F11**，在 MAXScript 侦听器中运行：

```maxscript
macros.run "NakedEye3D" "NineCameraSpacing"
```

打开新场景或重启 3ds Max 后需要重新绑定摄影机。面板在同一会话中关闭再打开，会保留绑定和恢复基准。

## 文件

| 文件 | 用途 |
| --- | --- |
| `NineCameraSpacing/NineCameraSpacing.ms` | 面板和机位调整源码，可直接运行 |
| `NineCameraSpacing/NineCameraSpacing.mcr` | 工具栏宏 |
| `NineCameraSpacing/Install.ms` | 安装脚本 |
| `NineCameraSpacing/Verify.ms` | 临时摄影机验证脚本 |
| `NineCameraSpacing-1.0.mzp` | 可拖入 Max 的安装包 |
| `NineCameraSpacing-1.0.zip` | ZIP 安装包 |

## 兼容与验证

已在 **3ds Max 2026 中文版**验证标准目标摄影机和自由摄影机，包括零间距、多组毫米间距、空间排序、旋转后的本地 X 轴、世界 Y 轴、不等距排列恢复，以及中心和目标点不变。

本版本用于静态位置调校，遇到已有位置动画、位置约束、列表或脚本控制器、共用位置控制器、冻结、位置轴锁定，以及会带动目标点的父子链接，会停止并提示原因。插件不自动保存场景。

详细行为和限制见[使用说明](NineCameraSpacing/README.md)。
