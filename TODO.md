# TODO — daggerheart-publish

Lista dei miglioramenti tecnici identificati dall'analisi del progetto.

---

## 🔴 Critici

### 1. ~~Rimuovere la prima `latex_escape` (bug + duplicazione)~~ ✅
**File:** `filters/daggerheart.lua` righe 78–98  
**Problema:** La prima definizione fa una passata separata su `\` e poi una gsub sugli altri caratteri, ma le `{}` prodotte dalla prima passata vengono riescappate dalla seconda (`\textbackslash{}` → `\textbackslash{\}`). La seconda definizione (riga 325) è corretta e usa una singola passata con tabella di sostituzione. La prima era inutilizzata e con bug latente.  
**Fix:** Rimossa la prima definizione.

### 2. ~~Pulire i pacchetti LaTeX duplicati in `daggerheart.cls`~~ ✅
**File:** `templates/daggerheart.cls` righe 7–33  
**Problema:** I seguenti pacchetti vengono caricati due volte:
- `geometry` (riga 12 con opzioni, riga 22 nudo)
- `multicol` (righe 17, 23)
- `tcolorbox` (riga 23 con `[most]`, riga 29 nudo)
- `graphicx` (righe 14, 32)
- `titlesec` (righe 24, 26)
- `setspace` (righe 13, 26)
- `enumitem` (righe 25, 28)
- `xcolor` caricato sia con `\RequirePackage[table]{xcolor}` sia con `\usepackage{xcolor}`  

LaTeX ignora silenziosamente i duplicati ma rallenta la compilazione e rende il file confuso.  
**Fix:** Rimuovere i duplicati; usare `\RequirePackage` uniformemente (mai `\usepackage` in un `.cls`).

### 3. ~~`cover-image-position` non supportato nell'esempio~~ ✅
**File:** `books/example-frame/book.md` riga 19  
**Problema:** Il frontmatter usa `cover-image-position: right` che non è riconosciuto dal filtro. Il parametro supportato per la cover standard è `title-image-position` / `titlepage-image-position`, non `cover-image-position`. Il valore viene silenziosamente ignorato.  
**Fix:** Rimuovere il parametro dall'esempio oppure implementare il supporto nel filtro se è un'esigenza reale.

---

## 🟡 Inconsistenze e ridondanze

### 4. ~~Merge `has_class` / `codeblock_has_class`~~ ✅
**File:** `filters/daggerheart.lua` righe 316 e 1109  
**Problema:** Le due funzioni sono identiche nell'implementazione — iterano su `el.classes` e confrontano il nome. Cambiano solo il nome.  
**Fix:** Usare una sola funzione `has_class` in entrambi i contesti.

### 5. ~~Typo `srtess` come alias di `stress`~~ ✅
**File:** `filters/daggerheart.lua` riga 554  
**Problema:** `get_first_value(parsed, { "stress", "srtess" })` — `srtess` è un typo storico probabilmente introdotto per compatibilità con un vecchio file. Se nessun libro usa `srtess`, è dead code confuso.  
**Fix:** Rimuovere `"srtess"` dall'alias list (o aggiungere un commento esplicito se la compatibilità è intenzionale).

### 6. ~~Nomi `attr_value` / `attr_or_empty` non comunicano la differenza~~ ✅
**Fix:** `attr_or_empty` era dead code (zero utilizzi) — rimossa.

---

## 🟢 Documentazione

### 7. ~~README — sezione Box: aggiornare alla sintassi shorthand~~ ✅
**File:** `README.md` sezione "Box"  
**Problema:** `squarebox`, `roundedbox`, `quotebox` usano ancora `{.classname}` mentre `fullpage` e altri usano già la forma breve. Il filtro riconosce entrambe.  
**Fix:** Aggiungere la forma breve come alternativa o principale, per uniformità.

### 8. ~~README — `rotate` in `fullpagemap`: documentare inversione larghezza/altezza~~ ✅
**File:** `README.md` sezione "Mappa a pagina intera"  
**Problema:** Non è documentato che con `rotate: 90` il filtro scambia `\paperwidth` e `\paperheight` nel calcolo delle dimensioni immagine.  
**Fix:** Aggiungere una nota nell'elenco attributi di `rotate`.

### 9. ~~README — sezione Utility: separare gli snippet per leggibilità~~ ✅
**File:** `README.md` sezione "Utility"  
**Problema:** `columnbreak`, `pagebreak` e `fullpage` sono tutti in un unico code block, suggerendo che vadano usati insieme.  
**Fix:** Separare in tre snippet distinti con una riga descrittiva ciascuno.

---

## ⚪ Minori

### 10. ~~`build.sh` — nessun check esistenza `daggerheart.lua`~~ ✅
**File:** `scripts/build.sh`  
**Problema:** Lo script verifica l'esistenza di `CLASS_FILE` e `ASSETS_DIR/fonts`, ma non del filtro Lua. Se manca, pandoc fallisce con un messaggio criptico.  
**Fix:** Aggiungere un check esplicito prima della chiamata pandoc.

### 11. ~~`build.sh` — copia font senza feedback su errore~~ ✅
**File:** `scripts/build.sh` righe ~99  
**Problema:** La logica di copia `LeagueSpartan-Extrabold` / `LeagueSpartan-ExtraBold` (case sensitivity) non ha error checking se la copia fallisce silenziosamente.  
**Fix:** Aggiungere `|| echo "Warning: font copy failed"` o simile.
