local ox_inventory = exports.ox_inventory

RegisterNetEvent('hunterXhunter:sellItem')
AddEventHandler('hunterXhunter:sellItem', function(itemName, amount, price)
	ox_inventory:RemoveItem(source, itemName, amount)
	local amountToPay = amount * price
	ox_inventory:AddItem(source, 'money', amountToPay, nil, nil, function(success, reason)
			if success then
				TriggerClientEvent('ox_lib:notify', source, {
					type = 'success',
					description = locale("items_sold")..amount..locale("items_count")..itemName
				})
				--TODO push them out before deleting
			else
				TriggerClientEvent('ox_lib:notify', source, {
					type = 'error',
					description = reason
				})
			end
		end)
end)