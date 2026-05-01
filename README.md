# daggerheart-publish

Un workflow moderno per creare eleganti PDF a due colonne per campagne di GdR (come Daggerheart) partendo da semplici file Markdown. Usa un template LaTeX personalizzato, filtri Lua per Pandoc e una struttura di cartelle organizzata per rendere il processo semplice — anche per chi non ha esperienza con LaTeX.

Guarda il [modulo di esempio](dist/example.pdf)!

## Obiettivo

Con questo progetto puoi:

- scrivere l'avventura in Markdown
- usare blocchi semantici (adversary, environment, box, fullpage)
- produrre un PDF in stile Daggerheart
- eseguire tutto in locale oppure via Docker

## Struttura

- `filters/daggerheart.lua`: converte blocchi Markdown in macro LaTeX del template
- `templates/daggerheart.latex`: template Pandoc minimale per la classe `daggerheart`
- `templates/daggerheart.cls`: copia locale della classe LaTeX (modificabile nel repo)
- `assets/fonts`: font richiesti dalla classe LaTeX
- `assets/photos`: immagini di supporto al template
- `scripts/build.sh`: build locale
- `scripts/docker-build.sh`: build tramite container
- `docker/Dockerfile`: immagine con pandoc + XeLaTeX
- `books/<nome-libro>/book.md`: frontmatter e metadati del libro
- `books/<nome-libro>/chapters/*.md`: capitoli, ordinati numericamente per filename
- `books/<nome-libro>/assets`: immagini specifiche del libro

## Prerequisiti e installazione

Per istruzioni dettagliate su Linux, macOS e Windows (nativo e Docker) consulta [INSTALL.md](INSTALL.md).

In sintesi:

- **Linux/macOS**: installa `pandoc` e `texlive-xetex` con il package manager, poi usa `./scripts/build.sh`.
- **Windows**: installa Pandoc e MiKTeX, poi usa `.\scripts\build.ps1` su PowerShell oppure `scripts\build.bat` da `cmd.exe`.
- **Docker**: usa `./scripts/docker-build.sh` su shell POSIX, `.\scripts\docker-build.ps1` su PowerShell oppure `scripts\docker-build.bat` da `cmd.exe`; non richiede LaTeX locale.

Note:

- Lo script usa `templates/daggerheart.cls` locale se presente.
- Font e assets vengono letti da `./assets` di default.
- Se vuoi un percorso diverso per gli asset, imposta `ASSETS_DIR`.

## Uso locale

### Build diretta

```bash
cd daggerheart-publish
./scripts/build.sh ./books/example
```

Su Windows PowerShell:

```powershell
.\scripts\build.ps1 .\books\example
```

Su Windows `cmd.exe`:

```bat
scripts\build.bat .\books\example
```

Con questo comando l'output predefinito sara:

```bash
dist/example.pdf
```

Puoi comunque specificare un output esplicito:

```bash
./scripts/build.sh ./books/example/ mio-libro.pdf
```

Per vedere uso e opzioni disponibili:

```bash
./scripts/build.sh --help
```

Sintassi:

```bash
./scripts/build.sh <book-dir> [output.pdf]
```

### Con Makefile

```bash
cd daggerheart-publish
make build INPUT=./books/example OUTPUT=dist/example.pdf
```

Variabili supportate dal target `build`:

- `INPUT`: cartella libro (default: `./books/example`)
- `OUTPUT`: file PDF di output (default: `dist/example.pdf`)

Pulizia output:

```bash
make clean
```

## Uso Docker

La build Docker usa solo i file presenti in questo repository.

```bash
cd daggerheart-publish
./scripts/docker-build.sh ./books/example
```

Su Windows PowerShell:

```powershell
.\scripts\docker-build.ps1 .\books\example
```

Su Windows `cmd.exe`:

```bat
scripts\docker-build.bat .\books\example
```

Oppure:

```bash
cd daggerheart-publish
make docker-build INPUT=./books/example OUTPUT=dist/example.pdf
```

Per vedere uso e opzioni disponibili:

```bash
./scripts/docker-build.sh --help
```

Sintassi:

```bash
./scripts/docker-build.sh <book-dir> [output.pdf]
```

## Formato cartella libro

Ogni libro deve avere questa struttura:

```text
books/<nome-libro>/
  book.md
  assets/
  chapters/
    01 - Capitolo.md
    02 - Capitolo.md
    ...
```

Regole di build:

- `book.md` contiene frontmatter e contenuto introduttivo.
- Tutti i file `chapters/*.md` vengono concatenati automaticamente dopo `book.md`.
- L'ordine dei capitoli e determinato dal nome file con ordinamento numerico naturale (`sort -V`).
- Se non passi un output esplicito, il PDF va in `dist/<nome-libro>.pdf`.

## Formato Markdown supportato

Il parser e impostato a:

```text
markdown+fenced_divs+bracketed_spans
```

Questa configurazione viene applicata sia nella build locale sia nella build Docker.

### Estensioni Markdown attive

- `fenced_divs`: abilita i blocchi `:::` con classi e attributi (base dei blocchi `.fullpage`, `.adversary`, `.environment`, `.squarebox`, `.roundedbox`, `.quotebox`, ecc.).
- `bracketed_spans`: abilita gli span inline con attributi, utili per marcare porzioni di testo senza creare un blocco separato.

Esempi:

```md
::: fullpage
# Titolo sezione
Contenuto della pagina piena.
:::

[testo annotato]{.tag-personalizzato key="value"}
```

### Metadati documento

Usa frontmatter YAML:

```yaml
---
title: Titolo
subtitle: Sottotitolo
author:
  - Nome Autore
date: 25 aprile 2026
toc: true
toc-depth: 2
---
```

Per personalizzare la title page standard con un'immagine:

```yaml
---
title: Titolo
subtitle: Sottotitolo
author:
  - Nome Autore
title-image: assets/photos/copertina.jpg
title-image-mode: half
title-image-height: 0.5\\paperheight
---
```

Opzioni supportate:

- `title-image`: percorso immagine per la pagina del titolo
- `title-image-mode`: `half` (immagine centrata) oppure `background` (sfondo full-page)
- `title-image-height`: altezza immagine in modalita `half` (default `0.5\\paperheight`)
- `title-image-fit`: in modalita `background`, `fill` (default) oppure `contain`

Alias compatibili:

- `titlepage-image` o `cover-image` al posto di `title-image`
- `titlepage-image-mode`, `titlepage-image-height`, `titlepage-image-fit`

### Cover personalizzata

Per usare la cover personalizzata nel body del documento, imposta nel frontmatter:

```yaml
---
title: Titolo
subtitle: Sottotitolo
designer: Nome Designer
complexity: 2
cover-image: assets/copertina.jpg
cover-image-title: Titolo immagine
cover-image-author: Nome autore immagine
cover-page: custom
---
```

Poi inserisci nel body un blocco `framecoverpage`:

```md
::: framecoverpage
## Struttura

- Primo beat
- Secondo beat

## Tier

**Tier consigliato:** Tier 1
**Durata stimata:** 2h
:::
```

Note:

- `cover-page: custom` attiva la cover personalizzata e disabilita `\maketitle` nel template.
- `subtitle` nel frontmatter della cover personalizzata supporta markdown inline, hard line breaks Markdown (due spazi a fine riga) e paragrafi multipli.
- Il contenuto di `::: framecoverpage` viene renderizzato nella cover in due colonne.
- `cover-image-title` e `cover-image-author` popolano il box crediti in alto a destra.
- Se `cover-image-title` e `cover-image-author` sono entrambi assenti o vuoti, il box crediti non viene generato.

### Box

```md
::: squarebox
Testo nel box quadrato.
:::

::: roundedbox
Testo nel box arrotondato.
:::

::: quotebox
Citazione in stile template.
:::
```

In alternativa è supportata anche la forma con attributi Pandoc: `::: {.squarebox}`, `::: {.roundedbox}`, `::: {.quotebox}`.

### Adversary

````md
```statblock
layout: Daggerheart Adversary
source: daggerheart-adversary
name: Acid Burrower
tier: 1
type: Solo
description: A horse-sized insect with digging claws and acidic blood.
motives_and_tactics: Burrow, drag away, feed, reposition
difficulty: 14
thresholds: 8/15
hp: 8
stress: 3
atk: "+3"
attack: Claws
range: Very Close
damage: 1d12+2 phy
experience: Tremor Sense +2
feats:
  - name: Relentless (3) - Passive
    text: The Burrower can be spotlighted up to three times per GM turn.
  - name: Earth Eruption - Action
    text: Mark a Stress to have the Burrower burst out of the ground.
```
````

### Environment

````md
```statblock
layout: Daggerheart Environment
source: daggerheart-environment
name: Abandoned Grove
tier: 1
type: Exploration
description: A former druidic grove reclaimed by nature.
impulses: Draw in the curious, echo the past
difficulty: 11
potential_adversaries: Minor Treant, Sylvan Soldier, Young Dryad
feats:
  - name: Overgrown Battlefield - Passive
    text: PCs can inspect traces of a previous battle.
    question: Do you recognize something in this old battlefield?
  - name: Barbed Vines - Action
    text: Pick a point; targets in Very Close range risk damage and Restrained.
    question: What do you feel while the vines nail you to the ground?
```
````

Nota: Rispetto ai formati supportati dal plugin `obsidian fantasy statblocks`, il filtro Lua usa solo il formato `statblock` con layout `Daggerheart Adversary` e `Daggerheart Environment` per questi blocchi.

### Etichette multilingua (ITA/ENG)

Le etichette generate da template/filter (`Difficulty`, `Features`, `Impulses`, ecc.) vengono localizzate in base a `lang` nel frontmatter:

```yaml
lang: italian
```

Oppure:

```yaml
lang: english
```

### Utility

**Interruzione di colonna** — forma breve consigliata per uso inline; la forma a blocco è un'alternativa più visibile nel sorgente:

```md
[]{.columnbreak}

::: {.columnbreak}
:::
```

**Interruzione di pagina** — stessa logica:

```md
[]{.pagebreak}

::: {.pagebreak}
:::
```

**Pagina intera** (senza colonne, senza footer):

```md
::: fullpage
# Titolo pagina piena
Testo...
:::
```

### Mappa a pagina intera

Il blocco `fullpagemap` renderizza un'immagine che occupa l'intera pagina fisica, senza margini e senza footer. Viene usato tipicamente per mappe o illustrazioni full-bleed.

```md
::: fullpagemap
src: assets/mappa.png
rotate: 90
fit: none
:::
```

In alternativa, resta supportata anche la forma con attributi Pandoc:

```md
::: {.fullpagemap src="assets/mappa.png" rotate="90" fit="none"}
:::
```

Attributi disponibili:

- `src`: percorso dell'immagine (obbligatorio)
- `rotate`: rotazione in gradi (default: `0`). Utile per immagini in formato landscape su pagina portrait. Nota: con rotazione attiva, il filtro scambia larghezza e altezza della pagina nel calcolo delle dimensioni dell'immagine (`\paperwidth` ↔ `\paperheight`).
- `fit`: modalità di adattamento:
  - `fill`: l'immagine riempie esattamente la pagina (può essere ritagliata)
  - qualsiasi altro valore (es. `none`, `contain`): mantiene le proporzioni originali (default)

### H1 con sfondo (parametri supportati)

Per gli heading di livello 1 puoi usare attributi dedicati per renderizzare uno sfondo di sezione:

```md
# Titolo sezione {bg="assets/header.png"}
```

Attributi disponibili:

- `bg`: path immagine di sfondo per l'H1
- `bg-height`: altezza area sfondo (default: `150pt`)
- `bg-raise`: offset verticale del titolo rispetto allo sfondo (default: `-18pt`)
- `bg-fade-offset`: punto di inizio della sfumatura bianca dal top pagina (default: `bg-height - 80pt`)

Alias supportati:

- `background` o `section-bg` al posto di `bg`
- `section-bg-height` al posto di `bg-height`
- `section-bg-raise` al posto di `bg-raise`

Esempio completo:

```md
# Luoghi scoperti {bg="assets/location-section-header.png" bg-height="170pt" bg-raise="-14pt" bg-fade-offset="90pt"}
```

Note pratiche:

- Se imposti `bg-fade-offset`, il valore non viene ricalcolato automaticamente da `bg-height`.
- Se `h1-newpage` e attivo (default), anche gli H1 con `bg` iniziano su una nuova pagina.

### Colore di sezione

Il modo consigliato per impostare il colore di sezione e usare classi sull'H1. Il colore si applica automaticamente anche alle **tabelle** (header e righe alternate) e alle **squarebox** della sezione.

Sintassi consigliata:

```md
# Titolo sezione {.sectioncolor h1=dg-darkgreen}
```

Con solo `h1`, H1 e H2 usano lo stesso colore.

Con solo `h2`, H1 resta al colore standard (`h1text`, default `#444444`) e H2 usa il colore specificato.

Per differenziare H1 e H2:

```md
# Titolo sezione {.sectioncolor h1=dg-darkgreen h2=dg-orange}
```

Il colore viene resettato automaticamente all'H1 successivo se non ne viene impostato uno nuovo.

Compatibilita:

- consigliata: `.sectioncolor` con attributi `h1`/`h2`
- legacy deprecata: il comando `\setsectioncolor{<colore-h1>}{<colore-h2>}` resta supportato dal parser, ma e consigliato migrare alla sintassi a classi

Colori predefiniti disponibili:

| Nome           | Valore hex |
|----------------|------------|
| `dg-red`       | `#7a1e1f`  |
| `dg-darkgreen` | `#56673d`  |
| `dg-orange`    | `#ae5825`  |
| `dg-purple`    | `#754084`  |

Puoi anche usare qualsiasi colore definito nel template o aggiungerne di nuovi con `\definecolor` nel frontmatter.

Esempio:

```md
# Foresta Oscura {.sectioncolor h1=dg-darkgreen}

Testo della sezione con tabelle e squarebox nella tinta verde della sezione.
```

## Variabili di ambiente

- `ASSETS_DIR`: path della directory assets (font/foto)
- `ENABLE_TOC=0`: disabilita indice automatico
- `KEEP_TEX=1`: salva anche il `.tex` generato
- `KEEP_WORKDIR=1`: mantiene la cartella temporanea di build
- `IMAGE_NAME`: tag immagine Docker usata da `docker-build.sh` (default: `daggerheart-publish:latest`)

Note su `ENABLE_TOC`:

- Con `ENABLE_TOC=1` (default), il TOC viene aggiunto solo se nel frontmatter di `book.md` non c'e `toc: false`.
- Con `ENABLE_TOC=0`, il TOC viene sempre disabilitato.

Esempio:

```bash
ASSETS_DIR=./assets KEEP_TEX=1 ./scripts/build.sh ./books/example/
```

Esempio Docker con tag immagine personalizzato:

```bash
IMAGE_NAME=daggerheart-publish:dev ./scripts/docker-build.sh ./books/example/
```

## Limiti attuali

- Le tabelle Markdown vengono convertite automaticamente in `\ColoredTable`, ma tabelle molto larghe in layout a due colonne possono richiedere contenuti piu brevi per mantenere una resa leggibile.
- Per statistiche avanzate conviene usare direttamente le macro LaTeX nei blocchi `stats`.

## Esempio di conversione da odt a md
``` bash
pandoc -s "input.odt" -t markdown -o "output.md"
```

## Credits

La classe LaTeX `daggerheart.cls` è derivata da:

- **[Gladon4/daggerheart-latex-template](https://github.com/Gladon4/daggerheart-latex-template)** — template LaTeX da cui è derivata la classe

Ispirazione originale:

- **[roland04/daggerheart-template](https://github.com/roland04/daggerheart-template)** — idea originale del template Daggerheart

## Licenza

Questo progetto è distribuito sotto la **GNU General Public License, versione 3** (o qualsiasi versione successiva). Per maggiori dettagli, consulta il testo completo della licenza.

Questo progetto non è associato né approvato dai creatori di Critical Role, Darrington Press o qualsiasi altra entità commerciale. È un progetto indipendente creato per uso personale ed educativo.

Questo template utilizza i seguenti font:

- **Montserrat** (Google Fonts, SIL Open Font License)
- **Merriweather** (Google Fonts, SIL Open Font License)
- **LeagueSpartan** (Google Fonts, SIL Open Font License)
