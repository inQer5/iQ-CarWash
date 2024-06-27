fx_version 'cerulean'
game 'gta5'

author 'inQer'
description 'Car Wash Script'
version '0.0.2'

shared_scripts {
  'config.lua',
  '@es_extended/imports.lua',
  'Locales/*.lua'
}

client_scripts {
    'Client/client.lua'
}
server_script 'Server/server.lua'

dependencies {
    'es_extended',
    'ox_lib'
}
