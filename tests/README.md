# Test Suite — daggerheart-publish

Sistema di testing per verificare compilazione, output visuale e regressioni nella pipeline Pandoc → Lua → LaTeX.

## Struttura

```
tests/
├── test-suite.sh          # Main test runner
├── validate-tex.sh        # LaTeX structure validator
├── fixtures/              # Markdown test files (critical cases)
│   ├── test-headings-colors.md      # H1 con colori/background (B1)
│   ├── test-colored-table.md        # Effetti globali \ColoredTable (A1)
│   ├── test-framecoverpage.md       # Pipeline cover (B2)
│   ├── test-spacing.md              # Conflitto spacing (D3)
│   ├── test-header-levels.md        # H1-H5, needspace (B3)
│   └── test-section-reset.md        # Transizioni sezioni (B1)
├── baseline/              # PDF di riferimento (generati con --baseline)
└── results/               # Output di compilazione e log test
```

## Uso

### 1. Generare baseline PDF (PRE-MODIFICA)

Eseguire **prima** di qualsiasi modifica critica:

```bash
chmod +x tests/*.sh
./tests/test-suite.sh --baseline
```

Questo:
- Compila tutti i libri in `books/`
- Compila tutti i fixture in `tests/fixtures/`
- Salva i PDF in `tests/baseline/`
- Crea log dettagliato in `tests/results/test-results.log`

### 2. Compilare e testare (POST-MODIFICA)

Dopo una modifica, verificare che tutto compili ancora:

```bash
./tests/test-suite.sh --verbose
```

Output:
- `✓ PASS` — Compilazione riuscita e PDF valido
- `✗ FAIL` — Compilazione fallita o PDF invalido / Differenza rispetto a baseline
- `⚠ WARNING` — Compilazione OK ma con problemi

**NUOVO**: Se un test fallisce per "Baseline mismatch", la suite genera automaticamente un **file diff visivo** per permetterti di revisionare le differenze:

```bash
# La suite crea file diff-*.pdf in tests/results/
# Visualizzali con:
./tests/view-diff.sh test-colored-table

# Oppure aprili manualmente:
# xdg-open tests/results/diff-Fixture_test-colored-table_.pdf
```

### 3. Validare struttura LaTeX intermedia

Per analizzare il LaTeX generato (necessario KEEP_TEX=1):

```bash
KEEP_TEX=1 ./tests/test-suite.sh
./tests/validate-tex.sh tests/results/*.tex
```

Verifica:
- Assenza di `}{}` spurio
- Ordine corretto dei `\setsectioncolor` vs `\section`
- Bilanciamento di `\begin{multicols}` / `\end{multicols}`
- Coerenza definizioni colore

## Test Coverage (per priorità di modifica)

| Fixture | Colpisce | Nota |
|---------|----------|------|
| `test-headings-colors.md` | B1, D1 | **CRITICO** — H1 con colori/background. Verifica che il nuovo `\dghsection[color=,bg=]` funzioni. |
| `test-colored-table.md` | A1 | **CRITICO** — Effetti globali. Verifica che `\ColoredTable` sia isolato. |
| `test-framecoverpage.md` | B2 | **CRITICO** — Cover. Verifica che il frame cover mantiene layout corretto. |
| `test-spacing.md` | D3 | Alta — Spacing. Verifica che `\setstretch{1.2}` sia pulito. |
| `test-header-levels.md` | B3, A3 | Media — H4-H5 con `\needspace`. |
| `test-section-reset.md` | B1 | Stress — Transizioni multiple di colore. |

## Workflow di refactoring

1. **PRE-MODIFICA**
   ```bash
   ./tests/test-suite.sh --baseline
   ```

2. **DURANTE**: modifica il codice

3. **POST-MODIFICA**
   ```bash
   ./tests/test-suite.sh
   ```

4. **CONFRONTO VISIVO** (automatico con diff-pdf)
   
   Se la suite rileva un mismatch tra il tuo PDF e il baseline:
   - La suite **genera automaticamente** un file `diff-*.pdf` in `tests/results/`
   - Visualizzalo con: `./tests/view-diff.sh test-colored-table`
   - Il file diff mostra visualmente cosa è cambiato tra baseline e output corrente
   - **Approva il cambio** rigenere il baseline: `./tests/test-suite.sh --baseline`

5. **ANALISI LaTeX** (se necessario)
   ```bash
   KEEP_TEX=1 ./tests/test-suite.sh
   ./tests/validate-tex.sh tests/results/fixture-test-headings-colors.tex
   ```

## Log e Diagnostica

Tutti i test producono:
- **`tests/results/test-results.log`** — output completo
- **`tests/results/<name>.pdf`** — PDF compilato
- **`tests/results/fixture-<name>/<name>.pdf`** — PDF fixture

Per debug dettagliato:
```bash
./tests/test-suite.sh --verbose 2>&1 | tee debug.log
```

## Note Importanti

1. **Baseline è sacro**: Non regenerate il baseline di proposito se non volete perdere il punto di partenza. Usate versioning (`baseline-before-B1.tar`, etc.) per backup.

2. **Fixture sono *intenzionali***: Non sono libri reali, ma test case minimalisti che colpiscono un bug specifico.

3. **Velocità**: L'esecuzione completa della suite impiega ~30-60 secondi (dipende da disk I/O e XeLaTeX).

4. **Regressione visiva**: Il PDF confronto manuale rimane il gold standard. I test automatici catturano errori di compilazione, non problemi di rendering estetico.

## Integrare in CI/CD

Per una pipeline CI (GitHub Actions, GitLab CI, etc.):

```bash
./tests/test-suite.sh
exit_code=$?
[[ $exit_code -eq 0 ]] && echo "All tests passed" || echo "Tests failed"
exit $exit_code
```

## Estensioni Future

- [x] `diff-pdf` integration per confronto automatico visivo ✅ (implementato)
- [ ] Dashboard HTML per visualizzare risultati
- [ ] Test di performance (tempo compilazione per libro)
- [ ] Snapshot testing per struttura LaTeX intermedia
