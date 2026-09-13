-- ============================================================
-- COMBINED v10.1 - SMOOTH TWEEN + RETURN HOME
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    GlobalBoss    = true,
    Chihora       = true,
    Yhwach        = true,
    AutoAttack    = false,
    AttackRate    = 0.1,
    Weapon        = nil,
    SpawnInterval = 0.75,
    DebugMode     = true,
}

-- ============================================================
-- SMOOTH TWEEN HELPER (chống detect + return home)
-- ============================================================
local TweenHelper = {}
TweenHelper.__index = TweenHelper

local MIN_DURATION = 0.35          -- tween tối thiểu (không teleport tức thời)
local MIN_SPEED    = 12            -- studs/s tối thiểu khi speed quá thấp

function TweenHelper.new(hrp)
    local self = setmetatable({}, TweenHelper)
    self.hrp         = hrp
    self.home        = nil         -- vị trí gốc lưu lại
    self.activeTween = nil
    self.returning   = false
    return self
end

function TweenHelper:setHrp(hrp)
    if hrp ~= self.hrp then
        self.hrp = hrp
        self.home = nil            -- reset home khi đổi nhân vật
        self:cancel()
    end
end

-- Lưu vị trí gốc (chỉ lưu 1 lần cho tới khi clearHome)
function TweenHelper:saveHome()
    if self.hrp and not self.home then
        self.home = self.hrp.CFrame
    end
end

function TweenHelper:clearHome()
    self.home = nil
end

function TweenHelper:cancel()
    if self.activeTween then
        pcall(function() self.activeTween:Cancel() end)
        self.activeTween = nil
    end
end

-- Tính duration có jitter để tránh pattern cố định
local function computeDuration(dist, speed)
    if not speed or speed < MIN_SPEED then speed = MIN_SPEED end
    local base = dist / speed
    if base < MIN_DURATION then base = MIN_DURATION end
    -- jitter ±15%
    local jitter = 1 + (math.random() - 0.5) * 0.30
    return base * jitter
end

-- Tween mượt: Sine InOut + jitter, chia 2 chặng để tự nhiên
function TweenHelper:move(targetCFrame, speed, onDone)
    if not self.hrp then return end
    self:cancel()
    self.returning = false

    local dist = (self.hrp.Position - targetCFrame.Position).Magnitude
    if dist < 0.5 then
        -- đã ở gần đích → set nhẹ để không teleport
        local dur = MIN_DURATION
        self.activeTween = TweenService:Create(
            self.hrp,
            TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { CFrame = targetCFrame }
        )
    else
        -- Chia 2 chặng: chặng đầu nhanh hơn (Quad Out), chặng 2 chậm lại (Sine InOut)
        -- để giống chuyển động người thật, không bị "snap"
        local midPos = self.hrp.Position:Lerp(targetCFrame.Position, 0.65)
        local midCF  = CFrame.new(midPos, targetCFrame.Position)
        local dur1   = computeDuration((self.hrp.Position - midPos).Magnitude, speed * 1.1)
        local dur2   = computeDuration((midPos - targetCFrame.Position).Magnitude, speed * 0.9)

        local tween1 = TweenService:Create(
            self.hrp,
            TweenInfo.new(dur1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = midCF }
        )
        local tween2 = TweenService:Create(
            self.hrp,
            TweenInfo.new(dur2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { CFrame = targetCFrame }
        )

        self.activeTween = tween1
        tween1.Completed:Connect(function(st)
            if st ~= Enum.PlaybackState.Completed then return end
            if not self.hrp then return end
            self.activeTween = tween2
            tween2:Play()
            if onDone then
                tween2.Completed:Connect(function(st2)
                    if st2 == Enum.PlaybackState.Completed and onDone then onDone() end
                end)
            end
        end)
    end

    self.activeTween:Play()
    if onDone and not self.activeTween.Completed then
        -- fallback cho nhánh dist < 0.5
    end
end

-- Quay về vị trí gốc mượt mà
function TweenHelper:goHome(speed, onDone)
    if not self.home or not self.hrp then
        if onDone then onDone() end
        return
    end
    self.returning = true
    local homeCF = self.home
    self:move(homeCF, speed or 40, function()
        self.home = nil
        self.returning = false
        if onDone then onDone() end
    end)
end

-- ============================================================
-- UI (giữ nguyên)
-- ============================================================
local pg = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCtrlUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 610)
main.Position = UDim2.new(0, 30, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = main
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(80, 80, 100); s.Thickness = 2; s.Parent = main
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 46)
title.BorderSizePixel = 0
title.Text = "⚙  AUTO CONTROLS v10.1"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = main
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = title
end

-- ===== TOGGLES =====
local toggleHolder = Instance.new("Frame")
toggleHolder.Size = UDim2.new(1, -24, 0, 176)
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
makeToggle("Auto Attack", "AutoAttack", 4)

-- ===== SPAWN INTERVAL =====
local intFrame = Instance.new("Frame")
intFrame.Size = UDim2.new(1, -24, 0, 96)
intFrame.Position = UDim2.new(0, 12, 0, 240)
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
intBox.FocusLost:Connect(function() applyInterval() end)

-- ===== WEAPON =====
local wTitle = Instance.new("TextLabel")
wTitle.Size = UDim2.new(1, -24, 0, 26)
wTitle.Position = UDim2.new(0, 12, 0, 346)
wTitle.BackgroundTransparency = 1
wTitle.Text = "🔫  Weapon (auto equip)"
wTitle.TextXAlignment = Enum.TextXAlignment.Left
wTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
wTitle.Font = Enum.Font.GothamBold
wTitle.TextSize = 14
wTitle.Parent = main

local weaponList = Instance.new("ScrollingFrame")
weaponList.Size = UDim2.new(1, -24, 0, 220)
weaponList.Position = UDim2.new(0, 12, 0, 376)
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
-- AUTO ATTACK
-- ============================================================
task.spawn(function()
    local vim = game:GetService("VirtualInputManager")

    local function doOneAttack()
        local char = LocalPlayer.Character
        if not char then return false end

        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local ok = pcall(function() tool:Activate() end)
            if ok then return true end
        end

        if typeof(mouse1click) == "function" then
            pcall(mouse1click)
            return true
        end

        if typeof(mouse1press) == "function" and typeof(mouse1release) == "function" then
            pcall(function()
                mouse1press()
                task.wait(0.02)
                mouse1release()
            end)
            return true
        end

        if vim then
            pcall(function()
                vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            return true
        end

        return false
    end

    while true do
        if State.AutoAttack then
            doOneAttack()
            local rate = State.AttackRate or 0.1
            if rate < 0.03 then rate = 0.03 end
            task.wait(rate)
        else
            task.wait(0.3)
        end
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
    if not (OfferPanel and PartyPanel and StatusPanel) then
        warn("[AutoJoin] Thiếu panel → thoát")
        return
    end

    local OfferJoin   = findChild(OfferPanel,  "ButtonHolder", "JoinButton")
    local PartyJoin   = findChild(PartyPanel,  "ButtonHolder", "JoinButton")
    local RefreshBtn  = findChild(StatusPanel, "ButtonHolder", "RefreshButton")
    local StatusLabel = findChild(StatusPanel, "StatusLabel")
    local TitleLabel  = findChild(StatusPanel, "TitleLabel")

    print("[AutoJoin] Khởi tạo:")
    print("  - OfferJoin  =", OfferJoin and OfferJoin:GetFullName() or "NIL")
    print("  - PartyJoin  =", PartyJoin and PartyJoin:GetFullName() or "NIL")
    print("  - RefreshBtn =", RefreshBtn and RefreshBtn:GetFullName() or "NIL")
    print("  - StatusLabel=", StatusLabel and StatusLabel:GetFullName() or "NIL")

    local COOLDOWN, JOIN_DEBOUNCE, REFRESH_DEBOUNCE = 0.5, 1.0, 1.5
    local queued = false
    local lastJoinAt, lastRefreshAt = 0, 0
    local lastLogAt = 0

    local function contains(t, kw)
        if type(t) ~= "string" or type(kw) ~= "string" then return false end
        return string.find(string.lower(t), string.lower(kw), 1, true) ~= nil
    end

    local function fireButton(btn, tag)
        if not btn then
            print(("[Fire:%s] btn = nil"):format(tag or "?"))
            return false
        end
        if not btn.Visible then
            print(("[Fire:%s] btn KHÔNG Visible"):format(tag or "?"))
            return false
        end

        pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                btn:Activated()
            end
        end)
        pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                btn.MouseButton1Click:Fire()
            end
        end)
        pcall(function()
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                btn.MouseButton1Down:Fire()
                btn.MouseButton1Up:Fire()
            end
        end)
        pcall(function()
            if firesignal then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            end
        end)
        pcall(function()
            if btn:IsA("GuiButton") then
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                end
            end
        end)

        print(("[Fire:%s] Đã fire nút %s"):format(tag or "?", btn.Name))
        return true
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

    print("[AutoJoin] Bắt đầu vòng lặp...")

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

            if State.DebugMode and (now - lastLogAt) > 2 then
                lastLogAt = now
                print(("[Debug] Status='%s' | queued=%s | OfferJoin.V=%s A=%s"):format(
                    statusText, tostring(queued),
                    tostring(OfferJoin and OfferJoin.Visible),
                    tostring(OfferJoin and OfferJoin.Active)))
            end

            if isOk(statusText) then
                if not queued then print("[AutoJoin] ✅ ĐÃ VÀO QUEUE!") end
                queued = true
            else
                if queued then print("[AutoJoin] 🔄 Queue mất, quay lại join.") end
                queued = false
            end

            local hasErr, kw = isErr(statusText)
            if not hasErr then hasErr, kw = isErr(titleText) end

            if hasErr and RefreshBtn and RefreshBtn.Visible and (now - lastRefreshAt) > REFRESH_DEBOUNCE then
                lastRefreshAt = now
                print(("[AutoJoin] ⚠️ Lỗi (%s) → Refresh"):format(tostring(kw)))
                fireButton(RefreshBtn, "Refresh")
            end

            if not queued and (now - lastJoinAt) > JOIN_DEBOUNCE then
                if OfferJoin and OfferJoin.Visible then
                    if fireButton(OfferJoin, "OfferJoin") then lastJoinAt = now end
                elseif PartyJoin and PartyJoin.Visible then
                    if fireButton(PartyJoin, "PartyJoin") then lastJoinAt = now end
                end
            end

            task.wait(COOLDOWN)
        end
    end
end)

-- ============================================================
-- PART B: YHWACH (smooth + return home)
-- ============================================================
task.spawn(function()
    local CHECK_SLOW, CHECK_FAST = 5, 0.5
    local MOVE_SPEED   = 55      -- studs/s (mượt hơn, không teleport)
    local RETURN_SPEED = 45
    local STANDOFF     = 14

    local tweenH    = nil
    local yhwachOn  = false

    while true do
        local character = LocalPlayer.Character
        local myRoot    = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid")

        if tweenH == nil or tweenH.hrp ~= myRoot then
            tweenH = TweenHelper.new(myRoot)
        else
            tweenH:setHrp(myRoot)
        end

        if not State.Yhwach then
            if yhwachOn then
                yhwachOn = false
                if humanoid then humanoid.PlatformStand = false end
                -- Quay về chỗ cũ khi tắt
                if tweenH.home then
                    tweenH:goHome(RETURN_SPEED)
                end
            end
            task.wait(0.5)
        else
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
                    -- Lưu vị trí gốc lần đầu bám boss
                    tweenH:saveHome()
                    yhwachOn = true
                    if humanoid then humanoid.PlatformStand = true end

                    -- Tính điểm đứng sau lưng, có offset ngẫu nhiên nhẹ
                    local offsetBack  = STANDOFF + (math.random() - 0.5) * 4
                    local offsetSide  = (math.random() - 0.5) * 6
                    local backPos = (targetRoot.CFrame * CFrame.new(offsetSide, 0, offsetBack)).Position
                    local goalCF  = CFrame.new(backPos, targetRoot.Position)

                    tweenH:move(goalCF, MOVE_SPEED)
                end
            else
                if yhwachOn then
                    yhwachOn = false
                    if humanoid then humanoid.PlatformStand = false end
                    -- Boss chết / biến mất → về chỗ cũ
                    if tweenH.home then
                        tweenH:goHome(RETURN_SPEED)
                    end
                end
            end
            task.wait(yhwachOn and CHECK_FAST or CHECK_SLOW)
        end
    end
end)

-- ============================================================
-- PART C: NPC + SPAWN BOSS + CHIHORA (smooth + return home)
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

    local MOVE_SPEED       = 55
    local RETURN_SPEED     = 45
    local BOSS_STANDOFF    = 12
    local NPC_RETWEEN_DIST = 100
    local LOOP_WAIT        = 0.15

    local lastCharacter  = nil
    local tweenH         = nil
    local lastSpawnAt    = 0
    local phase          = "IDLE"

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
                if tweenH and tweenH.home then
                    tweenH:goHome(RETURN_SPEED)
                end
            end
            task.wait(0.5)
        else
            local ok, err = pcall(function()
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")

                if char ~= lastCharacter then
                    lastCharacter = char
                    tweenH        = TweenHelper.new(hrp)
                    phase         = "IDLE"
                else
                    tweenH:setHrp(hrp)
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
                    -- Lưu vị trí gốc lần đầu lao vào boss
                    tweenH:saveHome()
                    phase = "TO_BOSS"

                    local enemyRoot = chihora:FindFirstChild("HumanoidRootPart") or chihora.PrimaryPart
                    if enemyRoot then
                        local myPos, enemyPos = hrp.Position, enemyRoot.Position
                        local dx, dy, dz = myPos.X - enemyPos.X, myPos.Y - enemyPos.Y, myPos.Z - enemyPos.Z
                        local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
                        local ux, uy, uz
                        if mag < 0.5 then ux, uy, uz = 1, 0, 0
                        else ux, uy, uz = dx/mag, dy/mag, dz/mag end

                        -- Offset ngẫu nhiên nhẹ để không đứng y 1 chỗ
                        local jitter = 1 + (math.random() - 0.5) * 0.25
                        local tx = enemyPos.X + ux * BOSS_STANDOFF * jitter
                        local ty = enemyPos.Y + uy * BOSS_STANDOFF * jitter
                        local tz = enemyPos.Z + uz * BOSS_STANDOFF * jitter
                        local targetCF = CFrame.new(Vector3.new(tx, ty, tz), enemyPos)

                        tweenH:move(targetCF, MOVE_SPEED)
                    end
                else
                    -- Không còn boss → về vị trí gốc trước khi làm việc khác
                    if tweenH.home and not tweenH.returning then
                        tweenH:goHome(RETURN_SPEED)
                    end

                    local npcRoot = getNpcRoot()
                    if npcRoot then
                        local npcPos = npcRoot.Position
                        local myPos  = hrp.Position
                        local dx, dy, dz = myPos.X - npcPos.X, myPos.Y - npcPos.Y, myPos.Z - npcPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                        if dist >= NPC_RETWEEN_DIST and not tweenH.returning then
                            phase = "TO_NPC"
                            local lookVec = Vector3.new(npcPos.X - myPos.X, npcPos.Y - myPos.Y, npcPos.Z - myPos.Z)
                            if lookVec.Magnitude < 0.5 then lookVec = Vector3.new(1, 0, 0) end
                            local targetCF = CFrame.new(npcPos, npcPos + lookVec)
                            tweenH:move(targetCF, MOVE_SPEED)
                        else
                            phase = "SPAWNING"
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

print("[COMBINED v10.1] Đã chạy: GlobalBoss + Chihora + Yhwach + AutoAttack + Weapon + SmoothTween + ReturnHome")
