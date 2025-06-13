# Externen Task einbinden
-------------------------

## Aufgabenstellung

Was bei einem bestimmten Task zu tun ist, soll in einem Python-Skript definiert werden. Anstelle dass also Camunda die Abarbeitung eines Tasks übernimmt, soll ein Python-Skript die Verarbeitung übernehmen.

## Angaben zur Lösung

**Voraussetzung**

- Python muss installiert sein
- "camunda-external-task-client-python3" muss installiert sein
(```pip install camunda-external-task-client-python3```)

**Vorgehen**

1) BPMN deployen
2) Python-Skript starten
3) Prozess starten. Das Ergebnis ist abhängig von einer Zufallszahl. Alternativ kann eine Variable "vorgabe" gesetzt werden.


## Signal für Abbruch des Hochzählens

Während der Service aktiv ist, kann mit einem Signal diese Verarbeitung abgebrochen werden (attached interrupting event): 
``` cmd
curl -X "POST" "http://localhost:8080/engine-rest/signal" -H "accept: */*" -H "Content-Type: application/json" -d "{ \"name\": \"StopCountingSignal\" } "
```

Dem Signal können auch Werte mitgegeben werden:
``` cmd
curl -X 'POST' 'http://localhost:8080/engine-rest/signal' -H 'accept: */*' -H 'Content-Type: application/json' -d '{ "name": "StopCountingSignal", "variables": { "neueVorgabe": { "value": 1 }, "Abbruchmeldung": { "value": "Hochzaehlen wurde durch Signal abgebrochen" } } '
```

## Konfigurationsoptionen

Im Python-Skript wird eine Variable **default_config** verwendet. 
Die Bedeutung der Optionen finden Sie [hier](PythonConfigOptions.md) beschrieben.