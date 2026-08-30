fx_version 'cerulean'
game 'gta5'

name 'bs-population'
author 'Blackstone Development'
description 'Dynamic ambient population control with time profiles, regional density, peak traffic, nightlife, and debugging tools.'
version '1.5.0'

lua54 'yes'

shared_script 'config.lua'
client_script 'client.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
