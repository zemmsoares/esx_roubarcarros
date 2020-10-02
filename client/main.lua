-- Local
local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
local HasAlreadyEnteredMarker   = false
local LastZone                  = nil
local PlayerData                = {}
local CurrentActionMsg          = ''
local CurrentActionData         = {}
local GUI                       = {}
local DrawnMapBlips             = {}
GUI.Time                        = 0
local currentImpoundLot					= nil
local playerIsLoaded            = false 
local currentJob                = 'unemployed'


Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end

  while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()
		
	if PlayerData.job.name == Config.JobName then
		mainblip = AddBlipForCoord(1430.28, 1117.25, 113.38)

		SetBlipSprite (mainblip, 67)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 0.8)
		SetBlipColour (mainblip, 1)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('CARRO ROUBADO')
		EndTextCommandSetBlipName(mainblip)
	end
		
	esxloaded = true
end)

AddEventHandler('esx_roubarcarro:checkjob', function()
	if PlayerData.job.name ~= Config.JobName then
		if mainblip ~= nil then
			RemoveBlip(mainblip)
			mainblip = nil
		end
	elseif mainblip == nil then
		mainblip = AddBlipForCoord(1430.28, 1117.25, 113.38)

		SetBlipSprite (mainblip, 67)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 0.8)
		SetBlipColour (mainblip, 1)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('MOTOCLUBE')
		EndTextCommandSetBlipName(mainblip)
	end
end)


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  playerIsLoaded = true
  currentJob = ESX.GetPlayerData().job.name
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(xPlayer)
  currentJob = ESX.GetPlayerData().job.name
end)

function drawImpoundLotMapBlips()
  local zones = {}
  local blipInfo = {}
    for zoneKey,zoneValues in pairs(Config.ImpoundLots)do
      local blip = AddBlipForCoord(zoneValues.Pos.x, zoneValues.Pos.y, zoneValues.Pos.z)
      SetBlipSprite (blip, Config.BlipInfos.Sprite)
      SetBlipDisplay(blip, 4)
      SetBlipScale  (blip, 0.8)
      SetBlipColour (blip, Config.BlipInfos.Color)
      SetBlipAsShortRange(blip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("GARAGEM CARROS ROUBADOS")
      EndTextCommandSetBlipName(blip)
      table.insert(DrawnMapBlips, blip)
    end
end

function deleteImpoundLotMapBlips()
  for index, blip in pairs(DrawnMapBlips) do
    RemoveBlip(blip)
  end
end

Citizen.CreateThread(function()
  local currentZone = 'impound_lot'
  while true do
    Wait(0)

    local coords      = GetEntityCoords(GetPlayerPed(-1))
    local isInMarker  = false

    for _,v in pairs(Config.ImpoundLots) do
      if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
        isInMarker  = true
        currentImpoundLot = v
      end
    end

    if isInMarker and not hasAlreadyEnteredMarker then
      hasAlreadyEnteredMarker = true
      LastZone                = currentZone
      TriggerEvent('esx_roubarcarro:hasEnteredMarker', currentZone)
    end

    if not isInMarker and hasAlreadyEnteredMarker then
      hasAlreadyEnteredMarker = false
      TriggerEvent('esx_roubarcarro:hasExitedMarker', LastZone)
    end
  end
end)


Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    if CurrentAction ~= nil then

      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)

      if IsControlPressed(0,  Keys['E']) and (GetGameTimer() - GUI.Time) > 150 then
        if CurrentAction == 'impound_lot_menu' then
          print(currentJob)
          if ESX.GetPlayerData().job.name == 'mafia' then
           OpenImpoundMenu()
          end
        end
        CurrentAction = nil
        GUI.Time      = GetGameTimer()
      end
    end
  end
end)

AddEventHandler('esx_roubarcarro:hasEnteredMarker', function(zone)
  if zone == 'impound_lot' and ESX.GetPlayerData().job.name == 'mafia' then
    CurrentAction     = 'impound_lot_menu'
    CurrentActionMsg  = "Pressina ~INPUT_PICKUP~ para guardar carro roubado"
    CurrentActionData = {}
  end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
  TriggerEvent('esx_roubarcarro:checkjob')
end)

AddEventHandler('esx_roubarcarro:hasExitedMarker', function(zone)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

RegisterNetEvent("esx_roubarcarro:impound_nearest_vehicle")
AddEventHandler("esx_roubarcarro:impound_nearest_vehicle", function(args)
  local coords = GetEntityCoords(GetPlayerPed(-1))
  local vehicle = GetClosestVehicle(coords['x'],  coords['y'],  coords['z'],  2.0,  0,  71)

  if DoesEntityExist(vehicle) then
    if hasImpoundAppropriateJob() then
      if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
        ESX.ShowNotification('You can not use /impound when in a vehicle.')
      else
        local vprops = ESX.Game.GetVehicleProperties(vehicle)
        local plate = vprops.plate

        ESX.TriggerServerCallback('esx_roubarcarro:impound_vehicle', function()
          ESX.ShowNotification('Vehicle has been impounded!')
          ESX.Game.DeleteVehicle(vehicle)
        end, plate)
      end
    else
      ESX.ShowNotification('You do not have permission to use this command.')
      end
    end

  end)

  function hasImpoundAppropriateJob()
    if not Config.RestrictImpoundToJobs then
      return true
    end

    if has_value(Config.JobsThatCanImpound, currentJob) then
      return true
    else
      return false
    end
  end

  function hasRetrievalAppropriateJob()
    if not Config.RestrictRetrievalToJobs then
      return true
    end

    if has_value(Config.JobsThatCanRetrieve, currentJob) then
      return true
    else
      return false
    end
  end

-- Display markers
Citizen.CreateThread(function()
  while true do

    Wait(0)

    if PlayerData.job ~= nil and PlayerData.job.name == 'mafia' then

      local playerPed = GetPlayerPed(-1)
      local coords    = GetEntityCoords(playerPed)
      DrawMarker(1, 1430.28, 1117.25, 113.38, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
    end

  end
end)

  function OpenImpoundMenu()
    local ply = GetPlayerPed(-1)

    ESX.UI.Menu.CloseAll()

    local elements = {
      {label = "Retrieve Vehicle", value = "retrieve_vehicle"}
    }

    if hasImpoundAppropriateJob() and IsPedInAnyVehicle(ply, true) then
      table.insert(elements, {label = "Impound Vehicle", value="impound_vehicle"})
    end

    ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'impound_menu',
    {
      title    = 'Carros Roubados',
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)
      menu.close()

      if(data.current.value == 'retrieve_vehicle') then
        ListVehiclesMenu()
      end

      if(data.current.value == 'impound_vehicle') then
        ImpoundCurrentVehicle()
      end
    end,
    function(data, menu)
      menu.close()
    end
  )
end

function ImpoundCurrentVehicle()
  local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
  local vprops = ESX.Game.GetVehicleProperties(vehicle)
  local plate = vprops.plate

  ESX.TriggerServerCallback('esx_roubarcarro:impound_vehicle', function()
    ESX.ShowNotification('Vehicle has been impounded!')
    ESX.Game.DeleteVehicle(vehicle)
  end, plate)
end

function ListVehiclesMenu()
  local elements = {}
  local elementPages = {}

  ESX.TriggerServerCallback('esx_roubarcarro:get_vehicle_list', function(vehicles)
    for _,v in pairs(vehicles) do
      local hashVehicule = v.vehicle.model
      local vehicleName = GetDisplayNameFromVehicleModel(hashVehicule)
      local vehicleProps = v.vehicle
      local vehiclePlate = vehicleProps.plate
      local vehClassFilter = {}
      local allowedVehicles = {}
      if currentImpoundLot.AllowedVehicles ~= nil then
        allowedVehicles = currentImpoundLot.AllowedVehicles
      end

      if currentImpoundLot.Type == nil or currentImpoundLot.Type == "impound_lot" then
        table.insert(vehClassFilter,0) --compacts
        table.insert(vehClassFilter,1) --sedans
        table.insert(vehClassFilter,2) --SUV's
        table.insert(vehClassFilter,3) --coupes
        table.insert(vehClassFilter,4) --muscle
        table.insert(vehClassFilter,5) --sport classic
        table.insert(vehClassFilter,6) --sport
        table.insert(vehClassFilter,7) --super
        table.insert(vehClassFilter,8) --motorcycle
        table.insert(vehClassFilter,9) --offroad
        table.insert(vehClassFilter,10) --industrial
        table.insert(vehClassFilter,11) --utility
        table.insert(vehClassFilter,12) --vans
        table.insert(vehClassFilter,13) --bicycles
        table.insert(vehClassFilter,17) --service
        table.insert(vehClassFilter,18) --emergency
        table.insert(vehClassFilter,19) --military
      end

      if currentImpoundLot.Type == "smallhanger" then
        table.insert(vehClassFilter, 16) --planes
      end

      if currentImpoundLot.Type == "helipad" then
        table.insert(vehClassFilter, 15) --helicopters
      end

      if currentImpoundLot.Type == "dock" then
        table.insert(vehClassFilter, 14) --boats
      end

      if has_value(vehClassFilter,GetVehicleClassFromName(vehicleName)) then
        if has_value(allowedVehicles,vehicleName:lower()) or tablelength(allowedVehicles) == 0 then
          local labelvehicle

          if v.can_release then
            if Config.UserMustPayFine then
              labelvehicle = vehicleName .. " - " .. vehiclePlate .. " $(".. Config.ImpoundFineAmount ..")"
            else
              labelvehicle = vehicleName .. " - " .. vehiclePlate
            end
            release_value = v
          else
            labelvehicle = vehicleName .. " - " .. vehiclePlate .. " - NOT ELIGABLE FOR RELEASE"
            release_value = 'ne'
          end
          table.insert(elements, {label = labelvehicle, value = release_value})
        end

        if tablelength(elements) >= 10 then
          table.insert(elementPages, elements)
          elements = {}
        end
      end
    end

    table.insert(elementPages, elements)
    loadListVehiclePage(elementPages, 1)
  end)
end

function loadListVehiclePage(elementPages, page)
  if page <= tablelength(elementPages) then
    local elements = {}
    if page > 1 then
      table.insert(elements, {label = "Previous Page", value = "pp"})
    end

    elements = mergeTables(elements,elementPages[page])

    if page < tablelength(elementPages) then
      table.insert(elements, {label = "Next Page", value = "np"})
    end


    ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'inpound_spawn_vehicle',
    {
      title    = 'Carros Roubados',
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)
      if data.current.value == "np" then
        page = page + 1
        loadListVehiclePage(elementPages,page)
      elseif data.current.value == "pp" then
        page = page - 1
        loadListVehiclePage(elementPages,page)
      elseif data.current.value == "ne" then
        menu.close()
        ESX.ShowNotification('This vehicle is not eligable for release')
      else
        menu.close()

        if Config.UserMustPayFine then
          ESX.TriggerServerCallback('esx_roubarcarro:check_money', function(paidFine)
            if paidFine then
              SpawnVehicle(data.current.value.vehicle)
            else
              ESX.ShowNotification('You do not have enough money to retrieve your vehicle.')
              end
            end)
          else
            SpawnVehicle(data.current.value.vehicle)
          end
        end
      end,
      function(data, menu)
        menu.close()
      end)
    end
  end

  function SpawnVehicle(vehicle)
    local heading = 120.0
    local plate = vehicle.plate

    if currentImpoundLot.RetrievePoint.Heading ~= nil then
      heading = currentImpoundLot.RetrievePoint.Heading
    end

    ESX.TriggerServerCallback('esx_roubarcarro:retrieve_vehicle', function()
      ESX.ShowNotification('Vehicle has been released!')
      CreateClientSideVehicle(vehicle)
    end, plate)

  end

  function CreateClientSideVehicle(vehicle)
    ESX.Game.SpawnVehicle(vehicle.model, {
      x = currentImpoundLot.RetrievePoint.Pos.x ,
      y = currentImpoundLot.RetrievePoint.Pos.y,
      z = currentImpoundLot.RetrievePoint.Pos.z + 1
    }, heading, function(callback_vehicle)
      ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
      SetVehicleNumberPlateText(callback_vehicle, vehicle.plate)
    end)
  end

  function has_value (tab, val)
    for index, value in ipairs(tab) do
      if value == val then
        return true
      end
    end

    return false
  end

  function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

  function mergeTables(t1, t2)
    for k,v in ipairs(t2) do
      table.insert(t1, v)
    end
    return t1
  end
