# Luup-Daily-Energy-Cost-Monitor

# Scope

This is a Luup plugin to record your daily KwH usage and it's associated cost

Luup (Lua-UPnP) is a software engine which incorporates Lua, a popular scripting language, and UPnP, the industry standard way to control devices. Luup is the basis of a number of home automation controllers e.g. Micasaverde Vera, Vera Home Control, OpenLuup.

# Compatibility

This plug-in has been tested on the Ezlo Vera Home Control system.

# Features

It supports the following functions:

* Creation a device in the UI that show how much your electricity usage is costing you today
* Updates variables whenever your KwH usage changes
* Keeps a historical log in http://IP_address/DailyUsage.txt

Still to be added..

* Leverage the log to show your trend of usage in the UI
* Merging with the other Monthly and Weekly Energy Cost Monitor version
* other fixes/updates

# Imstallation / Usage

This installation assumes you are running the latest version of Vera software.

1. Upload the image .pngs file to the appropriate storage location on your controller. For Vera that's `/www/cmh/skins/default/icons`
2. Upload the .xml and .json file in the repository to the appropriate storage location on your controller. For Vera that's via `Apps/Develop Apps/Luup files/`
3. Create the decice instance via the appropriate route. For Vera that's `Apps/Develop Apps/Create Device` and enter "D_ECMDaily1.xml" into the Upnp Device Filename box. 
4. Reload luup to establish the device, your first load should create an error, as certain key attributes/variables will be missing..
5. To set it up correct;ly, access the device and update the `cost per KwH` varaible (e.g. put `0.264` if 26.4p per KwH) , `charge per day` variable (e.g. put `0.22` if 22p per day) and the `Energy Meter` variable, which can either be the URL of a remote device that can return a KwH value (e.g http://192.168.1.234:3480/data_request?id=variableget&DeviceNum=431&serviceId=urn:micasaverde-com:serviceId:EnergyMetering1&Variable=KWH) or the device ID of a local energy meter you have registered on your controller e.g `123` - Note - the latter configuration has not been tested yet..
6. Reload luup again (just to be sure) and check the plugin status variable for your success or failure - if all is ok, you should be good to go :-)

Due to some challanges getting the luup.timer to work, i've not been able to sucessfully set up an period updates and archiving, so you will need to create a couple of scenes (i) to set the frequency of KwH checks/updates during the day and (ii) to reset and log your daily usage report at the end of each day.

Enter the start a new day luup code in your function - (change 1139 to your DeviceID)
````
ECMdaily = require("L_ECMDaily1") 
ECMdaily.startNewDay(1139)
````
To carry out a KwH usage update, here's the luup code for that (remember to change 1139 to your DeviceID)
````
ECMdaily = require("L_ECMDaily1") 
ECMdaily.updateDaySoFar(1139) 
````

# Limitations

While it has been tested, it has not been tested very much and may not support other related devices or those running different firmware.

# Buy me a coffee

If you choose to use/customise or just like this plug-in, feel free to say thanks with a coffee or two.. 
(God knows I drank enough working on this :-)) 

<a href="https://www.paypal.me/nodezero" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

# Screenshots

Once installed, you should see the device listed with your energy cost so far today

![F8B3C7D1-0188-4DB8-ADC5-426A514F4EA0](https://user-images.githubusercontent.com/4349292/148679688-6a56d7b3-c029-445b-81b5-c44ddfd09510.jpeg)

# License

Copyright © 2021 Chris Parker (nodecentral)
