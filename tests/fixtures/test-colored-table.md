# Test: ColoredTable Global Effects

Verifica che `\ColoredTable` non contamini le tabelle successive (bug A1).

## Sezione: Tabelle

### Prima tabella (colorata)

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Riga 1A  | Riga 1B  | Riga 1C  |
| Riga 2A  | Riga 2B  | Riga 2C  |
| Riga 3A  | Riga 3B  | Riga 3C  |

### Paragrafo intermedio

Testo di transizione tra le due tabelle. La prima tabella era colorata e aveva stretching personalizzato delle righe. Questa deve tornare ai valori default.

### Seconda tabella (dovrebbe essere normal)

| Nome    | Valore | Stato |
|---------|--------|-------|
| Item 1  | 100    | OK    |
| Item 2  | 200    | KO    |
| Item 3  | 150    | OK    |

Se questa tabella ha le righe troppo distanziate o colori anomali, allora `\ColoredTable` ha inquinato lo stato globale.

### Terza tabella (verifica ancora)

| A | B | C |
|---|---|---|
| 1 | 2 | 3 |
| 4 | 5 | 6 |

Verifica che il problema non sia cumulativo.
