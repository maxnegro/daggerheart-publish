# TODO — daggerheart-publish

## Analisi Classe LaTeX: `daggerheart.cls`

### 🔍 Valutazioni di Design e Mantenibilità

---

### ❌ DOPPIONI E RIDONDANZE

#### 1. **Definizioni di Colori Sparse e Poco Uniforme**
- **Ubicazione**: Linee 164-189
- **Problema**: Colori definiti in ordine caotico (heading → box colors → special colors)
- **Ridondanza**: Pattern `squareboxbg-default` + `\colorlet{squareboxbg}` è ripetuto (4+ volte con varianti)
- **Impatto**: Difficile aggiungere nuovi colori o mantenerli coerenti
- **Soluzione**: Creare sezione "Color Palette" strutturata con categoria logica (text, boxes, entities, accents, etc.)

#### 2. **Label Multilingue Altamente Ridondante**
- **Ubicazione**: Linee 619-669 (`\dghsetlabelsenglish` / `\dghsetlabelsitalian`)
- **Problema**: Due funzioni quasi identiche, solo valori diversi (16 label per lingua)
- **Impatto**: Aggiungere una label richiede modifica in 2 posti; alto rischio di inconsistenza
- **Soluzione**: Creare macro parametrica `\dghsetlabels{lang}{pairs}` o file di configurazione esterno

#### 3. **Pattern `\fontsize{X}{Y}\selectfont` Ripetitivo**
- **Ubicazione**: Sparso in tutto il file (framecoverpage, titles, entity renderers)
- **Occorrenze**: 20+
- **Impatto**: Difficile cambiare globalmente uno stile tipografico
- **Soluzione**: Creare helper macro come `\textfontl` (large), `\textfontm` (medium), `\textfonts` (small)

#### 4. **Gestione Multicols Incapsulata Male**
- **Ubicazione**: Linee 365-406, 456-488, 778-792, 813-827
- **Problema**: Pattern `\end{multicols}...\begin{multicols}{2}\raggedcolumns` ripetuto 4+ volte
- **Impatto**: Bug localizzati difficili da propagare a tutte le occorrenze
- **Soluzione**: Creare macro helper `\dghexitmulticols`, `\dghentermulticols` per incapsulare la logica

#### 5. **Scatole (Boxes) con Configurazione Quasi Identica**
- **Ubicazione**: Linee 239-272 (squarebox, roundedbox, quotebox), 641, 701
- **Problema**: `adversarybox` e `environmentbox` usano identico `tcbset` con solo colori diversi
- **Impatto**: Modificare stile box base richiede 2+ edizioni separate
- **Soluzione**: Parametrizzare `\newtcolorbox` con macro factory

#### 6. **Footer Specchi (LE/RO) Quasi Identici**
- **Ubicazione**: Linee 113-136
- **Problema**: `\fancyfoot[LE]` e `\fancyfoot[RO]` hanno 90% codice duplicato
- **Impatto**: Aggiornamenti dispendiosi e propensi a divergenza
- **Soluzione**: Estrarre in macro `\dghfooterblock` con parametro di allineamento

#### 7. **Boolean State + Setters Ripetitivi**
- **Ubicazione**: Linee 46-84 (sezione background), 361-389, 464-468, 774-776
- **Pattern**: `\newif\ifdgh...`, `\newcommand{\set...}`, `\newcommand{\enable...}`, `\newcommand{\disable...}`
- **Occorrenze**: 5+ istanze
- **Impatto**: Boilerplate verboso, difficile leggere la logica principale
- **Soluzione**: Creare meta-macro `\dghdefinestateparam{name}{default}` che genera tutto

#### 8. **Comandi Deprecati Ancora Presenti**
- **Ubicazione**: Linee 694-698
- **Comandi**: `\adversarystats`, `\adversary`, `\colossusadversary`, etc.
- **Problema**: Alias deprecati aggravano la manutenzione futura
- **Soluzione**: Decisione: rimuovere completamente (se non usati) o consolidare in versione nuova

---

### ⚠️ INEFFICIENZE ARCHITETTURALI

#### 9. **Gestione Titoli/Intestazioni Eccessivamente Complessa**
- **Ubicazione**: Linee 338-406
- **Problema**: 
  - Logica di "reset color on next section" è fragile (`\ifdgresetsectioncoloronnextsection`)
  - Tre diversi sistemi: `\titleformat` per h1-h4, poi `\setsectioncolor`, poi `\applysectioncolor`
  - Ridefinizioni di `\section` e `\subsection` che hijack behavior
- **Impatto**: Alto rischio di bug; difficile capire flusso di colorazione
- **Soluzione**: Consolidare in sistema singolo di "section styling state machine"

#### 10. **Parametri Sezione Background Sparsi**
- **Ubicazione**: Linee 46-84
- **Problema**: Molte `\newlength` + setter verbosi per gestire un'unica feature
- **Impatto**: Difficile scoprire API (es. come configurare fade offset?)
- **Soluzione**: Creare `\dghconfigsectionbg{height, raise, fademode}` unificato

#### 11. **Frontpage vs Framecoverpage: Due Sistemi Paralleli**
- **Ubicazione**: Linee 510-545 (frontpage) vs. 255-350 (framecoverpage)
- **Problema**: Due ambienti completamente separati per titoli; condividono <5% codice
- **Impatto**: Bug in uno non si propaga all'altro; difficile mantenere stile coerente
- **Soluzione**: Unificare con parametro `covertype=framecoverpage|classic|half` su sistema unico

#### 12. **Entity Renderer Generico Ma Incompleto**
- **Ubicazione**: Linee 677-693 (`\dgh@entity`)
- **Problema**: 
  - Macro generico ma usato solo per avversari/ambienti
  - Logica IF innestata per campo vuoto è verbose
  - Label hardcoded per "Motives & Tactics" vs "Impulses"
- **Impatto**: Difficile aggiungere nuovi tipi di entity
- **Soluzione**: Parametrizzare label, rendere veramente generico

#### 13. **Gestione Linguaggio (Babel) Ad-Hoc**
- **Ubicazione**: Linee 670-684
- **Problema**: Check manuale di `\languagename`; hardcoded solo per EN/IT
- **Impatto**: Aggiungere lingua richiede modifica classe
- **Soluzione**: Creare sistema più estensibile (es. chiave-valore per lingua)

---

### 🎨 OPPORTUNITÀ DI MIGLIORAMENTO STILISTICO

#### 14. **Nomi Comando Inconsistenti**
- Pattern misto: `dgh` prefix a volte, a volte `\hfour`, `\fullpage` senza prefisso
- Parametri talvolta `[optional]`, talvolta `\set...` macro
- **Soluzione**: Standardizzare: `\dgh...` per tutti, API via `\dghset{key=val}` stile keyval

#### 15. **Magic Numbers Sparsi**
- `fontsize{8.5}{10}`, `arc=5pt`, `boxrule=1pt`, `height=1.5ex`, etc. hardcoded
- **Soluzione**: Creare "typography scale" e "spacing scale" constants

#### 16. **Assenza di Commenti di Sezione Coesivi**
- Commenti esistono ma minimalisti; difficile capire "ruolo" di ogni sezione
- **Soluzione**: Aggiungere header di sezione con scopo e liste di macro/env

#### 17. **Prestazioni: Ridondante `\AtBeginDocument`**
- Linee 93-98 calcolano dimensioni; Linea 670-684 controlla lingua
- Potrebbero consolidarsi in unico `\AtBeginDocument`
- **Soluzione**: Unire i blocchi `\AtBeginDocument`

#### 18. **Logica Condizionali Annidate Profondamente**
- Es. `\ifindaggerfullpage...\ifdghonepagebreak...\ifindaggerfullpage...` (linee 365-406)
- Difficili da seguire
- **Soluzione**: Estrarre sub-macro con nomi semantici

---

### 📊 TABELLA PRIORITÀ REFACTORING

| ID | Problema | Impatto | Sforzo | Priorità |
|----|---------|---------|----- --|----------|
| 2  | Label multilingue | Alto | Basso | 🔴 ALTA |
| 1  | Colori sparsi | Medio | Basso | 🔴 ALTA |
| 4  | Multicols ripetuto | Alto | Medio | 🔴 ALTA |
| 9  | Titoli complessi | Molto Alto | Alto | 🔴 ALTA |
| 5  | Scatole duplicate | Medio | Basso | 🟡 MEDIA |
| 3  | Font size ripetuto | Medio | Medio | 🟡 MEDIA |
| 11 | Frontpage dual | Medio | Alto | 🟡 MEDIA |
| 6  | Footer specchi | Basso | Basso | 🟢 BASSA |
| 7  | Boolean boilerplate | Basso | Medio | 🟢 BASSA |
| 8  | Comandi deprecati | Basso | Basso | 🟢 BASSA |

---

### 💡 RACCOMANDAZIONI ARCHITETTURALI

1. **Creare file di configurazione esterno** (`daggerheart-config.sty`?)
   - Separare tema (colori, font, spacing) da struttura
   - Permette utenti di skinning senza toccare classe

2. **Implementare "Style Macros Library"**
   - `\dghfont{size}`, `\dghcolor{role}`, `\dghspacing{amount}`
   - Riuso massimo, coesione stilistica

3. **Refactoring Incrementale**
   - Priorità: 2 → 1 → 4 → 9 (4 settimane ~ 2h/settimana)
   - Mantenere backward compat con alias deprecati durante transizione

4. **Test & Validation**
   - Creare test suite con output PDF di riferimento
   - Assicurare refactoring non cambiano output visivo

---

### 📝 CHECKPOINTS PER PROCEEDERE

- [ ] Accordo su priorità refactoring
- [ ] Definire backward compatibility strategy
- [ ] Allocare tempo per test post-refactoring
- [ ] Scegliere se unificare frontpage/framecoverpage
