local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = script.Parent

-- Asumimos que tienes este evento para comunicarte con el servidor
local VoiceCommandEvent = ReplicatedStorage:WaitForChild("SAO_Events"):WaitForChild("VoiceCommandEvent")

-- Función para conectar cables de audio (Wires)
local function ConnectAudio(source, target)
	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = target
	wire.Parent = source
	return wire
end

-- Esperamos a que el sistema asigne el micrófono al jugador
local audioInput = player:WaitForChild("AudioDeviceInput", 5) 

if audioInput then
	-- Creamos el traductor de Voz a Texto
	local speechToText = Instance.new("AudioSpeechToText")
	speechToText.Name = "SAO_VoiceRecognition"
	speechToText.Enabled = true
	speechToText.Parent = character

	-- Conectamos el micrófono al traductor con un "Wire"
	ConnectAudio(audioInput, speechToText)

	print("🎤 Sistema de Voz de Aincrad conectado.")

	-- Cada vez que el jugador deje de hablar, Roblox procesa el texto
	speechToText:GetPropertyChangedSignal("Text"):Connect(function()
		local textoHablado = string.lower(speechToText.Text)

		-- Si el jugador dijo algo vacío, lo ignoramos
		if textoHablado == "" then return end

		-- Imprimimos para que lo veas tú en consola local
		print("Detectado: " .. textoHablado)

		-- 🔥 Le enviamos TODA la frase al servidor. El ItemHandler ya se encargará de buscar si dijiste "teleport".
		VoiceCommandEvent:FireServer(textoHablado)
	end)
else
	warn("No se encontró el micrófono del jugador. Asegúrate de tener el Chat de Voz activado.")
end
