local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Input")

local targetSealNum = nil
local isBusy = false

-- ==========================================
-- PHẦN 1: BẮT TIN NHẮN CHAT (CHRONO SEAL)
-- ==========================================
local function checkText(text)
	if not text or text == "" then return false end
	local cleanText = text:gsub("<.->", "") -- Xóa thẻ HTML
	local lowerText = cleanText:lower()
	local sealNum = string.match(lowerText, "seal%s*(%d+)")
	if sealNum then return tonumber(sealNum) end
	return false
end

local function onMessageFound(sealNum)
	print("========================================")
	print(">>> ĐÃ BẮT ĐƯỢC TÍN HIỆU CHRONO SEAL:", sealNum)
	targetSealNum = sealNum
	if isBusy then
		print("Đang bận đánh quái, sẽ tới Seal này sau!")
	else
		print("Sẽ tới Seal này ngay bây giờ!")
	end
	print("========================================")
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
-- PHẦN 2: HÀM TWEEN AN TOÀN (SAFE TWEEN)
-- ==========================================
-- speed: Tốc độ di chuyển (studs/giây). 300 là nhanh, 50 là chậm.
-- useDashBypass: Có dùng Dash để lách anti-cheat không.
local function safeTween(hrp, targetCFrame, speed, useDashBypass)
	local maxAttempts = 5
	local attempt = 0
	
	while attempt < maxAttempts do
		attempt = attempt + 1
		local startPos = hrp.Position
		local targetPos = targetCFrame.Position
		local distance = (startPos - targetPos).Magnitude
		
		if distance < 5 then
			print("[DEBUG] Đã tới đích thành công!")
			break -- Đã tới nơi
		end
		
		-- Tính thời gian dựa trên tốc độ
		local duration = distance / speed
		print(string.format("[DEBUG] Tween lần %d: Khoảng cách %.1f studs, Tốc độ %d, Thời gian %.2fs", attempt, distance, speed, duration))
		
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
		tween:Play()
		
		-- Dash Bypass: Gửi lệnh Dash liên tục trong lúc Tween
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
		task.wait(0.2) -- Đợi server cập nhật vị trí
		
		-- Kiểm tra xem có bị kéo về không
		if hrp and hrp.Parent then
			local currentDistance = (hrp.Position - targetPos).Magnitude
			if currentDistance > 15 then
				warn(string.format("[DEBUG] Bị kéo về! Còn cách đích %.1f studs. Đang thử lại...", currentDistance))
			else
				print("[DEBUG] Tween thành công, đã đứng gần đích!")
				break
			end
		else
			break -- Nhân vật chết
		end
	end
end

-- ==========================================
-- PHẦN 3: CÁC HÀM HỖ TRỢ (ENEMY & SEAL)
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
	print("Mục tiêu hiện tại: " .. target.Name)
	local enemyHrp = target:FindFirstChild("HumanoidRootPart")
	
	-- TWEEN TỚI QUÁI: Tốc độ 300 (Nhanh), có Dash Bypass
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
		task.wait(0.15)
	end
	print("Đã hạ gục " .. target.Name)
end

local function processSeal(sealNum, myHrp)
	print("Đang tìm kiếm Chrono Seal", sealNum, "...")
	local chronoSealFolder = findChronoSealFolder(workspace)
	
	if not chronoSealFolder then
		warn("Không tìm thấy folder 'Chrono Seal'!")
		targetSealNum = nil
		return
	end
	
	local sealObj = chronoSealFolder:FindFirstChild(tostring(sealNum))
	if not sealObj then
		print("Chưa thấy Seal", sealNum, "đang đợi...")
		local timeout = tick() + 5
		while tick() < timeout do
			sealObj = chronoSealFolder:FindFirstChild(tostring(sealNum))
			if sealObj then break end
			task.wait(0.1)
		end
	end
	
	if not sealObj then
		warn("Không tìm thấy Seal " .. sealNum .. "!")
		targetSealNum = nil
		return
	end
	
	local sealPos = sealObj:IsA("BasePart") and sealObj.Position or sealObj:GetPivot().Position
	local targetCFrame = CFrame.new(sealPos) * CFrame.new(0, 5, 0)
	
	-- TWEEN TỚI SEAL: Tốc độ 50 (Chậm như đi bộ), có Dash Bypass
	print("[DEBUG] Bắt đầu Tween chậm tới Seal", sealNum)
	safeTween(myHrp, targetCFrame, 50, true)
	
	print("Bắt đầu spam Skill V...")
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
		
		print("Đang fire ProximityPrompt để spawn boss...")
		local injectTime = tick()
		while tick() - injectTime < 10 do
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("ProximityPrompt") and v.Enabled then
					pcall(function() fireproximityprompt(v) end)
				end
			end
			task.wait(0.2)
			if getTarget() then
				print("Boss đã spawn! Quay lại đánh boss.")
				break
			end
		end
	end
	targetSealNum = nil
end

-- ==========================================
-- PHẦN 4: VÒNG LẶP CHÍNH (MAIN LOOP)
-- ==========================================
print("Đã cài đặt xong! Bắt đầu Auto Farm...")

while task.wait(0.5) do
	local char = player.Character
	if not char then char = player.CharacterAdded:Wait() end
	local myHrp = char:FindFirstChild("HumanoidRootPart")
	local myHumanoid = char:FindFirstChild("Humanoid")
	
	if not myHrp or not myHumanoid or myHumanoid.Health <= 0 then
		task.wait(1)
		continue
	end

	local enemy = getTarget()
	if enemy then
		isBusy = true
		fightEnemy(enemy, myHrp)
		isBusy = false
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
