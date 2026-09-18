local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Input")

local targetSealNum = nil
local isBusy = false
local hasEnemies = false

-- ==========================================
-- PHẦN 1: BẮT TIN NHẮN CHAT (CHRONO SEAL)
-- ==========================================
local function checkText(text)
	if not text or text == "" then return false end
	local cleanText = text:gsub("<.->", "")
	local lowerText = cleanText:lower()
	local sealNum = string.match(lowerText, "seal%s*(%d+)")
	if sealNum then return tonumber(sealNum) end
	return false
end

local function onMessageFound(sealNum)
	print(">>> ĐÃ BẮT ĐƯỢC CHRONO SEAL:", sealNum)
	targetSealNum = sealNum
end

local function hookLabel(label)
	local sealNum = checkText(label.Text)
	if sealNum then onMessageFound(sealNum) end
	label:GetPropertyChangedSignal("Text"):Connect(function()
		local newSealNum = checkText(label.Text)
		if newSealNum then onMessageFound(newSealNum) end
	end)
end

local function scanUI(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if (child:IsA("TextLabel") or child:IsA("TextButton")) and not child:GetFullName():find("DevConsole") then
			hookLabel(child)
		end
	end
	parent.DescendantAdded:Connect(function(child)
		if (child:IsA("TextLabel") or child:IsA("TextButton")) and not child:GetFullName():find("DevConsole") then
			task.wait(0.1)
			hookLabel(child)
		end
	end)
end
pcall(function() scanUI(CoreGui) end)
scanUI(playerGui)

-- ==========================================
-- PHẦN 2: LUỒNG CHẠY NGẦM CHECK QUÁI
-- ==========================================
task.spawn(function()
	while task.wait(0.5) do
		local enemiesFolder = workspace:FindFirstChild("Enemies")
		local found = false
		
		if enemiesFolder then
			for _, enemy in ipairs(enemiesFolder:GetChildren()) do
				if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
					if enemy.Humanoid.Health > 0 then
						found = true
						break
					end
				end
			end
		end
		
		if hasEnemies ~= found then
			hasEnemies = found
			print(hasEnemies and "[DEBUG] Phát hiện quái!" or "[DEBUG] Đã dọn sạch quái!")
		end
	end
end)

-- ==========================================
-- PHẦN 3: HÀM TWEEN AN TOÀN
-- ==========================================
local function safeTween(hrp, targetCFrame, speed, useDashBypass)
	local maxAttempts = 5
	local attempt = 0
	while attempt < maxAttempts do
		attempt = attempt + 1
		local startPos = hrp.Position
		local targetPos = targetCFrame.Position
		local distance = (startPos - targetPos).Magnitude
		if distance < 5 then break end
		
		local duration = distance / speed
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
		tween:Play()
		
		if useDashBypass then
			task.spawn(function()
				local dashStart = tick()
				while tick() - dashStart < duration do
					if hrp and hrp.Parent then
						pcall(function() remote:FireServer("Dash", hrp.CFrame) end)
					end
					task.wait(0.1)
				end
			end)
		end
		
		tween.Completed:Wait()
		task.wait(0.2)
		
		if hrp and hrp.Parent then
			local currentDistance = (hrp.Position - targetPos).Magnitude
			if currentDistance > 15 then
				warn(string.format("[DEBUG] Bị kéo về! Còn %.1f studs. Thử lại...", currentDistance))
			else
				break
			end
		else
			break
		end
	end
end

-- ==========================================
-- PHẦN 4: CÁC HÀM HỖ TRỢ
-- ==========================================
local function getTarget()
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then return nil end
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
			if enemy.Humanoid.Health > 0 then return enemy end
		end
	end
	return nil
end

local function findChronoSealFolder(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == "Chrono Seal" then return child
		elseif child:IsA("Folder") or child:IsA("Model") or child:IsA("Workspace") then
			local found = findChronoSealFolder(child)
			if found then return found end
		end
	end
	return nil
end

local function fightEnemy(target, myHrp)
	print("Đánh: " .. target.Name)
	local enemyHrp = target:FindFirstChild("HumanoidRootPart")
	
	local targetCFrame = enemyHrp.CFrame * CFrame.new(0, 0, 5)
	safeTween(myHrp, targetCFrame, 300, true)
	
	while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
		local currentEnemyHrp = target:FindFirstChild("HumanoidRootPart")
		if currentEnemyHrp then
			myHrp.CFrame = currentEnemyHrp.CFrame * CFrame.new(0, 0, 5)
			
			pcall(function() remote:FireServer("Dash", currentEnemyHrp.CFrame) end)
			
			local worldTool = player.Character:FindFirstChild("The World")
			if worldTool then
				pcall(function() remote:FireServer("Tool", worldTool, "Z", currentEnemyHrp.Position) end)
				pcall(function() remote:FireServer("Tool", worldTool, "X", currentEnemyHrp.Position) end)
				pcall(function() remote:FireServer("Tool", worldTool, "C", currentEnemyHrp.Position) end)
			end
		end
		-- TỐI ƯU: Giảm từ 0.15 xuống 0.05 để spam nhanh hơn
		task.wait(0.05) 
	end
	print("Đã hạ " .. target.Name)
end

local function processSeal(sealNum, myHrp)
	print("Đang tìm Chrono Seal", sealNum, "...")
	local chronoSealFolder = findChronoSealFolder(workspace)
	if not chronoSealFolder then targetSealNum = nil return end
	
	local sealObj = chronoSealFolder:FindFirstChild(tostring(sealNum))
	if not sealObj then
		local timeout = tick() + 5
		while tick() < timeout do
			sealObj = chronoSealFolder:FindFirstChild(tostring(sealNum))
			if sealObj then break end
			task.wait(0.1)
		end
	end
	if not sealObj then targetSealNum = nil return end
	
	local sealPos = sealObj:IsA("BasePart") and sealObj.Position or sealObj:GetPivot().Position
	local targetCFrame = CFrame.new(sealPos) * CFrame.new(0, 5, 0)
	safeTween(myHrp, targetCFrame, 50, true)
	
	print("Đã tới Seal! Bắt đầu spam V và F cực nhanh...")
	
	local tool = player.Character:FindFirstChild("The World")
	
	if tool then
		local spamActive = true
		local startTime = tick()
		
		local vCoord = vector.create(-11220.2177734375, 429.3916015625, 1309.734130859375)
		local fCoord = vector.create(-11220.2177734375, 429.3916015625, 1309.734130859375)
		
		-- TỐI ƯU: Giảm wait từ 0.05 xuống 0.01 (100 lần/giây)
		-- Luồng 1: Spam V
		task.spawn(function()
			while spamActive and tick() - startTime < 15 do
				local args = { "Tool", tool, "V", vCoord }
				pcall(function() remote:FireServer(unpack(args)) end)
				task.wait(0.01) 
			end
		end)
		
		-- Luồng 2: Spam F
		task.spawn(function()
			while spamActive and tick() - startTime < 15 do
				local args = { "Tool", tool, "F", fCoord }
				pcall(function() remote:FireServer(unpack(args)) end)
				task.wait(0.01)
			end
		end)
		
		-- Đợi 3 giây cho V và F spam
		task.wait(3)
		spamActive = false
		
		print("Fire ProximityPrompt spawn boss...")
		local injectTime = tick()
		while tick() - injectTime < 10 do
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("ProximityPrompt") and v.Enabled then
					pcall(function() fireproximityprompt(v) end)
				end
			end
			-- TỐI ƯU: Giảm wait từ 0.2 xuống 0.1
			task.wait(0.1) 
			if getTarget() then
				print("Boss đã spawn!")
				break
			end
		end
	end
	targetSealNum = nil
end

-- ==========================================
-- PHẦN 5: VÒNG LẶP CHÍNH
-- ==========================================
print("Đã cài đặt xong! Auto Farm (Tốc độ cao)...")

while task.wait(0.5) do
	local char = player.Character
	if not char then char = player.CharacterAdded:Wait() end
	local myHrp = char:FindFirstChild("HumanoidRootPart")
	local myHumanoid = char:FindFirstChild("Humanoid")
	
	if not myHrp or not myHumanoid or myHumanoid.Health <= 0 then
		task.wait(1)
		continue
	end

	if hasEnemies then
		local enemy = getTarget()
		if enemy then
			isBusy = true
			fightEnemy(enemy, myHrp)
			isBusy = false
		end
	else
		if targetSealNum then
			isBusy = true
			processSeal(targetSealNum, myHrp)
			isBusy = false
		else
			task.wait(1)
		end
	end
end
