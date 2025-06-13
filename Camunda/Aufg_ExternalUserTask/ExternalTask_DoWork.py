# Beispiel übernommen aus https://github.com/camunda-community-hub/camunda-external-task-client-python3
# Betreffend Fehlerbehandlung: siehe https://docs.camunda.org/manual/7.21/reference/bpmn20/events/error-events/

import random
import requests
from camunda.external_task.external_task import ExternalTask, TaskResult
from camunda.external_task.external_task_worker import ExternalTaskWorker

VORGABE_COMPLETE = 1
VORGABE_BPMN_ERROR = 2
VORGABE_FAILURE = 3
VORGABE_EXCEPTION = 4
# VORGABE_LOOP = negative Zahl 

# configuration for the Client
default_config = {
    "maxTasks": 1,
    "lockDuration": 10000,
    "asyncResponseTimeout": 5000,
    "retries": 3,
    "retryTimeout": 5000,
    "sleepSeconds": 30
}


def printInLoop(task: ExternalTask, loopCount: int) -> TaskResult:
    i = 0
    try:
        for i in range(loopCount):
            print(f"External Task Durchlauf {i:>6}")
            dummy = task.get_variable("vorgabe") # damit festgestellt werden kann, ob Task noch verfügbar ist
        print(f"Schleife {i} durchlaufen. Erfolgreich beendet.") 
        return task.complete({"success": True, "ResultText": "Schleife erfolgreich beendet."}) 
    except requests.exceptions.HTTPError as e:
        print(f"Schleife nur {i} durchlaufen.") 
        # Prüfen, ob es sich um eine 404 (Not Found) oder eine 409 (Conflict) handelt
        if e.response.status_code == 404:
            print("Task wurde abgebrochen oder bereits verarbeitet.")
        elif e.response.status_code == 409:
            print("Task ist bereits gesperrt oder wurde verarbeitet.")
        else:
            print(f"HTTP-Fehler aufgetreten: {e}")
        
        # Task als fehlgeschlagen markieren, wenn er abgebrochen wurde
        return task.failure("Task abgebrochen", f"HTTP-Fehler: {e}", retries=0)
    except Exception as e:
        print("*** Exception aufgetreten ***")
        print(e)        

def handle_task(task: ExternalTask) -> TaskResult:
    vorgabe = task.get_variable("vorgabe")
    if vorgabe == None: # Bei keiner Vorgabe wird zufällig eine Verarbeitung gewählt
        vorgabe = random.randint(1, 4)
        print(f"TaskID ist {task.get_task_id()}: zufallszahl={vorgabe}")

    try:
        vorgabe = int(vorgabe)
    except:
        print(f"*** Ungültiger Inhalt in 'vorgabe': {vorgabe} ")
        return task.failure(error_message="vorgabe nicht numerisch",  error_details="Die Variable 'vorgabe' benötigt einen numerischen Inhalt.", 
                            max_retries=0, retry_timeout=0)
    
    if vorgabe == VORGABE_COMPLETE:  # Das wäre der positive Fall. Alles bestens
        # Alles bestens: Wir können Variablenwerte zurückgeben, wenn wir möchten
        return task.complete({"success": True, "ResultText": "Das ist mal gutgegangen"}) 
    elif vorgabe == VORGABE_BPMN_ERROR:  # Wir erzeugen einen BPMN-Fehler
        return task.bpmn_error(error_code="BPMN_ERROR_CODE", error_message="BPMN Error occurred", 
                                variables={"ZusatzMsg": "Hier könnte zusätzliche Info zum Fehler stehen", "success": False})
    elif vorgabe == VORGABE_FAILURE:
        # Der Task wird Camunda als "fehlerhaft beendet" zurückgemeldet
        print(f"*** Sauberer Fehler aufgetreten")
        return task.failure(error_message="task failed",  error_details="failed task details", 
                            max_retries=2, retry_timeout=2000)
    elif vorgabe == VORGABE_EXCEPTION:
        # Der Task endet unsauber mit einer nicht behandelten Exception
        print(f"***** Unsauberer Fehler aufgetreten")
        raise Exception("***** Unsauberer Fehler wird geworfen *****")
    elif vorgabe < 0:  
        # Negative Werte erzeugen Schleifendurchläufe
        durchgaenge = vorgabe * -1;
        # Der Task zählt in einer Schlaufe hoch bis zur übergebenen Zahl.
        # Dies ermöglicht es, an den Task angeheftete Ereignisse zu testen 
        printInLoop(task, durchgaenge)
    else:
        print(f"***** Für die Vorgabe '{vorgabe}' existiert keine Implementation")
        return task.complete({"success": False, "ResultText": f"Keine Implementation für die Vorgabe '{vorgabe}'."}) 
        

if __name__ == '__main__':
   ExternalTaskWorker(worker_id="1", config=default_config).subscribe("SetzeVariablenTopic", handle_task)