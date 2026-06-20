-- LocalScript inside StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

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

----------------------------------------------------------------
-- UI Notification System
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheatNotificationGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "NotificationContainer"
notificationContainer.Size = UDim2.new(0, 220, 0, 300)
notificationContainer.Position = UDim2.new(1, -230, 1, -310) -- Bottom Right
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.Parent = notificationContainer

local function showNotification(text, stateOrColor)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 35)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = 1 -- Start transparent for fade-in
	frame.BorderSizePixel = 0
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = frame
	
	-- Determine accent color based on variable type passed
	local accentColor = Color3.fromRGB(200, 200, 200) -- Default Neutral Grey
	if typeof(stateOrColor) == "boolean" then
		accentColor = stateOrColor and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 70, 70)
	elseif typeof(stateOrColor) == "Color3" then
		accentColor = stateOrColor
	end
	
	-- Colored accent line on the left side
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 4, 1, 0)
	indicator.Position = UDim2.new(0, 0, 0, 0)
	indicator.BackgroundColor3 = accentColor
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = frame
	
	local uiCornerInd = Instance.new("UICorner")
	uiCornerInd.CornerRadius = UDim.new(0, 6)
	uiCornerInd.Parent = indicator

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -15, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextTransparency = 1
	label.TextSize = 13
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	frame.Parent = notificationContainer

	-- Fade In
	TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 0.15}):Play()
	TweenService:Create(indicator, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
	TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

	-- Wait 2 seconds, then Fade Out and Destroy
	task.delay(2, function()
		if frame and frame.Parent then
			TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			TweenService:Create(indicator, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			local fadeOut = TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				frame:Destroy()
			end)
		end
	end)
end

----------------------------------------------------------------
-- Core Mechanics
----------------------------------------------------------------
local function isFriend(player)
	if player == localPlayer then return false end
	local success, result = pcall(function()
		return localPlayer:IsFriendsWith(player.UserId)
	end)
	return success and result
end

local function getClosestPlayerToCenter()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local viewportCenter = camera.ViewportSize / 2

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
			if friendWhitelistEnabled and isFriend(player) then continue end
			if player.Character.Humanoid.Health <= 0 then continue end

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

local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player == localPlayer then continue end

		local char = player.Character
		if char then
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

----------------------------------------------------------------
-- Input Bindings
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F2 then
		aimbotEnabled = not aimbotEnabled
		if not aimbotEnabled then currentTarget = nil end
		showNotification("Aim Lock: " .. (aimbotEnabled and "ENABLED" or "DISABLED"), aimbotEnabled)
	
	elseif input.KeyCode == Enum.KeyCode.F3 then
		espEnabled = not espEnabled
		if not espEnabled then updateESP() end
		showNotification("ESP: " .. (espEnabled and "ENABLED" or "DISABLED"), espEnabled)
		
	elseif input.KeyCode == Enum.KeyCode.F4 then
		friendWhitelistEnabled = not friendWhitelistEnabled
		if espEnabled then updateESP() end
		if aimbotEnabled then currentTarget = nil end
		showNotification("Friend Ignore: " .. (friendWhitelistEnabled and "ENABLED" or "DISABLED"), friendWhitelistEnabled)
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickHolding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isRightClickHolding = false
		currentTarget = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if espEnabled then updateESP() end

	if aimbotEnabled and isRightClickHolding then
		if currentTarget then
			local char = currentTarget.Character
			local isDead = char and char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0
			local isWhitelisted = friendWhitelistEnabled and isFriend(currentTarget)
			
			if isDead or isWhitelisted or not char:FindFirstChild("Head") then
				currentTarget = nil
			end
		end

		if not currentTarget then
			currentTarget = getClosestPlayerToCenter()
		end

		if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
			local head = currentTarget.Character.Head
			camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
		end
	end
end)

Players.PlayerRemoving:Connect(updateESP)

----------------------------------------------------------------
-- Initialization Notice
----------------------------------------------------------------
-- This runs immediately once everything above is successfully compiled and loaded.
showNotification("System Initialized", Color3.fromRGB(0, 160, 255))
