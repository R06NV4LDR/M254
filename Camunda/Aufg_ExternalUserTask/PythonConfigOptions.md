
# External Task Client – Konfigurationsoptionen (Python)

Dieses Dokument beschreibt die Konfigurationsoptionen eines External Task Workers in Python für die Integration mit Camunda BPM.

## Beispielkonfiguration

```python
default_config = {
    "maxTasks": 1,
    "lockDuration": 10000,
    "asyncResponseTimeout": 5000,
    "retries": 3,
    "retryTimeout": 5000,
    "sleepSeconds": 30
}
```

## Erklärung der Optionen

| Option                 | Beschreibung |
|------------------------|--------------|
| **`maxTasks`**         | Anzahl der Aufgaben, die der Worker gleichzeitig verarbeiten darf. <br>**Beispiel:** `1` = Nur eine Aufgabe gleichzeitig. |
| **`lockDuration`**     | Zeit (in Millisekunden), wie lange eine Aufgabe für diesen Worker gesperrt ist. <br>**Beispiel:** `10000` = 10 Sekunden Sperre. |
| **`asyncResponseTimeout`** | Wartezeit beim Long Polling, bevor ein neuer Request gestartet wird. Spart Ressourcen bei leerer Warteschlange. <br>**Beispiel:** `5000` = 5 Sekunden. |
| **`retries`**          | Anzahl automatischer Wiederholungsversuche bei Fehlern. <br>**Beispiel:** `3` = Drei Versuche vor endgültigem Fehlschlag. |
| **`retryTimeout`**     | Wartezeit (in Millisekunden) bis zur nächsten Wiederholung bei einem Fehler. <br>**Beispiel:** `5000` = 5 Sekunden Pause zwischen Retries. |
| **`sleepSeconds`**     | Pause in Sekunden, wenn keine Aufgaben verfügbar sind. <br>**Beispiel:** `30` = 30 Sekunden warten, bevor erneut nach Aufgaben gefragt wird. |

## Ablauf im Hintergrund

1. Der Worker registriert sich auf einen Topic (z. B. `"GenerateWords"`).
2. Er fragt regelmäßig Camunda nach neuen Aufgaben.
3. Wird eine Aufgabe gefunden, wird sie für die Dauer von `lockDuration` gesperrt.
4. Die Verarbeitung erfolgt über eine Handler-Funktion.
5. Bei Fehlern wird je nach `retries`- und `retryTimeout`-Konfiguration ein erneuter Versuch gestartet.
6. Wenn keine Aufgaben verfügbar sind, greift die Kombination aus `asyncResponseTimeout` und `sleepSeconds`, um Systemressourcen zu schonen.

## Weiterführende Links

- [Offizielle Camunda-Dokumentation zur Fehlerbehandlung in BPMN](https://docs.camunda.org/manual/7.21/reference/bpmn20/events/error-events/)
- [Camunda External Task Client Python (GitHub)](https://github.com/camunda-community-hub/camunda-external-task-client-python3)
