fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "hunterXhunter"
description "hunting job"
author "daiguel"
version "1.0.0"

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'config.lua',
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server/*.lua'
	
}

dependencies {
	'ox_lib',
	'ox_inventory',
	'ox_target',
	'es_extended'
}