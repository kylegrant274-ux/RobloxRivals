-- LocalScript inside StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Toggles
local aimbotEnabled = false
local espEnabled = false
local friendWhitelistEnabled = false
local isRightClickHolding = false

-- Tracking variables
local currentTarget = nil

-- Configuration
local ESP_COLOR = Color3.fromRGB(255, 0, 0) -- Neon Red

--- Helper: Check if a player is a friend
local function isFriend(player)
	if player == localPlayer then return false end
	local success, result = pcall(function()
		return localPlayer:IsFriendsWith(player.UserId)
	end)
	return success and result
end

--- Helper: Find the player closest to the center of the screen
local function getClosestPlayerToCenter()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local viewportCenter = camera.ViewportSize / 2

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
			-- Skip friends if whitelist is active
			if friendWhitelistEnabled and isFriend(player) then
				continue
			end
			
			-- Check if alive
			if player.Character.Humanoid.Health <= 0 then
				continue
			end

			local hrp = player.Character.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

			if onScreen then
				local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
				if distanceToCenter < shortestDistance then
					shortestDistance = distanceToCenter
					closestPlayer = player
				end
			end
		end
	end

	return closestPlayer
end

--- ESP Management
local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player == localPlayer then continue end

		local char = player.Character
		if char then
			-- Handle Outline (Highlight)
			local highlight = char:FindFirstChild("ESPHighlight")
			local shouldHaveESP = espEnabled and (not (friendWhitelistEnabled and isFriend(player)))
			
			if shouldHaveESP and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				if not highlight then
					highlight = Instance.new("Highlight")
					highlight.Name = "ESPHighlight"
					highlight.FillColor = ESP_COLOR
					highlight.FillTransparency = 0.5
					highlight.OutlineColor = ESP_COLOR
					highlight.OutlineTransparency = 0
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = char
				end
				
				-- Handle Name/Health Tag (BillboardGui)
				local billboard = char:FindFirstChild("ESPBillboard")
				if not billboard then
					billboard = Instance.new("BillboardGui")
					billboard.Name = "ESPBillboard"
					billboard.Size = UDim2.new(0, 200, 0, 50)
					billboard.AlwaysOnTop = true
					billboard.ExtentsOffset = Vector3.new(0, 3, 0)
					
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextColor3 = Color3.new(1, 1, 1)
					textLabel.TextStrokeTransparency = 0
					textLabel.TextSize = 14
					textLabel.Font = Enum.Font.SourceSansBold
					textLabel.Parent = billboard
					
					billboard.Parent = char
				end
				
				local label = billboard:FindFirstChildOfClass("TextLabel")
				if label and char:FindFirstChild("Humanoid") then
					label.Text = string.format("%s\nHP: %.0f", player.Name, char.Humanoid.Health)
				end
			else
				if highlight then highlight:Destroy() end
				if char:FindFirstChild("ESPBillboard") then char.ESPBillboard:Destroy() end
			end
		end
	end
end

--- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- F2: Toggle Aim Assist
	if input.KeyCode == Enum.KeyCode.F2 then
		aimbotEnabled = not aimbotEnabled
		if not aimbotEnabled then currentTarget = nil end
		print("Aim Assist:", aimbotEnabled and "ON" or "OFF")
	
	-- F3: Toggle ESP
	elseif input.KeyCode == Enum.KeyCode.F3 then
		espEnabled = not espEnabled
		if not espEnabled then updateESP() end
		print("ESP:", espEnabled and "ON" or "OFF")
		
	-- F4: Toggle Friend Whitelist
	elseif input.KeyCode == Enum.KeyCode.F4 then
		friendWhitelistEnabled = not friendWhitelistEnabled
		print("Friend Whitelist:", friendWhitelistEnabled and "ON" or "OFF")
		if espEnabled then updateESP() end
		if aimbotEnabled then currentTarget = nil end
		
	-- Track Right Click
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickHolding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickHolding = false
		currentTarget = nil -- Clear target when letting go of right click
	end
end)

--- Main Loop (Runs every frame before rendering)
RunService.RenderStepped:Connect(function()
	-- Update ESP visuals
	if espEnabled then
		updateESP()
	end

	-- Update Aim Assist
	if aimbotEnabled and isRightClickHolding then
		-- Target validation
		if currentTarget then
			local char = currentTarget.Character
			local isDead = char and char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0
			local isWhitelisted = friendWhitelistEnabled and isFriend(currentTarget)
			
			if isDead or isWhitelisted or not char:FindFirstChild("Head") then
				currentTarget = nil -- Lose lock-on if they die, become a friend, or leave
			end
		end

		-- If no current target, look for the closest one to the crosshair
		if not currentTarget then
			currentTarget = getClosestPlayerToCenter()
		end

		-- Lock camera onto target's head
		if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
			local head = currentTarget.Character.Head
			camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
		end
	end
end)

-- Clean up ESP tags if a player leaves or resets character
Players.PlayerRemoving:Connect(updateESP)
