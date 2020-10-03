# esx_roubarcarros

Made a few changes to esx_impound to work as a carjack job.
We´re using this as job function, they hijack other player cars, drive them into the blip to impound,
then place the car plate on yellowpages or disco, so the owner can pay to get it back.

**The same would work for Police / Mecano impound** 

## esx_eden_garage
###### client.lua

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

###### server.lua
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

## Credits
@michaelhodgejr for esx_impound
