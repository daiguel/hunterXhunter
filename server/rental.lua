local ox_inventory = exports.ox_inventory

lib.callback.register('hunterXhunter:removeMoney', function(source, amount)
	if  ox_inventory:GetItem(source, 'money', nil, true) > amount then
		ox_inventory:RemoveItem(source, 'money', amount)
		return true
	else
		TriggerClientEvent('ox_lib:notify', source, {
			type = 'error',
			description = "not enough cash, it cost's "..amount.."$"
		})
		return false
	end
    
end)

RegisterNetEvent('hunterXhunter:deleteCarAndRedeem')
AddEventHandler('hunterXhunter:deleteCarAndRedeem', function(vehNetId, amount)
	local veh = NetworkGetEntityFromNetworkId(vehNetId)
	if DoesEntityExist(veh) then
		ox_inventory:AddItem(source, 'money', amount, nil, nil, function(success, reason)
			if success then
				TriggerClientEvent('ox_lib:notify', source, {
					type = 'success',
					description = "redeemed successfully"
				})
				--TODO push them out before deleting
					DeleteEntity(veh)
			else
				TriggerClientEvent('ox_lib:notify', source, {
					type = 'error',
					description = reason
				})
			end
		end)
	end

end)