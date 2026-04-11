--[[
    🌊 Ocean Hub - Loader
    Auto-detect IP → VN thì hiện GUI tiếng Việt + shoptdang.vn
    Nước ngoài thì hiện GUI English + Linkvertise
]]

local GETKEY_URL = "https://ads.luarmor.net/get_key?for=OCEAN_HUB-VKrSguUYfFjq"
local BUYKEY_URL = "https://shoptdang.vn/cloudphone"
local LUARMOR_URL = "https://api.luarmor.net/files/v4/loaders/e18db1da2d589242931944ef08da4f1c.lua"

-- Check if user is from Vietnam via IP
local isVN = false
pcall(function()
    local geo = game:HttpGet("http://ip-api.com/json/?fields=countryCode")
    if geo and geo:find('"VN"') then
        isVN = true
    end
end)

-- Xoá GUI cũ nếu có
if game:GetService("CoreGui"):FindFirstChild("SailorKeyGui") then
    game:GetService("CoreGui"):FindFirstChild("SailorKeyGui"):Destroy()
end

local TweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Name = "SailorKeyGui"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Parent = gui
TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()

-- ========== BUILD GUI ==========

local frameHeight = isVN and 420 or 340

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, frameHeight)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -frameHeight/2)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Transparency = 0.7
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Colors based on region
if isVN then
    stroke.Color = Color3.fromRGB(250, 204, 21) -- gold border for VN
else
    stroke.Color = Color3.fromRGB(56, 189, 248) -- blue border for intl
end

-- Icon
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(1, 0, 0, 45)
icon.Position = UDim2.new(0, 0, 0, 18)
icon.BackgroundTransparency = 1
icon.Text = "\226\154\147" -- ⚓
icon.TextSize = 36
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0, 62)
title.BackgroundTransparency = 1
title.Text = "Ocean Hub"
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextColor3 = isVN and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(56, 189, 248)
title.Parent = mainFrame

-- Subtitle
local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 88)
sub.BackgroundTransparency = 1
sub.Text = isVN and "Nhap key de tiep tuc su dung script" or "Enter your key to continue"
sub.TextSize = 12
sub.Font = Enum.Font.Gotham
sub.TextColor3 = Color3.fromRGB(148, 163, 184)
sub.Parent = mainFrame

-- Input frame
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(0, 320, 0, 44)
inputFrame.Position = UDim2.new(0.5, -160, 0, 125)
inputFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
inputFrame.BorderSizePixel = 0
inputFrame.Parent = mainFrame
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 10)

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(55, 65, 81)
inputStroke.Thickness = 1
inputStroke.Parent = inputFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -20, 1, 0)
keyInput.Position = UDim2.new(0, 10, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.Text = ""
keyInput.PlaceholderText = isVN and "Dan key vao day..." or "Paste your key here..."
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
keyInput.TextColor3 = Color3.fromRGB(56, 189, 248)
keyInput.TextSize = 14
keyInput.Font = Enum.Font.Code
keyInput.ClearTextOnFocus = false
keyInput.Parent = inputFrame

-- Submit button
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0, 320, 0, 42)
submitBtn.Position = UDim2.new(0.5, -160, 0, 185)
submitBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
submitBtn.BorderSizePixel = 0
submitBtn.Text = isVN and "Xac Nhan Key" or "Submit Key"
submitBtn.TextSize = 15
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.AutoButtonColor = true
submitBtn.Parent = mainFrame
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 10)

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1
status.Text = ""
status.TextSize = 12
status.Font = Enum.Font.GothamSemibold
status.TextColor3 = Color3.fromRGB(239, 68, 68)
status.Parent = mainFrame

-- ========== BUTTONS BASED ON REGION ==========

if isVN then
    -- ========== VIETNAMESE GUI ==========
    
    -- Divider line
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 280, 0, 1)
    divider.Position = UDim2.new(0.5, -140, 0, 240)
    divider.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
    divider.BorderSizePixel = 0
    divider.Parent = mainFrame
    
    -- "Chua co key?" label
    local noKeyLabel = Instance.new("TextLabel")
    noKeyLabel.Size = UDim2.new(1, 0, 0, 18)
    noKeyLabel.Position = UDim2.new(0, 0, 0, 250)
    noKeyLabel.BackgroundTransparency = 1
    noKeyLabel.Text = "Chua co key? Chon 1 trong 2 cach:"
    noKeyLabel.TextSize = 11
    noKeyLabel.Font = Enum.Font.Gotham
    noKeyLabel.TextColor3 = Color3.fromRGB(100, 116, 139)
    noKeyLabel.Parent = mainFrame
    
    -- Primary: Buy Key (shoptdang.vn)
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, 320, 0, 42)
    buyBtn.Position = UDim2.new(0.5, -160, 0, 275)
    buyBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 15)
    buyBtn.BorderSizePixel = 0
    buyBtn.Text = "\240\159\155\146 Mua Key Tai shoptdang.vn (28 Coin)"
    buyBtn.TextSize = 13
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextColor3 = Color3.fromRGB(250, 204, 21)
    buyBtn.AutoButtonColor = true
    buyBtn.Parent = mainFrame
    Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 10)
    
    local buyStroke = Instance.new("UIStroke")
    buyStroke.Color = Color3.fromRGB(250, 204, 21)
    buyStroke.Transparency = 0.5
    buyStroke.Thickness = 1
    buyStroke.Parent = buyBtn
    
    -- Secondary: Get Key Free (Linkvertise)
    local freeBtn = Instance.new("TextButton")
    freeBtn.Size = UDim2.new(0, 320, 0, 36)
    freeBtn.Position = UDim2.new(0.5, -160, 0, 327)
    freeBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
    freeBtn.BorderSizePixel = 0
    freeBtn.Text = "\240\159\148\151 Lay Key Mien Phi (Linkvertise)"
    freeBtn.TextSize = 12
    freeBtn.Font = Enum.Font.Gotham
    freeBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
    freeBtn.AutoButtonColor = true
    freeBtn.Parent = mainFrame
    Instance.new("UICorner", freeBtn).CornerRadius = UDim.new(0, 8)
    
    status.Position = UDim2.new(0, 0, 0, 375)
    
    -- Events
    buyBtn.MouseButton1Click:Connect(function()
        pcall(function() if setclipboard then setclipboard(BUYKEY_URL) end end)
        status.TextColor3 = Color3.fromRGB(250, 204, 21)
        status.Text = "Da copy link! Vao shoptdang.vn de mua key"
        task.delay(4, function() pcall(function() status.Text = "" end) end)
    end)
    
    freeBtn.MouseButton1Click:Connect(function()
        pcall(function() if setclipboard then setclipboard(GETKEY_URL) end end)
        status.TextColor3 = Color3.fromRGB(56, 189, 248)
        status.Text = "Da copy link! Mo browser de lay key"
        task.delay(3, function() pcall(function() status.Text = "" end) end)
    end)

else
    -- ========== INTERNATIONAL GUI ==========
    
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0, 320, 0, 38)
    getKeyBtn.Position = UDim2.new(0.5, -160, 0, 237)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "Get Key (Free)"
    getKeyBtn.TextSize = 13
    getKeyBtn.Font = Enum.Font.GothamSemibold
    getKeyBtn.TextColor3 = Color3.fromRGB(129, 140, 248)
    getKeyBtn.AutoButtonColor = true
    getKeyBtn.Parent = mainFrame
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 10)
    
    local gkStroke = Instance.new("UIStroke")
    gkStroke.Color = Color3.fromRGB(129, 140, 248)
    gkStroke.Transparency = 0.6
    gkStroke.Thickness = 1
    gkStroke.Parent = getKeyBtn
    
    status.Position = UDim2.new(0, 0, 0, 290)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        pcall(function() if setclipboard then setclipboard(GETKEY_URL) end end)
        status.TextColor3 = Color3.fromRGB(56, 189, 248)
        status.Text = "Link copied! Open in browser"
        task.delay(3, function() pcall(function() status.Text = "" end) end)
    end)
end

-- ========== SHARED EVENTS ==========

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
closeBtn.Parent = mainFrame

-- Input focus effects
keyInput.Focused:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(56, 189, 248)}):Play()
end)
keyInput.FocusLost:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(55, 65, 81)}):Play()
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Submit → set script_key → ẩn GUI → load Luarmor script
submitBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text:gsub("%s+", "")
    if key == "" then
        status.TextColor3 = Color3.fromRGB(239, 68, 68)
        status.Text = isVN and "Vui long nhap key!" or "Please enter a key!"
        return
    end

    -- Disable nút + hiện loading
    submitBtn.Text = isVN and "Dang xac nhan..." or "Verifying..."
    submitBtn.BackgroundColor3 = Color3.fromRGB(100, 116, 139)
    submitBtn.AutoButtonColor = false
    status.TextColor3 = Color3.fromRGB(250, 204, 21)
    status.Text = isVN and "Dang kiem tra key, vui long cho..." or "Checking key, please wait..."

    -- Set script_key cho Luarmor
    getgenv().script_key = key

    task.wait(0.2)

    -- Ẩn GUI ngay trước khi load (để user thấy script chạy)
    local function hideGui()
        TweenService:Create(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        TweenService:Create(mainFrame, TweenInfo.new(0.25), {Position = UDim2.new(0.5, -190, 0, -500)}):Play()
        task.wait(0.3)
        gui:Destroy()
    end

    -- Load Luarmor script (Luarmor sẽ verify key server-side)
    local success, err = pcall(function()
        loadstring(game:HttpGet(LUARMOR_URL))()
    end)

    if success then
        -- Key đúng → Luarmor load xong → ẩn GUI
        hideGui()
    else
        -- Key sai hoặc lỗi → hiện lại GUI
        local errMsg = tostring(err)
        status.TextColor3 = Color3.fromRGB(239, 68, 68)
        if errMsg:find("key") or errMsg:find("Key") or errMsg:find("whitelist") then
            status.Text = isVN and "Key khong hop le hoac het han!" or "Invalid or expired key!"
        elseif errMsg:find("Executor") or errMsg:find("support") then
            status.Text = isVN and "Executor khong ho tro! Thu dung executor khac" or "Executor not supported!"
        else
            status.Text = "Error: " .. errMsg:sub(1, 50)
        end
        submitBtn.Text = isVN and "Xac Nhan Key" or "Submit Key"
        submitBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        submitBtn.AutoButtonColor = true
        -- Shake effect
        local orig = mainFrame.Position
        for i = 1, 3 do
            mainFrame.Position = orig + UDim2.new(0, 8, 0, 0)
            task.wait(0.05)
            mainFrame.Position = orig + UDim2.new(0, -8, 0, 0)
            task.wait(0.05)
        end
        mainFrame.Position = orig
    end
end)

-- Enter to submit
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitBtn.MouseButton1Click:Fire()
    end
end)
