# Camunda External Task Handler - PowerShell Template
# Erforderliche Parameter
$CamundaEndpoint = "http://localhost:8080/engine-rest" # Camunda REST API URL
$WorkerId = "powershell-worker"                        # Worker-ID
$TopicName = "SetzeVariablenTopic"                     # Topic-Name für den externen Task
$FetchAndLockEndpoint = "$CamundaEndpoint/external-task/fetchAndLock"
$CompleteTaskEndpoint = "$CamundaEndpoint/external-task"


# Variablen für Vorgaben
$VORGABE_COMPLETE = 1
$VORGABE_BPMN_ERROR = 2
$VORGABE_FAILURE = 3
$VORGABE_EXCEPTION = 4
# VORGABE_LOOP = negative Zahl 

# Konfiguration für den Client
$default_config = @{
    maxTasks = 1                        # Maximale Anzahl von Tasks
    lockDuration = 10000                # Lockdauer in Millisekunden
    #asyncResponseTimeout = 5000 
    #retries = 3
    #retryTimeout = 5000
    sleepSeconds = 5
}

# Funktion: Schleifen ausgeben
function PrintInLoop {
    param (
        [object]$Task,
        [int]$LoopCount
    )
    $i = 0
    try {
        for ($i = 0; $i -lt $LoopCount; $i++) {
            Log ("External Task Durchlauf {0,6}" -f $i)
            $dummy = $Task.variables.vorgabe?.value # Überprüfung, ob Task verfügbar ist
        }
        Log ("Schleife {0} durchlaufen. Erfolgreich beendet." -f $i)
        Complete-Task -Task $Task -success $true -resultText "Schleife erfolgreich beendet."
    } catch [System.Net.Http.HttpRequestException] {
        Log ("Schleife nur {0} durchlaufen." -f $i)
        if ($_.Response.StatusCode -eq 404) {
            Log "Task wurde abgebrochen oder bereits verarbeitet."
        } elseif ($_.Response.StatusCode -eq 409) {
            Log "Task ist bereits gesperrt oder wurde verarbeitet."
        } else {
            Log ("HTTP-Fehler aufgetreten: {0}" -f $_)
        }
        Complete-Task -Task $Task -success $false -resultText "Task abgebrochen. HTTP-Fehler: $_"        
    } catch {
        Log "*** Exception aufgetreten ***"
        Log $_
    }
}

# Funktion: Task behandeln
function HandleTask {
    param (
        [object]$Task
    )
    $vorgabe = $Task.variables.vorgabe?.value
    if (-not $vorgabe) {
        # Zufällige Auswahl, falls keine Vorgabe vorhanden
        $vorgabe = Get-Random -Minimum 1 -Maximum 5
        Write-Host ("TaskID ist {0}: zufallszahl={1}" -f $Task.GetTaskId(), $vorgabe)
    }

    try {
        $vorgabe = [int]$vorgabe
    } catch {
        Log ("*** Ungültiger Inhalt in 'vorgabe': {0}" -f $vorgabe)
        Complete-Task -Task $Task -success $false -resultText "vorgabe nicht numerisch: Die Variable 'vorgabe' benötigt einen numerischen Inhalt."        
    }

    switch ($vorgabe) {
        $VORGABE_COMPLETE {
            # Erfolgreiche Verarbeitung
            Complete-Task -Task $task -success $true -resultText "Das ist mal gutgegangen"
            Log "Task abgeschlossen. Daten: $Task"
        }
        $VORGABE_BPMN_ERROR {
            # BPMN-Fehler erzeugen
            CompleteWithBpmnError-Task -Task $Task -bpmnErrorCode "BPMN_ERROR_CODE" -errorMessage "BPMN Error occurred" -zusatzMsg "Hier könnte zusätzliche Info zum Fehler stehen"
            Log "Task mit BPMN-Error abgeschlossen"
        }
        $VORGABE_FAILURE {
            # Fehlerhafter Abschluss
            Log "*** Sauberer Fehler aufgetreten"
            Complete-Task -Task $task -success $false -resultText "failed task details"
            Log "Task mit Failure abgeschlossen. Daten: $Task"
        }
        $VORGABE_EXCEPTION {
            # Nicht behandelter Fehler
            Log "***** Unsauberer Fehler aufgetreten"
            throw "***** Unsauberer Fehler wird geworfen *****"
        }
        { $_ -lt 0 } {
            # Schleifenverarbeitung bei negativen Werten
            $durchgaenge = -1 * $vorgabe
            PrintInLoop -Task $Task -LoopCount $durchgaenge
        }
        default {
            Log ("***** Für die Vorgabe '{0}' existiert keine Implementation" -f $vorgabe)
            Complete-Task -Task $task -success $false -resultText "Keine Implementation für die Vorgabe '$vorgabe'."
        }
    }
}


# Hilfsfunktion: Log-Ausgabe
function Log {
    param ([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

# Funktion: Fetch and Lock
function FetchAndLock-Task {
    $payload = @{
        workerId = $WorkerId
        maxTasks = $default_config.maxTasks
        topics = @(
            @{
                topicName = $TopicName
                lockDuration = $default_config.lockDuration
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $FetchAndLockEndpoint -Method Post -ContentType "application/json" -Body $payload
    return $response
}

# Funktion: Task abschließen
function Complete-Task {
    param ([object]$Task, [bool]$success, [string]$resultText)

    $TaskId = $Task.Id
    $outputVariables = @{    # Hashtable
        success = @{ value = $success; type = "Boolean"}
        ResultText = @{value = $resultText; type = "String"}
    }

    $payload = @{
        workerId = $WorkerId
        variables = $outputVariables
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "$CompleteTaskEndpoint/$TaskId/complete" -Method Post -ContentType "application/json" -Body $payload
    return $response
}

function CompleteWithBpmnError-Task {
    param ([object]$Task, [string]$bpmnErrorCode, [string]$errorMessage, [string]$zusatzMsg)

    $TaskId = $Task.Id
    $outputVariables = @{    # Hashtable
        success = @{ value = $false; type = "Boolean"}
        ZusatzMsg =  @{value = $zusatzMsg; type = "String"}
    }

    $payload = @{
        workerId = $WorkerId
        errorCode = $bpmnErrorCode
        errorMsg = $errorMessage        
        variables = $outputVariables
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "$CompleteTaskEndpoint/$TaskId/bpmnError" -Method Post -ContentType "application/json" -Body $payload
    return $response
}


# Main Loop
Log "Starte External Task Handler..."
while ($true) {
    try {
        $tasks = FetchAndLock-Task
        if ($tasks.Count -eq 0) {
            Log "Keine Tasks gefunden. Warte..."
            Start-Sleep -Seconds $default_config.sleepSeconds
                continue
        }

        foreach ($task in $tasks) {

            $taskId = $task.id
            Log "Task $taskId wird ausgeführt"

            HandleTask -Task $task

        }
    } catch {
        Log "Fehler: $_"
        Start-Sleep -Seconds 5
    }
}
