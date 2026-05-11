# TODO — daggerheart-publish

---

## Analisi `daggerheart.cls` — Doppioni, inefficienze e miglioramenti

### 🟠 Duplicazione di codice (media priorità)


#### 7. Due API sovrapposte per il fullpage
Esistono sia `\fullpage{...}` (ambiente inline con argomento) sia la coppia
`\beginFullpage`/`\finishFullpage` per delimitare blocchi. Fanno la stessa cosa con
interfacce diverse; sarebbe più uniforme avere solo l'ambiente `\newenvironment{dghfullpage}`.

---

### 🟡 Inefficienze e fragilità (bassa priorità)

#### 8. `\dghsectionbgfadeoffset` non si ricalcola automaticamente
Il commento dice "recomputed whenever height or raise changes" ma nessun meccanismo lo
garantisce: se l'utente cambia `\dghsectionbgheight` con `\setlength`, `\dghsectionbgfadeoffset`
rimane al valore iniziale. Soluzione: calcolare il valore inline in `\dghsectionbgpicture`
con `\dimexpr` o fornire un comando `\setdghsectionbgheight{...}` che aggiorni entrambe le
lunghezze.

#### 9. Toggle numerici `0`/`1` con `\ifnum` — stile fragile
I flag per la cover (`\dghcoverimagecreditenabled`, `\dghcoverimagetitleenabled`,
`\dghcoverimageauthorenabled`) sono definiti come `\newcommand{...}{0}` e testati con
`\ifnum...\relax`. È preferibile usare `\newif\ifdgh...` che è idiomatico LaTeX, più
leggibile e meno soggetto a errori di parsing.

#### 10. `\colorlet` in `\setboxcolor` vs `\definecolor` in `\resetboxcolor`
I due comandi usano approcci diversi per gestire lo stesso colore. Unificare: usare
sempre `\colorlet` (per alias) o sempre `\definecolor` (per valori fissi), con una
coppia di colori "correnti" che viene ridefinita in entrambi i comandi.

#### 11. `Livello di Complessit\`a` — accento con macro invece di UTF-8
Nel bundle `\dghsetlabelsitalian`, la stringa contiene `\`a` invece di `à` diretto.
Il file usa UTF-8 (fontspec + LuaLaTeX/XeLaTeX), quindi i caratteri accentati vanno
scritti letteralmente. La macro potrebbe spaccare in contesti in cui il token `\`` è
ridefinito.

#### 12. `\dghenvironmenttiertype` definita due volte
Prima viene dichiarata come `\newcommand` con valore inglese di default, poi il blocco
babel `\captionsenglish` la ridefinisce con `\let`. La definizione iniziale è ridondante
se babel è sempre caricato; altrimenti va documentato esplicitamente il caso senza babel.

#### 13. `\ifdghonepagebreak` senza API pubblica di disattivazione
Il flag esiste e il suo valore di default è `true`, ma non c'è nessun comando utente per
impostarlo a `false` nella sorgente del documento. Aggiungere `\dghonepagebreakfalse` /
`\dghonepagebreaktrue` come comandi pubblici documentati, o rimuovere il flag se non usato.

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


