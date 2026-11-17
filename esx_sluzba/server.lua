AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if xPlayer and xPlayer.job and xPlayer.job.name == 'police' then
        Player(playerId).state:set('policeDuty', true, true)
        xPlayer.addWeapon('WEAPON_COMBATPISTOL', 150)
        xPlayer.addWeapon('WEAPON_NIGHTSTICK', 1)
        xPlayer.addWeapon('WEAPON_FLASHLIGHT', 1)
        xPlayer.addWeapon('WEAPON_STUNGUN', 1)
        
        pcall(function()
            xPlayer.addInventoryItem('handcuffs', 1)
        end)
        
        TriggerClientEvent('esx:showNotification', playerId, 'Witaj na służbie, Kadecie!')
        TriggerClientEvent('esx_sluzba:forceRestore', playerId)
    end
end)

RegisterNetEvent('esx_sluzba:getEquipment')
AddEventHandler('esx_sluzba:getEquipment', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if xPlayer.job.name == 'police' then
        xPlayer.addWeapon('WEAPON_COMBATPISTOL', 150)
        xPlayer.addWeapon('WEAPON_NIGHTSTICK', 1)
        xPlayer.addWeapon('WEAPON_FLASHLIGHT', 1)
        xPlayer.addWeapon('WEAPON_STUNGUN', 1)
        pcall(function() xPlayer.addInventoryItem('handcuffs', 1) end)
        xPlayer.showNotification('~g~Pobrano wyposażenie służbowe i ekwipunek!~s~')
    else
        xPlayer.showNotification('~r~Nie masz uprawnień policyjnych!~s~')
    end
end)

RegisterNetEvent('esx_sluzba:setDuty')
AddEventHandler('esx_sluzba:setDuty', function(state)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if state then
        xPlayer.setJob('police', 0)
        Player(source).state:set('policeDuty', true, true)
        xPlayer.addWeapon('WEAPON_COMBATPISTOL', 150)
        xPlayer.addWeapon('WEAPON_NIGHTSTICK', 1)
        xPlayer.addWeapon('WEAPON_FLASHLIGHT', 1)
        xPlayer.addWeapon('WEAPON_STUNGUN', 1)
        pcall(function() xPlayer.addInventoryItem('handcuffs', 1) end)
        xPlayer.showNotification('Rozpocząłeś ~b~służbę~s~. Wydano ekwipunek.')
    else
        Player(source).state:set('policeDuty', false, true)
        xPlayer.setJob('unemployed', 0)
        xPlayer.removeWeapon('WEAPON_COMBATPISTOL')
        xPlayer.removeWeapon('WEAPON_NIGHTSTICK')
        xPlayer.removeWeapon('WEAPON_FLASHLIGHT')
        xPlayer.removeWeapon('WEAPON_STUNGUN')
        pcall(function() xPlayer.removeInventoryItem('handcuffs', 1) end)
        xPlayer.showNotification('Zakończyłeś ~r~służbę~s~. Zwrócono sprzęt.')
    end
end)