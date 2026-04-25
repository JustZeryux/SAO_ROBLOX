local player = game.Players.LocalPlayer
local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local head = char:WaitForChild("Head")

-- Nos aseguramos que primero se eliminen las barras default de Roblox
humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

-- Esperamos a que el servidor termine de crear el UI de SAO
local bgui = head:WaitForChild("SAO_Fixed_Overhead", 10)

if bgui then
	local barContainer = bgui:WaitForChild("BarContainer", 5)

	if barContainer then
		-- OCULTAMOS SOLO EL CONTENEDOR DE LAS BARRAS
		-- La gema flotante y tu nombre se quedarán visibles
		barContainer.Visible = false
	end
end
