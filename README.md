# NodeZero-Config-Script

## Usage
Das Script kann in zwei Modi verwendet werden. Einmal im argument-based und config-based Modus. 
Der argument-modus wird über die Flag `-h` erklärt.

Für den config-based Modus legt man eine Config Datei mit den geforderten Variablen an:
```env
SID="UJ"
DOMAIN="ujima.de"
TOKEN="<xpliccittrust token here>"
NODEZERO_APIKEY="<API-Key from the Console>"
```
Das laden der Datei geht über den Befehl:
```bash
./configure-vm.sh -f ~/config.env
```

> **WICHTIG:**
> Für diesen Modus muss die Datei mit SCP herüber kopiert werden:
> `scp [path/to/config] nodezero@192.168.178.70:/home/nodezero/NodeZero-Config-Script/config.env`

Sollte irgendwas schief gehen gibt es für jede Ausführung des Scripts ein Logfile mit dem Zeitstempel der Ausführung im `.logs` Ordner des lokalen Git-Repository
## Setup

### Fix Keyboard Layout
Das Default Keyboard layout ist Amerikanisch und deswegen ändern wir das zu Deutsch. Dazu muss die `keyboard` Datei  modifiziert werden:
1. `sudo nano /etc/default/keyboard`
2. Ändern der Zeile `XKBLAYOUT="us"` zu `XKBLAYOUT="de"`
3. Neustarten der VM

### Setup DNS Resolving
Damit die VM auch Hostnames auflösen kann, müssen wir einen DNS Server konfigurieren. Ich habe mich für den Cloudflare DNS Server (1.1.1.1) entschieden:
```bash
sudo systemd-resolve --set-dns=1.1.1.1 --set-domain=~. --interface=[Netzwerk Interface]

# Beispiel:
sudo systemd-resolve --set-dns=1.1.1.1 --set-domain=~. --interface=eth0
```

### Setup RSA Keys and Auth
Um das Konfigurationsscript nutzen zu können, müssen einige kleine Vorarbeiten getätigt werden.
Zuerst muss in der VM ein RSA Key Pair angelegt werden. Dieses wird benötigt um einen Zugang zum Git Projekt zu erhalten:
```bash
ssh-keygen -b 4096 -N ""  # Das erstellt ein Keypair mit 4096 Bit Schlüssellänge und keinem extra Passwort.
``` 
>**WICHTIG:**
> Damit das kopieren des keys geht, müssen wir einen Workaround konfigurieren, da copy paste mit xclip nur bei einem laufenden X-Server geht (also mit einer GUI)

Wir müssen im selben Netzwerksegment wie die VM sein und dann die IP der VM haben. Nun kopieren wir den public key mit scp:
```bash
scp nodezero@[IP-Adress]:/home/nodezero/.ssh/id_rsa.pub .
```
Dieser Public Key muss nun für die Github Account admin_ujima hinterlegt werden, damit die VM sich das Repository herunterladen bzw. updaten kann.
Dazu geht man in die Account Einstellungen und dann auf "SSH and GPG Keys". Dort pasted man die kopierten public key and clickt auf hinzufügen.

### Clonen des Repositorys
Wir können das Repository nun auf der Nodezero VM clonen, da es nicht möglich einfach zu copy paste gibt es hier wieder ein SSH Workaround.
1. Brauchen wir den SSH Clone Link: "git@github.com:admin-ujima/NodeZero-Config-Script.git"
2. Nun müssen wir den Command dazu copieren bzw einfach über ssh ausführen:
```bash
ssh nodezero@[IP-Adress] "echo 'git clone git@github.com:admin-ujima/NodeZero-Config-Script.git' > ~/command-git.txt"
```
3. Jetzt müssen wir das Repo mit dem Command clonen:
```bash
cat ~/command-git.txt | bash
```
