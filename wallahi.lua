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
local hasEnemies = false -- Biến toàn cục theo dõi trạng thái quái

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
-- PHẦN 2: LUỒNG CHẠY NGẦM CHECK QUÁI (TASK.SPAWN)
-- ==========================================
task.spawn(function()
	while task.wait(0.5) do -- Quét mỗi 0.5 giây
		local enemiesFolder = workspace:FindFirstChild("Enemies")
		local found = false
		
		if enemiesFolder then
			for _, enemy in ipairs(enemiesFolder:GetChildren()) do
				if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
					if enemy.Humanoid.Health > 0 then
						found = true
						break -- Chỉ cần tìm thấy 1 con là đủ
					end
				end
			end
		end
		
		-- Cập nhật trạng thái
		if hasEnemies ~= found then
			hasEnemies = found
			if hasEnemies then
				print("[DEBUG] Phát hiện quái trong workspace.Enemies!")
			else
				print("[DEBUG] Đã dọn sạch quái trong workspace.Enemies!")
			end
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
-- PHẦN 4: HÀM GOM QUÁI (MOB GATHERING)
-- ==========================================
local function gatherEnemies(myHrp, gatherOffset)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then return 0 end
	
	local gatherPos = myHrp.CFrame * (gatherOffset or CFrame.new(0, 0, -10))
	local count = 0
	
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
			if enemy.Humanoid.Health > 0 then
				local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
				pcall(function() enemyHrp:SetNetworkOwner(player) end)
				enemyHrp.CFrame = gatherPos
				enemyHrp.AssemblyLinearVelocity = Vector3.zero
				enemyHrp.AssemblyAngularVelocity = Vector3.zero
				count = count + 1
			end
		end
	end
	return count
end

local function lockEnemiesPosition(myHrp, gatherPos)
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then return end
	
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
			if enemy.Humanoid.Health > 0 then
				local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
				pcall(function() enemyHrp:SetNetworkOwner(player) end)
				local dist = (enemyHrp.Position - gatherPos.Position).Magnitude
				if dist > 5 then
					enemyHrp.CFrame = gatherPos
				end
				enemyHrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end

-- ==========================================
-- PHẦN 5: CÁC HÀM HỖ TRỢ
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
	
	local gatherPos = myHrp.CFrame * CFrame.new(0, 0, -5)
	
	while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
		lockEnemiesPosition(myHrp, gatherPos) -- Liên tục kéo quái về
		
		local currentEnemyHrp = target:FindFirstChild("HumanoidRootPart")
		if currentEnemyHrp then
			pcall(function() remote:FireServer("Dash", currentEnemyHrp.CFrame) end)
			
			local worldTool = player.Character:FindFirstChild("The World")
			if worldTool then
				pcall(function() remote:FireServer("Tool", worldTool, "Z", currentEnemyHrp.Position) end)
				pcall(function() remote:FireServer("Tool", worldTool, "X", currentEnemyHrp.Position) end)
				pcall(function() remote:FireServer("Tool", worldTool, "C", currentEnemyHrp.Position) end)
			end
		end
		task.wait(0.15)
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
	
	print("Spam Skill V...")
	local tool = player.Character:FindFirstChild("The World")
	if tool then
		local spamV = true
		local startTime = tick()
		task.spawn(function()
			while spamV and tick() - startTime < 15 do
				local args = { "Tool", tool, "V", vector.create(-11220.2177734375, 429.3916015625, 1309.734130859375) }
				pcall(function() remote:FireServer(unpack(args)) end)
				task.wait(0.1)
			end
		end)
		
		task.wait(2)
		spamV = false
		
		print("Fire ProximityPrompt spawn boss...")
		local injectTime = tick()
		while tick() - injectTime < 10 do
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("ProximityPrompt") and v.Enabled then
					pcall(function() fireproximityprompt(v) end)
				end
			end
			task.wait(0.2)
			if getTarget() then
				print("Boss đã spawn!")
				break
			end
		end
	end
	targetSealNum = nil
end

-- ==========================================
-- PHẦN 6: VÒNG LẶP CHÍNH
-- ==========================================
print("Đã cài đặt xong! Auto Farm + Mob Gathering...")

while task.wait(0.5) do
	local char = player.Character
	if not char then char = player.CharacterAdded:Wait() end
	local myHrp = char:FindFirstChild("HumanoidRootPart")
	local myHumanoid = char:FindFirstChild("Humanoid")
	
	if not myHrp or not myHumanoid or myHumanoid.Health <= 0 then
		task.wait(1)
		continue
	end

	-- Dựa vào biến hasEnemies được cập nhật từ task.spawn
	if hasEnemies then
		local enemy = getTarget()
		if enemy then
			isBusy = true
			
			-- Gom quái trước khi đánh
			local gathered = gatherEnemies(myHrp, CFrame.new(0, 0, -10))
			if gathered > 0 then
				print(string.format("[GATHER] Đã gom %d con quái!", gathered))
				task.wait(0.3)
			end
			
			fightEnemy(enemy, myHrp)
			isBusy = false
		end
	else
		-- Không có quái
		if targetSealNum then
			isBusy = true
			processSeal(targetSealNum, myHrp)
			isBusy = false
		else
			task.wait(1)
		end
	end
end
