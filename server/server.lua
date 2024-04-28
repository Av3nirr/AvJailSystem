ESX = exports["es_extended"]:getSharedObject()
PlayerInJail = {}


ESX.RegisterServerCallback("av_jailsystem:getPlayers", function(playerId, cb)
    local players = {}
    local xPlayers = ESX.GetPlayers()
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer == nil then return 
        else
            table.insert(players, {
                id = "0",
                source = xPlayer.source,
                name = xPlayer.getName()
            })
        end
    end

    cb(players)
end)


ESX.RegisterServerCallback("av_jailsystem:jailedPlayers", function(playerId, cb)
    local playersInJail = {}
    MySQL.Async.fetchAll('SELECT * FROM users WHERE jail_time > 0', {}, function(result)
        if result[1] then
            for _, player in ipairs(result) do
                table.insert(playersInJail, {
                    identifier = player.identifier,
                    firstName = player.firstname,
                    lastName = player.lastname,
                    jailTime = player.jail_time,
                    jail_reason = player.jail_reason,
                    jail_base = player.jail_base
                })
            end
            cb(playersInJail)
        else
            cb(nil)
        end
    end)
end)



RegisterNetEvent("av_jailsystem:JailPlayer")
AddEventHandler("av_jailsystem:JailPlayer", function(id, time, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(id)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", source, "~r~Ce joueur n'éxiste pas !")
    end
    if not PlayerInJail[id] then
        MySQL.Async.execute('UPDATE users SET jail_base = @jail_base WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier,
            ['@jail_base'] = time
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_reason = @jail_reason WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier,
            ['@jail_reason'] = reason
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_time = @jail_time WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier,
            ['@jail_time'] = time
        }, function(rowsChanged)
            TriggerClientEvent('av_jailsystem:jailPlayer:return', xTarget.source, time, reason, id)
            PlayerInJail[id] = {timeRemaining = time, identifier = xTarget.identifier }
            TriggerClientEvent("esx:showNotification", id, "Vous avez été jail !")
        end)
    else
        TriggerClientEvent("esx:showNotification", source, "~r~Ce joueur est déjà en jail !")
    end

end)


RegisterNetEvent("av_jailsystem:updateTime")
AddEventHandler("av_jailsystem:updateTime", function(time)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    MySQL.Async.execute('UPDATE users SET jail_time = @jail_time WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier,
        ['@jail_time'] = time
    }, function(rowsChanged)
    end)
end)


RegisterNetEvent("av_jailsystem:unJail")
AddEventHandler("av_jailsystem:unJail", function(id)
    local _src = source
    local xPlayer = ESX.GetPlayerFromIdentifier(id) or ESX.GetPlayerFromId(id)

    if xPlayer then
        TriggerClientEvent("avjail:unjailPlayer", xPlayer.source)
        Wait(1000)
        MySQL.Async.execute('UPDATE users SET jail_time = @jail_time WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier,
            ['@jail_time'] = 0
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_base = @jail_base WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier,
            ['@jail_base'] = 0
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_reason = @jail_reason WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier,
            ['@jail_reason'] = nil
        }, function(rowsChanged)
        end)
        TriggerClientEvent("esx:showNotification", id, "Vous avez été unjail !")
    else
        MySQL.Async.execute('UPDATE users SET jail_time = @jail_time WHERE identifier = @identifier', {
            ['@identifier'] = id,
            ['@jail_time'] = 0
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_base = @jail_base WHERE identifier = @identifier', {
            ['@identifier'] = id,
            ['@jail_base'] = 0
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET jail_reason = @jail_reason WHERE identifier = @identifier', {
            ['@identifier'] = id,
            ['@jail_reason'] = nil
        }, function(rowsChanged)
        end)
        MySQL.Async.execute('UPDATE users SET position = @position WHERE identifier = @identifier', {
            ['@identifier'] = id,
            ['@position'] = json.encode({ x = Config.Unjail.x, y = Config.Unjail.y, z = Config.Unjail.z })
        }, function(rowsChanged)
        end)
    end
    PlayerInJail[id] = nil
end)

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].jail_time > 0 then
            local reason = result[1].jail_reason
            TriggerEvent("av_jailsystem:JailPlayer:deco", xPlayer.source, result[1].jail_time, reason)
        end
    end)
  end)



RegisterNetEvent('av_jailsystem:JailPlayer:deco')
AddEventHandler('av_jailsystem:JailPlayer:deco', function(playerId, jailTime, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        if not PlayerInJail[playerId] then
            MySQL.Async.execute('UPDATE users SET jail_time = @jail_time WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier,
                ['@jail_time'] = jailTime
            }, function(rowsChanged)
                print('A player with a jail has reconnected sending him in jail for '..jailTime..' sec')
                TriggerClientEvent('av_jailsystem:jailPlayer:return', xPlayer.source, jailTime, reason, playerId)
                PlayerInJail[playerId] = {timeRemaining = jailTime, identifier = xPlayer.identifier }
            end)
        end
    end
end)

