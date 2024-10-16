-- // Services \\ --
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- // UI Setup \\ --
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({ 
    Title = ' $ $ $ $ $ $$ $$$ $$ $  [warp.space] $ $$ $$ [v.1] $ $ $ $ $$$', 
    Center = true, 
    AutoShow = true 
})

local Tabs = { 
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'), 
    ['UI Settings'] = Window:AddTab('UI Settings') 
}

local GunModsGroupBox = Tabs.Main:AddLeftGroupbox('Gun Mods')
local MovementGroupBox = Tabs.Main:AddRightGroupbox('Movement')
local ExploitsGroupBox = Tabs.Main:AddLeftGroupbox('Exploits')
local HitboxExpanderGroupBox = Tabs.Main:AddRightGroupbox('Hitbox Expander')
local SilentAimGroupBox = Tabs.Main:AddLeftGroupbox('Silent Aim')
local ItemESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Item ESP')
local VehicleESPGroupBox = Tabs.Visuals:AddRightGroupbox('Vehicle ESP')
local PlayerESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Player ESP')
local WorldMiscGroupBox = Tabs.Visuals:AddRightGroupbox('World Misc')
local ZombieESPGroupBox = Tabs.Visuals:AddRightGroupbox('Zombie ESP')
local EventESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Event ESP')
local CorpseESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Corpse ESP')
local MapESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Map ESP')
local ReloadBarGroupBox = Tabs.Visuals:AddRightGroupbox('Reload Bar')
local AimedFOVGroupBox = Tabs.Visuals:AddLeftGroupbox('Aimed FOV')
local SelfChamsGroupBox = Tabs.Visuals:AddRightGroupbox('Self Chams')

-- // nigga shit \\ --
local ItemESPEnabled, VehicleESPEnabled, PlayerESPEnabled, ZombieESPEnabled, EventESPEnabled, CorpseESPEnabled = false, false, false, false, false, false
local ItemESPColor, VehicleESPColor, PlayerESPColor, ZombieESPColor, EventESPColor, CorpseESPColor = Color3.new(1, 1, 1), Color3.new(1, 1, 1), Color3.new(1, 1, 1), Color3.new(1, 1, 1), Color3.new(1, 1, 1), Color3.new(1, 0, 0)
local ItemESPSize, VehicleESPSize, PlayerESPSize, ZombieESPSize, EventESPSize, CorpseESPTextSize = 20, 20, 20, 20, 20, 20
local VehicleRenderDistance, PlayerRenderDistance, ZombieRenderDistance, EventRenderDistance, CorpseRenderDistance = 1000, 1000, 1000, 1000, 1000
local JumpHackEnabled, TpWalkingEnabled, InfiniteJumpEnabled, SpiderClimbEnabled = false, false, false, false
local JumpHeight, TpWalkSpeed, SpiderClimbSpeed = 50, 10, 1
local jumpHackConnection

local HighlightESPEnabled, ChamsWallcheckEnabled = false, false
local highlightConnections = {}
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local plr = player
local PlayerESPBoxEnabled, PlayerESPTextEnabled = false, false
local activePlayerDrawings, processedPlayerModels, playerConnections = {}, {}, {}
local TextESPPosition = { X = 0, Y = 0, Z = 0 }
local processedItemModels, processedVehicleModels = {}, {}
local activeItemDrawings, activeVehicleDrawings = {}, {}
local itemConnections, vehicleConnections = {}, {}
local activeZombieDrawings, processedZombieModels, zombieConnections = {}, {}, {}
local activeEventDrawings, processedEventModels, eventConnections = {}, {}, {}
local HitboxExpanderEnabled = false
local HitboxSize = 4
local activeCorpseDrawings, corpseConnections = {}, {}
local SilentAimEnabled = false
local FovCircleEnabled = false
local LootedCheckEnabled = false
local hitLogs = {}

-- // other nigga shit \\ --
local bulletDropEnabled, antiZombieEnabled, GodviewEnabled, selfChamsEnabled = false, false, false, false
local bulletDropValue, aimedFOVValue = 0, 90
local selfChamsColor = Color3.new(1, 0, 0)
local bodyParts = {
    "LeftFoot", "LeftHand", "LeftLowerArm", "LeftLowerLeg",
    "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "Head", "UpperTorso",
    "RightFoot", "RightHand", "RightLowerArm", "RightLowerLeg",
    "RightUpperArm", "RightUpperLeg"
}
local NetworkSyncHeartbeat, InteractHeartbeat, FindItemData, instantBulletConnection

local CircleInline = Drawing.new("Circle")
CircleInline.Transparency = 1
CircleInline.Thickness = 1
CircleInline.ZIndex = 2
CircleInline.Position = game:GetService("Workspace").CurrentCamera.ViewportSize / 2
CircleInline.Radius = 200
CircleInline.Color = Color3.new(1, 1, 1)
CircleInline.Visible = false

local function createTextDrawing(text, size, color)
    local drawing = Drawing.new("Text")
    drawing.Text = text
    drawing.Size = size
    drawing.Color = color
    drawing.Center = true
    drawing.Outline = false
    drawing.Visible = false
    return drawing
end

local function updateTextDrawing(drawing, distanceDrawing, position, renderDistance)
    local currentCamera = workspace.CurrentCamera
    local localPlayer = Players.LocalPlayer
    local localCharacter = localPlayer and localPlayer.Character

    if not currentCamera or not localCharacter then
        drawing.Visible = false
        distanceDrawing.Visible = false
        return
    end

    local screenPosition, onScreen = currentCamera:WorldToViewportPoint(position)
    local humanoidRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
    local distance = humanoidRootPart and (humanoidRootPart.Position - position).Magnitude or 0

    if distance > renderDistance then
        drawing.Visible = false
        distanceDrawing.Visible = false
        return
    end

    drawing.Visible = onScreen
    distanceDrawing.Visible = onScreen

    if onScreen then
        local textHeight = drawing.TextBounds.Y
        drawing.Position = Vector2.new(screenPosition.X, screenPosition.Y - textHeight / 2)
        distanceDrawing.Text = string.format("[%.1f studs]", distance)
        distanceDrawing.Position = Vector2.new(screenPosition.X, screenPosition.Y + textHeight / 2)
    end
end

local function createESPForModel(model, drawings, processedModels, connections, espSize, espColor, renderDistance)
    if processedModels[model] then return end
    processedModels[model] = true

    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then
                primaryPart = part
                break
            end
        end
    end

    if primaryPart then
        local drawing = createTextDrawing("[" .. model.Name .. "]", espSize, espColor)
        local distanceDrawing = createTextDrawing("", espSize, espColor)
        table.insert(drawings, drawing)
        table.insert(drawings, distanceDrawing)
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not model.Parent then
                drawing:Remove()
                distanceDrawing:Remove()
                connection:Disconnect()
                processedModels[model] = nil
                return
            end
            updateTextDrawing(drawing, distanceDrawing, primaryPart.Position, renderDistance)
        end)
        table.insert(connections, connection)
    end
end

local function clearDrawings(drawings, processedModels, connections)
    for _, drawing in ipairs(drawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(drawings)
    table.clear(processedModels)
    table.clear(connections)
end

local function manageItemESP()
    clearDrawings(activeItemDrawings, processedItemModels, itemConnections)
    if not ItemESPEnabled then return end

    if not workspace:FindFirstChild("Loot") then
        warn("workspace.Loot does not exist")
        return
    end

    local loot = workspace.Loot:GetDescendants()
    for _, item in ipairs(loot) do
        if item:IsA("MeshPart") then
            createESPForModel(item.Parent, activeItemDrawings, processedItemModels, itemConnections, ItemESPSize, ItemESPColor, 600)
        end
    end

    local lootConnection
    lootConnection = workspace.Loot.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("MeshPart") then
            createESPForModel(descendant.Parent, activeItemDrawings, processedItemModels, itemConnections, ItemESPSize, ItemESPColor, 600)
        end
    end)
    table.insert(itemConnections, lootConnection)
end

local function manageVehicleESP()
    clearDrawings(activeVehicleDrawings, processedVehicleModels, vehicleConnections)
    if not VehicleESPEnabled then return end

    for _, object in ipairs(workspace.Vehicles.Spawned:GetChildren()) do
        if object:IsA("Model") then
            createESPForModel(object, activeVehicleDrawings, processedVehicleModels, vehicleConnections, VehicleESPSize, VehicleESPColor, VehicleRenderDistance)
        end
    end

    workspace.Vehicles.Spawned.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            createESPForModel(child, activeVehicleDrawings, processedVehicleModels, vehicleConnections, VehicleESPSize, VehicleESPColor, VehicleRenderDistance)
        end
    end)
end

local function createDrawing(type, text, size, color)
    local drawing
    if type == "Text" then
        drawing = Drawing.new("Text")
        drawing.Text = text
        drawing.Size = size
        drawing.Color = color
        drawing.Center = true
        drawing.Outline = false
    elseif type == "Square" then
        drawing = Drawing.new("Square")
        drawing.Color = color
        drawing.Thickness = 2
        drawing.Filled = false
    end
    drawing.Visible = false
    return drawing
end

local function updatePlayerESP(element, position, distance)
    if not element then return end

    local camera = workspace.CurrentCamera
    local screenPosition, onScreen = camera:WorldToViewportPoint(position)

    if element.CombinedLabel then
        element.CombinedLabel.Visible = PlayerESPEnabled and PlayerESPTextEnabled and onScreen and distance <= PlayerRenderDistance
        if PlayerESPEnabled and PlayerESPTextEnabled and onScreen and distance <= PlayerRenderDistance then
            local player = Players:GetPlayerFromCharacter(element.Model)
            local stats = player and player:FindFirstChild("Stats")
            local health = stats and stats:FindFirstChild("Health") and stats.Health.Value or "N/A"
            local primary = stats and stats:FindFirstChild("Primary") and stats.Primary.Value or "N/A"
            local secondary = stats and stats:FindFirstChild("Secondary") and stats.Secondary.Value or "N/A"
            local playerName = player and player.Name or "Unknown"

            local combinedText = string.format("[Player: %s | HP: %d]\n[Primary: %s]\n[Secondary: %s]\n[Distance: %.1f studs]", playerName, math.floor(health), primary, secondary, distance)
            element.CombinedLabel.Text = combinedText

            local textBounds = element.CombinedLabel.TextBounds
            element.CombinedLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y + 20)

            element.LastHealth = health
        end
    end

    if PlayerESPBoxEnabled and element.Box then
        element.Box.Visible = onScreen and distance <= PlayerRenderDistance
        if onScreen and distance <= PlayerRenderDistance then
            local model = element.Model
            local cframe, size = model:GetBoundingBox()
            local fixedSize = Vector3.new(4, 6, 4) -- temp
            local min = cframe.Position - fixedSize / 2
            local max = cframe.Position + fixedSize / 2
            local minScreenPos, onScreenMin = camera:WorldToViewportPoint(min)
            local maxScreenPos, onScreenMax = camera:WorldToViewportPoint(max)

            if onScreenMin and onScreenMax then
                element.Box.Visible = true
                element.Box.Position = Vector2.new(minScreenPos.X, minScreenPos.Y)
                element.Box.Size = Vector2.new(maxScreenPos.X - minScreenPos.X, maxScreenPos.Y - minScreenPos.Y)
            else
                element.Box.Visible = false
            end
        else
            element.Box.Visible = false
        end
    end
end

local function createPlayerESPElements(model, espSize, espColor) -- breaks the font
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then
                primaryPart = part
                break
            end
        end
    end

    if primaryPart then
        local player = Players:GetPlayerFromCharacter(model)
        local stats = player and player:FindFirstChild("Stats")
        local health = stats and stats:FindFirstChild("Health") and stats.Health.Value or "N/A"
        local primary = stats and stats:FindFirstChild("Primary") and stats.Primary.Value or "N/A"
        local secondary = stats and stats:FindFirstChild("Secondary") and stats.Secondary.Value or "N/A"
        local playerName = player and player.Name or "Unknown"

        local combinedText = string.format("[Player: %s | HP: %d]\n[Primary: %s]\n[Secondary: %s]\n[Distance: 0 studs]", playerName, math.floor(health), primary, secondary)
        local combinedLabel = createTextDrawing(combinedText, espSize, espColor)
        local box = Drawing.new("Square")
        box.Color = espColor
        box.Thickness = 2
        box.Filled = false
        box.Visible = false

        return {
            Model = model,
            PrimaryPart = primaryPart,
            CombinedLabel = combinedLabel,
            Box = box,
            LastHealth = health
        }
    end
end

local function clearPlayerESPElements(elements)
    for _, element in ipairs(elements) do
        if element.CombinedLabel then
            element.CombinedLabel:Remove()
        end
        if element.Box then
            element.Box:Remove()
        end
    end
    table.clear(elements)
    table.clear(processedPlayerModels)
end

local function managePlayerBoxESP()
    if not PlayerESPBoxEnabled then
        for _, element in ipairs(activePlayerDrawings) do
            if element.Box then
                element.Box.Visible = false
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local esp = processedPlayerModels[character]
                if not esp then
                    esp = createPlayerESPElements(character, PlayerESPSize, PlayerESPColor)
                    if esp then
                        table.insert(activePlayerDrawings, esp)
                        processedPlayerModels[character] = esp
                    end
                end
                if esp and esp.Box then
                    esp.Box.Visible = PlayerESPBoxEnabled
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    for i = #activePlayerDrawings, 1, -1 do
        local element = activePlayerDrawings[i]
        local model = element.Model
        if model.Parent then
            local localCharacter = Players.LocalPlayer.Character
            if localCharacter and localCharacter ~= model then
                local localCharacterPosition = localCharacter.PrimaryPart.Position
                local distance = (localCharacterPosition - element.PrimaryPart.Position).Magnitude

                updatePlayerESP(element, element.PrimaryPart.Position, distance)

                if distance > PlayerRenderDistance then
                    element.CombinedLabel.Visible = false
                    if element.Box then
                        element.Box.Visible = false
                    end
                end
            end
        else
            element.CombinedLabel:Remove()
            if element.Box then
                element.Box:Remove()
            end
            table.remove(activePlayerDrawings, i)
            processedPlayerModels[model] = nil
        end
    end
end)

local function create_esp(model)
    local nameLabel = Drawing.new("Text")
    nameLabel.Size = CorpseESPTextSize
    nameLabel.Color = CorpseESPColor
    nameLabel.Outline = false
    nameLabel.Center = true
    nameLabel.Visible = false

    local distanceLabel = Drawing.new("Text")
    distanceLabel.Size = CorpseESPTextSize
    distanceLabel.Color = CorpseESPColor
    distanceLabel.Outline = false
    distanceLabel.Center = true
    distanceLabel.Visible = false

    local connection
    local function refresh_esp()
        if not model.Parent or not model.PrimaryPart or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            nameLabel:Remove()
            distanceLabel:Remove()
            if connection then
                connection:Disconnect()
            end
            return
        end

        if LootedCheckEnabled and model:GetAttribute("Searched") then
            nameLabel.Visible = false
            distanceLabel.Visible = false
            return
        end

        local camera = workspace.CurrentCamera
        local screenPosition, onScreen = camera:WorldToViewportPoint(model.PrimaryPart.Position)
        if onScreen then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - model.PrimaryPart.Position).Magnitude
            if distance <= CorpseRenderDistance then
                nameLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                distanceLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y + 25)
                nameLabel.Text = model.Name:find("Zombie") and "[Zombie Corpse]" or "[" .. model.Name .. "]"
                distanceLabel.Text = string.format("[%d studs]", math.floor(distance))
                nameLabel.Visible = true
                distanceLabel.Visible = true
            else
                nameLabel.Visible = false
                distanceLabel.Visible = false
            end
        else
            nameLabel.Visible = false
            distanceLabel.Visible = false
        end
    end

    connection = RunService.RenderStepped:Connect(refresh_esp)
    table.insert(corpseConnections, connection)
    table.insert(activeCorpseDrawings, nameLabel)
    table.insert(activeCorpseDrawings, distanceLabel)
end

local function setup_esp()
    if not CorpseESPEnabled then return end

    local corpsesFolder = workspace:FindFirstChild("Corpses")
    if not corpsesFolder then
        return
    end

    for _, model in ipairs(corpsesFolder:GetChildren()) do
        if model:IsA("Model") and model.PrimaryPart then
            create_esp(model)
        end
    end

    local childAddedConnection = corpsesFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child.PrimaryPart then
            create_esp(child)
        end
    end)
    table.insert(corpseConnections, childAddedConnection)
end

LocalPlayer.CharacterAdded:Connect(setup_esp)

if LocalPlayer.Character then
    setup_esp()
end

local function clearCorpseESP()
    for _, drawing in ipairs(activeCorpseDrawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, connection in ipairs(corpseConnections) do
        connection:Disconnect()
    end
    table.clear(activeCorpseDrawings)
    table.clear(corpseConnections)
end

local function createZombieESPForModel(model, drawings, processedModels, connections, espSize, espColor, renderDistance)
    if processedModels[model] then return end
    processedModels[model] = true

    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then
                primaryPart = part
                break
            end
        end
    end

    if primaryPart then
        local drawing = createTextDrawing("[" .. model.Name .. "]", espSize, espColor)
        local distanceDrawing = createTextDrawing("", espSize, espColor)
        table.insert(drawings, drawing)
        table.insert(drawings, distanceDrawing)
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not model.Parent then
                drawing:Remove()
                distanceDrawing:Remove()
                connection:Disconnect()
                processedModels[model] = nil
                return
            end
            local localCharacter = Players.LocalPlayer.Character
            local humanoidRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            local distance = humanoidRootPart and (humanoidRootPart.Position - primaryPart.Position).Magnitude or 0
            updateTextDrawing(drawing, distanceDrawing, primaryPart.Position, renderDistance)
            distanceDrawing.Text = string.format("[%.1f studs]", distance)
        end)
        table.insert(connections, connection)
    end
end

local function manageZombieESP()
    clearDrawings(activeZombieDrawings, processedZombieModels, zombieConnections)
    if not ZombieESPEnabled then return end

    local mobs = workspace.Zombies.Mobs:GetChildren()
    for _, mob in ipairs(mobs) do
        if mob:IsA("Model") then
            createZombieESPForModel(mob, activeZombieDrawings, processedZombieModels, zombieConnections, ZombieESPSize, ZombieESPColor, ZombieRenderDistance)
        end
    end

    local childAddedConnection
    childAddedConnection = workspace.Zombies.Mobs.ChildAdded:Connect(function(child)
        if ZombieESPEnabled and child:IsA("Model") then
            createZombieESPForModel(child, activeZombieDrawings, processedZombieModels, zombieConnections, ZombieESPSize, ZombieESPColor, ZombieRenderDistance)
        end
    end)
    table.insert(zombieConnections, childAddedConnection)
end

local function configureLighting()
    while true do
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogStart = 1999999
        Lighting.FogEnd = 2000000
        Lighting.FogColor = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        RunService.RenderStepped:Wait()
    end
end

local function attachJumpHack()
    if Humanoid then
        if jumpHackConnection then
            jumpHackConnection:Disconnect()
        end

        jumpHackConnection = Humanoid.StateChanged:Connect(function(oldState, newState)
            if JumpHackEnabled and newState == Enum.HumanoidStateType.Jumping then
                HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, HumanoidRootPart.Velocity.Y + JumpHeight, HumanoidRootPart.Velocity.Z)
            end
        end)
    end
end

attachJumpHack()

local function clearEventESP()
    for _, drawing in ipairs(activeEventDrawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, connection in ipairs(eventConnections) do
        connection:Disconnect()
    end
    table.clear(activeEventDrawings)
    table.clear(processedEventModels)
    table.clear(eventConnections)
end

local function highlightp(target)
    if not HighlightESPEnabled then return end
    local highlight = target:FindFirstChildOfClass("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = target
    end
    highlight.Enabled = true
    highlight.DepthMode = ChamsWallcheckEnabled and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end

local function highlightplayer(character)
    if not HighlightESPEnabled then return end
    if character and character:FindFirstChild("HumanoidRootPart") then
        highlightp(character)
    end
end

local function startHighlightESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                highlightp(player.Character)
            end
            local connection = player.CharacterAdded:Connect(function(character)
                highlightp(character)
            end)
            table.insert(highlightConnections, connection)
        end
    end
    
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            if player.Character then
                highlightp(player.Character)
            end
            local connection = player.CharacterAdded:Connect(function(character)
                highlightp(character)
            end)
            table.insert(highlightConnections, connection)
        end
    end)
    table.insert(highlightConnections, playerAddedConnection)
end

local function stopHighlightESP() -- // fix this later nigga remember
    for _, connection in ipairs(highlightConnections) do
        connection:Disconnect()
    end
    table.clear(highlightConnections)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight.Enabled = false
            end
        end
    end
end

local function managePlayerESP()
    clearPlayerESPElements(activePlayerDrawings)
    if not PlayerESPEnabled then return end

    local function onCharacterAdded(character)
        if PlayerESPEnabled then
            local esp = createPlayerESPElements(character, PlayerESPSize, PlayerESPColor)
            if esp then
                table.insert(activePlayerDrawings, esp)
                processedPlayerModels[character] = esp
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            if player.Character then
                onCharacterAdded(player.Character)
            end
            player.CharacterAdded:Connect(onCharacterAdded)
        end
    end

    local playerAddedConnection
    playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if player ~= Players.LocalPlayer then
            if player.Character then
                onCharacterAdded(player.Character)
            end
            player.CharacterAdded:Connect(onCharacterAdded)
        end
    end)
    table.insert(playerConnections, playerAddedConnection)

    local playerRemovingConnection
    playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        local esp = processedPlayerModels[player.Character]
        if esp then
            if esp.CombinedLabel then esp.CombinedLabel:Remove() end
            if esp.Box then esp.Box:Remove() end
            processedPlayerModels[player.Character] = nil
            for i, v in ipairs(activePlayerDrawings) do
                if v == esp then
                    table.remove(activePlayerDrawings, i)
                    break
                end
            end
        end
    end)
    table.insert(playerConnections, playerRemovingConnection)
end

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    
    attachJumpHack()
    
    if ItemESPEnabled then
        manageItemESP()
    end
    if VehicleESPEnabled then
        manageVehicleESP()
    end
    if PlayerESPEnabled then
        managePlayerESP()
    end
    if ZombieESPEnabled then
        manageZombieESP()
    end
    if EventESPEnabled then
        handleEventESP()
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    clearDrawings(activeItemDrawings, processedItemModels, itemConnections)
    clearDrawings(activeVehicleDrawings, processedVehicleModels, vehicleConnections)
    clearPlayerESPElements(activePlayerDrawings)
    clearDrawings(activeZombieDrawings, processedZombieModels, zombieConnections)
    clearEventESP()
end)

local function formatModelName(name)
    local formattedName = name:gsub("%d", ""):gsub("(%l)(%u)", "%1 %2")
    return formattedName
end

local function handlePlayerDeath()
    local function onCharacterAdded(newCharacter)
        local humanoid = newCharacter:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            clearDrawings(activeItemDrawings, processedItemModels, itemConnections)
            clearDrawings(activeVehicleDrawings, processedVehicleModels, vehicleConnections)
            clearPlayerESPElements(activePlayerDrawings)
            clearDrawings(activeZombieDrawings, processedZombieModels, zombieConnections)
            clearEventESP()
        end)
    end

    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

local function createEventESPForModel(model, drawings, processedModels, connections, espSize, espColor, renderDistance)
    if processedModels[model] then return end
    processedModels[model] = true

    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then
                primaryPart = part
                break
            end
        end
    end

    if primaryPart then
        local formattedName = formatModelName(model.Name)
        local drawing = Drawing.new("Text")
        drawing.Text = "[" .. formattedName .. "]"
        drawing.Size = espSize
        drawing.Color = espColor
        drawing.Center = true
        drawing.Outline = false
        drawing.Visible = false
        table.insert(drawings, drawing)

        local distanceDrawing = Drawing.new("Text")
        distanceDrawing.Size = espSize
        distanceDrawing.Color = espColor
        distanceDrawing.Center = true
        distanceDrawing.Outline = false
        distanceDrawing.Visible = false
        table.insert(drawings, distanceDrawing)

        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not model.Parent then
                drawing:Remove()
                distanceDrawing:Remove()
                connection:Disconnect()
                processedModels[model] = nil
                return
            end

            local localCharacter = Players.LocalPlayer.Character
            local humanoidRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            local distance = humanoidRootPart and (humanoidRootPart.Position - primaryPart.Position).Magnitude or 0

            local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(primaryPart.Position)
            if onScreen and distance <= renderDistance then
                drawing.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                drawing.Visible = true

                distanceDrawing.Text = string.format("[%.1f studs]", distance)
                distanceDrawing.Position = Vector2.new(screenPosition.X, screenPosition.Y + espSize)
                distanceDrawing.Visible = true
            else
                drawing.Visible = false
                distanceDrawing.Visible = false
            end
        end)
        table.insert(connections, connection)
    end
end

local function resetEventESP()
    for _, drawing in ipairs(activeEventDrawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, connection in ipairs(eventConnections) do
        connection:Disconnect()
    end
    table.clear(activeEventDrawings)
    table.clear(processedEventModels)
    table.clear(eventConnections)
end

local function handleEventESP()
    resetEventESP()
    if not EventESPEnabled then return end

    local events = workspace.Map.Client.RandomEvents:GetChildren()
    for _, event in ipairs(events) do
        if event:IsA("Model") then
            createEventESPForModel(event, activeEventDrawings, processedEventModels, eventConnections, EventESPSize, EventESPColor, EventRenderDistance)
        end
    end

    local eventConnection
    eventConnection = workspace.Map.Client.RandomEvents.ChildAdded:Connect(function(child)
        if EventESPEnabled and child:IsA("Model") then
            createEventESPForModel(child, activeEventDrawings, processedEventModels, eventConnections, EventESPSize, EventESPColor, EventRenderDistance)
        end
    end)
    table.insert(eventConnections, eventConnection)
end

task.spawn(function()
    local scriptContext = game:GetService("ScriptContext")
    local function disableErrorConnections()
        for _, v in pairs(getconnections(scriptContext.Error)) do
            v:Disable()
        end
    end
    disableErrorConnections()
    while task.wait(0.1) do
        disableErrorConnections()
    end
end)

local Framework = require(game:GetService("ReplicatedFirst"):WaitForChild("Framework"))
Framework:WaitForLoaded()
repeat task.wait() until Framework.Classes.Players.get()
local PlayerClass = Framework.Classes.Players.get()
local Network = Framework.Libraries.Network
local Bullets = Framework.Libraries.Bullets

local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local camera = game:GetService("Workspace").CurrentCamera
local runService = game:GetService("RunService")

local function get_target()
    if not SilentAimEnabled then
        return nil
    end

    local current_target = nil
    local maximum_distance = 200

    for i, v in pairs(plrs:GetPlayers()) do
        if v ~= plr then
            if v.Character and v.Character:FindFirstChild("Head") then
                local position, on_screen = game:GetService("Workspace").CurrentCamera:WorldToScreenPoint(v.Character:FindFirstChild("Head").Position)
                if on_screen then
                    local distance = (Vector2.new(position.X, position.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    if distance < maximum_distance then
                        if FovCircleEnabled then
                            local fov_distance = (Vector2.new(position.X, position.Y) - CircleInline.Position).Magnitude
                            if fov_distance > CircleInline.Radius then
                                break
                            end
                        end
                        current_target = v.Character:FindFirstChild("Head")
                        maximum_distance = distance
                    end
                end
            end
        end
    end
    return current_target
end

local function updateFovCircle()
    local viewportSize = camera.ViewportSize
    CircleInline.Position = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
end

local SanityBans = {
    "Chat Message Send", "Ping Return", "Bullet Impact Interaction", "Crouch Audio Mute", "Zombie Pushback Force Request",
    "Camera CFrame Report",
    "Movestate Sync Request", "Update Character Position", "Map Icon History Sync", "Playerlist Staff Icon Get",
    "Request Physics State Sync",
    "Inventory Sync Request", "Wardrobe Resync Request", "Door Interact ", "Sorry Mate, Wrong Path :/"
}
local NetworkSyncHeartbeat
local Globals = Framework.Configs.Globals
local ProjectileGravity = Globals.ProjectileGravity
local ProjectileSpeed = 1000

local activeHitLogs = {}
local hitLogYOffset = 25
local lastDisplayedHealth = {}

local activeHitLogs = {}
local hitLogYOffset = 25
local lastDisplayedHealth = {}

local function showHitLog(targetPlayer)
    task.delay(0.75, function()
        local statsFolder = targetPlayer:FindFirstChild("Stats")
        local currentHP = statsFolder and statsFolder:FindFirstChild("Health") and statsFolder.Health.Value or "Unknown"
        if type(currentHP) == "number" then
            currentHP = math.floor(currentHP + 0.5)
        end
        local playerName = targetPlayer.Name
        local currentTime = tick()
        if lastDisplayedHealth[playerName] and lastDisplayedHealth[playerName].health == currentHP and (currentTime - lastDisplayedHealth[playerName].timestamp) < 10 then
            return
        end

        lastDisplayedHealth[playerName] = { health = currentHP, timestamp = currentTime }
        local hitLogText = Drawing.new("Text")
        hitLogText.Size = 20
        hitLogText.Color = Color3.new(1, 0, 0)
        hitLogText.Center = true
        hitLogText.Outline = true
        hitLogText.Position = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.9)
        hitLogText.Visible = true
        hitLogText.Text = "[periphean.wtf] hit [" .. playerName .. "] to [" .. currentHP .. "]"
        for i, log in ipairs(activeHitLogs) do
            log.Position = log.Position - Vector2.new(0, hitLogYOffset)
        end
        table.insert(activeHitLogs, hitLogText)

        task.delay(3.5, function()
            hitLogText.Visible = false
            for i, log in ipairs(activeHitLogs) do
                if log == hitLogText then
                    table.remove(activeHitLogs, i)
                    break
                end
            end
            for i, log in ipairs(activeHitLogs) do
                log.Position = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.9 - (i - 1) * hitLogYOffset)
            end
        end)
    end)
end

local function HookCharacter(Character)
    for Index, Item in pairs(PlayerClass.Character.Maid.Items) do
        if type(Item) == "table" and rawget(Item, "Action") then
            if table.find(debug.getconstants(Item.Action), "Network sync") then
                NetworkSyncHeartbeat = Item.Action
            end
        end
    end
    local OldEquip = Character.Equip
    Character.Equip = function(Self, Item, ...)
        if Item.FireConfig and Item.FireConfig.MuzzleVelocity then
            ProjectileSpeed = Item.FireConfig.MuzzleVelocity * Globals.MuzzleVelocityMod
        end

        return OldEquip(Self, Item, ...)
    end
end

if PlayerClass.Character then
    HookCharacter(PlayerClass.Character)
end

PlayerClass.CharacterAdded:Connect(function(Character)
    HookCharacter(Character)
end)

local GetSpreadAngle = getupvalue(Bullets.Fire, 1)
setupvalue(Bullets.Fire, 1, function(Character, CCamera, Weapon, ...)
    local OldMoveState = Character.MoveState
    local OldZooming = Character.Zooming
    local OldFirstPerson = CCamera.FirstPerson
    Character.MoveState = "Walking"
    Character.Zooming = true
    CCamera.FirstPerson = true
    local ReturnArgs = {GetSpreadAngle(Character, CCamera, Weapon, ...)}
    Character.MoveState = OldMoveState
    Character.Zooming = OldZooming
    CCamera.FirstPerson = OldFirstPerson
    return unpack(ReturnArgs)
end)

local function GetStates()
    if not NetworkSyncHeartbeat then return {} end
    local Seed = debug.getupvalue(NetworkSyncHeartbeat, 6)
    local RandomData = {}
    local SeededRandom = Random.new(Seed)
    local Data = {
        "ServerTime",
        "RootCFrame",
        "RootVelocity",
        "FirstPerson",
        "InstanceCFrame",
        "LookDirection",
        "MoveState",
        "AtEaseInput",
        "ShoulderSwapped",
        "Zooming",
        "BinocsActive",
        "Staggered",
        "Shoving"
    }
    local DataLength = #Data
    while #Data > 0 do
        local ToRemove = SeededRandom:NextInteger(1, DataLength)
        ToRemove = ToRemove % #Data == 0 and #Data or ToRemove % #Data
        local Removed = table.remove(Data, ToRemove)
        table.insert(RandomData, Removed)
    end
    return RandomData
end

local function SolveTrajectory(Origin, Velocity, Time, Gravity)
    local GravityVector = Vector3.new(0, -math.abs(Gravity), 0)
    return Origin + (Velocity * Time) + (0.5 * GravityVector * Time * Time)
end

local function createTracer(startPos, endPos)
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = startPos
    attachment0.Parent = workspace.Terrain

    local attachment1 = Instance.new("Attachment")
    attachment1.Position = endPos
    attachment1.Parent = workspace.Terrain

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.FaceCamera = true
    beam.Width0 = 1
    beam.Width1 = 0.6
    beam.Color = ColorSequence.new(Color3.new(1, 0, 0))
    beam.Texture = "rbxassetid://446111271"
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureLength = 3
    beam.TextureSpeed = 3
    beam.LightEmission = 1
    beam.LightInfluence = 1
    beam.Parent = workspace.Terrain

    game:GetService("Debris"):AddItem(attachment0, 1.5)
    game:GetService("Debris"):AddItem(attachment1, 1.5)
    game:GetService("Debris"):AddItem(beam, 1.5)
end

local NewSend = function(OldSend, Self, Name, ...)
    if table.find(SanityBans, Name) then
        return
    end
    return OldSend(Self, Name, ...)
end

local NewFetch = function(OldFetch, Self, Name, ...)
    if table.find(SanityBans, Name) then
        return
    end
    if Name == "Character State Report" then
        local RandomData = GetStates()
        local Args = {...}
        for Index = 1, #Args do
            if RandomData[Index] == "MoveState" then
                Args[Index] = "Climbing"
            end
        end
        return OldFetch(Self, Name, unpack(Args))
    end
    return OldFetch(Self, Name, ...)
end

local NewFire = function(OldFire, Self, ...)
    local Args = { ... }
    local target = get_target() 
    if target then
        local Position = target.Position
        local Direction = Position - Args[4]
        Position = SolveTrajectory(Position , target.Parent.HumanoidRootPart.AssemblyLinearVelocity, Direction.Magnitude / ProjectileSpeed, ProjectileGravity)
        local ProjectileDirection = (Position - Args[4]).Unit
        Args[5] = ProjectileDirection
        createTracer(Args[4], Position)
        
        local ray = Ray.new(Args[4], ProjectileDirection * Direction.Magnitude)
        local hit, hitPosition = workspace:FindPartOnRay(ray, plr.Character)
        if hit and hit.Parent then
            local targetPlayer = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
            if targetPlayer then
                showHitLog(targetPlayer)
            end
        end
    end
    return OldFire(Self, unpack(Args))
end

local OldFire; OldFire = hookfunction(Bullets.Fire, function(Self, ...)
    return NewFire(OldFire, Self, ...)
end)

local OldSend; OldSend = hookfunction(Network.Send, function(Self, Name, ...)
    return NewSend(OldSend, Self, Name, ...)
end)

local OldFetch; OldFetch = hookfunction(Network.Fetch, function(Self, Name, ...)
    return NewFetch(OldFetch, Self, Name, ...)
end)

runService.RenderStepped:Connect(function()
    updateFovCircle()
end)

print('loaded')

local function changeHeadSize(head, size, transparency)
    pcall(function()
        head.Size = Vector3.new(size, size, size)
        head.Transparency = transparency
        head.CanCollide = true
    end)
end

local function resetHeadSize(head)
    pcall(function()
        head.Size = Vector3.new(1, 1, 1)
        head.Transparency = 0
        head.CanCollide = false
    end)
end

local function expandHitbox()
    if not HitboxExpanderEnabled then
        for _, player in pairs(game:GetService('Players'):GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                resetHeadSize(player.Character.Head)
            end
        end
        return
    end

    for _, player in pairs(game:GetService('Players'):GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            changeHeadSize(player.Character.Head, HitboxSize, 0.5)
        end
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head")
        expandHitbox()
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        onPlayerAdded(player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if HitboxExpanderEnabled and tostring(self) == "Head" and index == "Size" then
        return Vector3.new(1.15, 1.15, 1.15)
    end
    return oldIndex(self, index)
end)

RunService.RenderStepped:Connect(expandHitbox)

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:FindFirstChild("Head") and Players:GetPlayerFromCharacter(child) ~= LocalPlayer then
        changeHeadSize(child:FindFirstChild("Head"), HitboxSize, 0.5)
    end
end)

local mt = getrawmetatable(game)
local old_index = mt.__index
local old_newindex = mt.__newindex

setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if not checkcaller() then
        if key == "Scale" and self:IsA("SpecialMesh") and self.Parent and self.Parent.Name == "Head" then
            return Vector3.new(1, 1, 1)
        elseif key == "Size" and self.Name == "Head" then
            local character = self.Parent
            if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                return Vector3.new(1.15, 1.15, 1.15)
            end
        end
    end
    return old_index(self, key)
end)

mt.__newindex = newcclosure(function(self, key, value)
    if not checkcaller() then
        if key == "Scale" and self:IsA("SpecialMesh") and self.Parent and self.Parent.Name == "Head" then
            return
        elseif key == "Size" and self.Name == "Head" then
            local character = self.Parent
            if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                return
            end
        end
    end
    return old_newindex(self, key, value)
end)

setreadonly(mt, true)

local function onInputBegan(input)
    if InfiniteJumpEnabled and input.KeyCode == Enum.KeyCode.Space and not UserInputService:GetFocusedTextBox() then
        local player = Players.LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end

UserInputService.InputBegan:Connect(onInputBegan)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if InfiniteJumpEnabled and key == "State" and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local state = oldIndex(self, key)
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
            return Enum.HumanoidStateType.Climbing
        end
        return state
    end
    return oldIndex(self, key)
end)

local function seewalls(pos, lookvector)
    if pos and lookvector then
        local ray = Ray.new(pos, (lookvector).Unit * 2)
        local part, position = Workspace:FindPartOnRayWithIgnoreList(ray, {plr.Character, camera})
        
        if part then
            return true
        else
            return false
        end 
    else
        return false
    end
end

RunService.Heartbeat:Connect(function()
    local chr = plr.Character
    if chr and chr:FindFirstChild("HumanoidRootPart") and chr:FindFirstChild("Head") then
        local hrp = chr:FindFirstChild("HumanoidRootPart")
        local head = chr:FindFirstChild("Head")
        local result

        result = seewalls(hrp.CFrame.p, hrp.CFrame.LookVector)

        if result and SpiderClimbEnabled then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, SpiderClimbSpeed, 0)
            for _, v in pairs(plr.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Velocity, v.RotVelocity = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

local function enableInstantOpen()
    for Index, Table in pairs(getgc(true)) do
        if type(Table) == "table" and rawget(Table, "Rate") == 0.05 then
            InteractHeartbeat = Table.Action
            FindItemData = getupvalue(InteractHeartbeat, 11)
        end
    end

    setupvalue(InteractHeartbeat, 11, function(...)
        local ReturnArgs = {FindItemData(...)}
        if ReturnArgs[4] then ReturnArgs[4] = 0 end

        return unpack(ReturnArgs)
    end)
end

local function disableInstantOpen()
    if InteractHeartbeat and FindItemData then
        setupvalue(InteractHeartbeat, 11, FindItemData)
    end
end

local function refreshGodview()
    while GodviewEnabled do
        task.wait(10)
        if GodviewEnabled then
            local thing = require(game:GetService("ReplicatedStorage").Client.Abstracts.Interface.Map)
            thing:DisableGodview()
            task.wait(0.1)
            thing:EnableGodview()
        end
    end
end

local function applyMaterialAndColor(character)
    for _, partName in ipairs(bodyParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Material = Enum.Material.ForceField
            part.Color = selfChamsColor
        end
    end
end

local function enableSelfChams()
    selfChamsEnabled = true
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    applyMaterialAndColor(Character)

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if selfChamsEnabled then
            newCharacter:WaitForChild("HumanoidRootPart")
            applyMaterialAndColor(newCharacter)
        end
    end)
end

local function disableSelfChams()
    selfChamsEnabled = false
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    for _, partName in ipairs(bodyParts) do
        local part = Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Material = Enum.Material.Plastic
            part.Color = Color3.fromRGB(255, 255, 255)
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if not selfChamsEnabled then
            newCharacter:WaitForChild("HumanoidRootPart")
            for _, partName in ipairs(bodyParts) do
                local part = newCharacter:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    part.Material = Enum.Material.Plastic
                    part.Color = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end)
end

local function noFallDMG()
    local affectpos = Vector3.new(0, 0, 0)
    local affected = table.create(0)
    local human
    local stime = 0
    local atime = 0
    function check()
        local tracks = human.Animator:GetPlayingAnimationTracks()
        local isswim = tostring(tracks[9]) == "Swimming"
        if isswim then
            stime = stime + 1
        else
            stime = 0
        end
        return stime > 100
    end
    
    game["Run Service"].RenderStepped:Connect(function()
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            local hrp = char.HumanoidRootPart
            human = char.Humanoid
            affectpos = hrp.Position - Vector3.new(0, 4, 0)
            local stuff = workspace:GetPartBoundsInRadius(affectpos, 50)
            for i, v in pairs(stuff) do
                if v.Name ~= "Sea Floor" then
                    affected[v] = v.Name
                elseif check() and affected[v] then
                    v.Name = affected[v]
                end
                if v:IsDescendantOf(workspace.Map) and human.FloorMaterial == Enum.Material.Air and atime > 0.7 then
                    v.Name = "Sea Floor"
                end
            end
        end)
    end)
    task.spawn(function()
        while task.wait(0.1) do
            pcall(function()
                if human.FloorMaterial == Enum.Material.Air then
                    atime = atime + 0.1
                else
                    atime = 0
                end
            end)
        end
    end)
    print("loaded")
end

ItemESPGroupBox:AddToggle('ItemESP', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle item ESP on or off',
    Callback = function(Value)
        ItemESPEnabled = Value
        if Value then
            manageItemESP()
        else
            clearDrawings(activeItemDrawings, processedItemModels, itemConnections)
        end
    end
})

ItemESPGroupBox:AddLabel('ESP Color'):AddColorPicker('ItemESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Color', 
    Callback = function(Value) 
        ItemESPColor = Value 
        for _, drawing in ipairs(activeItemDrawings) do
            drawing.Color = ItemESPColor
        end
    end 
})

ItemESPGroupBox:AddSlider('ItemESPSize', { 
    Text = 'Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        ItemESPSize = Value 
        for _, drawing in ipairs(activeItemDrawings) do
            drawing.Size = ItemESPSize
        end
    end 
})

Options.ItemESPSize:OnChanged(function() end)
Options.ItemESPColor:OnChanged(function() end)
Options.ItemESPSize:SetValue(30)
Options.ItemESPColor:SetValueRGB(Color3.fromRGB(255, 0, 0))

VehicleESPGroupBox:AddToggle('VehicleESP', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle vehicle ESP on or off',
    Callback = function(Value)
        VehicleESPEnabled = Value
        if Value then
            manageVehicleESP()
        else
            clearDrawings(activeVehicleDrawings, processedVehicleModels, vehicleConnections)
        end
    end
})

VehicleESPGroupBox:AddLabel('ESP Color'):AddColorPicker('VehicleESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Color', 
    Callback = function(Value) 
        VehicleESPColor = Value 
        for _, drawing in ipairs(activeVehicleDrawings) do
            drawing.Color = VehicleESPColor
        end
    end 
})

VehicleESPGroupBox:AddSlider('VehicleESPSize', { 
    Text = 'Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        VehicleESPSize = Value 
        for _, drawing in ipairs(activeVehicleDrawings) do
            drawing.Size = VehicleESPSize
        end
    end 
})

VehicleESPGroupBox:AddSlider('VehicleRenderDistance', { 
    Text = 'Render Distance', 
    Default = 1000, 
    Min = 100, 
    Max = 5000, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        VehicleRenderDistance = Value 
        if VehicleESPEnabled then
            manageVehicleESP()
        end
    end 
})

Options.VehicleESPSize:OnChanged(function() end)
Options.VehicleESPColor:OnChanged(function() end)
Options.VehicleRenderDistance:OnChanged(function() end)
Options.VehicleESPSize:SetValue(30)
Options.VehicleESPColor:SetValueRGB(Color3.fromRGB(255, 0, 0))
Options.VehicleRenderDistance:SetValue(1000)

PlayerESPGroupBox:AddToggle('PlayerESP', {
    Text = 'Master Toggle',
    Default = false,
    Tooltip = 'Toggle player ESP on or off',
    Callback = function(Value)
        PlayerESPEnabled = Value
        managePlayerESP()
    end
})

PlayerESPGroupBox:AddToggle('HighlightESP', {
    Text = 'Chams',
    Default = false,
    Tooltip = 'Toggle chams on or off',
    Callback = function(Value)
        HighlightESPEnabled = Value
        if Value then
            startHighlightESP()
        else
            stopHighlightESP()
        end
    end
})

PlayerESPGroupBox:AddToggle('ChamsWallcheck', {
    Text = 'Wallcheck',
    Default = false,
    Tooltip = 'Toggle wallcheck on or off',
    Callback = function(Value)
        ChamsWallcheckEnabled = Value
        if HighlightESPEnabled then
            stopHighlightESP()
            startHighlightESP()
        end
    end
})

PlayerESPGroupBox:AddToggle('PlayerESPText', {
    Text = 'Text ESP',
    Default = false,
    Tooltip = 'Toggle text ESP on or off',
    Callback = function(Value)
        PlayerESPTextEnabled = Value
        for _, drawing in ipairs(activePlayerDrawings) do
            drawing.CombinedLabel.Visible = PlayerESPEnabled and PlayerESPTextEnabled
        end
    end
})

PlayerESPGroupBox:AddToggle('PlayerESPBox', {
    Text = 'Box ESP',
    Default = false,
    Tooltip = 'Toggle box ESP on or off',
    Callback = function(Value)
        PlayerESPBoxEnabled = Value
        managePlayerBoxESP()
    end
})

PlayerESPGroupBox:AddLabel('ESP Color'):AddColorPicker('PlayerESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Select ESP color', 
    Callback = function(Value) 
        PlayerESPColor = Value 
        for _, drawing in ipairs(activePlayerDrawings) do
            drawing.CombinedLabel.Color = PlayerESPColor
            if drawing.Box then
                drawing.Box.Color = PlayerESPColor
            end
        end
    end 
})

PlayerESPGroupBox:AddSlider('PlayerESPSize', { 
    Text = 'ESP Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        PlayerESPSize = Value 
        for _, drawing in ipairs(activePlayerDrawings) do
            drawing.CombinedLabel.Size = PlayerESPSize
        end
    end 
})

PlayerESPGroupBox:AddSlider('PlayerRenderDistance', { 
    Text = 'Render Distance', 
    Default = 1000, 
    Min = 100, 
    Max = 5000, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        PlayerRenderDistance = Value 
    end 
})

WorldMiscGroupBox:AddButton({
    Text = 'Fullbright',
    Func = function()
        configureLighting()
    end
})

WorldMiscGroupBox:AddButton({
    Text = 'No Foilage',
    Func = function()
        local move_down_amount = -1000
        local elements = workspace.Map.Client.Elements:GetChildren()

        local function move_part_down(part)
            if part and part:IsA("BasePart") then
                local current_position = part.Position
                part.Position = Vector3.new(current_position.X, current_position.Y + move_down_amount, current_position.Z)
            end
        end

        local function move_specified_parts(element)
            local parts_to_move = {"Canopy2", "Canopy1", "Fronds", "Canopy3"}
            for _, part_name in ipairs(parts_to_move) do
                local part = element:FindFirstChild(part_name)
                if part then
                    move_part_down(part)
                end
            end
        end

        for _, element in ipairs(elements) do
            if element:IsA("Model") then
                move_specified_parts(element)
            end
        end

        workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                move_specified_parts(child)
            end
        end)
    end
})

ZombieESPGroupBox:AddToggle('ZombieESP', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle zombie ESP on or off',
    Callback = function(Value)
        ZombieESPEnabled = Value
        manageZombieESP()
    end
})

ZombieESPGroupBox:AddLabel('ESP Color'):AddColorPicker('ZombieESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Color', 
    Callback = function(Value) 
        ZombieESPColor = Value 
        for _, drawing in ipairs(activeZombieDrawings) do
            drawing.Color = ZombieESPColor
        end
    end 
})

ZombieESPGroupBox:AddSlider('ZombieESPSize', { 
    Text = 'Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        ZombieESPSize = Value 
        for _, drawing in ipairs(activeZombieDrawings) do
            drawing.Size = ZombieESPSize
        end
    end 
})

ZombieESPGroupBox:AddSlider('ZombieRenderDistance', { 
    Text = 'Render Distance', 
    Default = 1000, 
    Min = 100, 
    Max = 5000, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        ZombieRenderDistance = Value 
        if ZombieESPEnabled then
            manageZombieESP()
        end
    end 
})

EventESPGroupBox:AddToggle('EventESP', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle event ESP on or off',
    Callback = function(Value)
        EventESPEnabled = Value
        handleEventESP()
    end
})

EventESPGroupBox:AddLabel('ESP Color'):AddColorPicker('EventESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Color', 
    Callback = function(Value) 
        EventESPColor = Value 
        for _, drawing in ipairs(activeEventDrawings) do
            drawing.Color = EventESPColor
        end
    end 
})

EventESPGroupBox:AddSlider('EventESPSize', { 
    Text = 'Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        EventESPSize = Value 
        for _, drawing in ipairs(activeEventDrawings) do
            drawing.Size = EventESPSize
        end
    end 
})

EventESPGroupBox:AddSlider('EventRenderDistance', { 
    Text = 'Render Distance', 
    Default = 1000, 
    Min = 100, 
    Max = 5000, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        EventRenderDistance = Value 
        if EventESPEnabled then
            handleEventESP()
        end
    end 
})

CorpseESPGroupBox:AddToggle('CorpseESP', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle corpse ESP on or off',
    Callback = function(Value)
        CorpseESPEnabled = Value
        if Value then
            setup_esp()
        else
            clearCorpseESP()
        end
    end
})

CorpseESPGroupBox:AddToggle('LootedCheck', {
    Text = 'Looted Check',
    Default = false,
    Tooltip = 'Check if the corpse has been looted',
    Callback = function(Value)
        LootedCheckEnabled = Value
        if CorpseESPEnabled then
            clearCorpseESP()
            setup_esp()
        end
    end
})

CorpseESPGroupBox:AddLabel('ESP Color'):AddColorPicker('CorpseESPColor', { 
    Default = Color3.new(1, 0, 0), 
    Title = 'Color', 
    Callback = function(Value) 
        CorpseESPColor = Value 
        for _, drawing in ipairs(activeCorpseDrawings) do
            drawing.Color = CorpseESPColor
        end
    end 
})

CorpseESPGroupBox:AddSlider('CorpseESPTextSize', { 
    Text = 'Size', 
    Default = 20, 
    Min = 10, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        CorpseESPTextSize = Value 
        for _, drawing in ipairs(activeCorpseDrawings) do
            drawing.Size = CorpseESPTextSize
        end
    end 
})

CorpseESPGroupBox:AddSlider('CorpseRenderDistance', { 
    Text = 'Render Distance', 
    Default = 1000, 
    Min = 100, 
    Max = 5000, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        CorpseRenderDistance = Value 
    end 
})

MapESPGroupBox:AddToggle('GodviewToggle', { -- redundant remember thiss nigega
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle Godview on or off',
    Callback = function(Value)
        GodviewEnabled = Value
        local thing = require(game:GetService("ReplicatedStorage").Client.Abstracts.Interface.Map)
        if Value then
            thing:DisableGodview()
            task.wait(0.1)
            thing:EnableGodview()
            task.spawn(refreshGodview)
        else
            thing:DisableGodview()
        end
    end
})

ReloadBarGroupBox:AddToggle('ReloadBarToggle', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle reload baar on or off',
    Callback = function(Value)
        if Value then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/fuckthiswebsite83/9840effr/refs/heads/main/barthing.lua"))()
        else
            stop_reload_bar()
        end
    end
})

AimedFOVGroupBox:AddSlider('AimedFOVSlider', {
    Text = 'Aimed FOV',
    Default = 90,
    Min = 30,
    Max = 120,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        aimedFOVValue = Value
    end
})

AimedFOVGroupBox:AddButton({
    Text = 'Update Aimed FOV',
    Func = function()
        local gun = require(game:GetService("ReplicatedStorage").Client.Abstracts.ItemInitializers.Firearm)
        local old
        old = hookfunction(gun, function(a, b, c)
            setreadonly(b, false)
            b.AimFieldOfView = aimedFOVValue
            return old(a, b, c)
        end)
    end,
    Tooltip = 'Update the aimed FOV based on the slider value'
})

SelfChamsGroupBox:AddToggle('SelfChamsEnabled', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Toggle self chams on or off',
    Callback = function(Value)
        selfChamsEnabled = Value
        if Value then
            enableSelfChams()
        else
            disableSelfChams()
        end
    end
}):AddColorPicker('SelfChamsColor', { 
    Default = Color3.new(1, 0, 0), 
    Title = 'Color', 
    Callback = function(Value) 
        selfChamsColor = Value 
        if selfChamsEnabled then
            local Character = LocalPlayer.Character
            if Character then
                applyMaterialAndColor(Character)
            end
        end
    end 
})

GunModsGroupBox:AddButton({
    Text = 'No Spread No Recoil V.1',
    Func = function()
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        repeat task.wait() until ReplicatedFirst:FindFirstChild("Framework")
        local Framework = require(ReplicatedFirst.Framework)

        repeat task.wait() until Framework.Classes.Players.get()
        local PlayerClass = Framework.Classes.Players.get()

        local Bullets = Framework.Libraries.Bullets
        local Firearm = require(ReplicatedStorage.Client.Abstracts.ItemInitializers.Firearm)

        local GetSpreadAngle = getupvalue(Bullets.Fire, 1)
        local GetSpreadVector = getupvalue(Bullets.Fire, 3)
        local CastLocalBullet = getupvalue(Bullets.Fire, 4)
        local GetFireImpulse = getupvalue(Bullets.Fire, 6)

        local function disableRecoil()
            setupvalue(Bullets.Fire, 6, function(...)
                local ReturnArgs = {GetFireImpulse(...)}

                for Index = 1, #ReturnArgs do
                    if typeof(ReturnArgs[Index]) == "Vector2" then
                        ReturnArgs[Index] = Vector2.new(0, 0)
                    else
                        ReturnArgs[Index] = 0
                    end
                end

                return unpack(ReturnArgs)
            end)
        end

        disableRecoil()
    end
})

GunModsGroupBox:AddButton({
    Text = 'No Spread No Recoil V.2',
    Func = function()
        local ReplicatedFirst = game:GetService("ReplicatedFirst")

        local Framework = require(ReplicatedFirst.Framework)
        
        local Bullets = Framework.Libraries.Bullets
        
        local GetSpreadAngle = getupvalue(Bullets.Fire, 1)
        local GetFireImpulse = getupvalue(Bullets.Fire, 6)
        
        local function disableRecoil()
            setupvalue(Bullets.Fire, 1, function(...)
                return 0
            end)
            setupvalue(Bullets.Fire, 6, function(...)
                local ReturnArgs = {GetFireImpulse(...)}
        
                for Index = 1, #ReturnArgs do
                    if typeof(ReturnArgs[Index]) == "Vector2" then
                        ReturnArgs[Index] = Vector2.new(0, 0)
                    else
                        ReturnArgs[Index] = 0
                    end
                end
        
                return unpack(ReturnArgs)
            end)
        end
        
        disableRecoil()
    end
})

GunModsGroupBox:AddButton({
    Text = 'Change Firemodes',
    Func = function()
        local gun = require(game:GetService("ReplicatedStorage").Client.Abstracts.ItemInitializers.Firearm)
        local old
        old = hookfunction(gun, function(a, b, c)
            setreadonly(b, false)
            setreadonly(b.FireModes, false)
            b.FireModes = {"Semiautomatic", "Burst", "Automatic"}
            b.DefaultFireMode = "Automatic"
            return old(a, b, c)
        end)
    end,
    Tooltip = '*DROP GUN AND PICK IT BACK UP*'
})

GunModsGroupBox:AddButton({
    Text = 'Instant Bullet',
    Func = function()
        if instantBulletConnection then
            instantBulletConnection:Disconnect()
        end

        local cam = workspace.CurrentCamera

        instantBulletConnection = game:GetService("RunService").RenderStepped:Connect(function()
            pcall(function()
                local char = game:GetService("Players").LocalPlayer.Character
                local ray = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 500)
                local baza = char.Equipped:GetChildren()[1]:FindFirstChild("Base")
                local muzzle = char.Equipped:GetChildren()[1]:FindFirstChild("Muzzle")
                if ray and ray.Position and muzzle then
                    local thing = muzzle.Weld
                    local cf = thing.C0
                    cf -= Vector3.new(0, 0, cf.Z)
                    cf += Vector3.new(0, 0, (ray.Position - baza.Position).Magnitude)
                    thing.C0 = cf
                end
            end)
        end)
    end
})

GunModsGroupBox:AddToggle('BulletDrop', {
    Text = 'Bullet Drop',
    Default = false,
    Tooltip = 'Toggle bullet drop on or off',
    Callback = function(Value)
        bulletDropEnabled = Value
        local v0 = require(game:GetService("ReplicatedFirst").Framework)
        local v1 = v0.require("Configs", "Globals")
        if bulletDropEnabled then
            v1.ProjectileGravity = bulletDropValue
        else
            v1.ProjectileGravity = 0
        end
    end
})

GunModsGroupBox:AddSlider('BulletDropValue', {
    Text = 'Bullet Drop Value',
    Default = 0,
    Min = -100,
    Max = 100,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        bulletDropValue = Value
        if bulletDropEnabled then
            local v0 = require(game:GetService("ReplicatedFirst").Framework)
            local v1 = v0.require("Configs", "Globals")
            v1.ProjectileGravity = bulletDropValue
        end
    end
})

local function attachJumpHack()
    if Humanoid then
        if jumpHackConnection then
            jumpHackConnection:Disconnect()
        end

        jumpHackConnection = Humanoid.StateChanged:Connect(function(oldState, newState)
            if JumpHackEnabled and newState == Enum.HumanoidStateType.Jumping then
                HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, HumanoidRootPart.Velocity.Y + JumpHeight, HumanoidRootPart.Velocity.Z)
            end
        end)
    end
end

MovementGroupBox:AddToggle('JumpHack', {
    Text = 'Jump Hack',
    Default = false,
    Tooltip = 'Toggle jump hack on or off',
    Callback = function(Value)
        JumpHackEnabled = Value
        if JumpHackEnabled then
            attachJumpHack()
        elseif jumpHackConnection then
            jumpHackConnection:Disconnect()
            jumpHackConnection = nil
        end
    end
})

MovementGroupBox:AddSlider('JumpHeight', { 
    Text = 'Jump Height', 
    Default = 50, 
    Min = 10, 
    Max = 200, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        JumpHeight = Value 
    end 
})

local function startTPWalking()
    while TpWalkingEnabled and Character and Humanoid and Humanoid.Parent do
        local delta = RunService.Heartbeat:Wait()
        if Humanoid.MoveDirection.Magnitude > 0 then
            Character:TranslateBy(Humanoid.MoveDirection * delta * TpWalkSpeed)
        end
    end
end

MovementGroupBox:AddToggle('TpWalking', {
    Text = 'Teleport Walking',
    Default = false,
    Tooltip = 'Toggle teleport walking on or off',
    Callback = function(Value)
        TpWalkingEnabled = Value
        if TpWalkingEnabled then
            startTPWalking()
        end
    end
})

MovementGroupBox:AddSlider('TpWalkSpeed', { 
    Text = 'Teleport Walk Speed', 
    Default = 10, 
    Min = 1, 
    Max = 50, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        TpWalkSpeed = Value 
    end 
})

MovementGroupBox:AddToggle('InfiniteJump', {
    Text = 'Infinite Jump',
    Default = false,
    Tooltip = 'Toggle infinite jump on or off',
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end
})

MovementGroupBox:AddToggle('SpiderClimb', {
    Text = 'Spider Climb',
    Default = false,
    Tooltip = 'Toggle spider climb on or off',
    Callback = function(Value)
        SpiderClimbEnabled = Value
    end
})

MovementGroupBox:AddSlider('SpiderClimbSpeed', { 
    Text = 'Spider Climb Speed', 
    Default = 1, 
    Min = 0.1, 
    Max = 10, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        SpiderClimbSpeed = Value 
    end 
})

ExploitsGroupBox:AddButton({
    Text = 'Anti-Zombie',
    Func = function()
        antiZombieEnabled = not antiZombieEnabled

        while antiZombieEnabled and task.wait() do
            pcall(function()
                for _, v in pairs(workspace.Zombies.Mobs:GetChildren()) do
                    v.HumanoidRootPart.VectorForce.MaxForce = Vector3.new(-4000, 4000, -4000)
                end
            end)
        end
    end
})

ExploitsGroupBox:AddButton({
    Text = 'No Fall Animations',
    Func = function()
        local v0 = require(game:GetService("ReplicatedFirst").Framework)
        local v1 = v0.require("Configs", "Globals")
        v1.FallDamageStart = 500
    end,
    Tooltip = 'Disable fall animations'
})

ExploitsGroupBox:AddToggle('InstantOpen', {
    Text = 'Instant Open',
    Default = false,
    Tooltip = 'Toggle instant open on or off',
    Callback = function(Value)
        if Value then
            enableInstantOpen()
        else
            disableInstantOpen()
        end
    end
})

ExploitsGroupBox:AddButton({
    Text = 'Use in Air',
    Func = function()
        local Grounded
        Grounded = hookfunction(Raycasting.CharacterGroundCast, newcclosure(function(Self, Position, LengthDown, ...)
            if PlayerClass.Character and Position == PlayerClass.Character.RootPart.CFrame then
                return GroundPart, CFrame.new(), Vector3.new(0, 1, 0)
            end
            return Grounded(Self, Position, LengthDown, ...)
        end))
    end,
    Tooltip = 'Enable using items in the airar'
})

ExploitsGroupBox:AddButton({
    Text = 'No Fall DMG',
    Func = noFallDMG,
    Tooltip = 'Enable No Fall Damage'
})

HitboxExpanderGroupBox:AddToggle('HitboxExpander', {
    Text = 'Enable Hitbox Expander',
    Default = false,
    Tooltip = 'Toggle hitbox expander on or off',
    Callback = function(Value)
        HitboxExpanderEnabled = Value
        expandHitbox()
    end
})

HitboxExpanderGroupBox:AddSlider('HitboxSize', { 
    Text = 'Hitbox Size', 
    Default = 4, 
    Min = 1, 
    Max = 40, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        HitboxSize = Value 
        if HitboxExpanderEnabled then
            expandHitbox()
        end
    end 
})

SilentAimGroupBox:AddToggle('SilentAim', {
    Text = 'Enable Silent Aim',
    Default = false,
    Tooltip = 'Toggle Silent Aim on or off',
    Callback = function(Value)
        SilentAimEnabled = Value
    end
})

SilentAimGroupBox:AddToggle('FovCircle', {
    Text = 'Enable FOV Circle',
    Default = false,
    Tooltip = 'Toggle FOV Circle on or off',
    Callback = function(Value)
        FovCircleEnabled = Value
        CircleInline.Visible = Value
    end
})

local function resetDrawings(drawings, processedModels, connections)
    for _, drawing in ipairs(drawings) do
        if drawing.Remove then
            drawing:Remove()
        end
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(drawings)
    table.clear(processedModels)
    table.clear(connections)
end

local function resetPlayerESPElements(elements, processedModels, connections)
    for _, element in ipairs(elements) do
        if element.CombinedLabel and element.CombinedLabel.Remove then
            element.CombinedLabel:Remove()
        end
        if element.Box and element.Box.Remove then
            element.Box:Remove()
        end
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(elements)
    table.clear(processedModels)
    table.clear(connections)
end

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() 
    Library:Unload() 
    resetDrawings(activeItemDrawings, processedItemModels, itemConnections)
    resetDrawings(activeVehicleDrawings, processedVehicleModels, vehicleConnections)
    resetPlayerESPElements(activePlayerDrawings, processedPlayerModels, playerConnections)
    resetDrawings(activeZombieDrawings, processedZombieModels, zombieConnections)
    clearEventESP()
    clearCorpseESP()
    ItemESPEnabled = false
    VehicleESPEnabled = false
    PlayerESPEnabled = false
    ZombieESPEnabled = false
    EventESPEnabled = false
    CorpseESPEnabled = false
end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
