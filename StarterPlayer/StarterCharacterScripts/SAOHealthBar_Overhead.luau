local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")
local hrp = character:WaitForChild("HumanoidRootPart")
local player = game.Players:GetPlayerFromCharacter(character)

humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

-- =========================================================
-- 1️⃣ LIMPIEZA PREVIA
-- =========================================================
for _, child in ipairs(head:GetChildren()) do
	if child.Name == "SAO_Fixed_Overhead" then child:Destroy() end
end
if character:FindFirstChild("SAO_Diamond_3D") then
	character.SAO_Diamond_3D:Destroy()
end

-- =========================================================
-- 💎 CONFIGURACIÓN DEL DIAMANTE 3D
-- =========================================================
local diamondPrefab = ReplicatedStorage:WaitForChild("SAO Diamond")
local diamond3D = diamondPrefab:Clone()
diamond3D.Name = "SAO_Diamond_3D"

-- Mantenemos el Neón pero SIN el PointLight
diamond3D.Material = Enum.Material.Neon

diamond3D.Anchored = false
diamond3D.CanCollide = false
diamond3D.Massless = true
diamond3D.Parent = character

local weld = Instance.new("Weld")
weld.Part0 = hrp
weld.Part1 = diamond3D
weld.Parent = diamond3D

-- =========================================================
-- 🔠 CONFIGURACIÓN DE LA INTERFAZ (Usuario Visual y Una Sola Línea)
-- =========================================================
local bgui = Instance.new("BillboardGui")
bgui.Name = "SAO_Fixed_Overhead"
bgui.Adornee = head
-- Lo hicimos mucho más ancho (10 en lugar de 6) para darle espacio a los símbolos y nombres largos
bgui.Size = UDim2.new(10, 0, 1.5, 0) 
-- Lo bajé un poco (de 4.8 a 4.0) porque en tu foto se veía demasiado en el cielo
bgui.StudsOffset = Vector3.new(0, 4.0, 0) 
bgui.AlwaysOnTop = true
bgui.MaxDistance = 80 
bgui.Parent = head

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "PlayerName"
nameLabel.Size = UDim2.new(1, 0, 1, 0)
nameLabel.BackgroundTransparency = 1

-- USAMOS EL DISPLAY NAME (Nombre Visual)
local realName = player and player.DisplayName or character.Name
nameLabel.Text = ">> " .. realName .. " <<"

nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextScaled = true
nameLabel.TextWrapped = false -- ESTO OBLIGA A QUE NO SE PASE A LA SIGUIENTE LÍNEA
nameLabel.Parent = bgui

local nameStroke = Instance.new("UIStroke")
nameStroke.Thickness = 2.5
nameStroke.Color = Color3.fromRGB(0, 0, 0)
nameStroke.Parent = nameLabel

-- =========================================================
-- 🎨 LÓGICA DE COLOR (Sistema PK)
-- =========================================================
local function actualizarColorGem()
	local esAsesino = character:GetAttribute("IsPK") or (player and player:GetAttribute("IsPK"))
	local targetColor

	if esAsesino then
		targetColor = Color3.fromRGB(255, 50, 50) 
	else
		targetColor = Color3.fromRGB(85, 255, 127) 
	end

	diamond3D.Color = targetColor
end

actualizarColorGem()

if player then
	player:GetAttributeChangedSignal("IsPK"):Connect(actualizarColorGem)
end
character:GetAttributeChangedSignal("IsPK"):Connect(actualizarColorGem)

-- =========================================================
-- 🌀 ANIMACIÓN DE FLOTACIÓN Y ROTACIÓN
-- =========================================================
local hoverHeight = 3.5 
local hoverSpeed = 2    
local spinSpeed = 1.5   
local hoverBounce = 0.3 

local animationConnection
animationConnection = RunService.Heartbeat:Connect(function()
	if not character or not character.Parent or humanoid.Health <= 0 then
		animationConnection:Disconnect()
		return
	end

	local time = os.clock()
	local offsetY = hoverHeight + (math.sin(time * hoverSpeed) * hoverBounce)

	weld.C0 = CFrame.new(0, offsetY, 0) * CFrame.Angles(0, time * spinSpeed, 0)
end)
