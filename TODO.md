# TODO — daggerheart-publish

---

## Analisi `daggerheart.cls` — Doppioni, inefficienze e miglioramenti

### 🟡 Inefficienze e fragilità (bassa priorità)

#### 14. Spaziatura di `\section` e `\subsection` ricalcolata in più punti
`\titlespacing*` viene chiamata una volta in modo definitivo, ma `\applysectioncolor`
chiama `\titleformat` senza preservare la spaziatura. Se `\titlespacing*` viene emessa
prima di `\applysectioncolor`, la spaziatura viene preservata; se dopo, viene sovrascritta.
L'ordine è attualmente corretto ma fragile: bastano due righe spostate per rompere il layout.
Soluzione: spostare `\titlespacing*` dentro `\applysectioncolor` o in un hook esplicito.

---

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

---

### 📋 Riepilogo priorità di intervento

| # | Problema | Priorità | Effort |
|---|----------|----------|--------|
| 1 | `\makeatletter` spezzato | 🔴 Alta | Basso |
| 2 | TikZ caricato due volte + librerie sparse | 🔴 Alta | Basso |
| 3 | `\tcbuselibrary{skins}` duplicata | 🔴 Alta | Minimo |
| 4 | Box adversary/environment duplicati | 🟠 Media | Medio |
| 5 | `\adversary`/`\colossusadversary` duplicati | 🟠 Media | Medio |
| 6 | Stats non uniformi | 🟠 Media | Medio |
| 7 | Due API fullpage sovrapposte | 🟠 Media | Basso |
| 8 | `\dghsectionbgfadeoffset` non aggiornato | 🟡 Bassa | Basso |
| 9 | Toggle `\ifnum` invece di `\newif` | 🟡 Bassa | Basso |
| 10 | `\colorlet` vs `\definecolor` incoerente | 🟡 Bassa | Minimo |
| 11 | Accento con macro invece di UTF-8 | 🟡 Bassa | Minimo |
| 12 | `\dghenvironmenttiertype` definita due volte | 🟡 Bassa | Minimo |
| 13 | `\ifdghonepagebreak` senza API pubblica | 🟡 Bassa | Minimo |
| 14 | `\titlespacing*` fragile rispetto a `\applysectioncolor` | 🟡 Bassa | Basso |
| 15 | Mix di `\gdef`/`\global\def`/`\renewcommand` | 🟢 Stile | Medio |
| 16 | Nomi comandi non consistenti | 🟢 Stile | Alto |
| 17 | `\tightlist` non documentata come shim Pandoc | 🟢 Stile | Minimo |


