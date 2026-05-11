# Test: Paragraph Spacing and Line Height

Verifica il conflitto `\onehalfspacing` vs `\baselinestretch` (bug D3).

## Sezione: Spacing Tests

### Paragrafo 1: Baseline

Questo è un paragrafo di prova. Dovrebbe avere uno spacing di riga consistente, senza conflitti tra `\onehalfspacing` (1.5x) e `\renewcommand{\baselinestretch}{1.2}` (1.2x).

La soluzione proposta è usare solo `\setstretch{1.2}` del pacchetto `setspace`.

Questo paragrafo è abbastanza lungo per verificare il comportamento dello spacing su più righe e per osservare se la spaziatura verticale è consistente e leggibile.

### Paragrafo 2: Lungo per test multi-line

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

### Paragrafo 3: Elenco per verifica

- Elemento 1 di un elenco per verificare spacing
- Elemento 2 con testo più lungo per vedere come si comporta
- Elemento 3 finale

Paragrafo dopo l'elenco per verifica del reset dello spacing.

### Paragrafo 4: Codice e verticale

Questo paragrafo viene dopo un blocco di codice:

	title: Example
	spacing: 1.2

La spaziatura dovrebbe essere uniforme dopo il codice.
