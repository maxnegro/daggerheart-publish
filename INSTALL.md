# Installazione e configurazione

Questa guida copre come installare e avviare `daggerheart-publish` su **Linux**, **macOS** e **Windows**, sia in modalità nativa che tramite Docker.

---

## Opzione A — Docker (tutti i sistemi operativi)

Docker è la via consigliata su qualsiasi piattaforma. Non richiede l'installazione locale di LaTeX o Pandoc.

### Prerequisiti

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) su Windows e macOS
- Docker Engine su Linux (es. `sudo apt install docker.io`)

### Build con Docker

```bash
./scripts/docker-build.sh ./books/example
```

Su Windows con PowerShell, usa lo script equivalente:

```powershell
.\scripts\docker-build.ps1 .\books\example
```

Se preferisci il prompt classico di Windows (`cmd.exe`), puoi usare anche:

```bat
scripts\docker-build.bat .\books\example
```

---

## Opzione B — Installazione nativa

### Linux

Testato su Ubuntu/Debian. Usa il package manager della tua distribuzione.

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y pandoc texlive-xetex texlive-latex-extra texlive-fonts-recommended texlive-pictures
```

**Fedora / RHEL:**

```bash
sudo dnf install -y pandoc texlive-xetex texlive-collection-latexextra
```

**Arch Linux:**

```bash
sudo pacman -S pandoc texlive-core texlive-latexextra
```

Poi esegui la build con:

```bash
./scripts/build.sh ./books/example
```

---

### macOS

Installa [Homebrew](https://brew.sh) se non è già presente, poi:

```bash
brew install pandoc
brew install --cask mactex-no-gui
```

> `mactex-no-gui` installa una distribuzione TeX Live completa (~4 GB). Per un'installazione più leggera, usa `basictex` e aggiungi i pacchetti necessari con `tlmgr`.

Dopo l'installazione, riavvia il terminale affinché `xelatex` sia disponibile nel PATH, poi:

```bash
./scripts/build.sh ./books/example
```

---

### Windows

Sono disponibili quattro approcci, in ordine di semplicità.

#### Opzione 1: Git Bash

Con [Git for Windows](https://git-scm.com/download/win) (include Git Bash):

1. Installa **Pandoc**:

   ```powershell
   winget install JohnMacFarlane.Pandoc
   ```

2. Installa **MiKTeX**:

   ```powershell
   winget install MiKTeX.MiKTeX
   ```

   Al primo utilizzo, MiKTeX installerà automaticamente i pacchetti LaTeX mancanti.

3. Apri **Git Bash** ed esegui:

   ```bash
   ./scripts/build.sh ./books/example
   ```

#### Opzione 2: WSL (Windows Subsystem for Linux)

Installa WSL con Ubuntu, poi segui le istruzioni per **Linux** qui sopra.

```powershell
wsl --install
```

#### Opzione 3: PowerShell nativo (senza Git Bash o WSL)

Con Pandoc e MiKTeX installati come sopra, usa lo script PowerShell incluso:

```powershell
.\scripts\build.ps1 .\books\example
```

Oppure da `cmd.exe`:

```bat
scripts\build.bat .\books\example
```

Con output esplicito:

```powershell
.\scripts\build.ps1 .\books\example dist\mio-libro.pdf
```

Da `cmd.exe`:

```bat
scripts\build.bat .\books\example dist\mio-libro.pdf
```

**Variabili d'ambiente** (sintassi PowerShell):

```powershell
$env:KEEP_WORKDIR = "1"   # conserva la cartella temporanea di build
$env:KEEP_TEX     = "1"   # conserva il file .tex generato
$env:ENABLE_TOC   = "0"   # disabilita il sommario automatico
$env:ASSETS_DIR   = "C:\percorso\assets"   # override cartella asset
```

Le stesse variabili da `cmd.exe`:

```bat
set KEEP_WORKDIR=1
set KEEP_TEX=1
set ENABLE_TOC=0
set ASSETS_DIR=C:\percorso\assets
```

#### Opzione 4: Docker su Windows

Con Docker Desktop installato, usa lo script dedicato:

```powershell
.\scripts\docker-build.ps1 .\books\example
```

Oppure da `cmd.exe`:

```bat
scripts\docker-build.bat .\books\example
```

Con output esplicito:

```powershell
.\scripts\docker-build.ps1 .\books\example dist\mio-libro.pdf
```

Per cambiare il tag dell'immagine Docker:

```powershell
$env:IMAGE_NAME = "daggerheart-publish:dev"
.\scripts\docker-build.ps1 .\books\example
```

Da `cmd.exe`:

```bat
set IMAGE_NAME=daggerheart-publish:dev
scripts\docker-build.bat .\books\example
```

---

## Verifica dell'installazione

Dopo aver installato le dipendenze, verifica che i tool siano disponibili:

```bash
pandoc --version
xelatex --version
```

Entrambi i comandi dovrebbero stampare informazioni sulla versione senza errori.

Poi costruisci il libro di esempio incluso nel progetto:

```bash
# Linux / macOS / Git Bash
./scripts/build.sh ./books/example dist/test.pdf

# Windows PowerShell
.\scripts\build.ps1 .\books\example dist\test.pdf

# Windows cmd.exe
scripts\build.bat .\books\example dist\test.pdf
```

Il file `dist/test.pdf` dovrebbe essere generato in pochi secondi.
