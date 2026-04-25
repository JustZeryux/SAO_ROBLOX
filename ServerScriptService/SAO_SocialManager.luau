local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local SocialEvent = SAO_Events:WaitForChild("SocialEvent")

-- Aquí guardaremos quién está tradeando con quién para no cruzarlos
local ActiveTrades = {}

SocialEvent.OnServerEvent:Connect(function(player, action, targetPlayer)

	-- ==========================================
	-- 👥 SISTEMA DE PARTY
	-- ==========================================
	if action == "InviteParty" then
		-- El jugador A invita al jugador B
		if targetPlayer then
			SocialEvent:FireClient(targetPlayer, "ReceiveInvite", player, "Party")
		end

	elseif action == "AcceptParty" then
		-- El jugador B acepta. Aquí deberías agregar lógica para unirlos en una tabla de grupo
		-- Por ahora, simulamos que se unieron enviándoles a ambos la UI de Party
		local partyData = {player, targetPlayer}
		SocialEvent:FireClient(player, "UpdateSocialUI", "Party", partyData)
		SocialEvent:FireClient(targetPlayer, "UpdateSocialUI", "Party", partyData)
		print(player.Name .. " y " .. targetPlayer.Name .. " formaron una Party.")


		-- ==========================================
		-- ⚔️ SISTEMA DE DUELOS
		-- ==========================================
	elseif action == "RequestDuel" then
		if targetPlayer then
			SocialEvent:FireClient(targetPlayer, "ReceiveInvite", player, "Duel")
		end

	elseif action == "AcceptDuel" then
		-- Avisamos a AMBOS jugadores que inicie la cuenta regresiva 3, 2, 1...
		SocialEvent:FireClient(player, "StartDuel", targetPlayer)
		SocialEvent:FireClient(targetPlayer, "StartDuel", player)
		print("Duelo iniciado entre " .. player.Name .. " y " .. targetPlayer.Name)
		-- TODO: Aquí meterías tu lógica de PvP (quitar forcefields, activar daño mutuo, etc.)


		-- ==========================================
		-- ⚖️ SISTEMA DE TRADEO
		-- ==========================================
	elseif action == "RequestTrade" then
		if targetPlayer then
			SocialEvent:FireClient(targetPlayer, "ReceiveInvite", player, "Trade")
		end

	elseif action == "AcceptTrade" then
		-- Registramos que están tradeando juntos
		ActiveTrades[player.Name] = targetPlayer.Name
		ActiveTrades[targetPlayer.Name] = player.Name

		-- Les abrimos la ventana de Tradeo a los dos
		SocialEvent:FireClient(player, "StartTrade", targetPlayer)
		SocialEvent:FireClient(targetPlayer, "StartTrade", player)

	elseif action == "CancelTrade" then
		-- Si alguien cancela, buscamos a su compañero y le cerramos la ventana
		local partnerName = ActiveTrades[player.Name]
		if partnerName then
			local partner = Players:FindFirstChild(partnerName)
			if partner then
				SocialEvent:FireClient(partner, "CloseTrade")
			end
			-- Limpiamos el registro
			ActiveTrades[partnerName] = nil
		end
		ActiveTrades[player.Name] = nil

	elseif action == "ConfirmTrade" then
		-- Aquí iría la lógica pesada cuando ambos le dan a Aceptar en la ventana de tradeo
		-- (Verificar qué items pusieron, quitárselos del inventario y dárselos al otro)
		print(player.Name .. " ha confirmado su parte del tradeo.")
	end

end)
