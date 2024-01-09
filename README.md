# NodeZero-Config-Script

## Usage
Das Script kann in zwei Modi verwendet werden. Einmal im argument-based und config-based Modus. 
Der argument-modus wird über die Flag `-h` erklärt.

Für den config-based Modus legt man eine Config Datei mit den geforderten Variablen an:
```env
SID="UJ"
DOMAIN="ujima.de"
TOKEN="<xpliccittrust token here>"
```
Das laden der Datei geht über den Befehl:
```bash
sudo ./configure-vm.sh -f ~/config.env
```
