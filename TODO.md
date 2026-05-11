# TODO — daggerheart-publish

> Documento di analisi e piano d'intervento per `daggerheart.cls`, `daggerheart.lua` e
> `daggerheart.latex`. L'utente finale non scrive LaTeX direttamente: tutta la superficie
> di authoring è Markdown → Pandoc AST → filtro Lua → LaTeX → PDF.
> Ogni proposta deve rispettare questo vincolo.
> I file attualmente in tests/baseline sono considerati fonti di verità e non vanno MAI
> modificati durante il refactor.

---

## Analisi architetturale

### A. Bug e comportamenti errati

#### A1. Effetti globali in `\ColoredTable`
- **File**: `daggerheart.cls` ~riga 875
- **Problema**: `\renewcommand{\arraystretch}{1.3}` e `\rowcolors{2}{...}{...}` sono emessi
  senza gruppo; rimangono attivi per il resto del documento, contaminando tabelle successive.
- **Soluzione**: racchiudere tutto il corpo in `\begingroup … \endgroup`.

#### A2. Sintassi spuria in `framecoverpage`
- **File**: `daggerheart.cls` fine dell'ambiente `framecoverpage`
- **Problema**: la definizione dell'ambiente si chiude con `}{}` di troppo, residuo di una
  riscrittura incompleta.
- **Soluzione**: rimuovere la coppia `}{}` prima del commento finale.

#### A3. `\section` e `\subsection` non gestiscono la forma con asterisco
- **File**: `daggerheart.cls` (~riga 440), `daggerheart.lua` (funzione `Header`)
- **Problema**: le ridefinizioni intercettano solo `\section{...}`. LaTeX permette
  `\section*{...}`, che bypassa multicols, page-break e reset del colore. Pandoc di norma
  non emette `\section*`, ma raw-block o template personalizzati possono farlo.
- **Soluzione (CLS)**: usare `\NewDocumentCommand{\section}{s o m}` (pacchetto `xparse`)
  oppure `\@ifstar` per applicare la stessa logica a entrambe le forme.

#### A4. `\renewcommand{\footrule}` fragile
- **File**: `daggerheart.cls` (~riga 108)
- **Problema**: ridefinire il comando interno di `fancyhdr` è una pratica fragile; cambi
  di versione del pacchetto possono rompere il layout senza warning.
- **Soluzione**: spostare la linea d'oro direttamente in `\fancyfoot` usando `\rule` o
  un bordo tikz/tcolorbox nel footer.

---

### B. Pipeline Pandoc → Lua → LaTeX: aree critiche

#### B1. Pipeline titoli distribuita su tre livelli
- **File**: `daggerheart.lua` (`Header()`, `normalize_section_color_blocks()`,
  `blocks_to_latex()`), `daggerheart.cls` (~righe 370-465)
- **Problema**:
  - `Header()` decide page-break, colori e background per gli H1, iniettando `RawBlock`
    LaTeX separati (`\setsectioncolor`, `\newpage`, `\sectionwithbg`) che devono stare in
    un preciso ordine relativo.
  - `normalize_section_color_blocks()` esiste solo per correggere a posteriori l'ordine
    di questi `RawBlock`: è un sintomo del problema, non una soluzione.
  - `blocks_to_latex()` interna richiama `Header()` ricorsivamente per blocchi Markdown
    annidati (dentro `framecoverpage`, ecc.), duplicando la logica di rendering.
  - La classe mantiene stato globale (`\dgsectioncolor`, `\ifdgresetsectioncoloronnextsection`)
    che il filtro modifica via `\global\...` iniettati come `RawBlock`, accoppiando
    strettamente i due livelli.
- **Principio Pandoc/Lua**: un filtro ben scritto trasforma l'AST in modo dichiarativo
  (AST in → AST out). I `RawBlock` sono un ultimo ricorso, non un canale di comunicazione
  con la classe. Lo stato condiviso via side effect LaTeX è l'anti-pattern più pericoloso.
- **Soluzione proposta**:
  1. Nel filtro: costruire un unico `RawBlock` per H1 con tutti i parametri come argomenti
     di una sola macro canonica, es. `\dghsection[color=dg-red,bg=img.jpg]{Titolo}`.
  2. Nella classe: `\dghsection` gestisce internamente multicols, page-break, colore e
     sfondo, eliminando la necessità di `normalize_section_color_blocks`.
  3. H1 semplice e H1 con sfondo convergono sulla stessa macro, con argomenti opzionali.

#### B2. Pipeline cover sdoppiata tra template e body
- **File**: `daggerheart.latex` (~riga 26), `daggerheart.lua` (`Meta()`, `Div(framecoverpage)`),
  `daggerheart.cls` (`\frontpage`, `\framecoverpage`)
- **Problema**: due entry point distinti per la copertina:
  - *Standard*: `Meta()` popola macro (`\dghcovertitle`, ecc.) → template emette `\maketitle`
    → classe chiama `\frontpage`.
  - *Frame*: `Div(framecoverpage)` raccoglie gli stessi default + body Markdown → emette
    `\begin{framecoverpage}...\end{framecoverpage}`.
  - Il termine *frame* ha un significato editoriale preciso nel manuale Daggerheart
    (tipo di avventura/ambientazione) e va preservato.
  - Ogni nuova feature cover tocca almeno due superfici separate.
- **Soluzione proposta**:
  1. Unificare il modello dati cover in `Meta()` (il dict `cover_defaults` esiste già).
  2. Nella classe, una macro base `\dghcoverrender{title}{subtitle}{designer}{complexity}{image}{body}`
     usata da entrambi gli ambienti come primitiva comune.
  3. `cover-page: custom` diventa `cover-page: frame`; la cover standard rimane il default.

#### B3. `\paragraph` e `\subparagraph` non gestiti nel filtro
- **File**: `daggerheart.lua` (funzione `Header`)
- **Problema**: `Header()` gestisce solo `el.level == 1`. I livelli 4-5 di Markdown
  (`####`, `#####`) mappati su `\paragraph` e `\subparagraph` non ricevono alcun
  trattamento: né `\needspace` né gestione speciale in multicols.
- **Soluzione**: estendere `Header()` per livelli 4-5 con almeno `\needspace{3\baselineskip}`.

#### B4. `blocks_to_latex` interna bypassa le normalizzazioni
- **File**: `daggerheart.lua` (~righe 1100-1155)
- **Problema**: la `blocks_to_latex` locale (usata dentro `framecoverpage`, `fullpagemap`,
  `squarebox`) richiama `Header()` direttamente ma non passa per `normalize_section_color_blocks`
  né `normalize_break_blocks`, producendo output LaTeX leggermente diverso.
- **Soluzione**: applicare le normalizzazioni anche nel percorso interno, oppure usare
  `pandoc.write(pandoc.Pandoc(blocks), "latex")` dopo aver applicato il filtro ricorsivamente
  con `pandoc.walk_block`.

---

### C. Duplicazioni e ridondanze (CLS)

#### C1. Label multilingue duplicate
- **File**: `daggerheart.cls` (~righe 619-669)
- **Problema**: `\dghsetlabelsenglish` e `\dghsetlabelsitalian` sono identiche al 95%
  (16 coppie chiave-valore). Aggiungere una label richiede due modifiche.
- **Soluzione**: table-driven con `pgfkeys` / `l3keys`, oppure file `.def` per lingua
  incluso con `\input`.

#### C2. Pattern multicols ripetuto quattro volte
- **File**: `daggerheart.cls` (~righe 440, 460, 810, 860)
- **Problema**: `\end{multicols}...\begin{multicols}{2}\raggedcolumns` identico in
  `\section`, `\sectionwithbg`, `\dghfullpagestart/end`, `\dghpagebreak`.
- **Soluzione**: macro interne `\dgh@exitmulticols` / `\dgh@entermulticols`; risolve
  anche la duplicazione di B1.

#### C3. Box entity quasi identiche
- **File**: `daggerheart.cls` (~righe 596-700)
- **Problema**: `adversarybox`/`adversaryinnerbox` e `environmentbox`/`environmentinnerbox`
  differiscono solo nei colori. Il corpo di `\dghadversary` e `\dghenvironment` è quasi
  identico; `\dgh@entity` esiste ma non è usato da `\dghenvironment`.
- **Soluzione**: rendere `\dgh@entity` davvero generico, parametrizzando il label
  "Motives & Tactics" / "Impulses".

#### C4. Footer specchi LE/RO duplicati
- **File**: `daggerheart.cls` (~righe 113-136)
- **Problema**: `\fancyfoot[LE]` e `\fancyfoot[RO]` hanno il 90% del codice identico,
  cambiando solo allineamento e ordine pagina/titolo.
- **Soluzione**: macro interna `\dgh@footerblock{align}{order}`.

#### C5. Colori sparsi e senza gerarchia
- **File**: `daggerheart.cls` (~righe 164-189)
- **Problema**: colori di heading, box, cover e accenti definiti in ordine casuale;
  `squareboxbg-default` + `\colorlet{squareboxbg}` ripetuto per ogni variante.
- **Soluzione**: sezione "design tokens" strutturata in categorie (`text`, `structure`,
  `entity`, `cover`, `accent`); `\colorlet` solo per alias modificabili a runtime.

---

### D. Qualità del codice

#### D1. Nomi comando inconsistenti
- **File**: `daggerheart.cls`, `daggerheart.lua`
- **Problema CLS**: mix tra `\dgh...` (pubblici), `\dgh@...` (interni parzialmente) e
  comandi senza prefisso (`\hfour`, `\fullpage`, `\applysectioncolor`, `\setboxcolor`).
- **Problema Lua**: funzioni helper non dichiarate `local` risultano globali per errore.
- **Soluzione CLS**: tutti i comandi pubblici `\dgh...`; interni `\dgh@...` (il `.cls`
  ha `@` sempre disponibile).
  **Soluzione Lua**: tutte le funzioni non-API dichiarate `local`.

#### D2. `\gdef` usato impropriamente per variabili di stato
- **File**: `daggerheart.cls` (~righe 376, 395-398, 410)
- **Problema**: `\gdef\dgsectioncolor{...}` bypassa il controllo di ridefinizione e
  forza globalità anche quando non necessaria.
- **Soluzione**: dichiarare con `\newcommand` e aggiornare con `\renewcommand` o `\def`
  solo dove la globalità è intenzionale e documentata.

#### D3. Conflitto `\onehalfspacing` + `\baselinestretch`
- **File**: `daggerheart.cls` (~righe 143-145)
- **Problema**: `\onehalfspacing` imposta `\baselinestretch` internamente; la riga
  successiva `\renewcommand{\baselinestretch}{1.2}` sovrascrive silenziosamente.
- **Soluzione**: usare solo `\setstretch{1.2}` di `setspace` e rimuovere `\onehalfspacing`.

#### D4. Mancanza di dichiarazione del motore richiesto
- **File**: `daggerheart.cls` (inizio file)
- **Problema**: `fontspec` richiede XeLaTeX o LuaLaTeX; con pdfLaTeX il fallimento è
  criptico.
- **Soluzione**:
  ```latex
  \RequirePackage{iftex}
  \RequireXeTeXorLuaTeX{La classe daggerheart richiede XeLaTeX o LuaLaTeX.}
  ```

#### D5. Opzioni di classe non propagate ad `article`
- **File**: `daggerheart.cls` (~riga 7)
- **Problema**: opzioni hardcoded in `\LoadClass`; l'utente non può passare opzioni custom.
- **Soluzione**:
  ```latex
  \DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
  \ProcessOptions\relax
  \LoadClass{article}
  ```

#### D6. Boolean boilerplate ripetuto
- **File**: `daggerheart.cls` (~righe 46-84, 361-389, 464-468, 774-776)
- **Problema**: pattern `\newif` + setter `\enable...` / `\disable...` ripetuto 5+ volte.
- **Soluzione**: macro factory interna `\dgh@definebool{name}{default}`.

#### D7. Gestione babel hardcoded solo EN/IT
- **File**: `daggerheart.cls` (~righe 670-684)
- **Problema**: check binario `italian`/altro; nessun warning per lingua non riconosciuta.
- **Soluzione**: emettere `\PackageWarning` per lingua non gestita e applicare inglese
  come default. Permettere override da Lua tramite `\dghsetlabels{lang}` nel frontmatter.

#### D8. `\AtBeginDocument` sdoppiato
- **File**: `daggerheart.cls` (~righe 93-98 e 670-684)
- **Soluzione**: unire in un unico blocco ordinato e commentato per sezione.

#### D9. Alias deprecati senza warning
- **File**: `daggerheart.cls` (~righe 694-698)
- **Comandi**: `\adversarystats`, `\adversary`, `\colossusadversary`, `\environmentstats`,
  `\environment`.
- **Soluzione**: `\PackageWarning` al primo uso (pattern `\ifdgh...warned` già presente);
  pianificare rimozione in versione major.

#### D10. Magic numbers sparsi
- **File**: `daggerheart.cls`
- **Problema**: `\fontsize{8.5}{10}`, `arc=5pt`, `boxrule=1pt`, `before skip=2em`, ecc.
  hardcoded senza nome semantico.
- **Soluzione**: sezione "design tokens" con `\newlength` e `\newcommand` nominati.

#### D11. `\applysectioncolor` ridefinisce `\titleformat` ad ogni chiamata
- **File**: `daggerheart.cls` (~riga 379)
- **Problema**: viene chiamata in `\section`, `\subsection` e ogni reset; operazione
  non idempotente e potenzialmente costosa.
- **Soluzione**: verificare se i colori correnti corrispondono prima di ri-applicare;
  oppure separare la definizione del formato dallo switch del colore.

---

### E. Configurazione e best practice generali

#### E1. Font locali senza fallback
- **File**: `daggerheart.cls` (~righe 149-157)
- **Problema**: `Path = ./fonts/` relativo alla directory di compilazione; errore criptico
  se i font mancano.
- **Soluzione**: `\IfFileExists{./fonts/Montserrat-Regular.ttf}{}{%
  \PackageError{daggerheart}{Font non trovati in ./fonts/}{...}}` in `\AtBeginDocument`.

#### E2. Argomenti posizionali multipli in `framecoverpage`
- **File**: `daggerheart.cls` (~riga 258), `daggerheart.lua` (~riga 1441)
- **Problema**: cinque argomenti posizionali non auto-esplicativi, impossibili da
  estendere senza rompere retrocompatibilità.
- **Soluzione**: `pgfkeys` o `l3keys` per argomenti chiave-valore; il filtro Lua genera
  `\begin{framecoverpage}[title=..., image=...]`.

#### E3. Assenza di commenti strutturati
- **File**: `daggerheart.cls`, `daggerheart.lua`
- **Soluzione**: header di sezione standard (scopo, comandi/ambienti esposti, dipendenze)
  prima di ogni blocco logico.

---

## Piano d'intervento

### 🔴 Bug bloccanti — prima di qualsiasi refactoring

- [x] **[A2]** Rimuovere `}{}` spurio in `framecoverpage` (`daggerheart.cls`)
- [x] **[A1]** Isolare effetti globali di `\ColoredTable` con `\begingroup...\endgroup`
- [x] **[D3]** Correggere conflitto `\onehalfspacing` / `\baselinestretch`:
  usare solo `\setstretch{1.2}`
- [x] **[D4]** Aggiungere dichiarazione motore con `\RequirePackage{iftex}` +
  `\ifxetex\else\ifluatex\else \PackageError{...}\fi\fi`

### 🟠 Priorità alta — impatto funzionale diretto

- [ ] **[B1]** Unificare pipeline titoli H1: macro `\dghsection[color=,bg=]{titolo}` nella
  classe; `Header()` nel filtro Lua genera un unico `RawBlock` dichiarativo; eliminare
  `normalize_section_color_blocks` e le coppie `RawBlock` color-before/after
- [x] **[C2]** Estrarre helper multicols `\dgh@exitmulticols` / `\dgh@entermulticols` e
  sostituire le 4 occorrenze duplicate
- [ ] **[D5]** Propagare opzioni di classe ad `article` con `\DeclareOption*` +
  `\ProcessOptions\relax`
- [ ] **[A3]** Gestire `\section*` / `\subsection*` con `\NewDocumentCommand` o `\@ifstar`
- [ ] **[B3]** Estendere `Header()` in Lua ai livelli 4-5 (almeno `\needspace`)

### 🟡 Priorità media — qualità e coerenza

- [ ] **[B2]** Unificare pipeline cover: macro base `\dghcoverrender` condivisa;
  `cover-page: frame` come valore esplicito invece di `custom`
- [ ] **[C1]** Refactoring label multilingue: table-driven, eliminare doppia definizione
- [ ] **[D1]** Uniformare prefissi: tutti pubblici `\dgh...`, interni `\dgh@...`;
  in Lua funzioni private dichiarate `local`
- [ ] **[D2]** Sostituire `\gdef` con `\newcommand` / `\renewcommand` per variabili di stato
- [ ] **[D6]** Macro factory per boolean: ridurre boilerplate `\newif` + enable/disable
- [ ] **[C3]** Rendere `\dgh@entity` generico: parametrizzare label dinamici,
  usare la stessa macro per avversari e ambienti
- [ ] **[D7]** Babel: aggiungere warning per lingua non gestita e fallback inglese esplicito
- [ ] **[B4]** Allineare `blocks_to_latex` interna: applicare normalizzazioni o usare
  `pandoc.walk_block` + `pandoc.write`
- [ ] **[D11]** Evitare re-setup di `\titleformat` se colori già invariati

### 🟢 Priorità bassa — ottimizzazione e manutenibilità

- [ ] **[C4]** Macro helper footer `\dgh@footerblock{align}{order}` per LE/RO
- [ ] **[C5]** Riorganizzare palette colori in sezione design tokens all'inizio del file
- [ ] **[D10]** Nominare magic numbers con `\newlength` / `\newcommand` semantici
- [ ] **[D8]** Unire blocchi `\AtBeginDocument` in un unico blocco ordinato
- [ ] **[D9]** Alias deprecati con `\PackageWarning` al primo uso
- [ ] **[A4]** Sostituire `\renewcommand{\footrule}` con `\rule` diretta in `\fancyfoot`
- [ ] **[E2]** Convertire argomenti `framecoverpage` a keyval (`pgfkeys` / `l3keys`);
  aggiornare il filtro Lua di conseguenza
- [ ] **[E1]** Aggiungere check font con `\IfFileExists` e messaggio d'errore esplicito
- [ ] **[E3]** Aggiungere commenti di sezione strutturati a `.cls` e `.lua`
- [ ] Modularizzare in file `.sty` separati (`dgh-colors`, `dgh-boxes`, `dgh-sections`,
  `dgh-cover`) inclusi dalla classe principale

---

## Raccomandazioni architetturali

1. **Principio filtro Lua**: trasformare l'AST in modo dichiarativo. Se una feature
   richiede più `RawBlock`, incapsularli in un'unica macro LaTeX con argomenti espliciti.
   Evitare coppie di `RawBlock` before/after che dipendono dall'ordine relativo.

2. **Principio classe LaTeX**: esporre primitive stabili. Non mantenere stato globale
   modificato dall'esterno tramite `\global\...` iniettati dal filtro. Lo stato condiviso,
   se necessario, è API pubblica documentata.

3. **Test di regressione visiva**: prima del refactoring di B1 e B2, generare PDF di
   riferimento da tutti gli esempi in `books/` e verificare l'invarianza con `diff-pdf`
   o confronto manuale dopo ogni modifica.

4. **Backward compatibility**: mantenere alias con `\PackageWarning` durante la
   transizione; rimozione pianificata in versione major. Documentare in `CHANGELOG.md`.

5. **Configurazione esterna**: valutare `daggerheart-theme.sty` per colori e font,
   incluso dalla classe con `\RequirePackage`; permette skinning senza modificare la classe.

---

## Mancanze emerse dalla baseline test

- **Framecover metadata nel body non supportato**: nel blocco `::: framecoverpage`, le chiavi
  tipo `title:`, `subtitle:`, `cover-image:` scritte nel corpo non vengono lette come attributi;
  oggi il filtro usa `div.attributes` e fallback da metadata globale.
  **Impatto**: fixture/authoring ambiguo se non si usa il frontmatter.

- **Code fencing con highlighting non robusto nel template attuale**: i blocchi fenced possono
  richiedere ambienti come `Shaded` non sempre definiti nella pipeline corrente.
  **Impatto**: alcuni fixture Markdown minimali falliscono anche se i libri reali compilano.

---

## Checkpoints

- [ ] Accordo sulle priorità del piano d'intervento
- [ ] Strategia di backward compatibility definita (alias con warning vs rimozione)
- [x] **Infrastruttura test creata**:
  - ✓ `tests/test-suite.sh` — test runner con baseline + regressione
  - ✓ `tests/validate-tex.sh` — analizzatore LaTeX intermedio
  - ✓ `tests/fixtures/` — 6 test case minimalisti per bug critici
  - ✓ `books/test-full-suite/` — libro completo (4 capitoli) per copertina standard
  - ✓ `books/test-frame-cover/` — libro separato per frame cover come copertina
- [x] PDF di riferimento generati da tutti gli esempi in `books/` (con `./tests/test-suite.sh --baseline`)
- [ ] Bug bloccanti (🔴) risolti — prerequisito per ogni altra modifica
- [ ] Pipeline titoli unificata (B1) implementata — blocco più a rischio, priorità assoluta
- [ ] Pipeline cover unificata (B2) — coordinare Lua + template + CLS insieme
- [ ] Revisione nomenclatura comandi pubblici prima del rilascio
