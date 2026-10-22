/* Disposable fixtures only. Does not move or save the user's cameras. */
(
    local made = #(), report = #(), failure = undefined
    local priorSelection = selection as array
    local priorNodes = objects as array
    local priorCameraNodes = for c in cameras where superclassof c == camera collect c
    local priorCameraTM = for c in priorCameraNodes collect (copy c.transform)
    local priorTargets = #()
    for c in priorCameraNodes do
    (
        local t = try(c.target)catch(undefined)
        if isValidNode t do appendIfUnique priorTargets t
    )
    local priorTargetTM = for t in priorTargets collect (copy t.transform)

    fn assertNE9 condition description = (if not condition do throw description)
    fn closePoint a b = (distance a b < 0.0000002)

    with undo off with redraw off
    (
        try
        (
            local cams = #(), targets = #()
            for i=1 to 9 do
            (
                local t = targetObject name:(uniqueName "NE9_TEST_TARGET_") pos:[10,11,4]
                append made t; append targets t
                local c = targetCamera name:("NE9_TEST_CAM_" + formattedPrint i format:"02d") pos:[10+(i-5)*0.003,-10,4] target:t
                append made c; append cams c
            )
            local state = NE9_SpacingState recordUndo:false
            state.bind #(cams[9],cams[1],cams[7],cams[2],cams[5],cams[8],cams[3],cams[6],cams[4]) axisMode:2 centerNode:cams[5]
            assertNE9 (state.nodes[5] == cams[5]) "Spatial center/order failed"
            local start = for c in cams collect (copy c.transform.row4)
            local targetStart = for t in targets collect (copy t.transform)
            local unitMM = state.mmUnit()
            for spacingMM in #(3.0, 12.345, 0.0, 6.0, 1.25) do
            (
                state.applySpacing spacingMM
                for i=1 to 9 do
                    assertNE9 (closePoint cams[i].transform.row4 (start[5]+[1,0,0]*((i-5)*spacingMM*unitMM))) "Absolute spacing or fixed center failed"
                for i=1 to 9 do assertNE9 (targets[i].transform == targetStart[i]) "Target transform changed"
            )
            state.restoreOriginal()
            for i=1 to 9 do assertNE9 (closePoint cams[i].transform.row4 start[i]) "Restore failed"
            append report "PASS: target cameras, spatial sorting, 0/1.25/3/6/12.345 mm, fixed center/targets, no drift, restore"

            -- Nonuniform input, copied measurements and exact original arrangement.
            in coordsys world cams[4].position += [0.0002,0,0]
            state.bind cams axisMode:2
            local uneven = for c in cams collect (copy c.transform.row4)
            state.applySpacing 4
            local measured = state.measurements()
            for gap in measured do assertNE9 (abs(gap-4.0) < 0.001) "Measured spacing failed"
            assertNE9 ((findString (state.recordText()) "mm") != undefined) "Measurement record failed"
            state.restoreOriginal()
            for i=1 to 9 do assertNE9 (closePoint cams[i].transform.row4 uneven[i]) "Nonuniform restore failed"
            append report "PASS: uneven arrangement restore, millimeter measurements and record"

            local freeCams = #()
            local rot = eulerAngles 15 10 33
            local basis = (rot as quat) as matrix3
            for i=1 to 9 do
            (
                local c = freeCamera name:(uniqueName "NE9_TEST_FREE_")
                append made c; append freeCams c
                c.transform = matrix3 basis.row1 basis.row2 basis.row3 ([25,25,25]+basis.row1*((i-5)*0.006))
            )
            state.bind freeCams axisMode:1
            local middleTM = copy state.nodes[5].transform
            state.applySpacing 8
            for i=1 to 9 do
            (
                assertNE9 (closePoint state.nodes[i].transform.row4 (middleTM.row4+normalize(middleTM.row1)*((i-5)*8*unitMM))) "Local X axis failed"
                assertNE9 (closePoint state.nodes[i].transform.row1 basis.row1) "Free camera orientation changed"
            )
            state.restoreOriginal()
            state.bind freeCams axisMode:3
            state.applySpacing 7
            for gap in (state.measurements()) do assertNE9 (abs(gap-7.0) < 0.002) "World Y failed"
            append report "PASS: rotated free cameras, local X, world Y, orientation preserved"

            local rejected = false
            try (state.bind #(cams[1],cams[2])) catch (rejected=true)
            assertNE9 rejected "Wrong camera count was accepted"
            animate on (at time 0 cams[1].position.x = 10; at time 10 cams[1].position.x = 11)
            rejected = false
            try (state.bind cams axisMode:2) catch (rejected=true)
            assertNE9 rejected "Animated position was accepted"
            append report "PASS: wrong-count and animated-position guards"
        )
        catch (failure = getCurrentException() as string)
        for n in made where isValidNode n do delete n
    )
    if priorSelection.count > 0 then select priorSelection else clearSelection()
    assertNE9 (objects.count == priorNodes.count) "Fixture cleanup failed"
    for i=1 to priorCameraNodes.count do assertNE9 (priorCameraNodes[i].transform == priorCameraTM[i]) "User camera changed"
    for i=1 to priorTargets.count do assertNE9 (priorTargets[i].transform == priorTargetTM[i]) "User target changed"
    if failure != undefined do throw failure
    append report "PASS: all fixtures removed; user's camera and target transforms unchanged"
    report
)
