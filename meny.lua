--====================================================--
-- AURORA PANEL — ProfitCruiser (fixed key→panel flow)
-- Full redesign: Compact 2-col layout + sections + gating
-- Aimbot, ESP (Highlight), Crosshair, Profiles
--====================================================--

--// Services
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local GuiService        = game:GetService("GuiService")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- forward-declare Root so click handlers can access it before it's created
local Root

pcall(function()
    GuiService.AutoSelectGuiEnabled = false
    GuiService.SelectedObject = nil
end)

--// Gate / links
local KEY_CHECK_URL = "https://pastebin.com/raw/QgqAaumb"
local GET_KEY_URL   = "https://pastebin.com/raw/QgqAaumb"
local DISCORD_URL   = "https://discord.gg/Pgn4NMWDH8"

--// Theme
local T = {
    BG      = Color3.fromRGB(10, 9, 18),
    Panel   = Color3.fromRGB(18, 16, 31),
    Card    = Color3.fromRGB(24, 21, 40),
    Ink     = Color3.fromRGB(34, 30, 52),
    Stroke  = Color3.fromRGB(82, 74, 120),
    Neon    = Color3.fromRGB(160, 105, 255),
    Accent  = Color3.fromRGB(116, 92, 220),
    Glass   = Color3.fromRGB(26, 23, 38),
    Section = Color3.fromRGB(30, 27, 46),
    Chip    = Color3.fromRGB(42, 36, 60),
    Text    = Color3.fromRGB(240, 240, 252),
    Subtle  = Color3.fromRGB(188, 182, 210),
    Good    = Color3.fromRGB(80, 210, 140),
    Warn    = Color3.fromRGB(255, 183, 77),
    Off     = Color3.fromRGB(100, 94, 130),
}

local function safeParent()
    local ok, ui = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    return (ok and ui) or LocalPlayer:WaitForChild("PlayerGui")
end

--// Utils
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function stroke(o,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o end
local function pad(o,p) local x=Instance.new("UIPadding"); x.PaddingTop=UDim.new(0,p); x.PaddingBottom=UDim.new(0,p); x.PaddingLeft=UDim.new(0,p); x.PaddingRight=UDim.new(0,p); x.Parent=o end
local function trim(s) s=tostring(s or ""):gsub("\r",""):gsub("\n",""):gsub("%s+$",""):gsub("^%s+",""); return s end
local function setInteractable(frame, on)
    if not frame or not frame:IsA("GuiObject") then return end
    local textTransparency = on and 0 or 0.45
    for _,v in ipairs(frame:GetDescendants()) do
        if v:IsA("TextLabel") then
            v.TextTransparency = textTransparency
        elseif v:IsA("TextButton") then
            v.TextTransparency = textTransparency
            v.AutoButtonColor = on
        elseif v:IsA("ImageLabel") then
            v.ImageTransparency = on and 0 or 0.25
        end
    end

    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Transparency = on and 0.25 or 0.6
    end

    local overlay = frame:FindFirstChild("DisabledOverlay")
    if not overlay then
        overlay = Instance.new("Frame")
        overlay.Name = "DisabledOverlay"
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 0.72
        overlay.Visible = false
        overlay.BorderSizePixel = 0
        overlay.ZIndex = frame.ZIndex + 1
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.Parent = frame
        local parentCorner = frame:FindFirstChildOfClass("UICorner")
        if parentCorner then
            local c = Instance.new("UICorner")
            c.CornerRadius = parentCorner.CornerRadius
            c.Parent = overlay
        end
    end

    overlay.Visible = not on
    frame.Active = on
end

--==================== ACCESS OVERLAY ====================--
local Blur = Instance.new("BlurEffect"); Blur.Enabled=false; Blur.Size=0; Blur.Parent=Lighting

local Gate = Instance.new("ScreenGui")
Gate.Name="PC_Gate"; Gate.IgnoreGuiInset=true; Gate.ResetOnSpawn=false; Gate.ZIndexBehavior=Enum.ZIndexBehavior.Global
Gate.DisplayOrder=100; Gate.Parent=safeParent()

local Dim = Instance.new("Frame", Gate)
Dim.BackgroundColor3=Color3.new(0,0,0); Dim.BackgroundTransparency=0.35; Dim.Size=UDim2.fromScale(1,1)

local Card = Instance.new("Frame", Gate)
Card.Size=UDim2.fromOffset(600, 360); Card.AnchorPoint=Vector2.new(0.5,0.5); Card.Position=UDim2.fromScale(0.5,0.5)
Card.BackgroundColor3=T.Card; stroke(Card,T.Stroke,1,0.45); corner(Card,18); pad(Card,22)

local CardLayout = Instance.new("UIListLayout", Card)
CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
CardLayout.Padding   = UDim.new(0, 12)

local Hero = Instance.new("Frame", Card)
Hero.Name = "Hero"; Hero.Size = UDim2.new(1,0,0,128); Hero.LayoutOrder = 1; Hero.BackgroundColor3 = T.Accent; Hero.BackgroundTransparency = 0.7
Hero.ZIndex = 2; Hero.ClipsDescendants = true; corner(Hero,16); stroke(Hero,T.Stroke,1,0.28)

local heroGradient = Instance.new("UIGradient", Hero)
heroGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Neon)
})
heroGradient.Rotation = 28
heroGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.22),
    NumberSequenceKeypoint.new(1, 0.32)
})

local heroPad = Instance.new("UIPadding", Hero)
heroPad.PaddingTop = UDim.new(0, 18); heroPad.PaddingBottom = UDim.new(0, 18)
heroPad.PaddingLeft = UDim.new(0, 20); heroPad.PaddingRight = UDim.new(0, 20)

local heroLayout = Instance.new("UIListLayout", Hero)
heroLayout.SortOrder = Enum.SortOrder.LayoutOrder; heroLayout.Padding = UDim.new(0, 8)

local Pill = Instance.new("TextLabel", Hero)
Pill.BackgroundTransparency = 0.2; Pill.BackgroundColor3 = T.Ink; Pill.LayoutOrder = 1
Pill.Size = UDim2.new(0, 150, 0, 26); Pill.Font = Enum.Font.GothamBold; Pill.TextSize = 13
Pill.Text = "ACCESS PASS"; Pill.TextColor3 = T.Text; Pill.TextXAlignment = Enum.TextXAlignment.Center
Pill.ZIndex = 3
corner(Pill, 13); stroke(Pill, T.Stroke, 1, 0.5)

local Title = Instance.new("TextLabel", Hero)
Title.BackgroundTransparency=1; Title.Text="ProfitCruiser — Access Portal"; Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextColor3=T.Text
Title.Size=UDim2.new(1,0,0,34); Title.TextXAlignment=Enum.TextXAlignment.Left; Title.LayoutOrder = 2; Title.ZIndex = 3

local Hint = Instance.new("TextLabel", Hero)
Hint.BackgroundTransparency=1; Hint.Text="Paste your private key to unlock Aurora. Grab a new key or meet the crew on Discord for instant drops."; Hint.Font=Enum.Font.Gotham
Hint.TextSize=14; Hint.TextColor3=T.Text; Hint.TextWrapped=true; Hint.TextXAlignment=Enum.TextXAlignment.Left; Hint.TextYAlignment=Enum.TextYAlignment.Top
Hint.Size=UDim2.new(1,0,0,44); Hint.LayoutOrder = 3; Hint.ZIndex = 3

local Features = Instance.new("TextLabel", Hero)
Features.BackgroundTransparency = 1; Features.Text = "⚡ Rapid updates    🛡️ Anti-ban shielding    🎯 Elite aim assist"
Features.Font = Enum.Font.Gotham; Features.TextSize = 13; Features.TextColor3 = T.Subtle; Features.TextXAlignment = Enum.TextXAlignment.Left
Features.Size = UDim2.new(1,0,0,22); Features.LayoutOrder = 4; Features.ZIndex = 3

local InputSection = Instance.new("Frame", Card)
InputSection.BackgroundColor3 = T.Panel; InputSection.BackgroundTransparency = 0.05; InputSection.Size = UDim2.new(1,0,0,120)
InputSection.LayoutOrder = 2; corner(InputSection,14); stroke(InputSection,T.Stroke,1,0.28)

local inputPad = Instance.new("UIPadding", InputSection)
inputPad.PaddingTop = UDim.new(0, 14); inputPad.PaddingBottom = UDim.new(0, 14)
inputPad.PaddingLeft = UDim.new(0, 18); inputPad.PaddingRight = UDim.new(0, 18)

local inputLayout = Instance.new("UIListLayout", InputSection)
inputLayout.SortOrder = Enum.SortOrder.LayoutOrder; inputLayout.Padding = UDim.new(0, 8)

local KeyLabel = Instance.new("TextLabel", InputSection)
KeyLabel.BackgroundTransparency = 1; KeyLabel.Text = "Master Key"; KeyLabel.Font = Enum.Font.GothamMedium; KeyLabel.TextSize = 15
KeyLabel.TextColor3 = T.Text; KeyLabel.TextXAlignment = Enum.TextXAlignment.Left; KeyLabel.Size = UDim2.new(1,0,0,22)
KeyLabel.LayoutOrder = 1

local KeyBox = Instance.new("TextBox", InputSection)
KeyBox.Size=UDim2.new(1,0,0,40); KeyBox.Text=""; KeyBox.PlaceholderText="Paste key or drop to auto-fill…"
KeyBox.ClearTextOnFocus=false; KeyBox.Font=Enum.Font.Gotham; KeyBox.TextSize=16; KeyBox.TextColor3=T.Text
KeyBox.BackgroundColor3=T.Ink; stroke(KeyBox,T.Stroke,1,0.35); corner(KeyBox,12); KeyBox.LayoutOrder = 2

local KeyNote = Instance.new("TextLabel", InputSection)
KeyNote.BackgroundTransparency = 1; KeyNote.Text = "Keys rotate fast — confirm before the cycle resets. Discord pings fire instantly."
KeyNote.Font = Enum.Font.Gotham; KeyNote.TextSize = 12; KeyNote.TextColor3 = T.Subtle; KeyNote.TextWrapped = true
KeyNote.TextXAlignment = Enum.TextXAlignment.Left; KeyNote.TextYAlignment = Enum.TextYAlignment.Top
KeyNote.Size = UDim2.new(1,0,0,32); KeyNote.LayoutOrder = 3

local Divider = Instance.new("Frame", Card)
Divider.BackgroundColor3 = T.Stroke; Divider.BackgroundTransparency = 0.55; Divider.Size = UDim2.new(1,0,0,1); Divider.LayoutOrder = 3

local Row = Instance.new("Frame", Card)
Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,48); Row.LayoutOrder = 4

local rowLayout = Instance.new("UIListLayout", Row)
rowLayout.FillDirection = Enum.FillDirection.Horizontal; rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center; rowLayout.Padding = UDim.new(0, 14)

local function btn(text, style)
    local b=Instance.new("TextButton", Row); b.Text=text; b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.TextColor3=T.Text
    b.AutoButtonColor=false; b.Size=UDim2.new(0,172,0,42); b.LayoutOrder = style == "primary" and 3 or 1
    local isPrimary = style == "primary"
    local baseColor = isPrimary and T.Accent or T.Ink
    local hoverColor = isPrimary and T.Neon or Color3.fromRGB(58, 52, 88)
    b.BackgroundColor3=baseColor; stroke(b,T.Stroke,1,0.35); corner(b,12)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=hoverColor}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=baseColor}):Play() end)
    return b
end

local GetKey = btn("Get Key Link")
local Discord = btn("Join Discord")
local Confirm = btn("Unlock Panel", "primary")

local Status = Instance.new("TextLabel", Card)
Status.BackgroundColor3 = T.Ink; Status.BackgroundTransparency = 0.6; Status.Text=""; Status.Font=Enum.Font.Gotham
Status.TextSize=13; Status.TextColor3=T.Subtle; Status.Size=UDim2.new(1,0,0,28); Status.LayoutOrder = 5
Status.TextXAlignment=Enum.TextXAlignment.Center; Status.TextYAlignment = Enum.TextYAlignment.Center; corner(Status,12)

local function updateStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or T.Subtle
end

updateStatus("Paste your key to unlock ProfitCruiser.")

-- Success overlay in its own GUI so it survives hiding Gate
local SuccessGui = Instance.new("ScreenGui")
SuccessGui.Name = "PC_Success"; SuccessGui.IgnoreGuiInset = true; SuccessGui.ResetOnSpawn = false
SuccessGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; SuccessGui.DisplayOrder = 110
SuccessGui.Parent = safeParent()

local Success = Instance.new("Frame", SuccessGui)
Success.Visible=false; Success.Size=UDim2.fromScale(1,1); Success.BackgroundTransparency=1
local Center = Instance.new("Frame", Success)
Center.Size=UDim2.fromOffset(420,220); Center.AnchorPoint=Vector2.new(0.5,0.5); Center.Position=UDim2.fromScale(0.5,0.5); Center.BackgroundColor3=T.Card
corner(Center,16); stroke(Center,T.Good,2,0)
local GG = Instance.new("TextLabel", Center)
GG.BackgroundTransparency=1; GG.Size=UDim2.fromScale(1,1); GG.Text="ACCESS GRANTED ✨"; GG.TextColor3=T.Good; GG.Font=Enum.Font.GothamBold; GG.TextSize=28

-- FLAG: only allow reveal of Root after overlay finished
local allowReveal = false

local function fetchRemoteKey()
    local ok,res=pcall(game.HttpGet,game,KEY_CHECK_URL)
    if not ok then return nil,res end
    local cleaned=trim(res); if #cleaned==0 then return nil,"empty" end
    return cleaned
end

GetKey.MouseButton1Click:Connect(function()
    if typeof(setclipboard)=="function" then
        setclipboard(GET_KEY_URL)
        updateStatus("Key link copied to clipboard.", T.Neon)
    else
        updateStatus("Key link: "..GET_KEY_URL)
    end
end)
Discord.MouseButton1Click:Connect(function()
    if typeof(setclipboard)=="function" then setclipboard(DISCORD_URL) end
    updateStatus("Discord invite copied — we'll see you inside!", T.Neon)
    if syn and syn.request then pcall(function() syn.request({Url=DISCORD_URL,Method="GET"}) end) end
end)

-- new showGranted supports callback after hide
local function showGranted(seconds, after)
    Success.Visible = true
    task.delay(seconds or 2.0, function()
        Success.Visible = false
        if after then pcall(after) end
    end)
end

Confirm.MouseButton1Click:Connect(function()
    updateStatus("Checking key…", T.Text)
    local expected,err = fetchRemoteKey()
    if not expected then updateStatus("Fetch failed: "..tostring(err or ""), T.Warn) return end

    if trim(KeyBox.Text) == expected then
        updateStatus("Accepted!", T.Good)

        -- Immediately hide the gate UI so the key box is gone
        Gate.Enabled = false

        -- Ensure Root is hidden while we show the success overlay
        if Root then Root.Visible = false end

        -- Show blur and keep it while overlay is visible
        Blur.Enabled = true
        TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 8}):Play()

        -- Show the granted overlay for 2s, then remove blur and reveal the panel
        showGranted(2.0, function()
            -- animate blur out
            TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 0}):Play()
            task.delay(0.2, function() Blur.Enabled = false end)

            -- mark that reveal is allowed and show Root
            allowReveal = true
            if Root then Root.Visible = true end
        end)

    else
        updateStatus("Wrong key.", T.Warn)
    end
end)

Gate.Enabled=true
Blur.Enabled=true; TweenService:Create(Blur,TweenInfo.new(0.2),{Size=8}):Play()

-- Ensure AA_GUI is disabled when gate is open
Gate:GetPropertyChangedSignal("Enabled"):Connect(function()
    AA_GUI.Enabled = not Gate.Enabled
end)

--==================== MAIN APP ====================--
local App = Instance.new("ScreenGui")
App.Name="AuroraPanel"; App.IgnoreGuiInset=true; App.ResetOnSpawn=false; App.ZIndexBehavior=Enum.ZIndexBehavior.Global
App.DisplayOrder=50; App.Parent=safeParent()

Root = Instance.new("Frame", App)
Root.Size=UDim2.fromOffset(1080, 680); Root.AnchorPoint=Vector2.new(0.5,0.5); Root.Position=UDim2.fromScale(0.5,0.5)
Root.BackgroundColor3=T.Glass; Root.BackgroundTransparency=0.05; Root.BorderSizePixel=0; Root.ClipsDescendants=false
corner(Root,18); stroke(Root,T.Stroke,1.6,0.35); pad(Root,20)
local rootGradient = Instance.new("UIGradient", Root)
rootGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 36, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 14, 30)),
})
rootGradient.Rotation = 90
Root.Visible=false

local PanelScale = Instance.new("UIScale", Root)
PanelScale.Scale = 1

local Top = Instance.new("Frame", Root)
Top.Name = "Header"
Top.Size=UDim2.new(1, 0, 0, 96)
Top.Position=UDim2.new(0,0,0,0)
Top.BackgroundColor3=T.Panel
Top.BackgroundTransparency = 0.05
corner(Top,14); stroke(Top,T.Stroke,1,0.4)
local topGradient = Instance.new("UIGradient", Top)
topGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 42, 82)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 22, 44)),
})
topGradient.Rotation = 18
local topPad = Instance.new("UIPadding", Top)
topPad.PaddingTop = UDim.new(0, 18)
topPad.PaddingBottom = UDim.new(0, 18)
topPad.PaddingLeft = UDim.new(0, 24)
topPad.PaddingRight = UDim.new(0, 24)

local TitleLbl = Instance.new("TextLabel", Top)
TitleLbl.BackgroundTransparency=1
TitleLbl.Position = UDim2.new(0, 0, 0, 0)
TitleLbl.Size=UDim2.new(0.6,0,0,32)
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
TitleLbl.Text="ProfitCruiser // Aurora Nexus"
TitleLbl.Font=Enum.Font.GothamBlack
TitleLbl.TextSize=24
TitleLbl.TextColor3=T.Text
TitleLbl.TextTransparency = 0

local SubTitle = Instance.new("TextLabel", Top)
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 0, 0, 34)
SubTitle.Size = UDim2.new(0.55, 0, 0, 20)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 14
SubTitle.Text = "Elite control surface for the ProfitCruiser suite."
SubTitle.TextColor3 = T.Subtle
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local ProfileChip = Instance.new("Frame", Top)
ProfileChip.Name = "ProfileChip"
ProfileChip.Size = UDim2.new(0, 220, 0, 44)
ProfileChip.AnchorPoint = Vector2.new(1, 0)
ProfileChip.Position = UDim2.new(1, -4, 0, 6)
ProfileChip.BackgroundColor3 = T.Chip
ProfileChip.BackgroundTransparency = 0.05
corner(ProfileChip, 12); stroke(ProfileChip, T.Stroke, 1, 0.45)

local chipGradient = Instance.new("UIGradient", ProfileChip)
chipGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 54, 110)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 30, 60))
})
chipGradient.Rotation = 120

local chipPad = Instance.new("UIPadding", ProfileChip)
chipPad.PaddingLeft = UDim.new(0, 16)
chipPad.PaddingRight = UDim.new(0, 16)
chipPad.PaddingTop = UDim.new(0, 10)
chipPad.PaddingBottom = UDim.new(0, 10)

local chipName = Instance.new("TextLabel", ProfileChip)
chipName.BackgroundTransparency = 1
chipName.Size = UDim2.new(1, 0, 0, 18)
chipName.Position = UDim2.new(0, 0, 0, 0)
chipName.Font = Enum.Font.GothamMedium
chipName.TextSize = 16
chipName.Text = LocalPlayer.DisplayName .. "  •  @" .. LocalPlayer.Name
chipName.TextColor3 = T.Text
chipName.TextXAlignment = Enum.TextXAlignment.Left

local chipNote = Instance.new("TextLabel", ProfileChip)
chipNote.BackgroundTransparency = 1
chipNote.Size = UDim2.new(1, 0, 0, 16)
chipNote.Position = UDim2.new(0, 0, 0, 20)
chipNote.Font = Enum.Font.Gotham
chipNote.TextSize = 13
chipNote.TextColor3 = T.Subtle
chipNote.Text = "Aurora access secured"
chipNote.TextXAlignment = Enum.TextXAlignment.Left

local StatusChip = Instance.new("Frame", Top)
StatusChip.Name = "StatusChip"
StatusChip.Size = UDim2.new(0, 160, 0, 30)
StatusChip.AnchorPoint = Vector2.new(1, 0)
StatusChip.Position = UDim2.new(1, -4, 0, 56)
StatusChip.BackgroundColor3 = T.Chip
StatusChip.BackgroundTransparency = 0.1
corner(StatusChip, 10); stroke(StatusChip, T.Stroke, 1, 0.5)

local statusPad = Instance.new("UIPadding", StatusChip)
statusPad.PaddingLeft = UDim.new(0, 12)
statusPad.PaddingRight = UDim.new(0, 12)
statusPad.PaddingTop = UDim.new(0, 6)
statusPad.PaddingBottom = UDim.new(0, 6)

local statusDot = Instance.new("Frame", StatusChip)
statusDot.Size = UDim2.fromOffset(12, 12)
statusDot.BackgroundColor3 = T.Good
statusDot.Position = UDim2.new(0, 0, 0.5, -6)
corner(statusDot, 6)

local statusText = Instance.new("TextLabel", StatusChip)
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.new(0, 18, 0, 0)
statusText.Size = UDim2.new(1, -18, 1, 0)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 13
statusText.TextColor3 = T.Text
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Text = "Systems Idle"

-- drag
local draggingEnabled = true
local dragging,rel=false,Vector2.zero
Top.InputBegan:Connect(function(i) if draggingEnabled and i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; rel=Root.AbsolutePosition-UserInputService:GetMouseLocation() end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
RunService.RenderStepped:Connect(function()
    if dragging then
        local vp=Camera.ViewportSize; local m=UserInputService:GetMouseLocation()
        local nx=math.clamp(m.X+rel.X,8,vp.X-Root.AbsoluteSize.X-8); local ny=math.clamp(m.Y+rel.Y,8,vp.Y-Root.AbsoluteSize.Y-8)
        Root.Position=UDim2.fromOffset(nx,ny)
    end
end)

local Metrics = Instance.new("Frame", Root)
Metrics.Name = "Metrics"
Metrics.Size = UDim2.new(1, 0, 0, 92)
Metrics.Position = UDim2.new(0, 0, 0, 110)
Metrics.BackgroundColor3 = T.Panel
Metrics.BackgroundTransparency = 0.08
corner(Metrics, 14); stroke(Metrics, T.Stroke, 1, 0.45)

local metricsPad = Instance.new("UIPadding", Metrics)
metricsPad.PaddingLeft = UDim.new(0, 24)
metricsPad.PaddingRight = UDim.new(0, 24)
metricsPad.PaddingTop = UDim.new(0, 18)
metricsPad.PaddingBottom = UDim.new(0, 18)

local metricsGrid = Instance.new("UIGridLayout", Metrics)
metricsGrid.FillDirection = Enum.FillDirection.Horizontal
metricsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
metricsGrid.VerticalAlignment = Enum.VerticalAlignment.Center
metricsGrid.CellPadding = UDim2.new(0, 18, 0, 0)
metricsGrid.CellSize = UDim2.new(0.32, -16, 1, -8)

local function metricCard(label, detail)
    local card = Instance.new("Frame", Metrics)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.08
    corner(card, 12)
    stroke(card, T.Stroke, 1, 0.3)

    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel", card)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 14
    title.TextColor3 = T.Subtle
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = label

    local value = Instance.new("TextLabel", card)
    value.Name = "Value"
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(0, 0, 0, 20)
    value.Size = UDim2.new(1, 0, 0, 26)
    value.Font = Enum.Font.GothamBold
    value.TextSize = 22
    value.TextColor3 = T.Text
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Text = "--"

    local foot = Instance.new("TextLabel", card)
    foot.BackgroundTransparency = 1
    foot.Position = UDim2.new(0, 0, 0, 50)
    foot.Size = UDim2.new(1, 0, 0, 16)
    foot.Font = Enum.Font.Gotham
    foot.TextSize = 12
    foot.TextColor3 = T.Subtle
    foot.TextXAlignment = Enum.TextXAlignment.Left
    foot.Text = detail or ""

    return value
end

local metricPlayersValue = metricCard("Players Tracked", "Live heads-up display coverage")
local metricUptimeValue = metricCard("Session Runtime", "Since Aurora booted this session")
local metricEspValue = metricCard("ESP Channels", "Box / Info / Tracer overlays")

local Body = Instance.new("Frame", Root)
Body.Name = "Body"
Body.Position = UDim2.new(0, 0, 0, 220)
Body.Size = UDim2.new(1, 0, 1, -300)
Body.BackgroundTransparency = 1

local Side = Instance.new("Frame", Body)
Side.Name = "Sidebar"
Side.Size=UDim2.new(0, 264, 1, -12)
Side.Position=UDim2.new(0,0,0,0)
Side.BackgroundColor3=T.Panel
Side.BackgroundTransparency = 0.08
corner(Side,14); stroke(Side,T.Stroke,1,0.45)

local sidePad = Instance.new("UIPadding", Side)
sidePad.PaddingTop = UDim.new(0, 18)
sidePad.PaddingBottom = UDim.new(0, 18)
sidePad.PaddingLeft = UDim.new(0, 18)
sidePad.PaddingRight = UDim.new(0, 18)

local SideList = Instance.new("UIListLayout", Side)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0,16)

local profileCard = Instance.new("Frame", Side)
profileCard.Name = "ProfileCard"
profileCard.Size = UDim2.new(1, 0, 0, 132)
profileCard.BackgroundColor3 = T.Card
profileCard.BackgroundTransparency = 0.05
corner(profileCard, 12); stroke(profileCard, T.Stroke, 1, 0.35)

local profilePad = Instance.new("UIPadding", profileCard)
profilePad.PaddingLeft = UDim.new(0, 16)
profilePad.PaddingRight = UDim.new(0, 16)
profilePad.PaddingTop = UDim.new(0, 16)
profilePad.PaddingBottom = UDim.new(0, 16)

local profileTitle = Instance.new("TextLabel", profileCard)
profileTitle.BackgroundTransparency = 1
profileTitle.Size = UDim2.new(1, 0, 0, 22)
profileTitle.Font = Enum.Font.GothamBold
profileTitle.TextSize = 18
profileTitle.TextColor3 = T.Text
profileTitle.TextXAlignment = Enum.TextXAlignment.Left
profileTitle.Text = "Aurora Session"

local profileInfo = Instance.new("TextLabel", profileCard)
profileInfo.BackgroundTransparency = 1
profileInfo.Size = UDim2.new(1, 0, 0, 18)
profileInfo.Position = UDim2.new(0, 0, 0, 28)
profileInfo.Font = Enum.Font.Gotham
profileInfo.TextSize = 14
profileInfo.TextColor3 = T.Subtle
profileInfo.TextXAlignment = Enum.TextXAlignment.Left
profileInfo.Text = "Operator: " .. LocalPlayer.DisplayName

local sessionLabel = Instance.new("TextLabel", profileCard)
sessionLabel.BackgroundTransparency = 1
sessionLabel.Size = UDim2.new(1, 0, 0, 18)
sessionLabel.Position = UDim2.new(0, 0, 0, 54)
sessionLabel.Font = Enum.Font.Gotham
sessionLabel.TextSize = 13
sessionLabel.TextColor3 = T.Subtle
sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
sessionLabel.Text = "Session uptime: --"

local quickStack = Instance.new("Frame", profileCard)
quickStack.Name = "QuickStatus"
quickStack.BackgroundTransparency = 1
quickStack.Position = UDim2.new(0, 0, 0, 80)
quickStack.Size = UDim2.new(1, 0, 0, 36)

local quickLayout = Instance.new("UIListLayout", quickStack)
quickLayout.FillDirection = Enum.FillDirection.Horizontal
quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
quickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
quickLayout.Padding = UDim.new(0, 8)

local function statusPill(text)
    local pill = Instance.new("Frame", quickStack)
    pill.BackgroundColor3 = T.Ink
    pill.BackgroundTransparency = 0.1
    pill.Size = UDim2.new(0, 74, 0, 24)
    corner(pill, 12)
    stroke(pill, T.Stroke, 1, 0.45)

    local lbl = Instance.new("TextLabel", pill)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = T.Subtle
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Center

    return pill, lbl
end

local aimbotPill, aimbotLabel = statusPill("AIM")
local espPill, espLabel = statusPill("ESP")
local crossPill, crossLabel = statusPill("CROSS")

aimbotPill.LayoutOrder = 1
espPill.LayoutOrder = 2
crossPill.LayoutOrder = 3

local navHeader = Instance.new("TextLabel", Side)
navHeader.BackgroundTransparency = 1
navHeader.Size = UDim2.new(1, 0, 0, 22)
navHeader.Font = Enum.Font.GothamMedium
navHeader.TextSize = 15
navHeader.TextColor3 = T.Subtle
navHeader.Text = "Navigation"
navHeader.TextXAlignment = Enum.TextXAlignment.Left

local Content = Instance.new("Frame", Body)
Content.Name = "Content"
Content.Position=UDim2.new(0, 284, 0, 0)
Content.Size=UDim2.new(1, -284, 1, 0)
Content.BackgroundTransparency=1
Content.ClipsDescendants = true

local Footer = Instance.new("Frame", Root)
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 48)
Footer.Position = UDim2.new(0, 0, 1, -52)
Footer.BackgroundColor3 = T.Panel
Footer.BackgroundTransparency = 0.08
corner(Footer, 12); stroke(Footer, T.Stroke, 1, 0.45)

local footerPad = Instance.new("UIPadding", Footer)
footerPad.PaddingLeft = UDim.new(0, 24)
footerPad.PaddingRight = UDim.new(0, 24)
footerPad.PaddingTop = UDim.new(0, 12)
footerPad.PaddingBottom = UDim.new(0, 12)

local footerText = Instance.new("TextLabel", Footer)
footerText.BackgroundTransparency = 1
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.Font = Enum.Font.Gotham
footerText.TextSize = 13
footerText.TextColor3 = T.Subtle
footerText.TextXAlignment = Enum.TextXAlignment.Left
footerText.Text = "Press K to hide the console • Press P to panic kill"

-- luxe page container with vertical sections
local function newPage(name)
    local p = Instance.new("ScrollingFrame", Content)
    p.Name = name
    p.Size = UDim2.fromScale(1, 1)
    p.Visible = false
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ClipsDescendants = true
    p.Active = true
    p.ScrollingEnabled = true
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = T.Subtle
    p.ScrollBarImageTransparency = 0.2
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.ScrollingDirection = Enum.ScrollingDirection.Y

    local padding = Instance.new("UIPadding", p)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 18)

    local layout = Instance.new("UIListLayout", p)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 18)

    local function syncCanvas()
        local contentY = layout.AbsoluteContentSize.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset
        local viewportY = p.AbsoluteSize.Y
        p.CanvasSize = UDim2.new(0, 0, 0, math.max(contentY, viewportY))

        local maxScroll = math.max(0, p.CanvasSize.Y.Offset - viewportY)
        local current = p.CanvasPosition
        if current.Y > maxScroll or current.Y < 0 then
            p.CanvasPosition = Vector2.new(current.X, math.clamp(current.Y, 0, maxScroll))
        end
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
    p:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncCanvas)
    task.defer(syncCanvas)

    return p
end

local sectionCounter = 0
local function createSection(page, title, subtitle)
    sectionCounter += 1
    local card = Instance.new("Frame", page)
    card.Name = (title:gsub("%W", "")) .. "Section"
    card.LayoutOrder = sectionCounter
    card.BackgroundColor3 = T.Section
    card.BackgroundTransparency = 0.08
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, -8, 0, 0)
    card.ClipsDescendants = false
    corner(card, 16)
    stroke(card, T.Stroke, 1, 0.35)

    local gradient = Instance.new("UIGradient", card)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 38, 68)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 24, 46)),
    })
    gradient.Rotation = 96

    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0, 22)
    pad.PaddingRight = UDim.new(0, 22)
    pad.PaddingTop = UDim.new(0, 20)
    pad.PaddingBottom = UDim.new(0, 20)

    local header = Instance.new("Frame", card)
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, subtitle and 48 or 34)

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = T.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title

    if subtitle and trim(subtitle) ~= "" then
        local subtitleLabel = Instance.new("TextLabel", header)
        subtitleLabel.Name = "Subtitle"
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Position = UDim2.new(0, 0, 0, 26)
        subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
        subtitleLabel.Font = Enum.Font.Gotham
        subtitleLabel.TextSize = 13
        subtitleLabel.TextColor3 = T.Subtle
        subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLabel.Text = subtitle
    end

    local divider = Instance.new("Frame", card)
    divider.Name = "Divider"
    divider.BackgroundColor3 = T.Stroke
    divider.BackgroundTransparency = 0.65
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, subtitle and 58 or 42)

    local body = Instance.new("Frame", card)
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 0, 0, subtitle and 70 or 54)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y

    local bodyLayout = Instance.new("UIListLayout", body)
    bodyLayout.FillDirection = Enum.FillDirection.Vertical
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Padding = UDim.new(0, 12)

    return body
end

local Tabs = {}

local TabIcons = {
    Aimbot = "🎯",
    ESP = "🛰️",
    Visuals = "🌈",
    Misc = "🧰",
    Config = "💾",
}

local function activateTab(targetPage)
    for _,entry in ipairs(Tabs) do
        local isActive = entry.Page == targetPage
        entry.Page.Visible = isActive
        if isActive and entry.Page:IsA("ScrollingFrame") then
            entry.Page.CanvasPosition = Vector2.new(0, 0)
        end
        entry.SetState(isActive, false)
    end
end

local function tabButton(text, page)
    local b=Instance.new("TextButton", Side)
    b.Size=UDim2.new(1,0,0,44)
    b.Text=""
    b.Font=Enum.Font.Gotham
    b.TextSize=15
    b.AutoButtonColor=false
    b.BackgroundColor3=T.Ink
    b.BackgroundTransparency = 0.12
    corner(b,12)
    stroke(b,T.Stroke,1,0.4)

    local indicator=Instance.new("Frame", b)
    indicator.Name = "Indicator"
    indicator.Size=UDim2.new(0,2,1,0)
    indicator.Position=UDim2.new(0,0,0,0)
    indicator.BackgroundColor3=T.Neon
    indicator.BackgroundTransparency = 0.7
    indicator.BorderSizePixel = 0

    local label=Instance.new("TextLabel", b)
    label.BackgroundTransparency=1
    label.Position=UDim2.new(0,20,0,0)
    label.Size=UDim2.new(1,-60,1,0)
    label.Font=Enum.Font.Gotham
    label.TextSize=15
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextColor3=T.Subtle
    label.Text=(TabIcons[text] or "◼️").."  "..text

    local arrow=Instance.new("TextLabel", b)
    arrow.BackgroundTransparency=1
    arrow.AnchorPoint = Vector2.new(1,0.5)
    arrow.Position=UDim2.new(1,-16,0.5,0)
    arrow.Size=UDim2.new(0,20,0,20)
    arrow.Font=Enum.Font.GothamBold
    arrow.TextSize=18
    arrow.TextColor3=T.Off
    arrow.Text="›"

    local function setState(active, hover)
        local bgTarget = active and T.Accent or (hover and Color3.fromRGB(48, 42, 70) or T.Ink)
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = bgTarget, BackgroundTransparency = active and 0 or 0.12}):Play()
        TweenService:Create(label, TweenInfo.new(0.12), {TextColor3 = active and T.Text or T.Subtle}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.12), {Size = active and UDim2.new(0,6,1,0) or UDim2.new(0,2,1,0), BackgroundTransparency = active and 0 or 0.7}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.12), {TextColor3 = active and T.Text or T.Off}):Play()
    end

    local entry = {Button = b, Page = page, SetState = setState}
    table.insert(Tabs, entry)

    b.MouseEnter:Connect(function()
        setState(page.Visible, true)
    end)

    b.MouseLeave:Connect(function()
        setState(page.Visible, false)
    end)

    b.MouseButton1Click:Connect(function()
        activateTab(page)
    end)

    if page.Visible then
        setState(true, false)
    end

    return entry
end

-- floating tooltip bubble for control descriptions
local Tooltip = Instance.new("Frame", App)
Tooltip.Name = "ControlTooltip"
Tooltip.Visible = false
Tooltip.Active = false
Tooltip.ZIndex = 200
Tooltip.BackgroundColor3 = T.Panel
Tooltip.BackgroundTransparency = 0.05
Tooltip.Size = UDim2.fromOffset(220, 64)
Tooltip.ClipsDescendants = false
corner(Tooltip, 10)
stroke(Tooltip, T.Stroke, 1, 0.2)

local tooltipPad = Instance.new("UIPadding", Tooltip)
tooltipPad.PaddingTop = UDim.new(0, 8)
tooltipPad.PaddingBottom = UDim.new(0, 8)
tooltipPad.PaddingLeft = UDim.new(0, 12)
tooltipPad.PaddingRight = UDim.new(0, 12)

local tooltipText = Instance.new("TextLabel", Tooltip)
tooltipText.BackgroundTransparency = 1
tooltipText.Size = UDim2.new(1, 0, 1, 0)
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 13
tooltipText.TextColor3 = T.Text
tooltipText.TextWrapped = true
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.ZIndex = Tooltip.ZIndex + 1

local tooltipOwner = nil
local tooltipBounds = Vector2.new(Tooltip.Size.X.Offset, Tooltip.Size.Y.Offset)

local function updateTooltipPosition(x, y)
    local vp = Camera.ViewportSize
    local width = tooltipBounds.X
    local height = tooltipBounds.Y
    local px = math.clamp(x + 16, 8, vp.X - width - 8)
    local py = math.clamp(y + 20, 8, vp.Y - height - 8)
    Tooltip.Position = UDim2.fromOffset(px, py)
end

local function openTooltip(owner, text)
    tooltipOwner = owner
    tooltipText.Text = text
    local bounds = TextService:GetTextSize(text, tooltipText.TextSize, tooltipText.Font, Vector2.new(280, 800))
    local width = math.clamp(bounds.X + 24, 160, 320)
    local height = math.clamp(bounds.Y + 16, 32, 220)
    tooltipBounds = Vector2.new(width, height)
    Tooltip.Size = UDim2.fromOffset(width, height)
    Tooltip.Visible = true
    local mouse = UserInputService:GetMouseLocation()
    updateTooltipPosition(mouse.X, mouse.Y)
end

local function closeTooltip(owner)
    if tooltipOwner ~= owner then return end
    tooltipOwner = nil
    Tooltip.Visible = false
end

local function trackTooltip(owner, x, y)
    if tooltipOwner ~= owner then return end
    updateTooltipPosition(x, y)
end

Root:GetPropertyChangedSignal("Visible"):Connect(function()
    if not Root.Visible then
        tooltipOwner = nil
        Tooltip.Visible = false
    end
end)

-- Controls factory (compact, reused)
local function rowBase(parent, name, desc)
    local infoText = trim(desc or "")
    local hasDesc = infoText ~= ""
    local r = Instance.new("Frame", parent)
    r.Name = name:gsub("%W", "") .. "Row"
    r.BackgroundColor3 = T.Card
    r.BackgroundTransparency = 0.06
    r.Size = UDim2.new(1, 0, 0, hasDesc and 96 or 76)
    r.AutomaticSize = Enum.AutomaticSize.Y
    r.ClipsDescendants = false
    corner(r, 14)
    stroke(r, T.Stroke, 1, 0.28)

    local accent = Instance.new("Frame", r)
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = T.Accent
    accent.BorderSizePixel = 0

    local accentGradient = Instance.new("UIGradient", accent)
    accentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.Neon),
    })
    accentGradient.Rotation = 90

    local content = Instance.new("Frame", r)
    content.Name = "RowContent"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 14, 0, 12)
    content.Size = UDim2.new(1, -28, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y

    local infoZone = Instance.new("Frame", content)
    infoZone.Name = "InfoZone"
    infoZone.BackgroundTransparency = 1
    infoZone.Size = UDim2.new(1, -260, 0, hasDesc and 56 or 32)
    infoZone.AutomaticSize = Enum.AutomaticSize.Y

    local titleLabel = Instance.new("TextLabel", infoZone)
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, hasDesc and -34 or 0, 0, 26)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = T.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = name

    local descLabel
    if hasDesc then
        descLabel = Instance.new("TextLabel", infoZone)
        descLabel.Name = "Description"
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 0, 0, 30)
        descLabel.Size = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize = Enum.AutomaticSize.Y
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 13
        descLabel.TextWrapped = true
        descLabel.TextColor3 = T.Subtle
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.Text = infoText
    end

    local infoButton
    if hasDesc then
        infoButton = Instance.new("TextButton", infoZone)
        infoButton.Name = "Info"
        infoButton.Size = UDim2.fromOffset(26, 26)
        infoButton.Position = UDim2.new(1, -26, 0, 0)
        infoButton.AnchorPoint = Vector2.new(1, 0)
        infoButton.BackgroundColor3 = T.Ink
        infoButton.AutoButtonColor = false
        infoButton.Text = "?"
        infoButton.Font = Enum.Font.GothamBold
        infoButton.TextSize = 16
        infoButton.TextColor3 = T.Subtle
        corner(infoButton, 13)
        stroke(infoButton, T.Stroke, 1, 0.45)

        local baseColor = infoButton.BackgroundColor3
        local baseText = infoButton.TextColor3

        infoButton.MouseEnter:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = T.Accent,
                TextColor3 = T.Text,
            }):Play()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseLeave:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = baseColor,
                TextColor3 = baseText,
            }):Play()
            closeTooltip(infoButton)
        end)

        infoButton.MouseButton1Click:Connect(function()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseMoved:Connect(function(x, y)
            trackTooltip(infoButton, x, y)
        end)
    end

    local actionZone = Instance.new("Frame", content)
    actionZone.Name = "ActionZone"
    actionZone.AnchorPoint = Vector2.new(1, 0)
    actionZone.Position = UDim2.new(1, 0, 0, 0)
    actionZone.Size = UDim2.new(0, 240, 0, hasDesc and 56 or 40)
    actionZone.BackgroundTransparency = 1
    actionZone.AutomaticSize = Enum.AutomaticSize.Y

    local actionLayout = Instance.new("UIListLayout", actionZone)
    actionLayout.FillDirection = Enum.FillDirection.Vertical
    actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    actionLayout.Padding = UDim.new(0, 8)

    return r, titleLabel, actionZone, descLabel
end

local function mkToggle(parent, name, default, cb, desc)
    local r,_,action=rowBase(parent,name,desc)
    local holder = action or r
    local sw=Instance.new("TextButton", holder)
    sw.AutoButtonColor=false
    sw.BackgroundColor3=T.Ink
    sw.BackgroundTransparency = 0.1
    sw.Text=""
    sw.Size=UDim2.new(0,96,0,34)
    sw.LayoutOrder = 2
    corner(sw,17)
    stroke(sw,T.Stroke,1,0.4)

    local track = Instance.new("Frame", sw)
    track.BackgroundTransparency = 1
    track.Size = UDim2.new(1, -12, 1, -12)
    track.Position = UDim2.new(0, 6, 0, 6)

    local k=Instance.new("Frame", sw)
    k.Size=UDim2.new(0,28,0,28)
    k.Position=UDim2.new(0,3,0.5,-14)
    k.BackgroundColor3=Color3.fromRGB(235,235,245)
    corner(k,14)

    local state = default
    local function set(v)
        state=v
        TweenService:Create(k,TweenInfo.new(0.12),{Position=v and UDim2.new(1,-31,0.5,-14) or UDim2.new(0,3,0.5,-14)}):Play()
        TweenService:Create(sw,TweenInfo.new(0.12),{BackgroundColor3=v and T.Neon or T.Ink, BackgroundTransparency = v and 0 or 0.1}):Play()
        if cb then cb(v,r) end
    end
    sw.MouseButton1Click:Connect(function()
        set(not state)
    end)
    set(state)
    return {Row=r, Set=set, Get=function() return state end}
end

local function mkSlider(parent, name, min, max, default, cb, unit, desc)
    local r,l,action=rowBase(parent,name,desc)
    l.TextYAlignment = Enum.TextYAlignment.Top

    local holder = Instance.new("Frame", action)
    holder.Name = "SliderHolder"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, 44)
    holder.LayoutOrder = 2

    local valueLabel = Instance.new("TextLabel", holder)
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.new(0, 80, 0, 20)
    valueLabel.TextColor3 = T.Subtle
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Top

    local bar=Instance.new("Frame", holder)
    bar.Name = "SliderBar"
    bar.BackgroundColor3=T.Ink
    bar.Position=UDim2.new(0,0,0,26)
    bar.Size=UDim2.new(1,-90,0,8)
    bar.BorderSizePixel = 0
    corner(bar,4)

    local fill=Instance.new("Frame", bar)
    fill.Name = "Fill"
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=T.Neon
    fill.BorderSizePixel = 0
    corner(fill,4)

    local val=math.clamp(default or min, min, max)
    local function render()
        local a=(val-min)/(max-min)
        fill.Size=UDim2.new(a,0,1,0)
        local u = unit and (" "..unit) or ""
        valueLabel.Text = (math.floor(val*100+0.5)/100)..u
    end
    local dragging=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local m=UserInputService:GetMouseLocation().X; local x=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
            local a=math.clamp((m-x)/w,0,1); val=min + a*(max-min); render(); if cb then cb(val,r) end
        end
    end)
    render()
    return {Row=r, Set=function(x) val=math.clamp(x,min,max); render(); if cb then cb(val,r) end end, Get=function() return val end}
end

-- simple button control (used for Kill Menu)
local function mkButton(parent, name, onClick, opts, desc)
    local r,label,action,descLabel = rowBase(parent, name, desc)
    opts = opts or {}
    local danger = opts.danger
    local buttonText = opts.buttonText or (danger and "Kill Menu" or "Run")
    local baseColor = opts.backgroundColor or (danger and Color3.fromRGB(170, 60, 70) or T.Accent)
    local hoverColor = opts.hoverColor or (danger and Color3.fromRGB(200, 75, 85) or Color3.fromRGB(138, 112, 232))
    local textColor = opts.textColor or (danger and Color3.fromRGB(255,235,235) or T.Text)

    local btn = Instance.new("TextButton", action)
    btn.Size = UDim2.new(0, 148, 0, 34)
    btn.LayoutOrder = 2
    btn.Text = buttonText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = textColor
    btn.BackgroundColor3 = baseColor
    btn.AutoButtonColor = false
    corner(btn, 12)
    stroke(btn, (danger and Color3.fromRGB(200,80,90)) or opts.strokeColor or T.Stroke, 1, 0.35)

    if not danger then
        local grad = Instance.new("UIGradient", btn)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, baseColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 120, 255)),
        })
        grad.Rotation = 28
    end

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick(r, label, descLabel, btn) end
    end)
    return {Row=r, Button=btn, Label=label, Description=descLabel}
end

local function mkCycle(parent, name, options, default, cb, desc)
    local r,label,action=rowBase(parent, name, desc)
    local btn = Instance.new("TextButton", action)
    btn.Size = UDim2.new(0, 168, 0, 34)
    btn.LayoutOrder = 2
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = T.Text
    btn.BackgroundColor3 = T.Ink
    btn.AutoButtonColor = false
    btn.Text = ""
    corner(btn, 12)
    stroke(btn, T.Stroke, 1, 0.35)

    local arrow = Instance.new("TextLabel", btn)
    arrow.Name = "Arrow"
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -10, 0.5, 0)
    arrow.Size = UDim2.new(0, 14, 0, 14)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextColor3 = T.Subtle
    arrow.Text = "›"

    local textLabel = Instance.new("TextLabel", btn)
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 14, 0, 0)
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextColor3 = T.Text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = "--"

    local normalized = {}
    for i,opt in ipairs(options) do
        if typeof(opt) == "table" then
            normalized[i] = {
                label = opt.label or opt.text or tostring(opt.value),
                value = opt.value,
            }
        else
            normalized[i] = {label = tostring(opt), value = opt}
        end
    end

    local function findIndexByValue(val)
        for i,opt in ipairs(normalized) do
            if opt.value == val then return i end
        end
        return nil
    end

    local idx = 1
    if default ~= nil then
        if typeof(default) == "number" and normalized[default] then
            idx = default
        else
            idx = findIndexByValue(default) or idx
        end
    end

    local function apply(index)
        if #normalized == 0 then return end
        idx = ((index - 1) % #normalized) + 1
        local opt = normalized[idx]
        textLabel.Text = opt.label
        if cb then cb(opt.value, r) end
    end

    btn.MouseButton1Click:Connect(function()
        apply(idx + 1)
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Accent}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.12), {TextColor3 = T.Text}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Ink}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.12), {TextColor3 = T.Subtle}):Play()
    end)

    apply(idx)

    return {
        Row = r,
        Set = function(value)
            local targetIndex
            if typeof(value) == "number" and normalized[value] then
                targetIndex = value
            else
                targetIndex = findIndexByValue(value)
            end
            if targetIndex then
                apply(targetIndex)
            end
        end,
        Get = function()
            if normalized[idx] then return normalized[idx].value end
        end,
    }
end

--==================== FEATURE STATE ====================--
local AA={
    Enabled=false,
    Strength=0.15,
    PartName="Head",
    ShowFOV=false,
    FOVRadiusPx=180,
    MaxDistance=250,
    MinDistance=0,
    Deadzone=4,
    RequireRMB=false,
    WallCheck=true,
    DynamicPart=false,
    StickyAim=false,
    StickTime=0.35,
    AdaptiveSmoothing=false,
    CloseRangeBoost=0.2,
    Prediction=0,
    TargetSort="Hybrid",
    DistanceWeight=0.02,
    ReactionDelay=0,
    ReactionJitter=0,
    VerticalOffset=0,
}
local ESP={
    Enabled=false,
    EnemiesOnly=false,
    UseDistance=true,
    MaxDistance=1200,
    EnemyColor=Color3.fromRGB(255,70,70),
    FriendColor=Color3.fromRGB(0,255,140),
    NeutralColor=Color3.fromRGB(255,255,0),
    FillTransparency=0.5,
    OutlineTransparency=0,
    ThroughWalls=true,
    ColorIntensity=1,
    BoxESP=false,
    BoxThickness=2,
    NameTag=false,
    HealthTag=false,
    TracerLines=false,
    TracerFrom="Bottom",
    TracerThickness=1.5,
}
local Cross={
    Enabled=false,
    Color=Color3.fromRGB(0,255,200),
    Opacity=0.9,
    Size=8,
    Gap=4,
    Thickness=2,
    CenterDot=false,
    DotSize=2,
    DotOpacity=1,
    UseTeamColor=false,
    Rainbow=false,
    RainbowSpeed=1,
    Pulse=false,
    PulseSpeed=2.5,
}

--==================== RUNTIME / DRAW ====================--
-- FOV ring
local AA_GUI=Instance.new("ScreenGui"); AA_GUI.Name="PC_FOV"; AA_GUI.IgnoreGuiInset=true; AA_GUI.ResetOnSpawn=false; AA_GUI.DisplayOrder=45; AA_GUI.Parent=safeParent()
local FOV=Instance.new("Frame", AA_GUI); FOV.AnchorPoint=Vector2.new(0.5,0.5); FOV.Position=UDim2.fromScale(0.5,0.5); FOV.BackgroundTransparency=1; FOV.Visible=false
local FStroke=Instance.new("UIStroke", FOV); FStroke.Thickness=2; FStroke.Transparency=0.15; FStroke.Color=Color3.fromRGB(0,255,140); corner(FOV, math.huge)

-- Crosshair
local CrossGui=Instance.new("ScreenGui"); CrossGui.Name="PC_Crosshair"; CrossGui.IgnoreGuiInset=true; CrossGui.ResetOnSpawn=false; CrossGui.DisplayOrder=44; CrossGui.Parent=safeParent()
local function crossPart() local f=Instance.new("Frame"); f.BorderSizePixel=0; f.Parent=CrossGui; f.Visible=false; return f end
local chL,chR,chU,chD = crossPart(),crossPart(),crossPart(),crossPart()
local dot = crossPart()
local function updCross()
    if not Cross.Enabled then for _,f in ipairs({chL,chR,chU,chD,dot}) do f.Visible=false end return end
    local vp=Camera.ViewportSize; local cx,cy=vp.X*0.5,vp.Y*0.5; local g,s,t=Cross.Gap,Cross.Size,Cross.Thickness

    local color = Cross.Color
    if Cross.Rainbow then
        local h = (os.clock() * math.max(Cross.RainbowSpeed, 0)) % 1
        color = Color3.fromHSV(h, 0.9, 1)
    elseif Cross.UseTeamColor and LocalPlayer.TeamColor then
        color = LocalPlayer.TeamColor.Color
    end

    local pulseFactor = 1
    if Cross.Pulse then
        local wave = math.sin(os.clock() * math.max(Cross.PulseSpeed, 0.01) * math.pi * 2) * 0.5 + 0.5
        pulseFactor = 0.6 + 0.4 * wave
    end

    local baseOpacity = math.clamp(Cross.Opacity * pulseFactor, 0, 1)
    local dotOpacity = math.clamp(Cross.DotOpacity * pulseFactor, 0, 1)

    local function sty(f,opa)
        f.BackgroundColor3=color
        f.BackgroundTransparency=1-math.clamp(opa or baseOpacity,0,1)
    end
    chU.Size=UDim2.fromOffset(t,s); chU.Position=UDim2.fromOffset(cx - t/2, cy - g - s)
    chD.Size=UDim2.fromOffset(t,s); chD.Position=UDim2.fromOffset(cx - t/2, cy + g)
    chL.Size=UDim2.fromOffset(s,t); chL.Position=UDim2.fromOffset(cx - g - s, cy - t/2)
    chR.Size=UDim2.fromOffset(s,t); chR.Position=UDim2.fromOffset(cx + g, cy - t/2)
    for _,f in ipairs({chL,chR,chU,chD}) do sty(f); f.Visible=true end
    dot.Size=UDim2.fromOffset(Cross.DotSize,Cross.DotSize); dot.Position=UDim2.fromOffset(cx - Cross.DotSize/2, cy - Cross.DotSize/2); sty(dot, dotOpacity); dot.Visible=Cross.CenterDot
end
RunService.RenderStepped:Connect(updCross)

-- Targeting helpers
local function isEnemy(p) if p==LocalPlayer then return false end if LocalPlayer.Team and p.Team then return LocalPlayer.Team~=p.Team end return true end
local function aimPart(c)
    if not c then return nil end
    if AA.DynamicPart then
        for _,name in ipairs({"Head","UpperTorso","HumanoidRootPart","Torso"}) do
            local part=c:FindFirstChild(name)
            if part and part:IsA("BasePart") then return part end
        end
    end
    local p=c:FindFirstChild(AA.PartName)
    if not(p and p:IsA("BasePart")) then p=(c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")) end
    return p
end
local function hasLOS(part,char)
    if not AA.WallCheck then return true end
    local origin=Camera.CFrame.Position; local dir=(part.Position-origin)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={LocalPlayer.Character, char}; rp.IgnoreWater=true
    return workspace:Raycast(origin, dir, rp)==nil
end
local function buildCandidate(pl, my, cx, cy)
    if not isEnemy(pl) then return nil end
    local char = pl.Character
    if not char then return nil end
    local part = aimPart(char)
    if not part then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local maxDist = math.max(0, AA.MaxDistance or 0)
    local minDist = math.clamp(AA.MinDistance or 0, 0, maxDist)
    local dist = (hrp.Position-my.Position).Magnitude
    if dist > maxDist or dist < minDist then return nil end
    local sp,on = Camera:WorldToViewportPoint(part.Position)
    if not on then return nil end
    local dx,dy = sp.X-cx, sp.Y-cy
    local pd = (dx*dx+dy*dy)^0.5
    if pd>AA.FOVRadiusPx then return nil end
    if not hasLOS(part, char) then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return {
        player = pl,
        character = char,
        part = part,
        hrp = hrp,
        humanoid = hum,
        distance = dist,
        pixelDist = pd,
        screen = Vector2.new(sp.X, sp.Y),
        velocity = (hrp.AssemblyLinearVelocity or part.AssemblyLinearVelocity or Vector3.zero),
    }
end
local function scoreCandidate(info)
    local mode = AA.TargetSort or "Hybrid"
    if mode == "Distance" then
        return info.distance
    elseif mode == "Health" then
        local hum = info.humanoid
        if hum then return hum.Health end
        return math.huge
    elseif mode == "Angle" then
        return info.pixelDist
    else
        local w = math.clamp(AA.DistanceWeight or 0, 0, 0.25)
        return info.pixelDist + info.distance * w
    end
end
local function getTarget()
    local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not my then return nil end
    local cx,cy=Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2; local best,bScore
    for _,pl in ipairs(Players:GetPlayers()) do
        local info = buildCandidate(pl, my, cx, cy)
        if info then
            local sc = scoreCandidate(info)
            if not bScore or sc < bScore then
                best,bScore = info,sc
            end
        end
    end
    return best
end

local stickyTarget, stickyTimer = nil, 0
local rng = Random.new()
local lastTargetPart, reactionTimer = nil, 0
local function validateTarget(info)
    return info and info.part and info.part:IsDescendantOf(workspace)
end
local function refreshTarget(info)
    if not validateTarget(info) then return nil end
    local player = info.player
    if not player then return nil end
    local char = player.Character
    if not char then return nil end
    info.character = char
    info.part = info.part and info.part.Parent and info.part or aimPart(char)
    if not info.part then return nil end
    info.hrp = char:FindFirstChild("HumanoidRootPart")
    if not info.hrp then return nil end
    info.humanoid = char:FindFirstChildOfClass("Humanoid")
    local my = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not my then return nil end
    local maxDist = math.max(0, AA.MaxDistance or 0)
    local minDist = math.clamp(AA.MinDistance or 0, 0, maxDist)
    info.distance = (info.hrp.Position - my.Position).Magnitude
    if info.distance > maxDist or info.distance < minDist then return nil end
    local sp,on = Camera:WorldToViewportPoint(info.part.Position)
    info.screen = Vector2.new(sp.X, sp.Y)
    local cx,cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local dx,dy = sp.X-cx, sp.Y-cy
    info.pixelDist = (dx*dx+dy*dy)^0.5
    if AA.WallCheck and not hasLOS(info.part, char) then return nil end
    info.onScreen = on
    info.velocity = (info.hrp.AssemblyLinearVelocity or info.part.AssemblyLinearVelocity or Vector3.zero)
    return info
end

-- Main render
RunService.RenderStepped:Connect(function(dt)
    local fovRadius = math.max(0, AA.FOVRadiusPx or 0)
    FOV.Visible = (AA.Enabled and AA.ShowFOV)
    FOV.Size    = UDim2.fromOffset(fovRadius*2, fovRadius*2)

    local aiming = AA.Enabled and (not AA.RequireRMB or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if aiming then
        local candidate = getTarget()
        if AA.StickyAim then
            if candidate then
                stickyTarget = candidate
                stickyTimer = AA.StickTime
            else
                stickyTimer = math.max(0, stickyTimer - dt)
                if stickyTimer <= 0 then
                    stickyTarget = nil
                end
            end
        else
            stickyTarget = nil
            stickyTimer = 0
        end

        if stickyTarget then
            stickyTarget = refreshTarget(stickyTarget)
            if not stickyTarget then
                stickyTimer = 0
            end
        end

        local targetInfo = stickyTarget or candidate
        if targetInfo and not validateTarget(targetInfo) then
            targetInfo = nil
            if stickyTarget and not validateTarget(stickyTarget) then
                stickyTarget = nil
                stickyTimer = 0
            end
        end

        if targetInfo then
            if targetInfo.part ~= lastTargetPart then
                lastTargetPart = targetInfo.part
                local delay = math.max(0, AA.ReactionDelay or 0)
                local jitter = math.max(0, AA.ReactionJitter or 0)
                if jitter > 0 then
                    delay = delay + rng:NextNumber(0, jitter)
                end
                reactionTimer = delay
            end

            if reactionTimer > 0 then
                reactionTimer = math.max(0, reactionTimer - dt)
            else
                local pos = Camera.CFrame.Position
                local targetPos = targetInfo.part.Position + Vector3.new(0, AA.VerticalOffset or 0, 0)
                if AA.Prediction > 0 then
                    targetPos = targetPos + targetInfo.velocity * math.clamp(AA.Prediction, 0, 1.5)
                end
                local des = CFrame.lookAt(pos, targetPos)
                local alpha = math.clamp(AA.Strength + dt*0.5, 0, 1)
                if AA.AdaptiveSmoothing then
                    local normalized = 1 - math.clamp((targetInfo.distance or 0) / math.max(AA.MaxDistance, 1), 0, 1)
                    alpha = math.clamp(alpha + normalized * AA.CloseRangeBoost, 0, 1)
                end

                local deadzone = math.max(0, AA.Deadzone or 0)
                if deadzone > 0 then
                    local closeness = (targetInfo.pixelDist - deadzone) / math.max(deadzone, 1)
                    if closeness > 0 then
                        local scale = math.clamp(closeness, 0.05, 1)
                        Camera.CFrame = Camera.CFrame:Lerp(des, math.clamp(alpha * scale, 0, 1))
                    end
                else
                    Camera.CFrame = Camera.CFrame:Lerp(des, alpha)
                end
            end
        else
            lastTargetPart = nil
            reactionTimer = 0
        end
    else
        lastTargetPart = nil
        reactionTimer = 0
    end
end)

-- ESP (Highlight)
local function hl(model)
    local h = model:FindFirstChild("_HL_")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "_HL_"
        h.DepthMode = ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.FillTransparency = ESP.FillTransparency
        h.OutlineTransparency = ESP.OutlineTransparency
        h.Parent = model
    end
    -- make sure it adorns the whole character even if parent/rig is unusual
    h.Adornee = model
    return h
end
local function isEnemyESP(p) if not LocalPlayer.Team or not p.Team then return nil end return LocalPlayer.Team~=p.Team end
local function distTo(c) local hrp=c and c:FindFirstChild("HumanoidRootPart"); local my=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and my then return (hrp.Position-my.Position).Magnitude end return math.huge end
local function tintESPColor(color)
    local h,s,v = Color3.toHSV(color)
    local intensity = math.clamp(ESP.ColorIntensity or 1, 0, 2)
    v = math.clamp(v * intensity, 0, 1)
    local satScale = math.clamp(0.55 + 0.45 * intensity, 0, 1.5)
    s = math.clamp(s * satScale, 0, 1)
    return Color3.fromHSV(h, s, v)
end

local drawingAvailable do
    local ok = pcall(function()
        local test = Drawing and Drawing.new
        if not test then error("no drawing") end
        local line = Drawing.new("Line")
        line.Visible = false
        line:Remove()
    end)
    drawingAvailable = ok
end

local function drawingColor(col)
    return Color3.new(col.R, col.G, col.B)
end

local function lerpColor3(a, b, t)
    t = math.clamp(t or 0, 0, 1)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local HEALTH_LOW_COLOR = Color3.fromRGB(235, 85, 85)
local HEALTH_HIGH_COLOR = Color3.fromRGB(80, 210, 140)

local espVisuals = {}

local function ensureVisual(p)
    if not drawingAvailable then return nil end
    local entry = espVisuals[p]
    if entry then return entry end
    entry = {}
    local ok
    ok, entry.Box = pcall(function()
        local sq = Drawing.new("Square")
        sq.Visible = false
        sq.Filled = false
        sq.Thickness = ESP.BoxThickness or 2
        return sq
    end)
    if not ok then entry.Box = nil end
    ok, entry.NameText = pcall(function()
        local txt = Drawing.new("Text")
        txt.Visible = false
        txt.Size = 13
        txt.Center = true
        txt.Outline = true
        txt.Color = Color3.new(1,1,1)
        txt.OutlineColor = Color3.new(0,0,0)
        if Drawing.Fonts and Drawing.Fonts.UI then
            txt.Font = Drawing.Fonts.UI
        end
        return txt
    end)
    if not ok then entry.NameText = nil end
    ok, entry.HealthText = pcall(function()
        local txt = Drawing.new("Text")
        txt.Visible = false
        txt.Size = 12
        txt.Center = true
        txt.Outline = true
        txt.Color = Color3.new(1,1,1)
        txt.OutlineColor = Color3.new(0,0,0)
        if Drawing.Fonts and Drawing.Fonts.UI then
            txt.Font = Drawing.Fonts.UI
        end
        return txt
    end)
    if not ok then entry.HealthText = nil end
    ok, entry.Tracer = pcall(function()
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = ESP.TracerThickness or 1.5
        return line
    end)
    if not ok then entry.Tracer = nil end
    espVisuals[p] = entry
    return entry
end

local function hideVisual(entry)
    if not entry then return end
    if entry.Box then entry.Box.Visible = false end
    if entry.NameText then entry.NameText.Visible = false end
    if entry.HealthText then entry.HealthText.Visible = false end
    if entry.Tracer then entry.Tracer.Visible = false end
end

local function removeVisual(p)
    local entry = espVisuals[p]
    if not entry then return end
    if entry.Box then entry.Box:Remove() end
    if entry.NameText then entry.NameText:Remove() end
    if entry.HealthText then entry.HealthText:Remove() end
    if entry.Tracer then entry.Tracer:Remove() end
    espVisuals[p] = nil
end
local function espTick(p)
    if p==LocalPlayer then return end
    local c=p.Character
    if not c then
        hideVisual(espVisuals[p])
        return
    end
    local h=hl(c); local show=ESP.Enabled
    if show and ESP.EnemiesOnly then local e=isEnemyESP(p); show=(e==true) end
    if show and ESP.UseDistance then show=distTo(c)<=ESP.MaxDistance end
    h.Enabled=show
    if not show then
        hideVisual(espVisuals[p])
        return
    end
    h.DepthMode = ESP.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.FillTransparency = math.clamp(ESP.FillTransparency, 0, 1)
    h.OutlineTransparency = math.clamp(ESP.OutlineTransparency, 0, 1)
    local e=isEnemyESP(p)
    local col
    if e==true then
        col = tintESPColor(ESP.EnemyColor)
        h.FillColor=col; h.OutlineColor=col
    elseif e==false then
        col = tintESPColor(ESP.FriendColor)
        h.FillColor=col; h.OutlineColor=col
    else
        col = tintESPColor(ESP.NeutralColor)
        h.FillColor=col; h.OutlineColor=col
    end

    local needs2D = (ESP.BoxESP or ESP.NameTag or ESP.HealthTag or ESP.TracerLines)
    if not needs2D then
        hideVisual(espVisuals[p])
        return
    end

    local entry = ensureVisual(p)
    if not entry then return end
    hideVisual(entry)

    local tinted = drawingColor(col)
    if entry.Box then
        entry.Box.Thickness = math.clamp(ESP.BoxThickness or 2, 1, 6)
        entry.Box.Color = tinted
    end
    if entry.Tracer then
        entry.Tracer.Thickness = math.clamp(ESP.TracerThickness or 1.5, 0.5, 6)
        entry.Tracer.Color = tinted
    end
    if entry.NameText then
        entry.NameText.Color = tinted
    end

    local success, bboxCFrame, bboxSize = pcall(function()
        return c:GetBoundingBox()
    end)
    if not success then return end

    local half = bboxSize * 0.5
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local onScreen = false
    for x=-1,1,2 do
        for y=-1,1,2 do
            for z=-1,1,2 do
                local worldPos = bboxCFrame * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                local screenPos, visible = Camera:WorldToViewportPoint(worldPos)
                if visible and screenPos.Z > 0 then
                    onScreen = true
                    minX = math.min(minX, screenPos.X)
                    minY = math.min(minY, screenPos.Y)
                    maxX = math.max(maxX, screenPos.X)
                    maxY = math.max(maxY, screenPos.Y)
                end
            end
        end
    end

    if not onScreen then return end

    local width = math.max(0, maxX - minX)
    local height = math.max(0, maxY - minY)
    if width < 2 or height < 2 then return end

    local humanoid = c:FindFirstChildWhichIsA("Humanoid")
    local hp = humanoid and humanoid.Health or 0
    local maxHp = humanoid and humanoid.MaxHealth or 100
    local hpPercent = maxHp > 0 and math.clamp(math.floor((hp / maxHp) * 100 + 0.5), 0, 999) or 0
    local hpRounded = math.clamp(math.floor(hp + 0.5), 0, 9999)
    local nameTag = trim((p.DisplayName and trim(p.DisplayName) ~= "") and p.DisplayName or p.Name)
    local centerX = minX + width * 0.5

    if entry.Box and ESP.BoxESP then
        entry.Box.Position = Vector2.new(minX, minY)
        entry.Box.Size = Vector2.new(width, height)
        entry.Box.Visible = true
    end

    if entry.NameText and ESP.NameTag then
        entry.NameText.Text = nameTag
        entry.NameText.Position = Vector2.new(centerX, minY - 18)
        entry.NameText.Visible = true
    end

    if entry.HealthText and ESP.HealthTag then
        local healthColor = lerpColor3(HEALTH_LOW_COLOR, HEALTH_HIGH_COLOR, (maxHp > 0) and math.clamp(hp / maxHp, 0, 1) or 0)
        entry.HealthText.Color = drawingColor(healthColor)
        entry.HealthText.Text = string.format("%d HP · %d%%", hpRounded, hpPercent)
        local baseY = ESP.NameTag and entry.NameText and entry.NameText.Visible and (minY - 6) or (minY - 14)
        entry.HealthText.Position = Vector2.new(centerX, baseY)
        entry.HealthText.Visible = true
    end

    if entry.Tracer and ESP.TracerLines then
        local viewport = Camera.ViewportSize
        local anchor
        if tostring(ESP.TracerFrom) == "Crosshair" then
            anchor = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
        else
            anchor = Vector2.new(viewport.X * 0.5, viewport.Y)
        end
        entry.Tracer.From = anchor
        entry.Tracer.To = Vector2.new(centerX, maxY)
        entry.Tracer.Visible = true
    end
end
RunService.RenderStepped:Connect(function()
    for _,pl in ipairs(Players:GetPlayers()) do
        espTick(pl)
    end
end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.2)
        espTick(p)
    end)
    p.CharacterRemoving:Connect(function()
        hideVisual(espVisuals[p])
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    removeVisual(p)
end)
for _,pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        pl.CharacterRemoving:Connect(function()
            hideVisual(espVisuals[pl])
        end)
    end
end

--==================== PAGES & CONTROLS ====================--
local AimbotP = newPage("Aimbot")
local ESPP    = newPage("ESP")
local VisualP = newPage("Visuals")
local MiscP   = newPage("Misc")
local ConfP   = newPage("Config")

local ESPColorPresets = {
    {label = "Crimson Pulse", value = Color3.fromRGB(255, 70, 70)},
    {label = "Solar Gold", value = Color3.fromRGB(255, 255, 0)},
    {label = "Toxic Lime", value = Color3.fromRGB(0, 255, 140)},
    {label = "Electric Azure", value = Color3.fromRGB(90, 190, 255)},
    {label = "Aurora Cyan", value = Color3.fromRGB(70, 255, 255)},
    {label = "Royal Violet", value = Color3.fromRGB(180, 110, 255)},
    {label = "Sunburst", value = Color3.fromRGB(255, 170, 60)},
    {label = "Frostbite", value = Color3.fromRGB(210, 235, 255)},
}

AimbotP.Visible = true

tabButton("Aimbot", AimbotP)
tabButton("ESP", ESPP)
tabButton("Visuals", VisualP)
tabButton("Misc", MiscP)
tabButton("Config", ConfP)
activateTab(AimbotP)

-- Aimbot sections
local AimCore = createSection(AimbotP, "Core Systems", "Primary toggles for the Aurora aim assist.")
mkToggle(AimCore, "Enable Aimbot", AA.Enabled, function(v) AA.Enabled = v end, "Turns the aimbot feature on or off.")
mkToggle(AimCore, "Require Right Mouse (hold)", AA.RequireRMB, function(v) AA.RequireRMB = v end, "Only activates the aimbot while the right mouse button is held down.")
mkToggle(AimCore, "Wall Check (line of sight)", AA.WallCheck, function(v) AA.WallCheck = v end, "Skips targets that are blocked by walls or other geometry.")
mkToggle(AimCore, "Show FOV", AA.ShowFOV, function(v) AA.ShowFOV = v end, "Displays the aiming field-of-view circle on your screen.")

local AimRange = createSection(AimbotP, "Field Controls", "Shape the capture cone and reach limits.")
mkSlider(AimRange, "FOV Radius", 40, 500, AA.FOVRadiusPx, function(x) AA.FOVRadiusPx = math.floor(x) end, "px", "Sets the radius of the aim assist field-of-view circle in pixels.")
mkSlider(AimRange, "Deadzone Padding", 0, 20, AA.Deadzone, function(x) AA.Deadzone = x end, "px", "Defines an inner deadzone where the aimbot will not move the camera.")
mkSlider(AimRange, "Strength (lower=stronger)", 0.05, 0.40, AA.Strength, function(x) AA.Strength = x end, nil, "Controls how strongly the camera lerps toward the target (lower means snappier).")
mkSlider(AimRange, "Max Distance", 50, 1000, AA.MaxDistance, function(x) AA.MaxDistance = math.floor(x) end, "studs", "Limits aiming to targets within this distance.")
mkSlider(AimRange, "Min Distance Gate", 0, 250, AA.MinDistance, function(x) AA.MinDistance = math.floor(x) end, "studs", "Ignores targets that are closer than this distance.")

local AimTarget = createSection(AimbotP, "Target Logic", "Choose who Aurora prefers when multiple players are visible.")
local targetPriority = mkCycle(AimTarget, "Target Priority", {
    {label = "Hybrid (angle+distance)", value = "Hybrid"},
    {label = "Closest Angle", value = "Angle"},
    {label = "Closest Distance", value = "Distance"},
    {label = "Lowest Health", value = "Health"},
}, AA.TargetSort, function(val) AA.TargetSort = val end, "Chooses how potential targets are ranked before aiming.")
local distanceWeight = mkSlider(AimTarget, "Hybrid Distance Weight", 0, 0.08, AA.DistanceWeight, function(x) AA.DistanceWeight = x end, nil, "Adjusts how much distance influences the hybrid priority mode.")
local dynamicPartToggle
dynamicPartToggle = mkToggle(AimTarget, "Auto Bone Selection", AA.DynamicPart, function(v) AA.DynamicPart = v end, "Automatically chooses which body part to aim at based on target movement.")
local partCycle = mkCycle(AimTarget, "Manual Target Bone", {"Head", "UpperTorso", "HumanoidRootPart"}, AA.PartName, function(val) AA.PartName = val end, "Selects the specific body part to aim at when auto selection is disabled.")

local AimBehavior = createSection(AimbotP, "Humanization & Advanced", "Blend delays and smoothing for a natural feel.")
local stickyToggle = mkToggle(AimBehavior, "Sticky Aim (keep last target)", AA.StickyAim, function(v)
    AA.StickyAim = v
    if not v then
        stickyTarget = nil
        stickyTimer = 0
    end
end, "Keeps following the most recent target for a short period even if they leave the FOV.")
local stickyDuration = mkSlider(AimBehavior, "Sticky Duration", 0.1, 1.5, AA.StickTime, function(x)
    AA.StickTime = x
    stickyTimer = math.min(stickyTimer, AA.StickTime)
end, "s", "How long sticky aim should hold onto the previous target.")
local reactionDelay = mkSlider(AimBehavior, "Reaction Delay", 0, 0.35, AA.ReactionDelay, function(x) AA.ReactionDelay = x end, "s", "Adds a delay before the aimbot begins to adjust toward a target.")
local reactionJitter = mkSlider(AimBehavior, "Reaction Jitter", 0, 0.3, AA.ReactionJitter, function(x) AA.ReactionJitter = x end, "s", "Adds random variation to the reaction delay for a more human feel.")
local adaptiveToggle = mkToggle(AimBehavior, "Adaptive Smoothing Boost", AA.AdaptiveSmoothing, function(v) AA.AdaptiveSmoothing = v end, "Boosts smoothing strength as enemies move closer to you.")
local closeBoost = mkSlider(AimBehavior, "Close-range Boost", 0, 0.6, AA.CloseRangeBoost, function(x) AA.CloseRangeBoost = x end, nil, "Amount of extra smoothing applied when targets are nearby.")
local predictionSlider = mkSlider(AimBehavior, "Lead Prediction", 0, 0.75, AA.Prediction, function(x) AA.Prediction = x end, "s", "Predicts where moving targets will be after this many seconds.")
local heightOffset = mkSlider(AimBehavior, "Aim Height Offset", -2, 2, AA.VerticalOffset, function(x) AA.VerticalOffset = x end, "studs", "Shifts the aim point up or down relative to the target.")

setInteractable(stickyDuration.Row, AA.StickyAim)
setInteractable(closeBoost.Row, AA.AdaptiveSmoothing)
if partCycle and partCycle.Row then setInteractable(partCycle.Row, not AA.DynamicPart) end
if reactionJitter and reactionJitter.Row then setInteractable(reactionJitter.Row, (AA.ReactionDelay or 0) > 0) end
if distanceWeight and distanceWeight.Row then setInteractable(distanceWeight.Row, (AA.TargetSort or "Hybrid") == "Hybrid") end

RunService.RenderStepped:Connect(function()
    setInteractable(stickyDuration.Row, AA.StickyAim)
    setInteractable(closeBoost.Row, AA.AdaptiveSmoothing)
    if partCycle and partCycle.Row then setInteractable(partCycle.Row, not AA.DynamicPart) end
    if reactionJitter and reactionJitter.Row then setInteractable(reactionJitter.Row, (AA.ReactionDelay or 0) > 0) end
    if distanceWeight and distanceWeight.Row then setInteractable(distanceWeight.Row, (AA.TargetSort or "Hybrid") == "Hybrid") end
end)

-- ESP sections
local EspCore = createSection(ESPP, "Visibility Channels", "Control who gets highlighted and when.")
mkToggle(EspCore, "Enable ESP", ESP.Enabled, function(v) ESP.Enabled = v end, "Turns highlight ESP visuals on or off.")
mkToggle(EspCore, "Enemies Only", ESP.EnemiesOnly, function(v) ESP.EnemiesOnly = v end, "Only shows ESP highlights on enemy players.")
mkToggle(EspCore, "Use Distance Limit", ESP.UseDistance, function(v) ESP.UseDistance = v end, "Restricts ESP to players within the max distance slider.")
mkSlider(EspCore, "Max Distance", 50, 2000, ESP.MaxDistance, function(x) ESP.MaxDistance = math.floor(x) end, "studs", "Sets the farthest distance that ESP highlights will appear.")
mkToggle(EspCore, "Render Through Walls", ESP.ThroughWalls, function(v) ESP.ThroughWalls = v end, "Forces highlight outlines to show even through walls.")

local EspStyling = createSection(ESPP, "Visual Styling", "Tune the brightness, transparency, and colors for each team state.")
mkSlider(EspStyling, "Fill Transparency", 0, 1, ESP.FillTransparency, function(x) ESP.FillTransparency = x end, nil, "Adjusts how solid the ESP highlight fill appears.")
mkSlider(EspStyling, "Outline Transparency", 0, 1, ESP.OutlineTransparency, function(x) ESP.OutlineTransparency = x end, nil, "Adjusts how visible the ESP outline is.")
mkSlider(EspStyling, "Color Intensity", 0.4, 1.6, ESP.ColorIntensity, function(x) ESP.ColorIntensity = x end, nil, "Boosts or softens highlight brightness for every player type.")
mkCycle(EspStyling, "Enemy Highlight", ESPColorPresets, ESP.EnemyColor, function(col) ESP.EnemyColor = col end, "Choose the glow color used when enemies are highlighted.")
mkCycle(EspStyling, "Friendly Highlight", ESPColorPresets, ESP.FriendColor, function(col) ESP.FriendColor = col end, "Select the highlight tint for teammates and allies.")
mkCycle(EspStyling, "Neutral Highlight", ESPColorPresets, ESP.NeutralColor, function(col) ESP.NeutralColor = col end, "Pick the tone shown for players with no team alignment.")

local EspExtras = createSection(ESPP, "Overlay Extras", "Additional drawing layers for extra battlefield context.")
local boxToggle = mkToggle(EspExtras, "Box ESP (2D)", ESP.BoxESP, function(v) ESP.BoxESP = v end, "Draws flat boxes around visible players using the ESP colors.")
local boxThickness = mkSlider(EspExtras, "Box Line Thickness", 1, 6, ESP.BoxThickness, function(x) ESP.BoxThickness = math.floor(x + 0.5) end, "px", "Controls how thick the 2D box outline appears.")
local nameToggle = mkToggle(EspExtras, "Player Name Tag", ESP.NameTag, function(v) ESP.NameTag = v end, "Shows a compact name label above each visible player.")
local healthToggle = mkToggle(EspExtras, "Health Tag", ESP.HealthTag, function(v) ESP.HealthTag = v end, "Adds a slimmer health readout with current HP and percent.")
local tracerToggle = mkToggle(EspExtras, "Tracer Lines", ESP.TracerLines, function(v) ESP.TracerLines = v end, "Draws a line from your screen to each highlighted target.")
local tracerThickness = mkSlider(EspExtras, "Tracer Thickness", 0.5, 4, ESP.TracerThickness, function(x) ESP.TracerThickness = x end, "px", "Adjusts the width of each tracer line.")
local tracerAnchor = mkCycle(EspExtras, "Tracer Anchor", {
    {label = "Screen Bottom", value = "Bottom"},
    {label = "Crosshair", value = "Crosshair"},
}, ESP.TracerFrom or "Bottom", function(val) ESP.TracerFrom = val end, "Choose where tracers originate on your screen.")

if not drawingAvailable then
    for _,control in ipairs({boxToggle, boxThickness, nameToggle, healthToggle, tracerToggle, tracerThickness, tracerAnchor}) do
        if control and control.Row then
            setInteractable(control.Row, false)
        end
    end
end

-- Visuals sections
local VisualCore = createSection(VisualP, "Crosshair Core", "Enable the overlay crosshair and adjust its frame.")
local crossT = mkToggle(VisualCore, "Crosshair", Cross.Enabled, function(v) Cross.Enabled = v; updCross() end, "Shows or hides the custom crosshair overlay.")
mkSlider(VisualCore, "Opacity", 0.1, 1, Cross.Opacity, function(x) Cross.Opacity = x; updCross() end, nil, "Sets how transparent the crosshair appears.")
mkSlider(VisualCore, "Size", 4, 24, Cross.Size, function(x) Cross.Size = math.floor(x); updCross() end, nil, "Controls the overall length of the crosshair lines.")
mkSlider(VisualCore, "Gap", 2, 20, Cross.Gap, function(x) Cross.Gap = math.floor(x); updCross() end, nil, "Adjusts the gap between the crosshair arms and the center.")
mkSlider(VisualCore, "Thickness", 1, 6, Cross.Thickness, function(x) Cross.Thickness = math.floor(x); updCross() end, nil, "Changes how thick each crosshair arm is.")

local VisualDot = createSection(VisualP, "Center Dot", "Dial in the optional center reference point.")
local dotT = mkToggle(VisualDot, "Center Dot", Cross.CenterDot, function(v) Cross.CenterDot = v; updCross() end, "Adds a dot to the middle of the crosshair.")
local dotS = mkSlider(VisualDot, "Dot Size", 1, 6, Cross.DotSize, function(x) Cross.DotSize = math.floor(x); updCross() end, nil, "Sets the size of the center dot.")
local dotO = mkSlider(VisualDot, "Dot Opacity", 0.1, 1, Cross.DotOpacity, function(x) Cross.DotOpacity = x; updCross() end, nil, "Controls the transparency of the center dot.")

local VisualColor = createSection(VisualP, "Color & Motion", "Animated effects and palette controls.")
local teamColorToggle
local rainbowToggle
teamColorToggle = mkToggle(VisualColor, "Use Team Color", Cross.UseTeamColor, function(v)
    Cross.UseTeamColor = v
    if v and rainbowToggle then
        Cross.Rainbow = false
        rainbowToggle.Set(false)
    end
    updCross()
end, "Applies your current team color to the crosshair.")
rainbowToggle = mkToggle(VisualColor, "Rainbow Cycle", Cross.Rainbow, function(v)
    Cross.Rainbow = v
    if v and teamColorToggle then
        Cross.UseTeamColor = false
        teamColorToggle.Set(false)
    end
    updCross()
end, "Cycles crosshair colors through a rainbow gradient.")
local rainbowSpeed = mkSlider(VisualColor, "Rainbow Speed", 0.2, 3, Cross.RainbowSpeed, function(x) Cross.RainbowSpeed = x; updCross() end, nil, "Controls how quickly the rainbow effect animates.")
local pulseToggle = mkToggle(VisualColor, "Pulse Opacity", Cross.Pulse, function(v) Cross.Pulse = v; updCross() end, "Makes the crosshair fade in and out repeatedly.")
local pulseSpeed = mkSlider(VisualColor, "Pulse Speed", 0.5, 5, Cross.PulseSpeed, function(x) Cross.PulseSpeed = x; updCross() end, nil, "Sets the speed of the crosshair opacity pulse.")

RunService.RenderStepped:Connect(function()
    local on = Cross.CenterDot
    setInteractable(dotS.Row, on)
    setInteractable(dotO.Row, on)
    if rainbowSpeed then setInteractable(rainbowSpeed.Row, Cross.Rainbow) end
    if pulseSpeed then setInteractable(pulseSpeed.Row, Cross.Pulse) end
    if drawingAvailable then
        if boxThickness then setInteractable(boxThickness.Row, ESP.BoxESP) end
        if tracerThickness then setInteractable(tracerThickness.Row, ESP.TracerLines) end
        if tracerAnchor and tracerAnchor.Row then setInteractable(tracerAnchor.Row, ESP.TracerLines) end
    end
end)

-- Misc sections
local MiscInterface = createSection(MiscP, "Interface", "Keep the ProfitCruiser bridge where you need it.")
mkToggle(MiscInterface, "Press K to toggle UI", true, function() end, "Reminder that you can press K to hide or show the panel.")
local dragToggle = mkToggle(MiscInterface, "Allow Dragging", true, function(v)
    draggingEnabled = v
    if not v then dragging = false end
end, "Enables dragging the window around the screen.")
mkButton(MiscInterface, "Center Panel", function()
    Root.Position = UDim2.fromScale(0.5, 0.5)
    dragging = false
end, {buttonText = "Center"}, "Recenters the panel on your screen.")
mkSlider(MiscInterface, "UI Scale", 0.85, 1.25, PanelScale.Scale, function(x) PanelScale.Scale = x end, "x", "Changes the overall size of the menu UI.")

local MiscCommunity = createSection(MiscP, "Community & Links", "Stay synced with key rotations and patch intel.")
local function discordFeedback(descLabel, success)
    if success then
        descLabel.Text = "Discord invite copied — see you on the bridge."
        descLabel.TextColor3 = T.Good
    else
        descLabel.Text = "Kunne ikke kopiere automatisk — bruk lenken: " .. DISCORD_URL
        descLabel.TextColor3 = T.Warn
    end
    TweenService:Create(descLabel, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
    task.delay(1.8, function()
        descLabel.Text = "Instant alerts for fresh keys and status updates."
        descLabel.TextColor3 = T.Subtle
    end)
end

mkButton(MiscCommunity, "Copy Discord Invite", function(row, label, descLabel)
    local ok = false
    if setclipboard then
        ok = pcall(function()
            setclipboard(DISCORD_URL)
        end) == true
    end
    if not ok then
        ok = pcall(function()
            return syn and syn.request and syn.request({Url = DISCORD_URL, Method = "GET"})
        end) == true
    end
    if descLabel then
        discordFeedback(descLabel, ok)
    end
end, {buttonText = "Copy Invite"}, "Instant alerts for fresh keys and status updates.")

local MiscUtilities = createSection(MiscP, "Utilities", "Panic controls for emergency disengage.")
mkButton(MiscUtilities, "Kill Menu (remove UI)", function()
    killMenu()
end, {danger = true, buttonText = "Kill Menu"}, "Completely closes the UI and disables every feature until re-executed.")

-- Config sections
local ConfigSection = createSection(ConfP, "Profiles", "Store and restore your favourite ProfitCruiser loadouts.")
mkButton(ConfigSection, "Save Default Profile", function(row, label, descLabel)
    local ok, err = save("Default")
    if descLabel then
        if ok then
            descLabel.Text = "Saved Default ✅"
            descLabel.TextColor3 = T.Good
        else
            descLabel.Text = "Save failed: " .. tostring(err)
            descLabel.TextColor3 = T.Warn
        end
        task.delay(1.6, function()
            descLabel.Text = "Write the current configuration into the Default slot."
            descLabel.TextColor3 = T.Subtle
        end)
    end
end, {buttonText = "Save"}, "Write the current configuration into the Default slot.")

mkButton(ConfigSection, "Load Default Profile", function(row, label, descLabel)
    local ok, err = load("Default")
    if descLabel then
        if ok then
            descLabel.Text = "Loaded Default ✅"
            descLabel.TextColor3 = T.Good
        else
            descLabel.Text = "Load failed: " .. tostring(err)
            descLabel.TextColor3 = T.Warn
        end
        task.delay(1.6, function()
            descLabel.Text = "Pull the Default slot back into every feature."
            descLabel.TextColor3 = T.Subtle
        end)
    end
end, {buttonText = "Load"}, "Pull the Default slot back into every feature.")

local sessionStart = os.time()
local function formatDuration(seconds)
    local s = math.max(0, math.floor(seconds))
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, sec)
    else
        return string.format("%02d:%02d", m, sec)
    end
end

RunService.Heartbeat:Connect(function()
    local count = 0
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then count += 1 end
    end
    metricPlayersValue.Text = tostring(count)

    local uptime = os.time() - sessionStart
    local formatted = formatDuration(uptime)
    metricUptimeValue.Text = formatted
    sessionLabel.Text = "Session uptime: " .. formatted

    local activeLayers = 0
    if ESP.Enabled then activeLayers += 1 end
    if ESP.BoxESP then activeLayers += 1 end
    if ESP.NameTag then activeLayers += 1 end
    if ESP.HealthTag then activeLayers += 1 end
    if ESP.TracerLines then activeLayers += 1 end
    metricEspValue.Text = string.format("%d active", activeLayers)

    local activeTags = {}
    if AA.Enabled then table.insert(activeTags, "Aim") end
    if ESP.Enabled then table.insert(activeTags, "ESP") end
    if Cross.Enabled then table.insert(activeTags, "Cross") end
    if #activeTags == 0 then
        statusText.Text = "Systems Idle"
        statusDot.BackgroundColor3 = T.Warn
    else
        statusText.Text = table.concat(activeTags, " • ") .. " online"
        statusDot.BackgroundColor3 = T.Good
    end

    local function updatePill(pill, label, active, base)
        pill.BackgroundColor3 = active and Color3.fromRGB(70, 54, 110) or T.Ink
        label.TextColor3 = active and T.Text or T.Off
        label.Text = active and (base .. " ON") or (base .. " OFF")
    end

    updatePill(aimbotPill, aimbotLabel, AA.Enabled, "AIM")
    updatePill(espPill, espLabel, ESP.Enabled, "ESP")
    updatePill(crossPill, crossLabel, Cross.Enabled, "CROSS")
end)

local function killMenu()
    -- hide all UIs
    if Root then Root.Visible = false end
    if Gate then Gate.Enabled = false end
    if SuccessGui then SuccessGui.Enabled = false end
    if AA_GUI then AA_GUI.Enabled = false end
    if CrossGui then CrossGui.Enabled = false end
    -- remove blur
    TweenService:Create(Blur, TweenInfo.new(0.15), {Size = 0}):Play()
    Blur.Enabled = false
    -- disable features so runtime loops render nothing
    AA.Enabled=false; ESP.Enabled=false; Cross.Enabled=false; updCross()
    stickyTarget=nil; stickyTimer=0
    -- clean existing highlights
    for _,pl in ipairs(Players:GetPlayers()) do
        local ch = pl.Character
        if ch then local h = ch:FindFirstChild("_HL_"); if h then pcall(function() h:Destroy() end) end end
    end
end

-- panic key (P) also kills the menu
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.K then Root.Visible = not Root.Visible end
    if i.KeyCode==Enum.KeyCode.P then killMenu() end
end)

-- Config / profiles
local save
local load

local BASE="ProfitCruiser"; local PROF=BASE.."/Profiles"; local MODE="memory"; local MEM=rawget(_G,"PC_ProfileStore") or {}; _G.PC_ProfileStore=MEM
local function ensure() if makefolder then local ok1=true if not (isfolder and isfolder(BASE)) then ok1=pcall(function() makefolder(BASE) end) end local ok2=true if not (isfolder and isfolder(PROF)) then ok2=pcall(function() makefolder(PROF) end) end return ok1 and ok2 end return false end
if ensure() and writefile and readfile then MODE="filesystem" end
local function deep(dst,src) for k,v in pairs(src) do if typeof(v)=="table" and typeof(dst[k])=="table" then deep(dst[k],v) else dst[k]=v end end end
local function gather() return {AA=AA, ESP=ESP, Cross=Cross} end
local function apply(s)
    if not s then return end
    deep(AA,s.AA or {})
    deep(ESP,s.ESP or {})
    deep(Cross,s.Cross or {})
    updCross()
end
save = function(name) local ok,data=pcall(function() return HttpService:JSONEncode(gather()) end); if not ok then return false,"encode" end if MODE=="filesystem" then local p=PROF.."/"..name..".json"; local s,err=pcall(function() writefile(p,data) end); return s,(s and nil or tostring(err)) else MEM[name]=data; return true end end
load = function(name) if MODE=="filesystem" then local p=PROF.."/"..name..".json"; if not (isfile and isfile(p)) then return false,"missing" end local ok,raw=pcall(function() return readfile(p) end); if not ok then return false,"read" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true else local raw=MEM[name]; if not raw then return false,"missing" end local ok2,tbl=pcall(function() return HttpService:JSONDecode(raw) end); if not ok2 then return false,"decode" end apply(tbl); return true end end

-- Show panel when gate closes (only if allowed by flow)
Gate:GetPropertyChangedSignal("Enabled"):Connect(function()
    local on = Gate.Enabled
    TweenService:Create(Blur, TweenInfo.new(0.2), {Size = on and 8 or 0}):Play()
    Blur.Enabled = on or (not on and not allowReveal)
    -- Only reveal Root if gate closed AND the reveal flag was set (set after overlay finishes)
    if (not on) and allowReveal and Root then
        Root.Visible = true
    end
end)
