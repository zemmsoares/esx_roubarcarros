ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand('impound', function(source, args)
  TriggerClientEvent('esx_roubarcarro:impound_nearest_vehicle', source)
end)

ESX.RegisterServerCallback('esx_roubarcarro:impound_vehicle', function(source, cb, plate)
  ImpoundVehicle(plate)
  cb()
end)

ESX.RegisterServerCallback('esx_roubarcarro:retrieve_vehicle', function(source, cb, plate)
  RetrieveVehicle(plate)
  cb()
end)

ESX.RegisterServerCallback('esx_roubarcarro:get_vehicle_list', function(source, cb)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local vehicles = {}

  MySQL.Async.fetchAll("SELECT * FROM carros_roubados",{['@identifier'] = xPlayer.getIdentifier()}, function(data)
    for _,v in pairs(data) do
      local vehicle = json.decode(v.vehicle)
      table.insert(vehicles, {vehicle = vehicle, stored = v.stored, can_release = VehicleEligableForRelease(v)})
    end
    cb(vehicles)
  end)
end)

ESX.RegisterServerCallback('esx_roubarcarro:check_money', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)

  if xPlayer.get('money') >= Config.ImpoundFineAmount then
    xPlayer.removeAccountMoney('bank', Config.ImpoundFineAmount)
    cb(true)
  else
    cb(false)
  end
end)

function ImpoundVehicle(plate)
  local current_time = os.time(os.date("!*t"))

  -- Retrieve vehicle data from garage
  if Config.OwnedVehiclesHasPlateColumn then
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate LIMIT 1', {
      ['@plate'] = plate
    }, function(vehicles)
      ProcessImpoundment(plate, current_time, vehicles)
    end)
  else
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE vehicle LIKE \'%"plate":"' .. plate .. '"%\' LIMIT 1', {}, function(vehicles)
      ProcessImpoundment(plate, current_time, vehicles)
    end)
  end

end

function ProcessImpoundment(plate, current_time, vehicles)
  for index, vehicle in pairs(vehicles) do
    -- Insert vehicle into impound table
    MySQL.Async.execute("INSERT INTO `carros_roubados` (`plate`, `vehicle`, `owner`, `impounded_at`,`tunerdata`) VALUES(@plate, @vehicle, @owner, @timestamp, @tunerdata)", {
      ['@plate'] = plate,
      ['@vehicle'] = vehicle.vehicle,
      ['@owner'] = vehicle.owner,
      ['@timestamp'] = current_time,
      ['@tunerdata'] = vehicle.tunerdata
    })

    -- Delete vehicle from garage
    MySQL.Async.execute("DELETE FROM owned_vehicles WHERE plate=@plate LIMIT 1", {['@plate'] = plate})
  end
end

function RetrieveVehicle(plate)

  -- Retrieve vehicle data from impound lot
  MySQL.Async.fetchAll('SELECT * FROM carros_roubados WHERE plate = @plate LIMIT 1', {
    ['@plate'] = plate
  }, function(vehicles)
    for index, vehicle in pairs(vehicles) do
      -- Insert vehicle into owned_vehicles table
      if Config.OwnedVehiclesHasPlateColumn then
        MySQL.Async.execute("INSERT INTO `owned_vehicles` (`plate`, `vehicle`, `owner`, `stored`, `tunerdata`) VALUES(@plate, @vehicle, @owner, '0', @tunerdata)",
          {
            ['@plate'] = plate,
            ['@vehicle'] = vehicle.vehicle,
            ['@owner'] = vehicle.owner,
            ['@tunerdata'] = vehicle.tunerdata
          }
        )
      else
        MySQL.Async.execute("INSERT INTO `owned_vehicles` (`vehicle`, `owner`, `stored`) VALUES(@vehicle, @owner, '0')",
          {
            ['@vehicle'] = vehicle.vehicle,
            ['@owner'] = vehicle.owner
          }
        )
      end
      -- Delete vehicle from Impound Lot
      MySQL.Async.execute("DELETE FROM carros_roubados WHERE plate=@plate LIMIT 1", {['@plate'] = plate})
    end
  end)
end

function VehicleEligableForRelease(vehicle)
  local current_time = os.time(os.date("!*t"))

  if Config.UserMustWaitElapsedTime then
    -- Determine the time the user could get their vehicle back and check if that time
    -- has expired
    if (vehicle.impounded_at + (Config.ElapsedTimeBeforeRelease * 60)) <= current_time then
      return true
    else
      return false
    end
  else
    return true
  end
end
