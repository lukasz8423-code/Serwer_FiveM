-- SPDX-License-Identifier: GPL-3.0-only
-- Police reception duty interaction, isolated from the main police job client.

local reception = vector3(441.2, -981.9, 30.6)
local interactionDistance = 2.0
local markerDistance = 20.0

CreateThread(function()
    print('[POLICEJOB] Reception duty client loaded')

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(coords - reception)

        if distance < markerDistance then
            sleep = 0

            DrawMarker(
                2,
                reception.x, reception.y, reception.z + 0.15,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.45, 0.45, 0.45,
                40, 120, 220, 220,
                false, true, 2, false, nil, nil, false
            )

            if distance < interactionDistance then
                local job = ESX.PlayerData and ESX.PlayerData.job
                local onDuty = LocalPlayer and LocalPlayer.state and LocalPlayer.state.policeDuty == true

                if job and job.name == 'police' and onDuty then
                    ESX.ShowHelpNotification('Naciśnij ~INPUT_CONTEXT~, aby zakończyć służbę')
                else
                    ESX.ShowHelpNotification('Naciśnij ~INPUT_CONTEXT~, aby rozpocząć służbę')
                end

                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('esx_policejob:toggleDuty')
                    Wait(750)
                end
            end
        end

        Wait(sleep)
    end
end)
