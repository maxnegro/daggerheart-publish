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

### Con Makefile

```bash
cd daggerheart-publish
make build INPUT=../books/location-armi OUTPUT=dist/location-armi.pdf
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

## Variabili utili

- `ASSETS_DIR`: path della directory assets (font/foto)
- `ENABLE_TOC=0`: disabilita indice automatico
- `KEEP_TEX=1`: salva anche il `.tex` generato
- `KEEP_WORKDIR=1`: mantiene la cartella temporanea di build

Esempio:

```bash
ASSETS_DIR=./assets KEEP_TEX=1 ./scripts/build.sh ../books/location-armi dist/location-armi.pdf
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
