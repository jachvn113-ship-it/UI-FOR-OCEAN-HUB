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
	local remotes     = ReplicatedStorage:WaitForChild("Remotes")
	local remote      = remotes:WaitForChild("Input")
	local events      = remotes:WaitForChild("Events")
	local dungeonSync = events:WaitForChild("DungeonInsideSync")

	-- ==========================================
	-- VOTE EXTREME + REPLAY VOTE (spam 1s/lần)
	-- ==========================================
	task.spawn(function()
		while true do
			pcall(function() dungeonSync:FireServer("Vote", "Extreme") end)
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
				local slotF = slots[9]
				if slotF then
					local af = slotF:WaitForChild("AbilityFrame", 5)
					if af then cdLabelF = af:WaitForChild("Cooldown", 5) end
				end
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
		warn("[CD] Không tìm thấy CD label F")
	end
	if cdLabelV then
		print("[CD] Hook V:", cdLabelV:GetFullName())
	else
		warn("[CD] Không tìm thấy CD label V -> spam V không check CD")
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
	local function isVReady() return isReady(cdLabelV) end

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
		local maxAttempts = 3
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
	-- FIGHT ENEMY (ARAYA - spam Z X C F V, BỎ B)
	-- ==========================================
	local FIGHT_TIMEOUT = 35

	local function fightEnemy(target, myHrp)
		print("[FIGHT] Đánh:", target.Name)
		local tool = equipTool("Araya")
		if not tool then
			warn("[FIGHT] Không có Araya!")
			return
		end

		local enemyHrp = target:FindFirstChild("HumanoidRootPart")
		if not enemyHrp then return end
		safeTween(myHrp, enemyHrp.CFrame * CFrame.new(0, 0, 5), 100, true)

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

				local t = player.Character and player.Character:FindFirstChild("Araya")
				if not t then t = equipTool("Araya") end

				if t then
					local pos = currentEnemyHrp.Position
					-- FIX: Bỏ B, chỉ spam Z X C F V
					pcall(function() remote:FireServer("Tool", t, "Z", pos) end)
					pcall(function() remote:FireServer("Tool", t, "X", pos) end)
					pcall(function() remote:FireServer("Tool", t, "C", pos) end)
					pcall(function() remote:FireServer("Tool", t, "F", pos) end)
					pcall(function() remote:FireServer("Tool", t, "V", pos) end)
				end
			end
			task.wait(0.05)
		end
		print("[FIGHT] Hạ xong:", target.Name)
	end

	-- ==========================================
	-- PROCESS SEAL (The World - spam V để spawn mob + prompt)
	-- ==========================================
	local SEAL_TIMEOUT         = 20
	local MAX_RETRY            = 5
	local PROMPT_SPAM_RATE     = 1
	local PROMPT_CACHE_REFRESH = 2
	local SEAL_TWEEN_SPEED     = 100
	local PROMPT_RADIUS        = 120   -- FIX: 60 -> 120 (mở rộng bán kính prompt)
	local V_SPAM_RATE          = 0.15  -- FIX: spam V liên tục, không đợi 1s

	local function processSeal(sealNum, myHrp)
		print("[SEAL] >>> Bắt đầu processSeal:", sealNum)

		local chronoSealFolder = findChronoSealFolder(workspace)
		if not chronoSealFolder then
			warn("[SEAL] ❌ Không tìm thấy folder 'Chrono Seal'!")
			targetSealNum = nil
			return
		end
		print("[SEAL] Folder:", chronoSealFolder:GetFullName())

		local sealObj = nil
		local function tryFind()
			local o = chronoSealFolder:FindFirstChild(tostring(sealNum))
			if o then return o end
			for _, c in ipairs(chronoSealFolder:GetChildren()) do
				if c.Name:match(tostring(sealNum)) then
					print("[SEAL] Match tên khác:", c.Name, c.ClassName)
					return c
				end
			end
			return nil
		end

		sealObj = tryFind()
		if not sealObj then
			local timeout = tick() + 5
			while tick() < timeout do
				sealObj = tryFind()
				if sealObj then break end
				task.wait(0.1)
			end
		end
		if not sealObj then
			warn("[SEAL] ❌ Không tìm thấy seal '"..tostring(sealNum).."'!")
			for _, c in ipairs(chronoSealFolder:GetChildren()) do
				print("   -", c.Name, c.ClassName)
			end
			targetSealNum = nil
			return
		end
		print("[SEAL] ✅ Seal:", sealObj:GetFullName(), "| Class:", sealObj.ClassName)

		local sealPos
		if sealObj:IsA("BasePart") then
			sealPos = sealObj.Position
		elseif sealObj:IsA("Model") then
			sealPos = sealObj:GetPivot().Position
		else
			local part = sealObj:FindFirstChildWhichIsA("BasePart", true)
			if part then sealPos = part.Position
			else
				warn("[SEAL] ❌ Không lấy được position!")
				targetSealNum = nil
				return
			end
		end
		print("[SEAL] Position:", sealPos)

		local tool = equipTool("The World")
		if not tool then
			warn("[SEAL] ❌ Không có The World!")
			targetSealNum = nil
			return
		end

		local targetCFrame = CFrame.new(sealPos) * CFrame.new(0, 5, 0)
		print("[SEAL] Tween tới seal...")
		safeTween(myHrp, targetCFrame, SEAL_TWEEN_SPEED, true)
		print("[SEAL] Đã tới seal.")

		local vCoord = vector.create(sealPos.X, sealPos.Y, sealPos.Z)
		local retryCount = 0
		local bossSpawned = false

		while retryCount < MAX_RETRY and not bossSpawned do
			retryCount = retryCount + 1
			print(string.format("=== [SEAL %d] Lần %d/%d ===", sealNum, retryCount, MAX_RETRY))

			local stopSpam = false
			local promptFireCount = 0
			local vFireCount = 0

			-- ==========================================
			-- THREAD 1: Spam V để mở seal spawn mob
			-- (chạy liên tục khi V ready, không đợi 1s)
			-- ==========================================
			local vThread = task.spawn(function()
				local lastVFire = -999
				while not stopSpam do
					-- Dừng ngay khi mob xuất hiện
					if getTarget() then
						print("[V] Mob xuất hiện -> dừng spam V!")
						break
					end

					local now = tick()
					local vReady = isVReady() and (now - lastVFire >= V_SPAM_RATE)

					if vReady then
						local t = player.Character and player.Character:FindFirstChild("The World")
						if not t then t = equipTool("The World") end
						if t then
							pcall(function()
								remote:FireServer("Tool", t, "V", vCoord)
								vFireCount = vFireCount + 1
							end)
						end
						lastVFire = now
					end
					task.wait(0.05)
				end
			end)

			-- ==========================================
			-- THREAD 2: Spam ProximityPrompt 1s/lần
			-- ==========================================
			local promptThread = task.spawn(function()
				refreshPrompts()
				while not stopSpam do
					-- Dừng ngay khi mob xuất hiện
					if getTarget() then
						print("[PROMPT] Mob xuất hiện -> dừng spam prompt!")
						break
					end

					if tick() - lastPromptRefresh > PROMPT_CACHE_REFRESH then
						refreshPrompts()
					end

					local fired = false
					for i = 1, #promptCache do
						local prompt = promptCache[i]
						if prompt and prompt.Parent and prompt.Enabled then
							local parentPart = prompt.Parent
							local pos = nil
							if parentPart:IsA("BasePart") then
								pos = parentPart.Position
							elseif parentPart:IsA("Model") then
								local pp = parentPart:FindFirstChildWhichIsA("BasePart")
								if pp then pos = pp.Position end
							end

							if pos and (pos - sealPos).Magnitude < PROMPT_RADIUS then
								pcall(function()
									fireproximityprompt(prompt)
									promptFireCount = promptFireCount + 1
								end)
								fired = true
							end
						end
					end
					task.wait(PROMPT_SPAM_RATE)
				end
			end)

			-- ==========================================
			-- CHỜ BOSS SPAWN HOẶC SEAL BIẾN MẤT
			-- ==========================================
			local waitStart = tick()
			while tick() - waitStart < SEAL_TIMEOUT do
				if not sealObj or not sealObj.Parent then
					print("[SEAL] Seal biến mất -> OK")
					bossSpawned = true
					break
				end
				if getTarget() then
					print("[SEAL] Boss spawn -> lao vào đánh!")
					bossSpawned = true
					break
				end
				task.wait(0.2)
			end

			stopSpam = true
			pcall(function() task.cancel(vThread) end)
			pcall(function() task.cancel(promptThread) end)
			task.wait(0.05)

			if bossSpawned then
				print(string.format(">>> [SEAL %d] Xong sau %d lần (V:%d, Prompt:%d)",
					sealNum, retryCount, vFireCount, promptFireCount))
			else
				warn(string.format("[SEAL %d] Timeout (V:%d, Prompt:%d) -> Retry",
					sealNum, retryCount, vFireCount, promptFireCount))
			end
		end

		if not bossSpawned then
			warn(string.format("[SEAL %d] Thất bại %d lần -> bỏ qua", sealNum, MAX_RETRY))
		end
		targetSealNum = nil
	end

	-- ==========================================
	-- VÒNG LẶP CHÍNH
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

		local enemy = getTarget()
		if enemy then
			pcall(fightEnemy, enemy, myHrp)
		else
			if targetSealNum then
				pcall(processSeal, targetSealNum, myHrp)
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
	print("[DISPATCH] Place Farm -> Auto Farm (Araya + The World V + Prompt)...")
	task.wait(2)
	runAutoFarm()

else
	warn("[DISPATCH] PlaceId không khớp flow:", game.PlaceId)
end
