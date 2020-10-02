# esx_roubarcarros

List "stolen" vehicles in esx_drp_garage

Client:
```lua
-- View Vehicle Listings
function ListVehiclesMenu()
    local elements = {}
            
            ESX.TriggerServerCallback('eden_garage:getVehiclesRoubados', function(vehicles)
            for _, v in pairs(vehicles) do
                local hashVehicule = v.vehicle.model
                local vehicleName = GetDisplayNameFromVehicleModel(hashVehicule)
                local labelvehicle
    
                if (v.plate) then
                    labelvehicle = _U('status_roubado', GetLabelText(vehicleName)..' ['..v.vehicle.plate..']')
                else
                    --labelvehicle = _U('status_impounded', GetLabelText(vehicleName)..' ['..v.vehicle.plate..']')
                end
    
                table.insert(elements, {
                    label = labelvehicle,
                    value = v
                })
            end
```

Server
```lua
ESX.RegisterServerCallback('eden_garage:getVehiclesRoubados', function(source, cb)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local vehiculesImp = {}

    MySQL.Async.fetchAll('SELECT * FROM carros_roubados WHERE owner=@identifier', {
        ['@identifier'] = xPlayer.getIdentifier()
    }, function(data)
        for _, v in pairs(data) do
            local vehicle = json.decode(v.vehicle)

            table.insert(vehiculesImp, {
                vehicle = vehicle,
                plate = v.plate
            })
        end

        cb(vehiculesImp)
    end)
end)
```
