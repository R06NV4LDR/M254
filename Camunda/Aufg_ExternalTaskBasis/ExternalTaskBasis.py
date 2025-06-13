# Beispiel übernommen aus https://github.com/camunda-community-hub/camunda-external-task-client-python3
# Betreffend Fehlerbehandlung: siehe https://docs.camunda.org/manual/7.21/reference/bpmn20/events/error-events/

from camunda.external_task.external_task import ExternalTask, TaskResult
from camunda.external_task.external_task_worker import ExternalTaskWorker


# configuration for the Client
default_config = {
    "maxTasks": 1,
    "lockDuration": 10000,
    "asyncResponseTimeout": 5000,
    "retries": 3,
    "retryTimeout": 5000,
    "sleepSeconds": 30
}


def handle_task(task: ExternalTask) -> TaskResult:
    print(f"TaskID ist {task.get_task_id()}")

    vorgabe = task.get_variable("vorgabe")
    print(f"***** Vorgabe '{vorgabe}' wurde vorgegeben")

    return task.complete({"success": True, "ResultText": f"Gestartet mit Vorgabe '{vorgabe}'."}) 
        
if __name__ == '__main__':
   ExternalTaskWorker(worker_id="1", config=default_config).subscribe("EinfacherExternerTaskhandler", handle_task)