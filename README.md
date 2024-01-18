# HASS-2-HwInfo
A PowerShell script that imports Home Assistant sensors into HwInfo

![HASS-2-HwInfo](introimg.png)

This script will automatically create a websocket that connects to HASS and imports/updates values into HwInfo for further monitoring. I had a personal need to import wall power info into HwInfo for display in AquaSuite, but this should work for any numeric sensors that you want to display. I've left my personal settings in the settings as both defaults and examples on how the settings work (especially the sensors object).

## Considerations
Testing was done with the following versions:

* HwInfo 7.38-5300
    * Custom sensors were added to HwInfo in v6.1, so you'll need at least that for this to work.
* Home Assistant 2023.6.2
    * I'm pretty confident that the HASS WebSocket API is stable between releases. Please let me know if you have problems with earlier versions.
* PowerShell 5.1
    * I'm far from an expert in PS and the intricacies between versions, but I'm pretty sure 5.1 will be the absolute minimum needed to run.



## Installation
Before running the script, you will need to create a Long-Lived Access Token (LLAT) in Home Assistant. This can be done in your profile, at the bottom of the page.

![How to find LLAT](ha_llat.png)

Once you create it, note down the token. If you lose it, you will have to delete and create another one. There is no way to access a token after it is created.

Once you have that, you will need to edit the following variables in ```settings.ps1```:
* **$Token**
    * This is your LLAT created in HASS
* **$HAServer**
    * This is your server hostname/ip
* **$HAPort**
    * The server port
* **$SleepTime**
    * The amount of time in milliseconds the script sleeps between checks for updates. Default is 100ms and works well for me, but adjust as needed.
* **$EnableLogging**
    * Enables/disables logging. 1 = enabled, 0 = disabled. Enabled by default.
* **$LogType**
    * How to store logs. Set to 'Single' by default.
        * **Single**: Keeps a single log file that's cleared on each run.
        * **Appended**: Keeps a single log file that's appended to on each run.
        * **Multiple**: Creates a new, timestamped log file for each individual run.
* **$LogSensors**
    * Enable/disable the logging of each sensor update. This can quickly explode the size of the log file, and recommended to keep off unless debugging is needed.
* **$LogPrefix**
    * Prefix appended to each log file (or the log file base name if 'Single' or 'Appended' log type is selected).
* **$LogPath**
    * Where to store log files.
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
            How the sensor value registry key will be stored. See full details at https://www.hwinfo.com/forum/threads/custom-user-sensors-in-hwinfo.5817/. Available options and registry equivelants are:
            * **String**: REG_SZ (for decimal numbers)
            * **DWORD**: REG_DWORD (32-bit integers)
            * **QWORD**: REG_QWORD (64-bit integers)
        * **Unit**           
            (optional) When using an "Other" sensor type, how the units will be displayed in HwInfo
        * **Value**          
            (optional) Can define a formula here to modify base sensor values before displaying in HwInfo. Use "VALUE" to represent base value as shown in HASS.

After that, it should just be a matter of running the script with ```./h2h.ps1```. You might have to restart HwInfo after the first run to get the custom device and sensors to appear. This can also be scheduled to run on startup by setting up a Windows task in Task Scheduler with the following settings:
* Action: Start a program
* Program/script: powershell
* Add arguments: -file <path_to_file>/h2h.ps1
* Start in: <path_to_file>

You might also want to set a small delay on the triggers to wait for your machine to connect to the network before running.