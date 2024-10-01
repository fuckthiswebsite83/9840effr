local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerESP = {}
PlayerESP.__index = PlayerESP

PlayerESP.Enabled = false
PlayerESP.BoxEnabled = false
PlayerESP.Color = Color3.new(1, 1, 1)
PlayerESP.Size = 20
PlayerESP.RenderDistance = 1000
PlayerESP.ActiveDrawings = {}
PlayerESP.ProcessedModels = {}

local function createDrawing(type, text, size, color)
    local drawing
    if type == "Text" then
        drawing = Drawing.new("Text")
        drawing.Text = text
        drawing.Size = size
        drawing.Color = color
        drawing.Center = true
        drawing.Outline = true
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

    element.CombinedLabel.Visible = PlayerESP.Enabled and onScreen
    if PlayerESP.Enabled and onScreen then
        local player = Players:GetPlayerFromCharacter(element.Model)
        local stats = player and player:FindFirstChild("Stats")
        local health = stats and stats:FindFirstChild("Health") and stats.Health.Value or "N/A"
        local primary = stats and stats:FindFirstChild("Primary") and stats.Primary.Value or "N/A"
        local secondary = stats and stats:FindFirstChild("Secondary") and stats.Secondary.Value or "N/A"
        local playerName = player and player.Name or "Unknown"

        local combinedText = string.format("[Player: %s | HP: %s]\n[Primary: %s]\n[Secondary: %s]\n[Distance: %.1f studs]", playerName, health, primary, secondary, distance)
        element.CombinedLabel.Text = combinedText

        local boxHeight = element.Box.Size.Y
        element.CombinedLabel.Position = Vector2.new(screenPosition.X, screenPosition.Y + boxHeight / 2 + 20)
    end

    if PlayerESP.BoxEnabled and element.Box then
        if onScreen then
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

        local combinedText = string.format("[Player: %s | HP: %s]\n[Primary: %s]\n[Secondary: %s]\n[Distance: 0 studs]", playerName, health, primary, secondary)
        local combinedLabel = createDrawing("Text", combinedText, espSize, espColor)
        local box = createDrawing("Square", "", espSize, espColor)

        return {
            Model = model,
            PrimaryPart = primaryPart,
            CombinedLabel = combinedLabel,
            Box = box
        }
    end
end

local function clearPlayerESPElements(elements)
    for _, element in ipairs(elements) do
        if element.CombinedLabel.Remove then
            element.CombinedLabel:Remove()
        end
        if element.Box and element.Box.Remove then
            element.Box:Remove()
        end
    end
    table.clear(elements)
end

function PlayerESP:Toggle(enabled)
    self.Enabled = enabled
    self:Update()
end

function PlayerESP:ToggleBox(enabled)
    self.BoxEnabled = enabled
end

function PlayerESP:SetColor(color)
    self.Color = color
    for _, drawing in ipairs(self.ActiveDrawings) do
        drawing.CombinedLabel.Color = self.Color
        if drawing.Box then
            drawing.Box.Color = self.Color
        end
    end
end

function PlayerESP:SetSize(size)
    self.Size = size
    for _, drawing in ipairs(self.ActiveDrawings) do
        drawing.CombinedLabel.Size = self.Size
    end
end

function PlayerESP:SetRenderDistance(distance)
    self.RenderDistance = distance
end

function PlayerESP:Update()
    clearPlayerESPElements(self.ActiveDrawings)
    if not self.Enabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            if character then
                local esp = createPlayerESPElements(character, self.Size, self.Color)
                if esp then
                    table.insert(self.ActiveDrawings, esp)
                    self.ProcessedModels[character] = esp
                end
            end
        end
    end
end

function PlayerESP:Init()
    Players.PlayerAdded:Connect(function(player)
        if player ~= Players.LocalPlayer then
            player.CharacterAdded:Connect(function(character)
                local esp = createPlayerESPElements(character, self.Size, self.Color)
                if esp then
                    table.insert(self.ActiveDrawings, esp)
                    self.ProcessedModels[character] = esp
                end
            end)
        end
    end)

    RunService.RenderStepped:Connect(function()
        for i = #self.ActiveDrawings, 1, -1 do
            local element = self.ActiveDrawings[i]
            local model = element.Model
            if model.Parent then
                local localCharacter = Players.LocalPlayer.Character
                if localCharacter and localCharacter ~= model then
                    local localCharacterPosition = localCharacter.PrimaryPart.Position
                    local distance = (localCharacterPosition - element.PrimaryPart.Position).Magnitude

                    if distance <= self.RenderDistance then
                        updatePlayerESP(element, element.PrimaryPart.Position, distance)
                    else
                        element.CombinedLabel.Visible = false
                    end
                end
            else
                element.CombinedLabel:Remove()
                if element.Box then
                    element.Box:Remove()
                end
                table.remove(self.ActiveDrawings, i)
                self.ProcessedModels[model] = nil
            end
        end
    end)
end

return PlayerESP
