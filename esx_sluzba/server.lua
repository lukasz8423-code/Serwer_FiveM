local dutyWeapons = {
    'WEAPON_COMBATPISTOL',
    'WEAPON_NIGHTSTICK',
    'WEAPON_FLASHLIGHT',
    'WEAPON_STUNGUN'
}

local function getJob(xPlayer)
    if xPlayer.getJob then
        return xPlayer.getJob()
    end
    return xPlayer.job
end

local function giveDutyEquipment(xPlayer)
    for _, weaponName in ipairs(dutyWeapons) do
        if not xPlayer.hasWeapon(weaponName) then
            xPlayer.addWeapon(weaponName, 150)
        end
    end

    -- Kajdanki dodaj tylko wtedy, gdy gracz jeszcze ich nie ma.
    pcall(function()
        local cuffs = xPlayer.getInventoryItem('handcuffs')
        if not cuffs or (cuffs.count or 0) < 1 then
            xPlayer.addInventoryItem('handcuffs', 1)
        end
    end)
end

local function removeDutyEquipment(xPlayer)
    for _, weaponName in ipairs(dutyWeapons) do
        if xPlayer.hasWeapon(weaponName) then
            xPlayer.removeWeapon(weaponName)
        end
    end

    pcall(function()
        local cuffs = xPlayer.getInventoryItem('handcuffs')
        if cuffs and (cuffs.count or 0) > 0 then
            xPlayer.removeInventoryItem('handcuffs', 1)
        end
    end)
end

-- W tym serwerze praca POLICE jest stałą pracą postaci.
-- policeDuty określa wyłącznie, czy funkcjonariusz jest aktualnie na służbie.
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not xPlayer then return end

    local job = getJob(xPlayer)
    if job and job.name == 'police' then
        Player(playerId).state:set('policeDuty', true, true)
        giveDutyEquipment(xPlayer)

        -- Daj skinchangerowi i postaci czas na pełne załadowanie.
        SetTimeout(3000, function()
            if GetPlayerPing(playerId) > 0 then
                TriggerClientEvent('esx_sluzba:forceRestore', playerId)
            end
        end)

        TriggerClientEvent('esx:showNotification', playerId, 'Witaj na służbie, funkcjonariuszu!')
    end
end)

RegisterNetEvent('esx_sluzba:getEquipment')
AddEventHandler('esx_sluzba:getEquipment', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = getJob(xPlayer)
    local isOnDuty = Player(src).state.policeDuty == true
    if job and job.name == 'police' and isOnDuty then
        giveDutyEquipment(xPlayer)
        xPlayer.showNotification('~g~Uzupełniono wyposażenie służbowe.~s~')
    else
        xPlayer.showNotification('~r~Musisz być policjantem na służbie.~s~')
    end
end)

RegisterNetEvent('esx_sluzba:setDuty')
AddEventHandler('esx_sluzba:setDuty', function(state)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local deskCoords = vector3(441.79, -982.07, 30.69)
    if #(GetEntityCoords(ped) - deskCoords) > 4.0 then
        return
    end

    local job = getJob(xPlayer)
    if not job or job.name ~= 'police' then
        xPlayer.showNotification('~r~Nie masz przypisanej pracy policjanta.~s~')
        return
    end

    if state == true then
        Player(src).state:set('policeDuty', true, true)
        giveDutyEquipment(xPlayer)
        TriggerClientEvent('esx_sluzba:forceRestore', src)
        xPlayer.showNotification('Rozpocząłeś ~b~służbę~s~. Wydano wyposażenie.')
    else
        Player(src).state:set('policeDuty', false, true)
        removeDutyEquipment(xPlayer)
        TriggerClientEvent('esx_sluzba:dutyEnded', src)
        xPlayer.showNotification('Zakończyłeś ~r~służbę~s~. Zwrócono wyposażenie.')
    end
end)
