# What's in this resource
+ deers with horns will give you horns to sell /if deer without horns it does not give u anything - only deer gives horns
+ police get notifications and markers on map when illegally hunting / easy to configure custom notifications 
+ add/remove animals to be hunted in config.lua check this file too see the default animals set to hunt 
+ set as many legal hunting areas as you want 
+ add/remove license check to allow player to hunt (this will prevent player from slaughtering animal)
+ add/remove custom item(default knifes) needed to slaughter the animal
+ set custom prices for (meat, horns, leather, cost of rent )
+ impossible to duplicate animal, synced between clients, 
+ quantity of meat is initialized by first client and will not give more then the first initialized value even for another player
+ if an animal is caried, another player cannot carry the same animal 
+ can not slaughter when animal is carried
+ rent a 4X4 vehicle to charge hunted animal on and take it to slaughterer, get redeemed when vehicle is returned 
+ sell your goods 
+ illegal hunting can be done everywhere in the map
+ used ox_inventory Store to purchase items needed for hunt

# PREVIEW
- <a href="https://youtu.be/4BJ8PjH5P8A">preview</a>

# HOW TO install
+ drag and drop

# DEPENDCIES
 - <a href="https://github.com/ESX-Org/es_extended">es_extended</a>
 - <a href="https://github.com/ESX-Org/esx_license">esx_license</a> 
 - <a href="https://github.com/overextended/ox_inventory">ox_inventory</a>
 - <a href="https://github.com/overextended/ox_lib">ox_lib</a>
 - <a href="https://github.com/overextended/ox_target">ox_target</a>

# RASMON AT HIGHEST USAGE
![alt text](https://i.imgur.com/wJfWxNK.png "perfs") 

# 	OX_INVENTORY CONFIG
1. shop
```lua
    hutingShop = {
		name = 'HUNTING SHOP',
		blip = {
			id = 470, colour = 3, scale = 0.9
		}, inventory = {
			{ name = 'WEAPON_KNIFE', price = 1500, license = 'weapon'},--add other licenses here 
			{ name = 'WEAPON_DAGGER', price = 2000, license = 'weapon'},
			{ name = 'ammo-musket', price = 400, license = 'weapon' },
			{ name = 'WEAPON_MUSKET', price = 50000, metadata = { registered = true }, license = 'weapon' }, 
		}, locations = {
			vec3(562.3336, 2741.6128, 42.8688),
		}, targets = {
			{ loc = vec3(562.3336, 2741.6128, 42.8688), length = 0.6, width = 0.5, heading = 189.0, minZ = 42.5688, maxZ = 43.8688, distance = 3.0 },
		}
	},
```
2. ITEMS
```lua
	['leather'] = {
		label = 'leather',
		weight = 5000,
		stack = false,
		close = false,
		consume = 0
	},

	['meat'] = {
		label = 'meat',
		weight = 1000,
		stack = true,
		close = false,
		consume = 0
	},

	['a_c_deer_horns'] = {
		label = 'deer_horns',
		weight = 2500,
		stack = true,
		close = false,
		consume = 0
	},
```
## images used for items 
![alt text](https://i.imgur.com/T5CMwjB.png "MEAT") 
![alt text](https://i.imgur.com/25H7bys.png "leather") 
![alt text](https://i.imgur.com/kwdrzYs.png "DAGGER") 
![alt text](https://i.imgur.com/eVDPru6.png "HORNS")  