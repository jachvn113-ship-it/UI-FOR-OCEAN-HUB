-- ============================================================
-- COMBINED v8 - UI TO RÕ, CÓ Ô SPAWN INTERVAL
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    GlobalBoss    = true,
    Chihora       = true,
    Yhwach        = true,
    Weapon        = nil,
    SpawnInterval = 0.75,
}

-- ============================================================
-- UI  (TO HƠN, CHỮ RÕ)
-- ============================================================
local pg = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCtrlUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pg

-- ===== KHUNG CHÍNH (TO) =====
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 560)
main.Position = UDim2.new(0, 30, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = main
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(80, 80, 100); s.Thickness = 2; s.Parent = main
end

-- ===== TITLE =====
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
title.BorderSizePixel = 0
title.Text = "⚙  AUTO CONTROLS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = main
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = title
end

-- ===== TOGGLES =====
local toggleHolder = Instance.new("Frame")
toggleHolder.Size = UDim2.new(1, -24, 0, 132)
toggleHolder.Position = UDim2.new(0, 12, 0, 54)
toggleHolder.BackgroundTransparency = 1
toggleHolder.Parent = main
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = toggleHolder
end

local function makeToggle(name, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = toggleHolder
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(70, 70, 90); s.Thickness = 1; s.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(240, 240, 245)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.Parent = btn

    local ind = Instance.new("TextLabel")
    ind.Size = UDim2.new(0, 60, 1, 0)
    ind.Position = UDim2.new(1, -70, 0, 0)
    ind.BackgroundTransparency = 1
    ind.Font = Enum.Font.GothamBold
    ind.TextSize = 14
    ind.Parent = btn

    local function refresh()
        if State[key] then
            ind.Text = "ON"
            ind.TextColor3 = Color3.fromRGB(90, 240, 130)
            btn.BackgroundColor3 = Color3.fromRGB(40, 75, 55)
        else
            ind.Text = "OFF"
            ind.TextColor3 = Color3.fromRGB(255, 100, 100)
            btn.BackgroundColor3 = Color3.fromRGB(70, 42, 42)
        end
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh()
        print(("[UI] %s = %s"):format(name, State[key] and "ON" or "OFF"))
    end)
end

makeToggle("Global Boss", "GlobalBoss", 1)
makeToggle("Chihora",     "Chihora",    2)
makeToggle("Yhwach",      "Yhwach",     3)

-- ===== SPAWN INTERVAL (TO, NỔI BẬT) =====
local intFrame = Instance.new("Frame")
intFrame.Size = UDim2.new(1, -24, 0, 96)
intFrame.Position = UDim2.new(0, 12, 0, 194)
intFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
intFrame.BorderSizePixel = 0
intFrame.Parent = main
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = intFrame
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(90, 90, 120); s.Thickness = 1; s.Parent = intFrame
end

local intLabel = Instance.new("TextLabel")
intLabel.Size = UDim2.new(1, -20, 0, 26)
intLabel.Position = UDim2.new(0, 10, 0, 6)
intLabel.BackgroundTransparency = 1
intLabel.Text = "⏱  Spawn Interval (giây)"
intLabel.TextXAlignment = Enum.TextXAlignment.Left
intLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
intLabel.Font = Enum.Font.GothamBold
intLabel.TextSize = 14
intLabel.Parent = intFrame

-- Hàng dưới: TextBox + nút Apply
local intBox = Instance.new("TextBox")
intBox.Size = UDim2.new(1, -110, 0, 42)
intBox.Position = UDim2.new(0, 10, 0, 42)
intBox.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
intBox.BorderSizePixel = 0
intBox.Text = tostring(State.SpawnInterval)
intBox.PlaceholderText = "vd: 0.1 / 0.5 / 1 / 3"
intBox.TextColor3 = Color3.fromRGB(255, 255, 255)
intBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 165)
intBox.Font = Enum.Font.GothamBold
intBox.TextSize = 18
intBox.ClearTextOnFocus = false
intBox.Parent = intFrame
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = intBox
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(100, 100, 130); s.Thickness = 2; s.Parent = intBox
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 12)
    p.Parent = intBox
end

local applyBtn = Instance.new("TextButton")
applyBtn.Size = UDim2.new(0, 90, 0, 42)
applyBtn.Position = UDim2.new(1, -100, 0, 42)
applyBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
applyBtn.BorderSizePixel = 0
applyBtn.Text = "APPLY"
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.Font = Enum.Font.GothamBold
applyBtn.TextSize = 14
applyBtn.AutoButtonColor = true
applyBtn.Parent = intFrame
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = applyBtn
end

local function applyInterval()
    local n = tonumber(intBox.Text)
    if n and n > 0 and n <= 60 then
        State.SpawnInterval = n
        intBox.TextColor3 = Color3.fromRGB(120, 255, 150)
        applyBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        print(("[UI] SpawnInterval = %.3fs"):format(n))
        task.delay(0.3, function()
            intBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            applyBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
        end)
    else
        intBox.TextColor3 = Color3.fromRGB(255, 110, 110)
        applyBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        warn("[UI] SpawnInterval không hợp lệ (0 < x <= 60).")
        task.delay(0.6, function()
            intBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            applyBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 180)
        end)
    end
end

applyBtn.MouseButton1Click:Connect(applyInterval)
intBox.FocusLost:Connect(function(enterPressed) applyInterval() end)

-- ===== WEAPON =====
local wTitle = Instance.new("TextLabel")
wTitle.Size = UDim2.new(1, -24, 0, 26)
wTitle.Position = UDim2.new(0, 12, 0, 300)
wTitle.BackgroundTransparency = 1
wTitle.Text = "🔫  Weapon (auto equip)"
wTitle.TextXAlignment = Enum.TextXAlignment.Left
wTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
wTitle.Font = Enum.Font.GothamBold
wTitle.TextSize = 14
wTitle.Parent = main

local weaponList = Instance.new("ScrollingFrame")
weaponList.Size = UDim2.new(1, -24, 0, 220)
weaponList.Position = UDim2.new(0, 12, 0, 330)
weaponList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
weaponList.BorderSizePixel = 0
weaponList.ScrollBarThickness = 6
weaponList.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 120)
weaponList.CanvasSize = UDim2.new(0, 0, 0, 0)
weaponList.Parent = main
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = weaponList
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = weaponList
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingRight = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 6)
    p.Parent = weaponList
end

local function refreshWeapons()
    for _, ch in ipairs(weaponList:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char     = LocalPlayer.Character
    local seen, list = {}, {}
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(list, item.Name)
            end
        end
    end
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(list, item.Name)
            end
        end
    end

    if #list == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -12, 0, 32)
        empty.BackgroundTransparency = 1
        empty.Text = "(Không có vũ khí)"
        empty.TextColor3 = Color3.fromRGB(150, 150, 165)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 13
        empty.Parent = weaponList
        return
    end

    for i, name in ipairs(list) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 34)
        btn.BackgroundColor3 = (State.Weapon == name)
            and Color3.fromRGB(60, 110, 190)
            or  Color3.fromRGB(48, 48, 60)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. name
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(240, 240, 245)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.LayoutOrder = i
        btn.Parent = weaponList
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if State.Weapon == name then
                State.Weapon = nil
                print("[UI] Weapon OFF")
            else
                State.Weapon = name
                print("[UI] Weapon = " .. name)
            end
            refreshWeapons()
        end)
    end

    weaponList.CanvasSize = UDim2.new(0, 0, 0, weaponList.UIListLayout.AbsoluteContentSize.Y + 12)
end

task.spawn(function()
    local bp = LocalPlayer:WaitForChild("Backpack", 30)
    if bp then
        bp.ChildAdded:Connect(function() task.wait(0.1); pcall(refreshWeapons) end)
        bp.ChildRemoved:Connect(function() task.wait(0.1); pcall(refreshWeapons) end)
    end
end)
task.spawn(function()
    while true do
        task.wait(2)
        pcall(refreshWeapons)
    end
end)
refreshWeapons()

-- ============================================================
-- WEAPON AUTO-EQUIP
-- ============================================================
task.spawn(function()
    while true do
        if State.Weapon then
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if char and hum and backpack then
                local equipped = char:FindFirstChild(State.Weapon)
                local isTool = equipped and equipped:IsA("Tool")
                if not isTool then
                    local tool = backpack:FindFirstChild(State.Weapon)
                    if tool and tool:IsA("Tool") then
                        pcall(function() hum:EquipTool(tool) end)
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- ============================================================
-- BỘ DỌN RÁC
-- ============================================================
task.spawn(function()
    local lastFull = 0
    while true do
        local now = os.clock()
        if now - lastFull >= 5 then
            lastFull = now
            pcall(function() collectgarbage("collect") end)
        else
            pcall(function() collectgarbage("step") end)
        end
        task.wait(1)
    end
end)

-- ============================================================
-- CACHE
-- ============================================================
local Cache = { enemiesFolder = nil, npcsFolder = nil, lastRefresh = 0, TTL = 2.0 }
local function refreshCache(force)
    local now = os.clock()
    if not force and (now - Cache.lastRefresh) < Cache.TTL then return end
    Cache.lastRefresh   = now
    Cache.enemiesFolder = Workspace:FindFirstChild("Enemies")
    Cache.npcsFolder    = Workspace:FindFirstChild("NPCs")
end

-- ============================================================
-- PART A: AUTO GLOBAL BOSS
-- ============================================================
task.spawn(function()
    local prompt = pg:WaitForChild("GlobalBossPrompt", 30)
    if not prompt then warn("[AutoJoin] Không có prompt") return end

    local function findChild(parent, ...)
        if not parent then return nil end
        local node = parent
        for _, name in ipairs({...}) do
            if not node then return nil end
            node = node:FindFirstChild(name)
        end
        return node
    end

    local OfferPanel  = prompt:WaitForChild("OfferPanel", 10)
    local PartyPanel  = prompt:WaitForChild("PartyPanel", 10)
    local StatusPanel = prompt:WaitForChild("StatusPanel", 10)
    if not (OfferPanel and PartyPanel and StatusPanel) then return end

    local OfferJoin   = findChild(OfferPanel,  "ButtonHolder", "JoinButton")
    local PartyJoin   = findChild(PartyPanel,  "ButtonHolder", "JoinButton")
    local RefreshBtn  = findChild(StatusPanel, "ButtonHolder", "RefreshButton")
    local StatusLabel = findChild(StatusPanel, "StatusLabel")
    local TitleLabel  = findChild(StatusPanel, "TitleLabel")

    local COOLDOWN, JOIN_DEBOUNCE, REFRESH_DEBOUNCE = 0.5, 1.0, 1.5
    local queued = false
    local lastJoinAt, lastRefreshAt = 0, 0

    local function contains(t, kw)
        if type(t) ~= "string" or type(kw) ~= "string" then return false end
        return string.find(string.lower(t), string.lower(kw), 1, true) ~= nil
    end
    local function fireButton(btn)
        if not btn or not btn.Visible or btn.Active == false then return false end
        return pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then btn:Activated() end
        end)
    end
    local ERR = {"GlobalBoss service is unavailable","Try again","unavailable","error","failed","unable","retry"}
    local function isErr(t)
        if type(t) ~= "string" then return false end
        for _, kw in ipairs(ERR) do
            if contains(t, kw) then return true, kw end
        end
        return false, nil
    end
    local function isOk(t)
        return contains(t, "queued for the GlobalBoss") and contains(t, "Parties will never be split")
    end

    while true do
        if not State.GlobalBoss then
            task.wait(0.5)
        else
            if not prompt or not prompt.Parent then
                prompt = pg:WaitForChild("GlobalBossPrompt", 30)
                if not prompt then break end
                OfferPanel  = prompt:WaitForChild("OfferPanel", 10)
                PartyPanel  = prompt:WaitForChild("PartyPanel", 10)
                StatusPanel = prompt:WaitForChild("StatusPanel", 10)
                OfferJoin   = findChild(OfferPanel,  "ButtonHolder", "JoinButton")
                PartyJoin   = findChild(PartyPanel,  "ButtonHolder", "JoinButton")
                RefreshBtn  = findChild(StatusPanel, "ButtonHolder", "RefreshButton")
                StatusLabel = findChild(StatusPanel, "StatusLabel")
                TitleLabel  = findChild(StatusPanel, "TitleLabel")
            end
            local now = os.clock()
            local statusText = (StatusLabel and StatusLabel.Text) or ""
            local titleText  = (TitleLabel  and TitleLabel.Text)  or ""

            if isOk(statusText) then
                queued = true
            else
                queued = false
            end

            local hasErr, kw = isErr(statusText)
            if not hasErr then hasErr, kw = isErr(titleText) end

            if hasErr and RefreshBtn and RefreshBtn.Visible and (now - lastRefreshAt) > REFRESH_DEBOUNCE then
                lastRefreshAt = now
                fireButton(RefreshBtn)
            end

            if not queued and (now - lastJoinAt) > JOIN_DEBOUNCE then
                if OfferJoin and OfferJoin.Visible and OfferJoin.Active ~= false then
                    if fireButton(OfferJoin) then lastJoinAt = now end
                elseif PartyJoin and PartyJoin.Visible and PartyJoin.Active ~= false then
                    if fireButton(PartyJoin) then lastJoinAt = now end
                end
            end
            task.wait(COOLDOWN)
        end
    end
end)

-- ============================================================
-- PART B: YHWACH
-- ============================================================
task.spawn(function()
    local CHECK_SLOW, CHECK_FAST = 5, 0.5
    local TWEEN_DISTANCE, TWEEN_TIME = 20, 1
    local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local currentTween, yhwachPresent = nil, false

    local function stopTween()
        if currentTween then
            pcall(function() currentTween:Cancel() end)
            currentTween = nil
        end
    end

    while true do
        if not State.Yhwach then
            if yhwachPresent then
                yhwachPresent = false
                stopTween()
                local ch = LocalPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
            task.wait(0.5)
        else
            local character = LocalPlayer.Character
            local myRoot    = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid  = character and character:FindFirstChild("Humanoid")
            refreshCache()
            local yhwach = Cache.enemiesFolder and Cache.enemiesFolder:FindFirstChild("Yhwach")
            local alive = false
            if yhwach then
                local hum = yhwach:FindFirstChildOfClass("Humanoid")
                alive = (hum == nil) or (hum.Health > 0)
            end
            if myRoot and yhwach and alive then
                local targetRoot = yhwach:FindFirstChild("HumanoidRootPart")
                    or yhwach.PrimaryPart
                    or yhwach:FindFirstChild("Torso")
                    or yhwach:FindFirstChild("UpperTorso")
                if targetRoot then
                    yhwachPresent = true
                    local backPosition = (targetRoot.CFrame * CFrame.new(0, 0, TWEEN_DISTANCE)).Position
                    local goalCFrame   = CFrame.new(backPosition, targetRoot.Position)
                    if humanoid then humanoid.PlatformStand = true end
                    stopTween()
                    currentTween = TweenService:Create(myRoot, tweenInfo, { CFrame = goalCFrame })
                    currentTween:Play()
                end
            else
                if yhwachPresent then
                    yhwachPresent = false
                    stopTween()
                end
                if humanoid then humanoid.PlatformStand = false end
            end
            task.wait(yhwachPresent and CHECK_FAST or CHECK_SLOW)
        end
    end
end)

-- ============================================================
-- PART C: NPC + SPAWN BOSS + CHIHORA
-- ============================================================
task.spawn(function()
    local Remotes   = ReplicatedStorage:WaitForChild("Remotes", 30)
    local Events    = Remotes:WaitForChild("Events", 30)
    local Functions = Remotes:WaitForChild("Functions", 30)
    local GoldShopBuy = Events:WaitForChild("GoldShopBuy", 30)
    local InputRemote = Functions:WaitForChild("Input", 30)

    task.spawn(function()
        while true do
            if State.Chihora then
                pcall(function() GoldShopBuy:FireServer("Boss Ticket", 100) end)
            end
            task.wait(3)
        end
    end)

    local TWEEN_SPEED      = 75
    local ARRIVE_DIST      = 6
    local BOSS_STANDOFF    = 10
    local LOOP_WAIT        = 0.15
    local NPC_RETWEEN_DIST = 100
    local BOSS_TWEEN_CD    = 5

    local lastCharacter   = nil
    local currentTween    = nil
    local npcTweenActive  = false
    local lastSpawnAt     = 0
    local lastBossTweenAt = 0
    local phase           = "IDLE"

    local function stopTween()
        if currentTween then
            pcall(function() currentTween:Cancel() end)
            currentTween = nil
        end
    end

    local function tweenAtSpeed(hrp, targetCFrame, speed, onDone)
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        local duration = math.max(dist / speed, 0.05)
        stopTween()
        currentTween = TweenService:Create(
            hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { CFrame = targetCFrame }
        )
        if onDone then
            currentTween.Completed:Connect(function(state)
                if state == Enum.PlaybackState.Completed then onDone() end
            end)
        end
        currentTween:Play()
    end

    local function trySpawnBoss(now)
        local interval = State.SpawnInterval or 0.75
        if interval < 0.05 then interval = 0.05 end
        if now - lastSpawnAt < interval then return end
        lastSpawnAt = now
        task.spawn(function()
            pcall(function()
                InputRemote:InvokeServer("SpawnBoss", "PauPau Whisperer", "Chihora", "Extreme")
            end)
        end)
    end

    local function getNpcRoot()
        local npc = Cache.npcsFolder and Cache.npcsFolder:FindFirstChild("PauPau Whisperer")
        if not npc then return nil end
        return npc:FindFirstChild("HumanoidRootPart")
            or npc.PrimaryPart
            or npc:FindFirstChild("Torso")
            or npc:FindFirstChild("UpperTorso")
    end

    while true do
        if not State.Chihora then
            if phase ~= "OFF" then
                phase = "OFF"
                stopTween()
                npcTweenActive = false
            end
            task.wait(0.5)
        else
            local ok, err = pcall(function()
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if char ~= lastCharacter then
                    lastCharacter   = char
                    npcTweenActive  = false
                    lastBossTweenAt = 0
                    phase           = "IDLE"
                    stopTween()
                end
                if not hrp then return end
                refreshCache()
                local chihora = Cache.enemiesFolder and Cache.enemiesFolder:FindFirstChild("Chihora")
                local chihoraAlive = false
                if chihora then
                    local hum = chihora:FindFirstChildOfClass("Humanoid")
                    chihoraAlive = (hum == nil) or (hum.Health > 0)
                end
                if chihora and chihoraAlive then
                    if phase ~= "TO_BOSS" then
                        phase = "TO_BOSS"
                        lastBossTweenAt = 0
                    end
                    local now = os.clock()
                    if now - lastBossTweenAt >= BOSS_TWEEN_CD then
                        lastBossTweenAt = now
                        local enemyRoot = chihora:FindFirstChild("HumanoidRootPart") or chihora.PrimaryPart
                        if enemyRoot then
                            local myPos, enemyPos = hrp.Position, enemyRoot.Position
                            local dx, dy, dz = myPos.X - enemyPos.X, myPos.Y - enemyPos.Y, myPos.Z - enemyPos.Z
                            local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
                            local ux, uy, uz
                            if mag < 0.5 then ux, uy, uz = 1, 0, 0
                            else ux, uy, uz = dx/mag, dy/mag, dz/mag end
                            local tx = enemyPos.X + ux * BOSS_STANDOFF
                            local ty = enemyPos.Y + uy * BOSS_STANDOFF
                            local tz = enemyPos.Z + uz * BOSS_STANDOFF
                            local targetCF = CFrame.new(Vector3.new(tx, ty, tz), enemyPos)
                            tweenAtSpeed(hrp, targetCF, TWEEN_SPEED)
                        end
                    end
                else
                    local npcRoot = getNpcRoot()
                    if npcRoot then
                        local npcPos = npcRoot.Position
                        local myPos  = hrp.Position
                        local dx, dy, dz = myPos.X - npcPos.X, myPos.Y - npcPos.Y, myPos.Z - npcPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist >= NPC_RETWEEN_DIST and not npcTweenActive then
                            npcTweenActive = true
                            phase = "TO_NPC"
                            local lookVec = Vector3.new(npcPos.X - myPos.X, npcPos.Y - myPos.Y, npcPos.Z - myPos.Z)
                            if lookVec.Magnitude < 0.5 then lookVec = Vector3.new(1, 0, 0) end
                            local targetCF = CFrame.new(npcPos, npcPos + lookVec)
                            tweenAtSpeed(hrp, targetCF, TWEEN_SPEED, function()
                                npcTweenActive = false
                            end)
                        elseif npcTweenActive then
                            -- chờ
                        else
                            if phase ~= "SPAWNING" then
                                phase = "SPAWNING"
                            end
                            trySpawnBoss(os.clock())
                        end
                    end
                end
            end)
            if not ok then warn("[PART C] Lỗi: " .. tostring(err)) end
            task.wait(LOOP_WAIT)
        end
    end
end)

print("[COMBINED v8] UI to rõ + SpawnInterval + Weapon + Cache")
