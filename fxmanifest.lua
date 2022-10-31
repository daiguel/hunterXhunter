fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "hunterXhunter"
description "hunting job"
author "daiguel"
version "1.0.5"

shared_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'@ox_lib/init.lua',
	'locales/*.lua',	
	'config.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
	
}

dependencies {
	'ox_lib',
	'ox_inventory',
	'ox_target',
	'es_extended'
}