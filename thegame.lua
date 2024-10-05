local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({ Title = ' $ $ $ $ $ $$ $$$ $$ $  [warp.space] $ $$ $$ [v.1] $ $ $ $ $$$', Center = true, AutoShow = true })
local Tabs = { 
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'), 
    ['UI Settings'] = Window:AddTab('UI Settings') 
}

-- // Nigga stuff \\ --

local GunModsGroupBox = Tabs.Main:AddLeftGroupbox('Gun Mods')
local MovementGroupBox = Tabs.Main:AddRightGroupbox('Movement')
local ExploitsGroupBox = Tabs.Main:AddLeftGroupbox('Exploits')
local HitboxExpanderGroupBox = Tabs.Main:AddRightGroupbox('Hitbox Expander')
local ItemESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Item ESP')
local VehicleESPGroupBox = Tabs.Visuals:AddRightGroupbox('Vehicle ESP')
local PlayerESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Player ESP')
local WorldMiscGroupBox = Tabs.Visuals:AddRightGroupbox('World Misc')
local ZombieESPGroupBox = Tabs.Visuals:AddRightGroupbox('Zombie ESP')
local EventESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Event ESP')
local CorpseESPGroupBox = Tabs.Visuals:AddLeftGroupbox('Corpse ESP')

local ItemESPEnabled = false
local VehicleESPEnabled = false
local ItemESPColor = Color3.new(1, 1, 1)
local VehicleESPColor = Color3.new(1, 1, 1)
local ItemESPSize = 20
local VehicleESPSize = 20
local VehicleRenderDistance = 1000
local JumpHackEnabled = false
local JumpHeight = 50
local TpWalkingEnabled = false
local TpWalkSpeed = 10
local jumpHackConnection

local HighlightESPEnabled = false
local ChamsWallcheckEnabled = false
local highlightConnections = {}

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local PlayerESPEnabled = false
local PlayerESPBoxEnabled = false
local PlayerESPTextEnabled = false
local PlayerESPColor = Color3.new(1, 1, 1)
local PlayerESPSize = 20
local PlayerRenderDistance = 1000
local activePlayerDrawings = {}
local processedPlayerModels = {}
local playerConnections = {}

local TextESPPosition = { X = 0, Y = 0, Z = 0 }
local processedItemModels = {}
local processedVehicleModels = {}
local activeItemDrawings = {}
local activeVehicleDrawings = {}
local itemConnections = {}
local vehicleConnections = {}

local ZombieESPEnabled = false
local ZombieESPColor = Color3.new(1, 1, 1)
local ZombieESPSize = 20
local ZombieRenderDistance = 1000
local activeZombieDrawings = {}
local processedZombieModels = {}
local zombieConnections = {}

local EventESPEnabled = false
local EventESPColor = Color3.new(1, 1, 1)
local EventESPSize = 20
local EventRenderDistance = 1000
local activeEventDrawings = {}
local processedEventModels = {}
local eventConnections = {}

local HitboxExpanderEnabled = false
local HitboxSize = 4

local CorpseESPEnabled = false
local CorpseESPColor = Color3.new(1, 0, 0)
local CorpseESPTextSize = 20
local CorpseRenderDistance = 1000
local corpseConnections = {}
local activeCorpseDrawings = {}

-- // end of Nigga stuff \\ --

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
    local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(position)
    local localCharacter = Players.LocalPlayer.Character
    local humanoidRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local distance = humanoidRootPart and (humanoidRootPart.Position - position).Magnitude or 0

    if distance > renderDistance then
        drawing.Visible = false
        distanceDrawing.Visible = false
        return
    end

    drawing.Visible = onScreen
    distanceDrawing.Visible = onScreen

    if onScreen then
        drawing.Position = Vector2.new(screenPosition.X, screenPosition.Y)
        distanceDrawing.Text = string.format("[%.1f studs]", distance)
        distanceDrawing.Position = Vector2.new(screenPosition.X, screenPosition.Y + 20)
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

            if element.Box then
                local boxHeight = element.Box.Size.Y
                element.CombinedLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y + boxHeight / 2 + 20)
            end

            element.LastHealth = health
        end
    end

    if PlayerESPBoxEnabled and element.Box then
        element.Box.Visible = onScreen and distance <= PlayerRenderDistance
        if onScreen and distance <= PlayerRenderDistance then
            local model = element.Model
            local cframe, size = model:GetBoundingBox()
            local min = cframe.Position - size / 2
            local max = cframe.Position + size / 2
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

local function createPlayerESPElements(model, espSize, espColor)
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
    if jumpHackConnection then
        jumpHackConnection:Disconnect()
    end
    jumpHackConnection = UserInputService.JumpRequest:Connect(function()
        if JumpHackEnabled and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, JumpHeight, HumanoidRootPart.Velocity.Z)
        end
    end)
end

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

local function stopHighlightESP()
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

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local esp = createPlayerESPElements(character, PlayerESPSize, PlayerESPColor)
                if esp then
                    table.insert(activePlayerDrawings, esp)
                    processedPlayerModels[character] = esp
                end
            end
        end
    end

    local playerAddedConnection
    playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            local function onCharacterAdded(character)
                if PlayerESPEnabled then
                    local esp = createPlayerESPElements(character, PlayerESPSize, PlayerESPColor)
                    if esp then
                        table.insert(activePlayerDrawings, esp)
                        processedPlayerModels[character] = esp
                    end
                end
            end

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

local function changeMeshSize(mesh, size)
    pcall(function()
        mesh.Scale = Vector3.new(size, size, size)
    end)
end

local function resetMeshSize(mesh)
    pcall(function()
        mesh.Scale = Vector3.new(1, 1, 1)
    end)
end

local function expandHitbox()
    if not HitboxExpanderEnabled then
        for _, player in pairs(game:GetService('Players'):GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                resetHeadSize(player.Character.Head)
                local mesh = player.Character.Head:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    resetMeshSize(mesh)
                end
            end
        end
        return
    end

    for _, player in pairs(game:GetService('Players'):GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            changeHeadSize(player.Character.Head, HitboxSize, 0.5)
            local mesh = player.Character.Head:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                changeMeshSize(mesh, HitboxSize)
            end
        end
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head")
        expandHitbox()
    end)
end

for _, player in pairs(game:GetService('Players'):GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayerAdded(player)
    end
end

game:GetService('Players').PlayerAdded:Connect(onPlayerAdded)

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
        local head = child:FindFirstChild("Head")
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            changeMeshSize(mesh, HitboxSize)
        end
    end
end)

local mt = getrawmetatable(game)
local old_index = mt.__index
local old_newindex = mt.__newindex

setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if not checkcaller() then
        if key == "Scale" and self:IsA("SpecialMesh") and self.Parent and self.Parent.Name == "Head" then
            local character = self.Parent.Parent
            if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                return Vector3.new(1, 1, 1)
            end
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
            local character = self.Parent.Parent
            if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                return
            end
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

ItemESPGroupBox:AddToggle('ItemESP', {
    Text = 'Item ESP',
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
    Title = 'Select ESP color', 
    Callback = function(Value) 
        ItemESPColor = Value 
        for _, drawing in ipairs(activeItemDrawings) do
            drawing.Color = ItemESPColor
        end
    end 
})

ItemESPGroupBox:AddSlider('ItemESPSize', { 
    Text = 'ESP Size', 
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
    Text = 'Vehicle ESP',
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
    Title = 'Select ESP color', 
    Callback = function(Value) 
        VehicleESPColor = Value 
        for _, drawing in ipairs(activeVehicleDrawings) do
            drawing.Color = VehicleESPColor
        end
    end 
})

VehicleESPGroupBox:AddSlider('VehicleESPSize', { 
    Text = 'ESP Size', 
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
    Text = 'Player ESP',
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
    Text = 'Zombie ESP',
    Default = false,
    Tooltip = 'Toggle zombie ESP on or off',
    Callback = function(Value)
        ZombieESPEnabled = Value
        manageZombieESP()
    end
})

ZombieESPGroupBox:AddLabel('ESP Color'):AddColorPicker('ZombieESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Select ESP color', 
    Callback = function(Value) 
        ZombieESPColor = Value 
        for _, drawing in ipairs(activeZombieDrawings) do
            drawing.Color = ZombieESPColor
        end
    end 
})

ZombieESPGroupBox:AddSlider('ZombieESPSize', { 
    Text = 'ESP Size', 
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
    Text = 'Event ESP',
    Default = false,
    Tooltip = 'Toggle event ESP on or off',
    Callback = function(Value)
        EventESPEnabled = Value
        handleEventESP()
    end
})

EventESPGroupBox:AddLabel('ESP Color'):AddColorPicker('EventESPColor', { 
    Default = Color3.new(1, 1, 1), 
    Title = 'Select ESP color', 
    Callback = function(Value) 
        EventESPColor = Value 
        for _, drawing in ipairs(activeEventDrawings) do
            drawing.Color = EventESPColor
        end
    end 
})

EventESPGroupBox:AddSlider('EventESPSize', { 
    Text = 'ESP Size', 
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
    Text = 'Corpse ESP',
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

CorpseESPGroupBox:AddLabel('ESP Color'):AddColorPicker('CorpseESPColor', { 
    Default = Color3.new(1, 0, 0), 
    Title = 'Select ESP color', 
    Callback = function(Value) 
        CorpseESPColor = Value 
        for _, drawing in ipairs(activeCorpseDrawings) do
            drawing.Color = CorpseESPColor
        end
    end 
})

CorpseESPGroupBox:AddSlider('CorpseESPTextSize', { 
    Text = 'ESP Size', 
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

ExploitsGroupBox:AddButton({
    Text = 'Anti-Zombie',
    Func = function()
        while task.wait() and TpWalkingEnabled do
            pcall(function()
                for _, v in pairs(workspace.Zombies.Mobs:GetChildren()) do
                    v.HumanoidRootPart.VectorForce.MaxForce = Vector3.new(-4000, 4000, -4000)
                end
            end)
        end
    end
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
    Max = 10, 
    Rounding = 1, 
    Compact = false, 
    Callback = function(Value) 
        HitboxSize = Value 
        if HitboxExpanderEnabled then
            expandHitbox()
        end
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

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('[warp.space] | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    print('Unloaded!')
    Library.Unloaded = true
end)

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
