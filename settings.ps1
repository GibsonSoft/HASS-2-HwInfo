# Insert your Long-Lived Access Token (LLAT) here. LLATs can be generated at the bottom of your profile page in HA.
$Token = '<INSERT LLAT HERE>'

# The server:port of your HA instance
$HAServer = 'raspberrypi.local:8123'

# Time to sleep in milliseconds before checking for sensor updates
$SleepTime = 100

# Enable/disable logging. 1 = enable, 0 = disable
$EnableLogging = 1

# Type of log. 'Single' for one log file, cleared on each run. 'Appended' for one log file, appended to on each run. 'Multiple' for multiple timestamped logs.
$LogType = 'Single'

# Enable logging of sensor updates. CAUTION: Can grow log files quickly!
$LogSensors = 0

# Prefix used for log files
$LogPrefix = 'h2h'

# Path to store log files
$LogPath = './h2h-logs'

<# 
    Define your sensors here.

    HWIDeviceName:  
        The name of the device your sensors will appear under in HwInfo
    Name:           
        The name of the sensor in HwInfo
    Type:           
        The type of sensor HwInfo will recognize as. Should have a unique # at the end per device. See full details at https://www.hwinfo.com/forum/threads/custom-user-sensors-in-hwinfo.5817/
    HASensor:       
        The sensor ID in HA
    PropertyType:   
        How the sensor value registry key will be stored. See full details at https://www.hwinfo.com/forum/threads/custom-user-sensors-in-hwinfo.5817/
    Unit:           
        (optional) When using an "Other" sensor type, how the units will be displayed in HwInfo
    Value:          
        (optional) Can define a formula here to modify base sensor value before displaying in HwInfo. Use "VALUE" to represent base value.
#>
$Sensors = @(
    @{HWIDeviceName='PC Power Usage'; Name='Active Power'; Type='Power0'; HASensor='sensor.travis_pc_outlet_active_power'; PropertyType='DWORD'},
    @{HWIDeviceName='PC Power Usage'; Name='RMS Voltage'; Type='Volt0'; HASensor='sensor.travis_pc_outlet_rms_voltage'; PropertyType='DWORD'},
    @{HWIDeviceName='PC Power Usage'; Name='RMS Current'; Type='Current0'; HASensor='sensor.travis_pc_outlet_rms_current'; PropertyType='String'},
    @{HWIDeviceName='PC Power Usage'; Name='AC Frequency'; Type='Other1'; HASensor='sensor.travis_pc_outlet_ac_frequency'; Unit='Hz'; PropertyType='DWORD'}
    @{HWIDeviceName='PC Power Usage'; Name='Power Factor'; Type='Usage0'; HASensor='sensor.travis_pc_outlet_power_factor'; Value='VALUE * 10'; PropertyType='String'},
    @{HWIDeviceName='PC Power Usage'; Name='Total Usage'; Type='Other0'; HASensor='sensor.travis_pc_outlet_summation_delivered'; Unit='kWh'; PropertyType='String'}
)