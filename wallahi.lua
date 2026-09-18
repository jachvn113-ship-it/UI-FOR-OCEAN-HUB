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
-- CẤU HÌNH
-- ==========================================
local SEAL_TIMEOUT = 30 -- Nếu ở Seal quá 30s mà chưa có boss -> retry
local MAX_RETRY = 5     -- Số lần retry tối đa (tránh treo vô hạn)

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
-- PHẦN 4: HÀM SPAM PROXIMITYPROMPT THÔNG MINH
-- ==========================================
-- Trả về true nếu tìm thấy ít nhất 1 prompt enabled trong lúc spam
local function spamProximityPrompt(duration)
	local startTime = tick()
	local fireCount = 0
	
	while tick() - startTime < duration do
		local found = false
		
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ProximityPrompt") and v.Enabled then
				pcall(function()
					fireproximityprompt(v)
					fireCount = fireCount + 1
				end)
				found = true
				break
			end
		end
		
		if not found then
			task.wait(0.05)
		end
	end
	
	print(string.format("[DEBUG] Đã fire ProximityPrompt %d lần trong %.1f giây", fireCount, duration))
	return fireCount
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
		task.wait(0.05)
	end
	print("Đã hạ " .. target.Name)
end

-- ==========================================
-- HÀM CHÍNH XỬ LÝ SEAL (CÓ TIMEOUT 30s)
-- ==========================================
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
	safeTween(myHrp, targetCFrame, 50, true) -- Tween chậm tới Seal
	
	local tool = player.Character:FindFirstChild("The World")
	if not tool then
		warn("Không tìm thấy Tool 'The World'!")
		targetSealNum = nil
		return
	end
	
	-- ==========================================
	-- VÒNG LẶP RETRY: NẾU 30S KO CÓ BOSS -> SPAM V LẠI
	-- ==========================================
	local retryCount = 0
	local bossSpawned = false
	
	while retryCount < MAX_RETRY and not bossSpawned do
		retryCount = retryCount + 1
		print(string.format("=== [SEAL %d] Lần thử %d/%d ===", sealNum, retryCount, MAX_RETRY))
		
		-- ==========================================
		-- BƯỚC 1: SPAM V (TIME STOP) CỰC NHANH
		-- ==========================================
		print("Spam V (Time Stop) cực nhanh...")
		local vCoord = vector.create(sealPos.X, sealPos.Y, sealPos.Z)
		local vSpamEnd = tick() + 3
		local vCount = 0
		
		while tick() < vSpamEnd do
			local vArgs = { "Tool", tool, "V", vCoord }
			pcall(function() 
				remote:FireServer(unpack(vArgs))
				vCount = vCount + 1
			end)
			task.wait(0.01)
		end
		print(string.format("[DEBUG] Đã spam V %d lần", vCount))
		
		-- ==========================================
		-- BƯỚC 2: SPAM PROMPT VÀ CHỜ BOSS SPAWN (TỐI ĐA 30S)
		-- ==========================================
		print("Bắt đầu spam ProximityPrompt và chờ boss (tối đa 30s)...")
		local waitStart = tick()
		local promptSpamActive = true
		
		-- Luồng spam prompt chạy ngầm
		task.spawn(function()
			while promptSpamActive do
				for _, v in ipairs(workspace:GetDescendants()) do
					if v:IsA("ProximityPrompt") and v.Enabled then
						pcall(function() fireproximityprompt(v) end)
						break
					end
				end
				task.wait(0.05)
			end
		end)
		
		-- Vòng lặp kiểm tra boss spawn
		while tick() - waitStart < SEAL_TIMEOUT do
			-- Nếu có quái xuất hiện -> boss đã spawn
			if getTarget() then
				bossSpawned = true
				break
			end
			
			-- Nếu seal biến mất (đã bị phá) -> cũng coi như xong
			if not sealObj or not sealObj.Parent then
				print("[DEBUG] Seal đã biến mất, coi như thành công!")
				bossSpawned = true
				break
			end
			
			task.wait(0.5)
		end
		
		promptSpamActive = false -- Dừng spam prompt
		
		if bossSpawned then
			print(string.format(">>> [SEAL %d] Boss đã spawn sau %d lần thử!", sealNum, retryCount))
		else
			warn(string.format("[SEAL %d] Hết %ds mà boss chưa spawn! Retry lại...", sealNum, SEAL_TIMEOUT))
		end
	end
	
	if not bossSpawned then
		warn(string.format("[SEAL %d] Đã thử %d lần nhưng boss vẫn không spawn. Bỏ qua Seal này!", sealNum, MAX_RETRY))
	end
	
	targetSealNum = nil
end

-- ==========================================
-- PHẦN 6: VÒNG LẶP CHÍNH
-- ==========================================
print("Đã cài đặt xong! Auto Farm (V = Time Stop, có Timeout 30s)")

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
