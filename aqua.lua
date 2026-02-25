local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

local pos1 = Vector3.new(-352.98, -7, 74.30)
local pos2 = Vector3.new(-352.98, -6.49, 45.76)
local standing1 = Vector3.new(-336.36, -4.59, 99.51)
local standing2 = Vector3.new(-334.81, -4.59, 18.90)

local spot1_sequence = {
CFrame.new(-370.810913, -7.00000334, 41.2687263, 0.99984771, 1.22364419e-09, 0.0174523517, -6.54859778e-10, 1, -3.2596418e-08, -0.0174523517, 3.25800258e-08, 0.99984771),
CFrame.new(-336.355286, -5.10107088, 17.2327671, -0.999883354, -2.76150569e-08, 0.0152716246, -2.88224964e-08, 1, -7.88441525e-08, -0.0152716246, -7.9275118e-08, -0.999883354)
}

local spot2_sequence = {
CFrame.new(-354.782867, -7.00000334, 92.8209305, -0.999997616, -1.11891862e-09, -0.00218066527, -1.11958298e-09, 1, 3.03415071e-10, 0.00218066527, 3.05855785e-10, -0.999997616),
CFrame.new(-336.942902, -5.10106993, 99.3276443, 0.999914348, -3.63984611e-08, 0.0130875716, 3.67094941e-08, 1, -2.35254749e-08, -0.0130875716, 2.40038975e-08, 0.999914348)
}

if CoreGui:FindFirstChild("BloodHubGui") then
CoreGui["BloodHubGui"]:Destroy()
end
if CoreGui:FindFirstChild("AquaHubGui") then
CoreGui["AquaHubGui"]:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AquaHubGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- ===================== UI AQUA HUB =====================
local BLUE_MAIN = Color3.fromRGB(0, 180, 255)
local BLUE_TEXT = Color3.fromRGB(200, 240, 255)
local BLUE_GLOW = Color3.fromRGB(0, 120, 255)
local BLUE_BRIGHT = Color3.fromRGB(100, 200, 255)
local BG_DARK = Color3.fromRGB(15, 15, 15)
local BG_BUTTON = Color3.fromRGB(30, 30, 30)
local KEYBIND_BG = Color3.fromRGB(45, 45, 45)
local KEYBIND_TEXT = Color3.fromRGB(180, 180, 180)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 220) -- Ajusté après suppression TikTok
mainFrame.Position = UDim2.new(1, -255, 0.5, -122)
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.BackgroundColor3 = BG_DARK
mainFrame.BackgroundTransparency = 0.12
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- ===== ROTATING BORDER EFFECT =====
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(255, 255, 255)
frameStroke.Thickness = 4 -- Barre assez prononcée
frameStroke.Parent = mainFrame
local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 40, 120)),
	ColorSequenceKeypoint.new(0.4, BLUE_MAIN),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.6, BLUE_MAIN),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 40, 120))
})
frameGradient.Parent = frameStroke

-- ===================== UI AQUA SPAMMER =====================
local spammerFrame = Instance.new("Frame")
spammerFrame.Name = "SpammerFrame"
spammerFrame.Size = UDim2.new(0, 240, 0, 252)
spammerFrame.Position = UDim2.new(1, -505, 0.5, -122)
spammerFrame.AnchorPoint = Vector2.new(0, 0.5)
spammerFrame.BackgroundColor3 = BG_DARK
spammerFrame.BackgroundTransparency = 0.12
spammerFrame.BorderSizePixel = 0
spammerFrame.Active = true
spammerFrame.Parent = screenGui
Instance.new("UICorner", spammerFrame).CornerRadius = UDim.new(0, 10)

local spamStroke = Instance.new("UIStroke")
spamStroke.Color = Color3.fromRGB(255, 255, 255)
spamStroke.Thickness = 4
spamStroke.Parent = spammerFrame
local spamGradient = Instance.new("UIGradient")
spamGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 40, 120)),
	ColorSequenceKeypoint.new(0.4, BLUE_MAIN),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.6, BLUE_MAIN),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 40, 120))
})
spamGradient.Parent = spamStroke

RunService.RenderStepped:Connect(function(dt)
	if screenGui and screenGui.Parent then
		local newRot = (frameGradient.Rotation + dt * 130) % 360
		frameGradient.Rotation = newRot
		spamGradient.Rotation = newRot
	end
end)

local spamTitle = Instance.new("TextLabel")
spamTitle.Size = UDim2.new(1, 0, 0, 20)
spamTitle.Position = UDim2.new(0, 0, 0, 4)
spamTitle.BackgroundTransparency = 1
spamTitle.Text = "AQUA SPAMMER"
spamTitle.TextColor3 = BLUE_MAIN
spamTitle.TextSize = 14
spamTitle.Font = Enum.Font.GothamBlack
spamTitle.TextStrokeTransparency = 0.3
spamTitle.TextStrokeColor3 = BLUE_GLOW
spamTitle.Parent = spammerFrame

local spamToggleLabel = Instance.new("TextLabel")
spamToggleLabel.Size = UDim2.new(1, 0, 0, 18)
spamToggleLabel.Position = UDim2.new(0, 0, 0, 24)
spamToggleLabel.BackgroundTransparency = 1
spamToggleLabel.Text = "Toggle Menu: V"
spamToggleLabel.TextColor3 = BLUE_TEXT
spamToggleLabel.TextSize = 14
spamToggleLabel.Font = Enum.Font.GothamMedium
spamToggleLabel.TextStrokeTransparency = 0.5
spamToggleLabel.TextStrokeColor3 = BLUE_GLOW
spamToggleLabel.Parent = spammerFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.9, 0, 1, -55)
scrollFrame.Position = UDim2.new(0.05, 0, 0, 46)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = BLUE_MAIN
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = spammerFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 5) 
end)

local function sendCommand(cmd, target)
	local msg = cmd .. " " .. target
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if ch then ch:SendAsync(msg) end
	else
		local rep = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
		if rep then rep.SayMessageRequest:FireServer(msg, "All") end
	end
end

local function updatePlayerList()
	for _, v in ipairs(scrollFrame:GetChildren()) do
		if v:IsA("GuiObject") then v:Destroy() end
	end
	local cmds = {";ragdoll", ";ballon", ";petit", ";rocket", ";inverse", ";morph"}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 28)
			btn.BackgroundColor3 = BG_BUTTON
			btn.Text = pl.Name
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 14
			btn.Font = Enum.Font.GothamBold
			btn.Parent = scrollFrame
			
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			local stroke = Instance.new("UIStroke", btn)
			stroke.Thickness = 1.5
			stroke.Color = BLUE_MAIN
			
			btn.MouseButton1Down:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
				stroke.Color = BLUE_GLOW
			end)
			btn.MouseButton1Up:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = BG_BUTTON}):Play()
				stroke.Color = BLUE_MAIN
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = BG_BUTTON}):Play()
				stroke.Color = BLUE_MAIN
			end)
			
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					for _, c in ipairs(cmds) do
						sendCommand(c, pl.Name)
						task.wait(0.25)
					end
				end)
			end)
		end
	end
end
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.new(1, 0, 0, 20)
hubTitle.Position = UDim2.new(0, 0, 0, 4)
hubTitle.BackgroundTransparency = 1
hubTitle.Text = "AQUA HUB  SEMI TP"
hubTitle.TextColor3 = BLUE_MAIN
hubTitle.TextSize = 14
hubTitle.Font = Enum.Font.GothamBlack
hubTitle.TextStrokeTransparency = 0.3
hubTitle.TextStrokeColor3 = BLUE_GLOW
hubTitle.Parent = mainFrame

-- Toggle Menu: V
local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, 0, 0, 18)
toggleLabel.Position = UDim2.new(0, 0, 0, 24)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Toggle Menu: V"
toggleLabel.TextColor3 = BLUE_TEXT
toggleLabel.TextSize = 10
toggleLabel.Font = Enum.Font.GothamMedium
toggleLabel.TextStrokeTransparency = 0.5
toggleLabel.TextStrokeColor3 = BLUE_GLOW
toggleLabel.Parent = mainFrame

-- ===== KEYBIND SYSTEM =====
local kbLeft, kbRight, speedKeybind -- forward declarations
local keybinds = {
	tpLeft = Enum.KeyCode.F,
	tpRight = Enum.KeyCode.G,
	speed = Enum.KeyCode.C,
	toggle = Enum.KeyCode.V
}
local listeningFor = nil -- which keybind we're currently rebinding
local listeningLabel = nil -- the label to update

local function startListening(bindName, label)
	if listeningFor then return end
	listeningFor = bindName
	listeningLabel = label
	label.Text = "..."
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.BackgroundColor3 = Color3.fromRGB(30, 80, 130)
end

local function finishListening(keyCode)
	if not listeningFor then return false end
	-- Empêcher les doublons : si une autre action a déjà cette touche, la libérer
	for name, key in pairs(keybinds) do
		if key == keyCode and name ~= listeningFor then
			keybinds[name] = Enum.KeyCode.Unknown
			-- Mettre à jour le badge visuel de l'ancien
			if name == "tpLeft" and kbLeft then kbLeft.Text = "-" end
			if name == "tpRight" and kbRight then kbRight.Text = "-" end
			if name == "speed" then speedKeybind.Text = "-" end
		end
	end
	keybinds[listeningFor] = keyCode
	listeningLabel.Text = keyCode.Name
	listeningLabel.TextColor3 = KEYBIND_TEXT
	listeningLabel.BackgroundColor3 = KEYBIND_BG
	listeningFor = nil
	listeningLabel = nil
	return true
end

-- ===== ROW HELPER =====
local function createRow(parent, yPos, labelText, keybindChar, bindName)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.9, 0, 0, 30)
	row.Position = UDim2.new(0.05, 0, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -38, 1, 0)
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = BG_BUTTON
	btn.BackgroundTransparency = 0
	btn.Text = labelText
	btn.TextColor3 = BLUE_TEXT
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextStrokeTransparency = 0.4
	btn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Thickness = 1.5
	btnStroke.Color = BLUE_MAIN

	-- Effet enfoncement
	local originalPos = UDim2.new(0.05, 0, 0, yPos)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.85, 0, 0, 26),
			Position = UDim2.new(0.075, 0, 0, yPos + 2)
		}):Play()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			TextColor3 = Color3.fromRGB(150, 220, 255),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.08), {Color = BLUE_BRIGHT}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.9, 0, 0, 30),
			Position = originalPos
		}):Play()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			TextColor3 = BLUE_TEXT,
			BackgroundColor3 = BG_BUTTON
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.12), {Color = BLUE_MAIN}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.9, 0, 0, 30),
			Position = originalPos
		}):Play()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			TextColor3 = BLUE_TEXT,
			BackgroundColor3 = BG_BUTTON
		}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.12), {Color = BLUE_MAIN}):Play()
	end)

	local keybindBtn = Instance.new("TextButton")
	keybindBtn.Size = UDim2.new(0, 26, 0, 22)
	keybindBtn.Position = UDim2.new(1, -28, 0.5, -11)
	keybindBtn.BackgroundColor3 = KEYBIND_BG
	keybindBtn.BackgroundTransparency = 0.2
	keybindBtn.Text = keybindChar
	keybindBtn.TextColor3 = KEYBIND_TEXT
	keybindBtn.TextSize = 12
	keybindBtn.Font = Enum.Font.GothamBold
	keybindBtn.Parent = row
	Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, 5)
	keybindBtn.MouseButton1Click:Connect(function()
		startListening(bindName, keybindBtn)
	end)

	return row, btn, keybindBtn
end

-- Row 1: Auto tp Left (F)
local row1, btnLeft
row1, btnLeft, kbLeft = createRow(mainFrame, 46, "Auto tp Left", "F", "tpLeft")

-- Row 2: Auto tp Right (G)
local row2, btnRight
row2, btnRight, kbRight = createRow(mainFrame, 80, "Auto tp Right", "G", "tpRight")

-- ===== PROGRESS BAR =====
local progressBarBg = Instance.new("Frame")
progressBarBg.Size = UDim2.new(0.9, 0, 0, 8)
progressBarBg.Position = UDim2.new(0.05, 0, 0, 114)
progressBarBg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
progressBarBg.BackgroundTransparency = 0.2
progressBarBg.BorderSizePixel = 0
progressBarBg.Parent = mainFrame
Instance.new("UICorner", progressBarBg).CornerRadius = UDim.new(0, 4)
local progressBarStroke = Instance.new("UIStroke", progressBarBg)
progressBarStroke.Thickness = 1
progressBarStroke.Color = Color3.fromRGB(60, 60, 60)

local progressBarFill = Instance.new("Frame")
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.Position = UDim2.new(0, 0, 0, 0)
progressBarFill.BackgroundColor3 = BLUE_MAIN
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarBg
Instance.new("UICorner", progressBarFill).CornerRadius = UDim.new(0, 4)

local progressGradient = Instance.new("UIGradient")
progressGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 100, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 150, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
})
progressGradient.Parent = progressBarFill

local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(0.9, 0, 0, 34)
speedRow.Position = UDim2.new(0.05, 0, 0, 130)
speedRow.BackgroundTransparency = 1
speedRow.Parent = mainFrame

local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(1, -82, 1, 0)
speedButton.Position = UDim2.new(0, 0, 0, 0)
speedButton.BackgroundColor3 = BLUE_BRIGHT
speedButton.Text = "Enable Speed"
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.TextSize = 14
speedButton.Font = Enum.Font.GothamBold
speedButton.Parent = speedRow
Instance.new("UICorner", speedButton).CornerRadius = UDim.new(0, 8)
local speedStroke = Instance.new("UIStroke", speedButton)
speedStroke.Thickness = 2
speedStroke.Color = BLUE_MAIN

local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0, 36, 0, 26)
speedInputBox.Position = UDim2.new(1, -70, 0.5, -13)
speedInputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
speedInputBox.Text = "27"
speedInputBox.TextColor3 = BLUE_TEXT
speedInputBox.TextSize = 13
speedInputBox.Font = Enum.Font.GothamBold
speedInputBox.TextXAlignment = Enum.TextXAlignment.Center
speedInputBox.ClearTextOnFocus = false
speedInputBox.Parent = speedRow
Instance.new("UICorner", speedInputBox).CornerRadius = UDim.new(0, 6)
local speedInputStroke = Instance.new("UIStroke", speedInputBox)
speedInputStroke.Color = BLUE_MAIN
speedInputStroke.Thickness = 1

speedInputBox:GetPropertyChangedSignal("Text"):Connect(function()
	local val = tonumber(speedInputBox.Text)
	if val then
		BOOST_SPEED = val
	end
end)

speedKeybind = Instance.new("TextButton")
speedKeybind.Size = UDim2.new(0, 26, 0, 22)
speedKeybind.Position = UDim2.new(1, -28, 0.5, -11)
speedKeybind.BackgroundColor3 = KEYBIND_BG
speedKeybind.BackgroundTransparency = 0.2
speedKeybind.Text = "C"
speedKeybind.TextColor3 = KEYBIND_TEXT
speedKeybind.TextSize = 12
speedKeybind.Font = Enum.Font.GothamBold
speedKeybind.Parent = speedRow
Instance.new("UICorner", speedKeybind).CornerRadius = UDim.new(0, 5)
speedKeybind.MouseButton1Click:Connect(function()
	startListening("speed", speedKeybind)
end)

local speedEnabled = false
local speedIntensity = 28

local allowRow = Instance.new("Frame")
allowRow.Size = UDim2.new(0.9, 0, 0, 34)
allowRow.Position = UDim2.new(0.05, 0, 0, 168)
allowRow.BackgroundTransparency = 1
allowRow.Parent = mainFrame

local allowToggle = Instance.new("TextButton")
allowToggle.Size = UDim2.new(1, 0, 1, 0)
allowToggle.Position = UDim2.new(0, 0, 0, 0)
allowToggle.BackgroundColor3 = BG_BUTTON
allowToggle.Text = "Disallow"
allowToggle.TextColor3 = BLUE_TEXT
allowToggle.TextSize = 14
allowToggle.Font = Enum.Font.GothamBold
allowToggle.TextStrokeTransparency = 0.4
allowToggle.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
allowToggle.Parent = allowRow
Instance.new("UICorner", allowToggle).CornerRadius = UDim.new(0, 8)
local allowStroke = Instance.new("UIStroke", allowToggle)
allowStroke.Thickness = 1.5
allowStroke.Color = BLUE_MAIN

local isAllowed = false

local allowOriginalPos = UDim2.new(0.05, 0, 0, 168)
allowToggle.MouseButton1Down:Connect(function()
	TweenService:Create(allowRow, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.85, 0, 0, 30),
		Position = UDim2.new(0.075, 0, 0, 170)
	}):Play()
	TweenService:Create(allowToggle, TweenInfo.new(0.08), {
		TextColor3 = Color3.fromRGB(150, 220, 255),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	}):Play()
	TweenService:Create(allowStroke, TweenInfo.new(0.08), {Color = BLUE_BRIGHT}):Play()
end)
allowToggle.MouseButton1Up:Connect(function()
	TweenService:Create(allowRow, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.9, 0, 0, 34),
		Position = allowOriginalPos
	}):Play()
	TweenService:Create(allowToggle, TweenInfo.new(0.12), {
		TextColor3 = BLUE_TEXT,
		BackgroundColor3 = BG_BUTTON
	}):Play()
	TweenService:Create(allowStroke, TweenInfo.new(0.12), {Color = BLUE_MAIN}):Play()
end)
allowToggle.MouseLeave:Connect(function()
	TweenService:Create(allowRow, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.9, 0, 0, 34),
		Position = allowOriginalPos
	}):Play()
	TweenService:Create(allowToggle, TweenInfo.new(0.12), {
		TextColor3 = BLUE_TEXT,
		BackgroundColor3 = BG_BUTTON
	}):Play()
	TweenService:Create(allowStroke, TweenInfo.new(0.12), {Color = BLUE_MAIN}):Play()
end)

local function findMyPlot()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local closest, cd = nil, 999
	for _, plot in ipairs(workspace.Plots:GetChildren()) do
		local fp = plot:FindFirstChild("FriendPanel")
		if fp then
			local m = fp:FindFirstChild("Main")
			if m and m:IsA("BasePart") then
				local d = (hrp.Position - m.Position).Magnitude
				if d < cd then cd = d; closest = plot end
			end
		end
	end
	return closest
end

local function toggleFriendsAccess()
	local mp = findMyPlot()
	if not mp then return end
	local fp = mp:FindFirstChild("FriendPanel")
	if not fp then return end
	local m = fp:FindFirstChild("Main")
	if not m then return end
	local pp = m:FindFirstChild("ProximityPrompt")
	if pp then
		fireproximityprompt(pp)
	end
end

local esp_items_aqua = {}

local function isFriendsBlocked(plot)
	local fp = plot:FindFirstChild("FriendPanel")
	local mn = fp and fp:FindFirstChild("Main")
	local sGui = mn and mn:FindFirstChild("SurfaceGui")
	local img = sGui and (sGui:FindFirstChild("ImageLabel") or sGui:FindFirstChildOfClass("ImageLabel"))
	if img then
		local id = tostring(img.Image)
		if string.find(id, "110783679426495") then return false else return true end
	end
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			local c = d.Color
			if c.R > c.G + 0.3 and c.R > c.B + 0.3 and d.Transparency < 0.8 then return true end
		end
		local ln = string.lower(d.Name)
		if (ln == "barrier" or ln == "lockwall") and d:IsA("BasePart") and d.CanCollide and d.Transparency < 0.9 then return true end
	end
	local iw = plot:FindFirstChild("InvisibleWalls")
	if iw then
		for _, p in ipairs(iw:GetChildren()) do
			if p:IsA("BasePart") and p.CanCollide and p.Transparency < 0.9 then return true end
		end
	end
	return false
end

local function clearEspAqua()
	for _, item in ipairs(esp_items_aqua) do pcall(function() item:Destroy() end) end
	esp_items_aqua = {}
end

local function updateEspAqua()
	clearEspAqua()
	local my_plot = findMyPlot()
	for _, plot in ipairs(workspace.Plots:GetChildren()) do
		if plot ~= my_plot then
			local fp = plot:FindFirstChild("FriendPanel")
			if not fp then continue end
			local anchor = fp:FindFirstChild("Main")
			if not anchor or not anchor:IsA("BasePart") then continue end
			pcall(function()
			local blocked = not isFriendsBlocked(plot)
			local col = blocked and Color3.fromRGB(255, 60, 50) or Color3.fromRGB(50, 255, 60)
			local bb = Instance.new("BillboardGui")
			bb.Name = "AquaESP"
			bb.Size = UDim2.new(0, 140, 0, 30)
			bb.StudsOffset = Vector3.new(0, 3.5, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = anchor
			bb.Parent = CoreGui
			local bg = Instance.new("Frame", bb)
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			bg.BackgroundTransparency = 0.2
			Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
			Instance.new("UIStroke", bg).Color = col
			local txt = Instance.new("TextLabel", bg)
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			if blocked then
				txt.Text = "🔒 DISALLOWED"
			else
				txt.Text = "✅ ALLOWED"
			end
			txt.TextColor3 = col
			txt.TextSize = 14
			txt.Font = Enum.Font.GothamBlack
			txt.TextStrokeTransparency = 0.15
			txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			table.insert(esp_items_aqua, bb)
		end)
		end
	end
end

task.spawn(function()
	while screenGui and screenGui.Parent do
		updateEspAqua()
		task.wait(1)
	end
	clearEspAqua()
end)

allowToggle.MouseButton1Click:Connect(function()
	isAllowed = not isAllowed
	if isAllowed then
		allowToggle.Text = "Allow"
		allowToggle.BackgroundColor3 = BLUE_BRIGHT
		allowToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		allowToggle.Text = "Disallow"
		allowToggle.BackgroundColor3 = BG_BUTTON
		allowToggle.TextColor3 = BLUE_TEXT
	end
	toggleFriendsAccess()
end)

local discordLabel = Instance.new("TextButton")
discordLabel.Size = UDim2.new(1, 0, 0, 14)
discordLabel.Position = UDim2.new(0, 0, 0, 206)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = "discord: https://discord.gg/tb3qtaZZ" -- Update discord link
discordLabel.TextColor3 = BLUE_MAIN
discordLabel.TextSize = 9
discordLabel.Font = Enum.Font.GothamMedium
discordLabel.TextStrokeTransparency = 0.6
discordLabel.TextStrokeColor3 = BLUE_GLOW
discordLabel.Parent = mainFrame

discordLabel.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard("https://discord.gg/tb3qtaZZ")
	elseif toclipboard then
		toclipboard("https://discord.gg/tb3qtaZZ")
	end
	local originalText = discordLabel.Text
	discordLabel.Text = "Copied!"
	discordLabel.TextColor3 = BLUE_BRIGHT
	task.delay(1, function()
		discordLabel.Text = originalText
		discordLabel.TextColor3 = BLUE_MAIN
	end)
end)

local speedConnection = nil

local boostEnabled = false
local BOOST_SPEED = 27
local boostConn
local startBoost, stopBoost

local function toggleSpeed()
	speedEnabled = not speedEnabled
	if speedEnabled then
		speedButton.Text = "Disable Speed"
		speedButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
		speedConnection = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = speedIntensity
				end
			end
		end)
		if not boostEnabled then
			boostEnabled = true
			startBoost()
		end
	else
		speedButton.Text = "Enable Speed"
		speedButton.BackgroundColor3 = BLUE_BRIGHT
		if speedConnection then speedConnection:Disconnect() speedConnection = nil end
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = 16 end
		end
		if boostEnabled then
			boostEnabled = false
			stopBoost()
		end
	end
end

speedButton.MouseButton1Click:Connect(toggleSpeed)

local function getCharBoost()
	local c = player.Character or player.CharacterAdded:Wait()
	local hrp = c:WaitForChild("HumanoidRootPart")
	local hum = c:FindFirstChildWhichIsA("Humanoid")
	return c, hrp, hum
end

local function getBoostMoveDir()
	local _, _, hum = getCharBoost()
	local move = hum.MoveDirection
	return move.Magnitude > 0.1 and move.Unit or Vector3.zero
end

startBoost = function()
	if boostConn then return end
	boostConn = RunService.Heartbeat:Connect(function()
		local _, hrp, hum = getCharBoost()
		if not hrp or not hum then return end
		local dir = getBoostMoveDir()
		if dir.Magnitude > 0 then
			hrp.AssemblyLinearVelocity = Vector3.new(
				dir.X * BOOST_SPEED,
				hrp.AssemblyLinearVelocity.Y,
				dir.Z * BOOST_SPEED
			)
		end
	end)
end


stopBoost = function()
	if boostConn then
		boostConn:Disconnect()
		boostConn = nil
	end
end

local function makeDraggable(frame)
	local dragging, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = frame.Position end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end
makeDraggable(mainFrame)
makeDraggable(spammerFrame)

local function ResetToWork()
	local flags = {
		{"GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000"},
		{"LargeReplicatorWrite5", "true"},
		{"LargeReplicatorEnabled9", "true"},
		{"AngularVelociryLimit", "360"},
		{"TimestepArbiterVelocityCriteriaThresholdTwoDt", "2147483646"},
		{"S2PhysicsSenderRate", "15000"},
		{"DisableDPIScale", "true"},
		{"MaxDataPacketPerSend", "2147483647"},
		{"ServerMaxBandwith", "52"},
		{"PhysicsSenderMaxBandwidthBps", "20000"},
		{"MaxTimestepMultiplierBuoyancy", "2147483647"},
		{"SimOwnedNOUCountThresholdMillionth", "2147483647"},
		{"MaxMissedWorldStepsRemembered", "-2147483648"},
		{"CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth", "1"},
		{"StreamJobNOUVolumeLengthCap", "2147483647"},
		{"DebugSendDistInSteps", "-2147483648"},
		{"MaxTimestepMultiplierAcceleration", "2147483647"},
		{"LargeReplicatorRead5", "true"},
		{"SimExplicitlyCappedTimestepMultiplier", "2147483646"},
		{"GameNetDontSendRedundantNumTimes", "1"},
		{"CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent", "1"},
		{"CheckPVCachedRotVelThresholdPercent", "10"},
		{"LargeReplicatorSerializeRead3", "true"},
		{"ReplicationFocusNouExtentsSizeCutoffForPauseStuds", "2147483647"},
		{"NextGenReplicatorEnabledWrite4", "true"},
		{"CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth", "1"},
		{"GameNetDontSendRedundantDeltaPositionMillionth", "1"},
		{"InterpolationFrameVelocityThresholdMillionth", "5"},
		{"StreamJobNOUVolumeCap", "2147483647"},
		{"InterpolationFrameRotVelocityThresholdMillionth", "5"},
		{"WorldStepMax", "30"},
		{"TimestepArbiterHumanoidLinearVelThreshold", "1"},
		{"InterpolationFramePositionThresholdMillionth", "5"},
		{"TimestepArbiterHumanoidTurningVelThreshold", "1"},
		{"MaxTimestepMultiplierContstraint", "2147483647"},
		{"GameNetPVHeaderLinearVelocityZeroCutoffExponent", "-5000"},
		{"CheckPVCachedVelThresholdPercent", "10"},
		{"TimestepArbiterOmegaThou", "1073741823"},
		{"MaxAcceptableUpdateDelay", "1"},
		{"LargeReplicatorSerializeWrite4", "true"},
	}
	for _, data in ipairs(flags) do pcall(function() if setfflag then setfflag(data[1], data[2]) end end) end
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
		char:ClearAllChildren()
		local f = Instance.new("Model", workspace)
		player.Character = f task.wait()
		player.Character = char f:Destroy()
	end
end

task.spawn(function() task.wait(1) ResetToWork() end)

local allAnimalsCache = {}
local InternalStealCache = {}
local IsStealing = false
local StealProgress = 0
local function getHRP() local char = player.Character return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")) end
local function isMyBase(plotName) local plot = workspace.Plots:FindFirstChild(plotName) return plot and plot:FindFirstChild("PlotSign") and plot.PlotSign:FindFirstChild("YourBase") and plot.PlotSign.YourBase.Enabled end
local function scan() table.clear(allAnimalsCache) for _, p in ipairs(workspace.Plots:GetChildren()) do if not isMyBase(p.Name) and p:FindFirstChild("AnimalPodiums") then for _, pod in ipairs(p.AnimalPodiums:GetChildren()) do if pod:FindFirstChild("Base") then table.insert(allAnimalsCache, {plot=p.Name, slot=pod.Name, worldPosition=pod:GetPivot().Position, uid=p.Name.."_"..pod.Name}) end end end end end
task.spawn(function() while task.wait(5) do scan() end end) scan()

local function buildSteal(prompt) if InternalStealCache[prompt] then return end local d = {hold={}, trig={}, ready=true} local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan) if ok1 then for _, c in ipairs(c1) do table.insert(d.hold, c.Function) end end local ok2, c2 = pcall(getconnections, prompt.Triggered) if ok2 then for _, c in ipairs(c2) do table.insert(d.trig, c.Function) end end InternalStealCache[prompt] = d end
local function execSteal(prompt, animal, seq) buildSteal(prompt) local d = InternalStealCache[prompt] if not d or not d.ready or IsStealing then return end d.ready = false IsStealing = true StealProgress = 0 progressBarFill.Size = UDim2.new(0, 0, 1, 0) progressBarFill.BackgroundTransparency = 0 progressBarStroke.Color = BLUE_MAIN local tpDone = false task.spawn(function() for _, f in ipairs(d.hold) do task.spawn(f) end local s = tick() while tick()-s < 1.3 do StealProgress = (tick()-s)/1.3 if not tpDone then progressBarFill.Size = UDim2.new(math.clamp(StealProgress, 0, 1), 0, 1, 0) end if StealProgress >= 0.73 and not tpDone then tpDone = true local hrp = getHRP() if hrp then local b = player:FindFirstChild("Backpack") if b and b:FindFirstChild("Flying Carpet") then player.Character.Humanoid:EquipTool(b["Flying Carpet"]) task.wait(0.1) end hrp.CFrame = seq[1] task.wait(0.1) hrp.CFrame = seq[2] task.wait(0.2) local d1 = (hrp.Position-pos1).Magnitude local d2 = (hrp.Position-pos2).Magnitude hrp.CFrame = CFrame.new(d1<d2 and pos1 or pos2) end progressBarFill.Size = UDim2.new(1, 0, 1, 0) end task.wait() end progressBarFill.Size = UDim2.new(1, 0, 1, 0) for _, f in ipairs(d.trig) do task.spawn(f) end task.wait(0.2) TweenService:Create(progressBarFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play() TweenService:Create(progressBarStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(60, 60, 60)}):Play() task.wait(0.4) progressBarFill.Size = UDim2.new(0, 0, 1, 0) progressBarFill.BackgroundTransparency = 0 d.ready=true IsStealing=false StealProgress=0 end) end

local function doStealLeft()
	local hrp = getHRP() if not hrp or IsStealing then return end
	scan()
	local target, dist = nil, 200
	for _, a in ipairs(allAnimalsCache) do local d = (hrp.Position-a.worldPosition).Magnitude if d < dist then dist=d target=a end end
	if target then
		local p = workspace.Plots[target.plot].AnimalPodiums[target.slot].Base.Spawn.PromptAttachment:FindFirstChildOfClass("ProximityPrompt")
		if p then execSteal(p, target, spot1_sequence) end
	end
end

local function doStealRight()
	local hrp = getHRP() if not hrp or IsStealing then return end
	scan()
	local target, dist = nil, 200
	for _, a in ipairs(allAnimalsCache) do local d = (hrp.Position-a.worldPosition).Magnitude if d < dist then dist=d target=a end end
	if target then
		local p = workspace.Plots[target.plot].AnimalPodiums[target.slot].Base.Spawn.PromptAttachment:FindFirstChildOfClass("ProximityPrompt")
		if p then execSteal(p, target, spot2_sequence) end
	end
end

btnLeft.MouseButton1Click:Connect(doStealLeft)
btnRight.MouseButton1Click:Connect(doStealRight)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	-- Si on est en mode écoute, assigner la touche
	if listeningFor then
		finishListening(input.KeyCode)
		return
	end

	if input.KeyCode == keybinds.toggle then
		mainFrame.Visible = not mainFrame.Visible
		if spammerFrame then spammerFrame.Visible = not spammerFrame.Visible end
	elseif input.KeyCode == keybinds.tpLeft then
		doStealLeft()
	elseif input.KeyCode == keybinds.tpRight then
		doStealRight()
	elseif input.KeyCode == keybinds.speed then
		toggleSpeed()
	end
end)
