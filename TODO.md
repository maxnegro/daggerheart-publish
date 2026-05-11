# TODO — daggerheart-publish

---

## Analisi `daggerheart.cls` — Doppioni, inefficienze e miglioramenti


### 🟢 Suggerimenti di uniformità stilistica

#### 15. Mescola di `\gdef`, `\global\def`, `\renewcommand`, `\newcommand` per variabili globali
Il file usa tutti e quattro indistintamente per definire o aggiornare variabili di
stato (colori, etichette). Adottare una convenzione unica: `\gdef` per state interni
(prefisso `\dgh@`), `\newcommand`/`\renewcommand` per comandi pubblici.

#### 16. Nomi di comandi pubblici non consistenti
Alcuni comandi usano il prefisso `\dgh` (es. `\dghpagebreak`, `\dghsectionseparator`),
altri `\dgh` senza separatore di parola (`\dghsectionbgrender`), altri ancora nessun
prefisso (`\adversary`, `\environment`, `\fullpage`). Adottare lo schema:
- `\dgh<Comando>` per API pubbliche
- `\dgh@<comando>` per interni

#### 17. `\providecommand{\tightlist}` — compatibilità Pandoc
`\tightlist` è iniettato da Pandoc nel documento; tenerlo nella classe è corretto ma va
documentato esplicitamente come "shim Pandoc" per evitare che venga rimosso per errore.

