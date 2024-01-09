# Insert your Long-Lived Access Token (LLAT) here. LLATs can be generated at the bottom of your profile page in HA.
$Token = '<INSERT LLAT HERE>'

# The server:port of your HA instance
$HAServer = 'raspberrypi.local:8123'

# Time to sleep in milliseconds before checking for sensor updates
$SleepTime = 100

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

<# *************************************** #>
<# ***** NO MORE UPDATES BEYOND HERE ***** #>
<# *************************************** #>

Add-Member -InputObject $Sensors -MemberType ScriptMethod -Name FindSensor -Value { param([String]$Column) $this | ? { $_.HASensor -eq $Column }  }

$APIURI = "ws://$($HAServer)/api/websocket"
$RegBasePath = 'HKCU:\Software\HWiNFO64\Sensors\Custom'

$BufferSize = 1024
$BufferSizeInitial = $BufferSize * $Sensors.Length
$BufferArray = $([Byte[]]::CreateInstance([Byte], $BufferSizeInitial))
$Buffer = New-Object System.ArraySegment[Byte] -ArgumentList @(,$BufferArray)

function Receive-Message {
    param (
        [System.Net.WebSockets.ClientWebSocket]$WebSocket,
        [System.Threading.CancellationToken]$CancellationToken
    )

    $Buffer.Array.Clear()
    $Conn = $WS.ReceiveAsync($Buffer, $CT)
    while (!$Conn.IsCompleted) {
        Start-Sleep -Milliseconds $SleepTime
    }

    return [System.Text.Encoding]::UTF8.GetString($Buffer.Array).trim([char]0x0000)  | ConvertFrom-Json
}

function Send-Message {
    param (
        [System.Net.WebSockets.ClientWebSocket]$WebSocket,
        [System.Threading.CancellationToken]$CancellationToken,
        [Hashtable]$HashtableMessage
    )

    $JSONMessage = [System.Text.Encoding]::UTF8.GetBytes($($HashtableMessage | ConvertTo-Json))
    $ByteMessage = New-Object System.ArraySegment[byte] -ArgumentList @(,$JSONMessage)
        
    $Conn = $WebSocket.SendAsync($ByteMessage, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $CT)
    while (!$Conn.IsCompleted) {
        Start-Sleep -Milliseconds $SleepTime
    }
}

function Update-SensorValues {
    param (
        [String]$SensorName,
        $SensorState
    )

    $Sensor = $Sensors.FindSensor($SensorName)
    $SensorPath = "$($RegBasePath)\$($Sensor.HWIDeviceName)\$($Sensor.Type)"

    if (!(Test-Path $SensorPath)) {
        New-Item -Path $SensorPath -Force
    }

    New-ItemProperty -Force -Path $SensorPath -Name Name -Value $Sensor.Name -PropertyType String > $null

    if (!([string]::IsNullOrEmpty($Sensor.Value))) {
        $SensorState = $Sensor.Value.replace('VALUE', $SensorState)
    }
    New-ItemProperty -Force -Path $SensorPath -Name Value -Value $SensorState -PropertyType $Sensor.PropertyType > $null
        

    if (!([string]::IsNullOrEmpty($Sensor.Unit))) {
        New-ItemProperty -Force -Path $SensorPath -Name Unit -Value $Sensor.Unit -PropertyType String > $null
    }
}

function Connect-HAInstance {
    param (
        [System.Net.WebSockets.ClientWebSocket] $WebSocket,
        [System.Threading.CancellationToken] $CancellationToken
    )

    # Initial WS connection
    $Conn = $WS.ConnectAsync($APIURI, $CT)
    while (!$Conn.IsCompleted) {
        Start-Sleep -Milliseconds $SleepTime
    }

    # Get our authentication required message
    Receive-Message $WS $CT

    $AuthMessage = @{
        type = "auth"
        access_token = "$($Token)"
    }

    # Authenticate with HA
    Send-Message $WS $CT $AuthMessage
    
    # Receive our auth OK
    Receive-Message $WS $CT

    $entities = @()
    foreach ($sensor in $sensors) {
        $entities += $sensor.HASensor
    }

    $SubscribeMessage = @{
        id = 1
        type = "subscribe_entities"
        entity_ids = $entities
    }   

    # Subscribe to our listed entities
    Send-Message $WS $CT $SubscribeMessage

    # Receive successful sub message
    Receive-Message $WS $CT
}

try {
    do {
        $WS = New-Object System.Net.WebSockets.ClientWebSocket
        $CT = New-Object System.Threading.CancellationToken
        
        Connect-HAInstance $WS $CT

        # Begin our sensor updates
        while ($WS.State -eq 'Open') {
            # Receive our sensor updates
            $Status = Receive-Message $WS $CT

            # event.c is the usual event updates. Sent for a single sensor at a time
            if ($Status.event.c) {
                $SensorName = $Status.event.c.PSObject.Properties.Name
                $SensorState = $Status.event.c.$SensorName.'+'.s

                Update-SensorValues $SensorName $SensorState
            }
            # event.a is the initial statuses of ALL sensors
            elseif ($Status.event.a) {
                foreach ($Sensor in $Status.event.a.PSObject.Properties.Name) {
                    $SensorName = $Sensor
                    $SensorState = $Status.event.a.$Sensor.s

                    Update-SensorValues $SensorName $SensorState
                }

                # After the event.a, singular sensor updates are sent instead (event.c). Resize the buffer.
                $BufferArray = $([Byte[]]::CreateInstance([Byte], $BufferSize))
                $Buffer = New-Object System.ArraySegment[Byte] -ArgumentList @(,$BufferArray)
            }
            
        }
    } until ($WS.State -ne 'Open')
} finally {
    if ($WS) {
        Write-Host "Closing websocket"
        $WS.Dispose()
    }
}
    
