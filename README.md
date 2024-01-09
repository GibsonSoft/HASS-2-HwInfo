# HASS-2-HwInfo
A PowerShell script that imports Home Assistant sensors into HwInfo

![HASS-2-HwInfo](introimg.png)

This script will automatically create a websocket that connects to HASS and imports/updates values into HwInfo for further monitoring.

## Considerations
Testing was done with the following versions:

* HwInfo 7.38-5300
* Home Assistant 2023.6.2
* PowerShell 5.1

Custom sensors were added to HwInfo in v6.1.

## Installation
Before running the script, you will need to create a Long-Lived Access Token (LLAT) in Home Assistant. This can be done in your profile, at the bottom of the page.

![How to find LLAT](ha_llat.png)

Once you create it, note down the token. If you lose it, you will have to delete and create another one. There is no way to access a token after it is created.

Once you have that, you will need to edit the following variables in the beginning of the script:
* **$Token**
    * This is your LLAT created in HASS
* **$HAServer**
    * This is your server hostname/ip and port
* **$SleepTime**
    * The amount of time in milliseconds the script sleeps between checks for updates. Default is 100ms, but feel free to adjust as needed.
* **$Sensors**
    * This is where you will define how the sensors look in HwInfo. For each sensor, you will need to define the following:
        * **HWIDeviceName**   
             The name of the device your sensors will appear under in HwInfo
        * **Name**           
            The name of the sensor in HwInfo
        * **Type**           
            The type of sensor HwInfo will recognize as. Should have a unique # at the end per device. See full details at https://www.hwinfo.com/forum/threads/custom-user-sensors-in-hwinfo.5817/
        * **HASensor**       
            The sensor ID in HA
        * **PropertyType**  
            How the sensor value registry key will be stored. See full details at https://www.hwinfo.com/forum/threads/custom-user-sensors-in-hwinfo.5817/
        * **Unit**           
            (optional) When using an "Other" sensor type, how the units will be displayed in HwInfo
        * **Value**          
            (optional) Can define a formula here to modify base sensor values before displaying in HwInfo. Use "VALUE" to represent base value.

After that, it should just be a matter of running the script with ```./h2h.ps1```. This can also be scheduled to run on startup by setting up a Windows task in Task Scheduler with the following settings:
* Action: Start a program
* Program/script: powershell
* Add arguments: -file <path_to_file>/h2h.ps1
* Start in: <path_to_file>
