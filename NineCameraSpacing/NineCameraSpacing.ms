/* Nine Camera Spacing 1.0 -- camera positions ONLY. Targets are never written. */
global NE9_State
global NE9_Rollout
global NE9_NoAutoOpen
global NE9_Open

try (destroyDialog NE9_Rollout) catch ()

struct NE9_SpacingState
(
    nodes = #(), original = #(), axis = [1,0,0], axisLabel = "",
    referenceMM = 3.0, inputMM = 3.0, originalMeanMM = 0.0, recordUndo = true,

    fn isCamera n = (isValidNode n and superclassof n == camera),
    fn mmUnit = (units.decodeValue "1mm"),
    fn mmText value = (formattedPrint value format:".5f"),
    fn worldPos n = (copy n.transform.row4),
    fn getTarget n = (try (n.target) catch (undefined)),

    fn valid =
    (
        if nodes.count != 9 then false
        else ((for n in nodes where isCamera n collect n).count == 9)
    ),

    fn clear = (nodes = #(); original = #(); true),

    fn controllerTree ctrl =
    (
        local result = #()
        if ctrl != undefined do
        (
            append result ctrl
            for i = 1 to ctrl.numSubs do
            (
                local child = try ((getSubAnim ctrl i).controller) catch (undefined)
                if child != undefined do join result (controllerTree child)
            )
        )
        result
    ),

    fn checkWritable cams =
    (
        for n in cams do
        (
            if not isCamera n do throw "摄影机已删除或场景已切换，请重新绑定。"
            if n.isFrozen do throw (n.name + " 已冻结，请先解冻。")
            if (getTransformLockFlags n * #{1..3}).numberSet > 0 do
                throw (n.name + " 的位置轴被锁定，请先解除位置锁定。")
            local pc = n.position.controller
            local allowed = #(Position_XYZ, Bezier_Position, Linear_Position, TCB_Position, Bezier_Float, Linear_Float, TCB_Float)
            for ctrl in (controllerTree pc) do
            (
                if findItem allowed (classof ctrl) == 0 do
                    throw (n.name + " 使用约束、列表或表达式位置控制器，此版本不覆盖这些控制器。")
                if (numKeys ctrl) > 0 do throw (n.name + " 的位置已有动画，此版本只调整静态机位。")
                for dep in (refs.dependentNodes ctrl) where dep != n do
                    throw (n.name + " 的位置控制器被其他节点共用，已停止以保护目标点和其他节点。")
            )
        )
        local allTargets = for n in cameras where isCamera n and isValidNode (getTarget n) collect (getTarget n)
        for n in (cams + allTargets) do
        (
            local p = n.parent
            while isValidNode p do
            (
                if findItem cams p > 0 do throw "摄影机或目标点是这些摄影机的子节点，请先解除这类父子链接。"
                p = p.parent
            )
        )
        true
    ),

    fn bind cams axisMode:1 centerNode:undefined =
    (
        local picked = #()
        for n in cams where isCamera n do appendIfUnique picked n
        if picked.count != 9 do throw "请绑定恰好 9 台摄影机。选择中可以包含目标点，它们会被忽略。"
        checkWritable picked
        local direction = case axisMode of (2:[1,0,0]; 3:[0,1,0]; 4:[0,0,1]; default:undefined)
        if direction == undefined do
        (
            -- First find the spatial middle along the dominant spread axis.
            local low = worldPos picked[1], high = worldPos picked[1]
            for n in picked do
            (
                local p = worldPos n
                for k=1 to 3 do (low[k] = amin low[k] p[k]; high[k] = amax high[k] p[k])
            )
            local span = high-low
            local k = if span.x >= span.y and span.x >= span.z then 1 else (if span.y >= span.z then 2 else 3)
            direction = [0,0,0]; direction[k] = 1
        )
        -- Stable insertion sort; node names disambiguate fully collapsed cameras.
        for pass = 1 to (if axisMode == 1 then 2 else 1) do
        (
            for i = 2 to 9 do
            (
                local j = i
                while j > 1 do
                (
                    local a = dot (worldPos picked[j-1]) direction
                    local b = dot (worldPos picked[j]) direction
                    if a > b or (a == b and stricmp picked[j-1].name picked[j].name > 0) then
                    (swap picked[j-1] picked[j]; j -= 1)
                    else exit
                )
            )
            if pass == 1 and axisMode == 1 do
            (
                local mid = if isCamera centerNode then centerNode else picked[5]
                direction = normalize mid.transform.row1
            )
        )
        if isCamera centerNode and picked[5] != centerNode do throw "指定摄影机不是该排列轴上的中间第 5 台，请重新选择中心或排列轴。"
        nodes = picked
        original = for n in nodes collect (worldPos n)
        axis = direction
        axisLabel = #("中心摄影机本地 X", "世界 X", "世界 Y", "世界 Z")[axisMode]
        originalMeanMM = (distance original[1] original[9]) / 8.0 / (mmUnit())
        referenceMM = if originalMeanMM > 0.00001 then originalMeanMM else 3.0
        inputMM = originalMeanMM
        true
    ),

    fn measurements =
    (
        if not valid() do throw "请先绑定 9 台摄影机。"
        for i=1 to 8 collect ((distance (worldPos nodes[i]) (worldPos nodes[i+1])) / (mmUnit()))
    ),

    fn writePositions desired labelText =
    (
        if not valid() do throw "请先绑定 9 台摄影机。"
        checkWritable nodes
        local before = for n in nodes collect (worldPos n)
        local targets = #()
        for n in cameras where isCamera n and isValidNode (getTarget n) do appendIfUnique targets (getTarget n)
        local targetBefore = for t in targets collect (copy t.transform)
        local failed = undefined
        undo labelText recordUndo with animate off
        (
            try
            (
                -- Skip index 5 entirely. Never assign a target or a camera transform.
                for i=1 to 9 where i != 5 do in coordsys world nodes[i].position = desired[i]
                for i=1 to 9 do
                    if distance (worldPos nodes[i]) desired[i] > 0.00001 * (mmUnit()) + 0.0000001 do
                        throw (nodes[i].name + " 未能到达指定位置，已恢复本次操作。")
                for i=1 to targets.count do
                    if targets[i].transform != targetBefore[i] do throw "检测到目标点关联变化，已恢复摄影机位置。"
                if (worldPos nodes[5]) != before[5] do throw "中心摄影机发生关联变化，已恢复摄影机位置。"
            )
            catch
            (
                failed = getCurrentException()
                for i=1 to 9 where i != 5 do in coordsys world nodes[i].position = before[i]
            )
        )
        redrawViews()
        if failed != undefined do throw failed
        true
    ),

    fn applySpacing spacingMM =
    (
        if spacingMM < 0 do throw "间距不能小于 0。"
        if not valid() do throw "请先绑定 9 台摄影机。"
        local center = worldPos nodes[5]
        local desired = for i=1 to 9 collect (center + axis * ((i-5) * spacingMM * (mmUnit())))
        writePositions desired "九机位：调整相邻间距"
        inputMM = spacingMM
        true
    ),

    fn restoreOriginal =
    (
        if not valid() do throw "请先绑定 9 台摄影机。"
        local delta = (worldPos nodes[5]) - original[5]
        local desired = for p in original collect (p+delta)
        writePositions desired "九机位：恢复绑定时排列"
        inputMM = originalMeanMM
        true
    ),

    fn recordText =
    (
        local gaps = measurements()
        local ss = stringStream ""
        format "九机位间距记录 | %\r\n中心：% | 排列轴：%\r\n" localTime nodes[5].name axisLabel to:ss
        format "输入相邻间距：% mm | 输入总跨度：% mm\r\n" (mmText inputMM) (mmText (inputMM*8)) to:ss
        for i=1 to 8 do format "% -> %：% mm\r\n" nodes[i].name nodes[i+1].name (mmText gaps[i]) to:ss
        format "实际首尾跨度：% mm\r\n目标点：保持原位\r\n" (mmText ((distance (worldPos nodes[1]) (worldPos nodes[9]))/(mmUnit()))) to:ss
        ss as string
    )
)

-- Retain a session's bindings and restore snapshot when merely reopening the panel.
if NE9_State == undefined do NE9_State = NE9_SpacingState()

rollout NE9_Rollout "裸眼 3D · 九机位间距 1.0" width:490 height:648
(
    local syncing = false
    label intro "中心固定 · 目标点固定 · 只移动两侧摄影机" pos:[16,12] width:458 height:20
    groupBox bindGroup "1. 绑定摄影机" pos:[10,38] width:470 height:148
    dropdownlist axisChoice "排列轴：" items:#("中心摄影机本地 X（横向）", "世界 X", "世界 Y", "世界 Z") selection:1 pos:[24,58] width:280
    pickbutton pickCenter "指定中心（可选）" autoDisplay:true filter:NE9_State.isCamera pos:[316,75] width:148 height:24
    button bindSelection "绑定选中的 9 台" pos:[24,110] width:205 height:28
    button bindScene "绑定场景中的 9 台" pos:[244,110] width:220 height:28
    label centerLabel "尚未绑定" pos:[24,149] width:326 height:20
    button unbind "解除绑定" pos:[365,147] width:99 height:24
    groupBox spacingGroup "2. 等距展开 / 合拢（毫米）" pos:[10,196] width:470 height:164
    spinner spacing "相邻间距 (mm)：" range:[0,100000000,3] type:#float scale:0.1 fieldWidth:130 pos:[27,219] width:300
    button applyButton "应用数值" pos:[349,216] width:114 height:28
    slider amount "相对绑定间距 (%)" range:[0,300,100] type:#float ticks:6 pos:[24,254] width:438 height:42
    button collapse "完全合拢（0）" pos:[24,314] width:135 height:28
    button baseline "100% 等距排列" pos:[170,314] width:140 height:28
    button restore "恢复绑定时原排列" pos:[321,314] width:142 height:28
    groupBox valuesGroup "3. 实际间距 / 记录" pos:[10,371] width:470 height:217
    edittext measured "当前：" text:"尚未绑定" readOnly:true pos:[24,395] width:438 height:18
    label widthLabel "总跨度：—" pos:[24,423] width:438 height:18
    listbox gapList "每对相邻摄影机的实际距离 (mm)" items:#() height:8 pos:[24,448] width:438
    button copyButton "复制间距记录" pos:[24,595] width:144 height:28
    edittext status "" text:"绑定只读取机位；调整后可用 Ctrl+Z 撤销。" readOnly:true multiLine:true pos:[181,595] width:286 height:40
    timer refreshTimer interval:700 active:true

    fn setStatus txt = (status.text = txt)
    fn refreshValues =
    (
        local ready = NE9_State.valid()
        for c in #(spacing, applyButton, amount, collapse, baseline, restore, copyButton, unbind) do c.enabled = ready
        axisChoice.enabled = not ready
        pickCenter.enabled = not ready
        if ready then
        (
            centerLabel.text = "已绑定 9 台 | 中心：" + NE9_State.nodes[5].name
            local gaps = NE9_State.measurements()
            local lo = amin gaps, hi = amax gaps
            measured.text = if (hi-lo) < 0.0001 then ((NE9_State.mmText ((lo+hi)*0.5)) + " mm（相邻间距）") else ("不等距：" + NE9_State.mmText lo + " ～ " + NE9_State.mmText hi + " mm")
            local widthMM = (distance (NE9_State.worldPos NE9_State.nodes[1]) (NE9_State.worldPos NE9_State.nodes[9])) / (NE9_State.mmUnit())
            widthLabel.text = "实际首尾跨度：" + NE9_State.mmText widthMM + " mm | 基准间距：" + NE9_State.mmText NE9_State.referenceMM + " mm"
            gapList.items = for i=1 to 8 collect (NE9_State.nodes[i].name + " → " + NE9_State.nodes[i+1].name + "  =  " + NE9_State.mmText gaps[i] + " mm")
        )
        else
        (
            centerLabel.text = "尚未绑定（请选择或绑定场景的 9 台摄影机）"
            measured.text = "尚未绑定"; widthLabel.text = "总跨度：—"; gapList.items = #()
        )
    )
    fn syncInput =
    (
        syncing = true
        axisChoice.selection = findItem #("中心摄影机本地 X", "世界 X", "世界 Y", "世界 Z") NE9_State.axisLabel
        spacing.value = NE9_State.inputMM
        spacing.scale = amax 0.001 (NE9_State.referenceMM / 30.0)
        amount.value = amin 300.0 (100.0 * NE9_State.inputMM / NE9_State.referenceMM)
        syncing = false
        refreshValues()
    )
    fn doBind candidates =
    (
        try
        (
            NE9_State.bind candidates axisMode:axisChoice.selection centerNode:pickCenter.object
            syncInput(); setStatus "已绑定。目标点保持原位。"
        ) catch (setStatus (getCurrentException() as string))
    )
    fn doApply value =
    (
        if not syncing do
        (
            try (NE9_State.applySpacing value; syncInput(); setStatus "间距已更新；目标点保持原位。")
            catch (setStatus (getCurrentException() as string))
        )
    )
    on bindSelection pressed do doBind (selection as array)
    on bindScene pressed do doBind (for n in cameras where NE9_State.isCamera n collect n)
    on unbind pressed do (NE9_State.clear(); pickCenter.object = undefined; refreshValues(); setStatus "已解除绑定，可重新选择轴和中心。")
    on spacing changed value do doApply value
    on applyButton pressed do doApply spacing.value
    on amount changed value do doApply (NE9_State.referenceMM * value / 100.0)
    on collapse pressed do doApply 0.0
    on baseline pressed do doApply NE9_State.referenceMM
    on restore pressed do
    (
        try (NE9_State.restoreOriginal(); syncInput(); setStatus "已恢复绑定时排列；目标点保持原位。")
        catch (setStatus (getCurrentException() as string))
    )
    on copyButton pressed do
    (
        try (setClipboardText (NE9_State.recordText()); setStatus "已复制每对间距、中心和总跨度。")
        catch (setStatus (getCurrentException() as string))
    )
    on refreshTimer tick do try (refreshValues()) catch ()
    on NE9_Rollout open do
    (
        if NE9_State.valid() then syncInput() else refreshValues()
    )
)

fn NE9_Open =
(
    try (destroyDialog NE9_Rollout) catch ()
    createDialog NE9_Rollout style:#(#style_titlebar, #style_border, #style_sysmenu, #style_toolwindow)
)
if NE9_NoAutoOpen != true do NE9_Open()
