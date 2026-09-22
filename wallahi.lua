local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ENTRY_PLACE_ID = 111097829542198
local FARM_PLACE_ID  = 105440532661931

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- GIAI ĐOẠN 1: VÀO GAME TỪ PLACE ENTRY
-- ==========================================
local function runEntrySequence()
	local remotes   = ReplicatedStorage:WaitForChild("Remotes")
	local functions = remotes:WaitForChild("Functions")
	local events    = remotes:WaitForChild("Events")

	local inputFn      = functions:WaitForChild("Input")
	local useItem      = remotes:WaitForChild("RE_UseItem")
	local portalRemote = events:WaitForChild("RealmBeyondHeavenPortal")

	print("[ENTRY] Loadout Load 3...")
	inputFn:InvokeServer("Loadout", "Load", "3")
	task.wait(0.5)

	print("[ENTRY] Dùng Realm Beyond Heaven Key...")
	useItem:FireServer("Realm Beyond Heaven Key", 1, 0)
	task.wait(0.5)

	print("[ENTRY] Mở Realm Beyond Heaven Portal...")
	portalRemote:FireServer("Start")
end

-- ==========================================
-- GIAI ĐOẠN 2: CHUẨN BỊ TRƯỚC KHI FARM
-- ==========================================
local function runPreFarmSequence()
	local char    = player.Character or player.CharacterAdded:Wait()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local inputEv = remotes:WaitForChild("Input")
	local events  = remotes:WaitForChild("Events")
	local dungeonSync = events:WaitForChild("DungeonInsideSync")

	local theWorld = char:FindFirstChild("The World")
	if not theWorld then
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			theWorld = backpack:FindFirstChild("The World")
		end
	end
	if not theWorld then
		local deadline = tick() + 10
		while tick() < deadline and not theWorld do
			theWorld = char:FindFirstChild("The World")
				or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("The World"))
			if not theWorld then task.wait(0.1) end
		end
	end
	if not theWorld then
		warn("[PRE-FARM] Không tìm thấy 'The World' trong Character/Backpack!")
		return
	end

	print("[PRE-FARM] Equip The World (Backpack -> Character)...")
	if theWorld.Parent ~= char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:EquipTool(theWorld)
		else
			theWorld.Parent = char
		end
	end
	task.wait(0.5)

	print("[PRE-FARM] Vote Extreme...")
	dungeonSync:FireServer("Vote", "Extreme")
	task.wait(0.5)

	print("[PRE-FARM] Skill B...")
	inputEv:FireServer("Tool", theWorld, "B", vector.create(-11119.25390625, 429.3916015625, 1162.5849609375))
	task.wait(15)

	print("[PRE-FARM] Skill F...")
	inputEv:FireServer("Tool", theWorld, "F", vector.create(-11204.4619140625, 429.3916015625, 1087.3521728515625))
	task.wait(1)
end

-- ==========================================
-- GIAI ĐOẠN 3: AUTO FARM
-- ==========================================
local function runAutoFarm()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Input")

	task.spawn(function()
		local dungeonSync = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("DungeonInsideSync")
		while true do
			pcall(function()
				dungeonSync:FireServer("ReplayVote")
			end)
			task.wait(1)
		end
	end)

	-- COOLDOWN LABEL
	local cdLabel = nil
	pcall(function()
		local abilityDisplay = playerGui:WaitForChild("AbilityDisplay", 10)
		if abilityDisplay then
			local skillDisplay = abilityDisplay:WaitForChild("SkillDisplay", 10)
			if skillDisplay then
				local slot = skillDisplay:GetChildren()[10]
				if slot then
					local abilityFrame = slot:WaitForChild("AbilityFrame", 5)
					if abilityFrame then
						cdLabel = abilityFrame:WaitForChild("Cooldown", 5)
					end
				end
			end
		end
	end)

	if cdLabel then
		print("[CD] Đã hook Cooldown label:", cdLabel:GetFullName())
	else
		warn("[CD] Không tìm thấy Cooldown label -> fallback spam V liên tục")
	end

	local function parseCooldown(text)
		if not text or text == "" then return nil end
		return tonumber(text:match("(%d+%.?%d*)"))
	end

	local function isVReady()
		if not cdLabel or not cdLabel.Parent then return true end
		local num = parseCooldown(cdLabel.Text)
		return num == nil or num <= 0
	end

	local targetSealNum = nil
	local isBusy = false

	local SEAL_TIMEOUT = 30
	local MAX_RETRY = 5
	local PROMPT_SPAM_RATE = 0.005
	local PROMPT_CACHE_REFRESH = 2
	local SEAL_TWEEN_SPEED = 80
	local V_CAST_DELAY = 0.75
	local V_REFIRE_GUARD = 2.0
	local MIN_SPAWN_DURATION = 8
	local FIGHT_TIMEOUT = 25
	local MAIN_TICK = 0.1        -- poll main loop mỗi 0.1s thay vì 0.5s

	-- PHẦN 1: BẮT CHAT CHRONO SEAL
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

	-- PHẦN 3: TWEEN AN TOÀN
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

	-- PHẦN 4: CACHE PROMPT
	local promptCache = {}
	local lastPromptRefresh = 0
	local function refreshPrompts()
		local newCache = {}
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ProximityPrompt") then
				table.insert(newCache, v)
			end
		end
		promptCache = newCache
		lastPromptRefresh = tick()
	end

	-- PHẦN 5: HÀM HỖ TRỢ
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
		if not enemyHrp then return end
		local targetCFrame = enemyHrp.CFrame * CFrame.new(0, 0, 5)
		safeTween(myHrp, targetCFrame, 300, true)

		local fightStart = tick()
		while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
			if tick() - fightStart > FIGHT_TIMEOUT then
				warn("[FIGHT] Timeout target:", target.Name, "-> bỏ qua")
				break
			end

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

	-- PHẦN 6: XỬ LÝ SEAL
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
		safeTween(myHrp, targetCFrame, SEAL_TWEEN_SPEED, true)

		local tool = player.Character:FindFirstChild("The World")
		if not tool then
			warn("Không tìm thấy Tool 'The World'!")
			targetSealNum = nil
			return
		end

		local retryCount = 0
		local bossSpawned = false

		while retryCount < MAX_RETRY and not bossSpawned do
			retryCount = retryCount + 1
			print(string.format("=== [SEAL %d] Lần thử %d/%d ===", sealNum, retryCount, MAX_RETRY))

			local vCoord = vector.create(sealPos.X, sealPos.Y, sealPos.Z)
			local stopAll = false
			local vFireCount = 0
			local promptFireCount = 0
			local spawnStart = tick()
			local lastVFireTime = -999

			-- LUỒNG DUY NHẤT
			task.spawn(function()
				refreshPrompts()
				while not stopAll do
					if tick() - lastPromptRefresh > PROMPT_CACHE_REFRESH then
						refreshPrompts()
					end

					local now = tick()
					local vCanFire = isVReady() and (now - lastVFireTime >= V_REFIRE_GUARD)

					if vCanFire then
						pcall(function()
							remote:FireServer("Tool", tool, "V", vCoord)
							vFireCount = vFireCount + 1
						end)
						lastVFireTime = now
						task.wait(V_CAST_DELAY)
					else
						for i = 1, #promptCache do
							local v = promptCache[i]
							if v and v.Parent and v.Enabled then
								pcall(function()
									fireproximityprompt(v)
									promptFireCount = promptFireCount + 1
								end)
								break
							end
						end
						task.wait(PROMPT_SPAM_RATE)
					end
				end
			end)

			-- CHỜ BOSS SPAWN
			local waitStart = tick()
			while tick() - waitStart < SEAL_TIMEOUT do
				if not sealObj or not sealObj.Parent then
					print("[DEBUG] Seal đã biến mất, coi như thành công!")
					bossSpawned = true
					break
				end

				if getTarget() and (tick() - spawnStart) >= MIN_SPAWN_DURATION then
					print(string.format("[DEBUG] Đã spawn đủ %.1fs, thoát sang fight!", MIN_SPAWN_DURATION))
					bossSpawned = true
					break
				end

				task.wait(0.5)
			end

			stopAll = true
			task.wait(0.1)  -- FIX: giảm 0.3 -> 0.1 để thoát nhanh hơn

			if bossSpawned then
				print(string.format(">>> [SEAL %d] Kết thúc spawn sau %d lần thử! (V: %d, Prompt: %d)",
					sealNum, retryCount, vFireCount, promptFireCount))
			else
				warn(string.format("[SEAL %d] Hết %ds chưa spawn đủ! Retry... (V: %d, Prompt: %d)",
					sealNum, SEAL_TIMEOUT, vFireCount, promptFireCount))
			end
		end

		if not bossSpawned then
			warn(string.format("[SEAL %d] Đã thử %d lần nhưng không đạt. Bỏ qua Seal này!", sealNum, MAX_RETRY))
		end
		targetSealNum = nil
	end

	-- ==========================================
	-- PHẦN 7: VÒNG LẶP CHÍNH
	-- ==========================================
	-- FIX: Gọi getTarget() trực tiếp mỗi tick (không dùng cache flag hasEnemies)
	--      Priority: ENEMY TRƯỚC -> SEAL SAU (theo yêu cầu user)
	print("Đã cài đặt xong Auto Farm!")
	while task.wait(MAIN_TICK) do
		local char = player.Character
		if not char then char = player.CharacterAdded:Wait() end
		local myHrp = char:FindFirstChild("HumanoidRootPart")
		local myHumanoid = char:FindFirstChild("Humanoid")

		if not myHrp or not myHumanoid or myHumanoid.Health <= 0 then
			task.wait(0.5)
			continue
		end

		-- PRIORITY 1: Nếu có enemy trong folder Enemies -> đánh trước
		local enemy = getTarget()
		if enemy then
			isBusy = true
			fightEnemy(enemy, myHrp)
			isBusy = false
			-- Sau khi hạ xong 1 con, loop lại ngay (tick 0.1s), check tiếp con khác
		else
			-- PRIORITY 2: Hết enemy -> mới xử lý seal
			if targetSealNum then
				isBusy = true
				processSeal(targetSealNum, myHrp)
				isBusy = false
			else
				task.wait(0.3)
			end
		end
	end
end

-- DISPATCHER
if game.PlaceId == ENTRY_PLACE_ID then
	print("[DISPATCH] Place entry -> chạy sequence vào Realm Beyond Heaven...")
	runEntrySequence()

elseif game.PlaceId == FARM_PLACE_ID then
	print("[DISPATCH] Place farm -> pre-farm + auto farm...")
	task.wait(2)
	runPreFarmSequence()
	task.wait(2)
	runAutoFarm()

else
	warn("[DISPATCH] PlaceId không khớp flow:", game.PlaceId)
end
