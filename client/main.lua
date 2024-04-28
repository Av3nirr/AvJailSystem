ESX = exports["es_extended"]:getSharedObject()

SelectedPlayer = nil
Menu = {}
Menu.Toggle = false
ActivePlayers = {}
JailedPlayers = {}

local JailTime = 0
local JailReason = "Aucune"
local InJail = false
local UnJail = false


function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
	AddTextEntry(entryTitle, textEntry)
	DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength)

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(850)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		return result
	else
		Citizen.Wait(850)
		return nil
	end
end


function MenuCreate()
    Menu.Toggle = true
    Main = RageUI.CreateMenu("Av_jail", 'MENU PRINCIPAL', nil, nil, nil, nil)
    jailPlayer = RageUI.CreateSubMenu(Main, "Av_jail", 'JAIL UN JOUEUR')
    jailedPlayers = RageUI.CreateSubMenu(Main, "Av_jail", 'JOUEURS JAIL')
    Main.Closed = function()
        Menu.Toggle = false
    end
end


function OpenMainMenu()
    MenuCreate()
    ESX.TriggerServerCallback("av_jailsystem:getPlayers", function(players) 
        if players then
            ActivePlayers = players
        else
            ActivePlayers = nil
        end
    end)
    ESX.TriggerServerCallback("av_jailsystem:jailedPlayers", function(playersInJail)
        if playersInJail then
            JailedPlayers = playersInJail
        else
            JailedPlayers = nil
        end
    end)

    RageUI.Visible(Main, true)
    CreateThread(function ()
        while true do
            Wait(2)
            if Menu.Toggle then
                --Main Menu
                RageUI.IsVisible(Main, function()
                    RageUI.Button('Jail un Joueur', nil, {RightLabel = '→'}, true, {}, jailPlayer)
                    RageUI.Button('Joueurs Jail', nil, {RightLabel = '→'}, true, {}, jailedPlayers)
                end)

                --Jail Player Menu
                RageUI.IsVisible(jailPlayer, function()
                    if ActivePlayers == nil then
                        RageUI.Separator('~r~Aucun joueur ne peut être Jail actuelement !')
                    else
                        for _, player in ipairs(ActivePlayers) do
                            RageUI.Button("[~b~"..player.source.."~s~] ~b~"..player.name, nil, {RightLabel = "→"}, true , {
                                onSelected = function()
                                    local time = tonumber(KeyboardInput('AV_JAIL_TIME', "Temps de jail (en minutes)", "30", 11))*60
                                    local reason = KeyboardInput('AV_JAIL_REASON', "Raison du jail", "Staff", 150)
                                    TriggerServerEvent('av_jailsystem:JailPlayer', player.source, time, reason)
                                end
                            }) 
                        end
                    end
                end)
                -- jailed players menu
                RageUI.IsVisible(jailedPlayers, function()
                    if JailedPlayers == nil then
                        RageUI.Separator('~r~Aucun Joueur En Jail Actuelement')
                    else
                        for _, player in ipairs(JailedPlayers) do
                            RageUI.Info("Informations du jail", {"Nom", "Prénom", "Identifier","Temps de jail restant", "Raison du Jail", "Peine (en minutes)"}, {player.lastName,player.firstName,player.identifier,player.jailTime,player.jail_reason or "Aucune", (player.jail_base/60).."min"})
                            RageUI.Button("~b~"..player.firstName.." "..player.lastName, nil, {RightLabel = "→"}, true , {
                                onSelected = function()
                                    TriggerServerEvent("av_jailsystem:unJail", player.identifier)
                                end
                            }) 
                        end
                    end
                end)
            end
            
        end
        
    end)
end




RegisterNetEvent("av_jailsystem:jailPlayer:return")
AddEventHandler("av_jailsystem:jailPlayer:return", function(time, reason, id)
    FirstJailTime = time
    jailTime = time
    JailReason = reason
    local playerPed = PlayerPedId()
    SetNuiFocus(false, false)
    SetPedArmour(playerPed, 0)
    SetEntityCoords(playerPed, Config.JailPosition)

    InJail = true

    CreateThread(function()
        while InJail do
            Wait(1000)
            if jailTime > 0 then
                jailTime = jailTime - 1
                Visual.Subtitle('Vous êtes jail pendant ~b~'..(jailTime..('~s~ secondes pour la raison: ~b~'..(reason or "Aucune"))), 1000)
                TriggerServerEvent("av_jailsystem:updateTime", jailTime)
            else
                InJail = false
                UnJail = true
                TriggerServerEvent("av_jailsystem:unJail", id, false)
            end
    
            if #(GetEntityCoords(PlayerPedId()) - Config.JailPosition) > 15 then
                SetEntityCoords(PlayerPedId(), Config.JailPosition)
            end
                
            DisableControlAction(2, 37, true) -- Select Weapon
            DisableControlAction(0, 25, true) -- Input Aim
            DisableControlAction(0, 24, true) -- Input Attack
            DisableControlAction(0, 257, true) -- Disable melee
            DisableControlAction(0, 140, true) -- Disable melee
            DisableControlAction(0, 142, true) -- Disable melee
            DisableControlAction(0, 143, true) -- Disable melee
        end

        SetEntityCoords(PlayerPedId(), Config.Unjail)
    end)
end)


RegisterCommand("jail", function(source, rawComand, args)
    OpenMainMenu()
end, false)

RegisterNetEvent("avjail:unjailPlayer")
AddEventHandler("avjail:unjailPlayer", function()
    InJail = false
    UnJail = true
end)