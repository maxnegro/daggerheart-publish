# daggerheart-publish

Pipeline di pubblicazione Markdown -> PDF autosufficiente, con classe LaTeX e asset vendorizzati nel repository.

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

## Prerequisiti (locale)

Su Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y pandoc texlive-xetex texlive-latex-extra texlive-fonts-recommended texlive-pictures
```

Note:

- Lo script usa `templates/daggerheart.cls` locale se presente.
- Font e assets vengono letti da `./assets` di default.
- Se vuoi un percorso diverso per gli asset, imposta `ASSETS_DIR`.

## Uso locale

### Build diretta

```bash
cd daggerheart-publish
./scripts/build.sh ../books/location-armi
```

Con questo comando l'output predefinito sara:

```bash
dist/location-armi.pdf
```

Puoi comunque specificare un output esplicito:

```bash
./scripts/build.sh ../books/location-armi dist/mio-libro.pdf
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
make build INPUT=../books/location-armi OUTPUT=dist/location-armi.pdf
```

Variabili supportate dal target `build`:

- `INPUT`: cartella libro (default: `../books/location-armi`)
- `OUTPUT`: file PDF di output (default: `dist/location-armi.pdf`)

Pulizia output:

```bash
make clean
```

## Uso Docker

La build Docker usa solo i file presenti in questo repository.

```bash
cd daggerheart-publish
./scripts/docker-build.sh ../books/location-armi
```

Oppure:

```bash
cd daggerheart-publish
make docker-build INPUT=../books/location-armi OUTPUT=dist/location-armi.pdf
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
::: {.fullpage}
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
---
```

Per personalizzare la title page con un'immagine:

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

### Box

```md
::: {.squarebox}
Testo nel box quadrato.
:::

::: {.roundedbox}
Testo nel box arrotondato.
:::

::: {.quotebox}
Citazione in stile template.
:::
```

### Adversary

```md
::: {.adversary title="Nome" tier="Tier 1" summary="Descrizione" motives="Motivi"}
::: {.stats}
\adversarystats{12}{6/12}{4}{2}{+1}{Morso}{Close}{1d8 phy}
:::

::: {.features}
\textbf{Feature - Passive:} testo.
:::
:::
```

### Environment

```md
::: {.environment title="Nome" tier="Tier 1" summary="Descrizione" impulses="Impulsi"}
::: {.stats}
\environmentstats{12}{Avversario A, Avversario B}
:::

::: {.features}
\textbf{Feature - Passive:} testo.
:::
:::
```

### Utility

```md
::: {.columnbreak}
:::

::: {.pagebreak}
:::

::: {.fullpage}
# Titolo pagina piena
Testo...
:::
```

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

## Variabili utili

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
ASSETS_DIR=./assets KEEP_TEX=1 ./scripts/build.sh ../books/location-armi dist/location-armi.pdf
```

Esempio Docker con tag immagine personalizzato:

```bash
IMAGE_NAME=daggerheart-publish:dev ./scripts/docker-build.sh ../books/location-armi dist/location-armi.pdf
```

## Limiti attuali

- Il filtro non trasforma automaticamente tabelle Markdown in `\ColoredTable`.
- Per statistiche avanzate conviene usare direttamente le macro LaTeX nei blocchi `stats`.

## Licenza

Classe, font e asset inclusi seguono le rispettive licenze originali del template di provenienza.
## Esempio di conversione da odt a md
``` bash
pandoc -s "input.odt" -t markdown -o "output.md"
```
