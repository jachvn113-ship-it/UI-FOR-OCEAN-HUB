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
-- GIAI ĐOẠN 2: AUTO FARM
-- ==========================================
local function runAutoFarm()
	local remotes    = ReplicatedStorage:WaitForChild("Remotes")
	local remote     = remotes:WaitForChild("Input")
	local events     = remotes:WaitForChild("Events")
	local dungeonSync = events:WaitForChild("DungeonInsideSync")

	-- ==========================================
	-- REPLAY VOTE THREAD
	-- ==========================================
	task.spawn(function()
		while true do
			pcall(function() dungeonSync:FireServer("ReplayVote") end)
			task.wait(1)
		end
	end)

	-- ==========================================
	-- HOOK CD LABEL (slot[9] = F, slot[10] = V)
	-- ==========================================
	local cdLabelF = nil
	local cdLabelV = nil
	pcall(function()
		local abilityDisplay = playerGui:WaitForChild("AbilityDisplay", 10)
		if abilityDisplay then
			local skillDisplay = abilityDisplay:WaitForChild("SkillDisplay", 10)
			if skillDisplay then
				local slots = skillDisplay:GetChildren()
				-- F = slot thứ 9
				local slotF = slots[9]
				if slotF then
					local af = slotF:WaitForChild("AbilityFrame", 5)
					if af then cdLabelF = af:WaitForChild("Cooldown", 5) end
				end
				-- V = slot thứ 10
				local slotV = slots[10]
				if slotV then
					local av = slotV:WaitForChild("AbilityFrame", 5)
					if av then cdLabelV = av:WaitForChild("Cooldown", 5) end
				end
			end
		end
	end)

	if cdLabelF then
		print("[CD] Hook F:", cdLabelF:GetFullName())
	else
		warn("[CD] Không tìm thấy CD label F -> spam F liên tục")
	end

	local function parseCooldown(text)
		if not text or text == "" then return nil end
		return tonumber(text:match("(%d+%.?%d*)"))
	end

	local function isReady(label)
		if not label or not label.Parent then return true end
		local num = parseCooldown(label.Text)
		return num == nil or num <= 0
	end

	local function isFReady() return isReady(cdLabelF) end

	-- ==========================================
	-- EQUIP TOOL HELPER
	-- ==========================================
	local function equipTool(toolName)
		local char = player.Character
		if not char then return nil end
		local current = char:FindFirstChild(toolName)
		if current then return current end
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return nil end
		local tool = backpack:FindFirstChild(toolName)
		if not tool then return nil end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function() humanoid:EquipTool(tool) end)
		else
			tool.Parent = char
		end
		task.wait(0.1)
		return char:FindFirstChild(toolName)
	end

	-- ==========================================
	-- BẮT CHAT CHRONO SEAL
	-- ==========================================
	local targetSealNum = nil

	local function checkText(text)
		if not text or text == "" then return false end
		local cleanText = text:gsub("<.->", "")
		local lowerText = cleanText:lower()
		local sealNum = string.match(lowerText, "seal%s*(%d+)")
		if sealNum then return tonumber(sealNum) end
		return false
	end

	local function onMessageFound(sealNum)
		print(">>> BẮT ĐƯỢC CHRONO SEAL:", sealNum)
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
			if (child:IsA("TextLabel") or child:IsA("TextButton"))
				and not child:GetFullName():find("DevConsole") then
				hookLabel(child)
			end
		end
		parent.DescendantAdded:Connect(function(child)
			if (child:IsA("TextLabel") or child:IsA("TextButton"))
				and not child:GetFullName():find("DevConsole") then
				task.wait(0.1)
				hookLabel(child)
			end
		end)
	end
	pcall(function() scanUI(CoreGui) end)
	scanUI(playerGui)

	-- ==========================================
	-- SAFE TWEEN
	-- ==========================================
	local function safeTween(hrp, targetCFrame, speed, useDashBypass)
		local maxAttempts = 5
		local attempt = 0
		while attempt < maxAttempts do
			attempt = attempt + 1
			local startPos  = hrp.Position
			local targetPos = targetCFrame.Position
			local distance  = (startPos - targetPos).Magnitude
			if distance < 5 then break end

			local duration  = distance / speed
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
			local tween     = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
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
					warn(string.format("[TWEEN] Bị kéo về, còn %.1f studs. Retry...", currentDistance))
				else
					break
				end
			else
				break
			end
		end
	end

	-- ==========================================
	-- PROMPT CACHE
	-- ==========================================
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

	-- ==========================================
	-- GET TARGET
	-- ==========================================
	local function getTarget()
		local enemiesFolder = workspace:FindFirstChild("Enemies")
		if not enemiesFolder then return nil end
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if enemy:IsA("Model")
				and enemy:FindFirstChild("Humanoid")
				and enemy:FindFirstChild("HumanoidRootPart") then
				if enemy.Humanoid.Health > 0 then return enemy end
			end
		end
		return nil
	end

	local function findChronoSealFolder(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == "Chrono Seal" then
				return child
			elseif child:IsA("Folder") or child:IsA("Model") or child:IsA("Workspace") then
				local found = findChronoSealFolder(child)
				if found then return found end
			end
		end
		return nil
	end

	-- ==========================================
	-- FIGHT ENEMY (UNDYNE - spam ZXCFVB cùng lúc)
	-- ==========================================
	local FIGHT_TIMEOUT = 25

	local function fightEnemy(target, myHrp)
		print("[FIGHT] Đánh:", target.Name)
		local tool = equipTool("Undyne")
		if not tool then
			warn("[FIGHT] Không có Undyne!")
			return
		end

		local enemyHrp = target:FindFirstChild("HumanoidRootPart")
		if not enemyHrp then return end
		safeTween(myHrp, enemyHrp.CFrame * CFrame.new(0, 0, 5), 300, true)

		local fightStart = tick()
		while target and target.Parent
			and target:FindFirstChild("Humanoid")
			and target.Humanoid.Health > 0 do

			if tick() - fightStart > FIGHT_TIMEOUT then
				warn("[FIGHT] Timeout:", target.Name)
				break
			end

			local currentEnemyHrp = target:FindFirstChild("HumanoidRootPart")
			if currentEnemyHrp then
				myHrp.CFrame = currentEnemyHrp.CFrame * CFrame.new(0, 0, 5)
				pcall(function() remote:FireServer("Dash", currentEnemyHrp.CFrame) end)

				-- Re-equip nếu bị mất tool
				local t = player.Character and player.Character:FindFirstChild("Undyne")
				if not t then t = equipTool("Undyne") end

				if t then
					local pos = currentEnemyHrp.Position
					pcall(function() remote:FireServer("Tool", t, "Z", pos) end)
					pcall(function() remote:FireServer("Tool", t, "X", pos) end)
					pcall(function() remote:FireServer("Tool", t, "C", pos) end)
					pcall(function() remote:FireServer("Tool", t, "F", pos) end)
					pcall(function() remote:FireServer("Tool", t, "V", pos) end)
					pcall(function() remote:FireServer("Tool", t, "B", pos) end)
				end
			end
			task.wait(0.05)
		end
		print("[FIGHT] Hạ xong:", target.Name)
	end

	-- ==========================================
	-- PROCESS SEAL (The World - spam F tại sealPos)
	-- ==========================================
	local SEAL_TIMEOUT      = 20    -- safety net, giảm 30 -> 20
	local MAX_RETRY         = 5
	local PROMPT_SPAM_RATE  = 0.005
	local PROMPT_CACHE_REFRESH = 2
	local SEAL_TWEEN_SPEED  = 80
	local F_CAST_DELAY      = 0.75
	local F_REFIRE_GUARD    = 2.0

	local function processSeal(sealNum, myHrp)
		print("[SEAL] Tìm Chrono Seal", sealNum)
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

		-- EQUIP THE WORLD
		local tool = equipTool("The World")
		if not tool then
			warn("[SEAL] Không có The World!")
			targetSealNum = nil
			return
		end

		local sealPos = sealObj:IsA("BasePart") and sealObj.Position or sealObj:GetPivot().Position
		local targetCFrame = CFrame.new(sealPos) * CFrame.new(0, 5, 0)
		safeTween(myHrp, targetCFrame, SEAL_TWEEN_SPEED, true)

		local retryCount = 0
		local bossSpawned = false

		while retryCount < MAX_RETRY and not bossSpawned do
			retryCount = retryCount + 1
			print(string.format("=== [SEAL %d] Lần %d/%d ===", sealNum, retryCount, MAX_RETRY))

			local vCoord = vector.create(sealPos.X, sealPos.Y, sealPos.Z)
			local stopSpam = false
			local fFireCount = 0
			local promptFireCount = 0
			local lastFTime = -999

			-- SPAM THREAD
			local spamThread = task.spawn(function()
				refreshPrompts()
				while not stopSpam do
					if tick() - lastPromptRefresh > PROMPT_CACHE_REFRESH then
						refreshPrompts()
					end

					local t = player.Character and player.Character:FindFirstChild("The World")
					if not t then t = equipTool("The World") end

					if t then
						local now = tick()
						local fCanFire = isFReady() and (now - lastFTime >= F_REFIRE_GUARD)

						if fCanFire then
							pcall(function()
								remote:FireServer("Tool", t, "F", vCoord)
								fFireCount = fFireCount + 1
							end)
							lastFTime = now
							task.wait(F_CAST_DELAY)
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
					else
						task.wait(0.1)
					end
				end
			end)

			-- WAIT: seal mất HOẶC boss spawn (KHÔNG chờ MIN_SPAWN_DURATION nữa)
			local waitStart = tick()
			while tick() - waitStart < SEAL_TIMEOUT do
				if not sealObj or not sealObj.Parent then
					print("[SEAL] Seal biến mất -> thành công")
					bossSpawned = true
					break
				end

				-- Boss spawn = enemy đầu tiên xuất hiện -> thoát ngay để đánh
				if getTarget() then
					print("[SEAL] Boss đã spawn -> lao vào đánh!")
					bossSpawned = true
					break
				end

				task.wait(0.2)
			end

			stopSpam = true
			-- Cancel thread để không còn fire F sau khi exit
			pcall(function() task.cancel(spamThread) end)
			task.wait(0.05)

			if bossSpawned then
				print(string.format(">>> [SEAL %d] Xong sau %d lần (F:%d, Prompt:%d)",
					sealNum, retryCount, fFireCount, promptFireCount))
			else
				warn(string.format("[SEAL %d] Timeout %ds (F:%d, Prompt:%d) -> Retry",
					sealNum, SEAL_TIMEOUT, fFireCount, promptFireCount))
			end
		end

		if not bossSpawned then
			warn(string.format("[SEAL %d] Thất bại %d lần -> bỏ qua", sealNum, MAX_RETRY))
		end
		targetSealNum = nil
	end

	-- ==========================================
	-- VÒNG LẶP CHÍNH
	-- Priority: ENEMY trước -> SEAL sau
	-- ==========================================
	local MAIN_TICK = 0.1
	print("[FARM] Auto Farm đã sẵn sàng!")

	while task.wait(MAIN_TICK) do
		local char = player.Character
		if not char then char = player.CharacterAdded:Wait() end
		local myHrp      = char:FindFirstChild("HumanoidRootPart")
		local myHumanoid = char:FindFirstChild("Humanoid")

		if not myHrp or not myHumanoid or myHumanoid.Health <= 0 then
			task.wait(0.5)
			continue
		end

		-- PRIORITY 1: ENEMY (dùng Undyne)
		local enemy = getTarget()
		if enemy then
			fightEnemy(enemy, myHrp)
		else
			-- PRIORITY 2: SEAL (chỉ khi hết enemy)
			if targetSealNum then
				processSeal(targetSealNum, myHrp)
			else
				task.wait(0.3)
			end
		end
	end
end

-- ==========================================
-- DISPATCHER
-- ==========================================
if game.PlaceId == ENTRY_PLACE_ID then
	print("[DISPATCH] Place Entry -> chạy sequence vào Realm Beyond Heaven...")
	runEntrySequence()

elseif game.PlaceId == FARM_PLACE_ID then
	print("[DISPATCH] Place Farm -> Auto Farm (Undyne + The World F)...")
	task.wait(2)
	runAutoFarm()

else
	warn("[DISPATCH] PlaceId không khớp flow:", game.PlaceId)
end
