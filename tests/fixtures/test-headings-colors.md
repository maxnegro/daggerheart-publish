# Test: Heading Colors and Section Backgrounds

Test per verificare la pipeline H1 (B1) e il reset dei colori tra sezioni.

## Sezione 1: Rosso senza background {.sectioncolor-dg-red}

Paragrafo di prova per la sezione rossa. Il colore dovrebbe resetarsi prima della sezione successiva.

Altro paragrafo per verificare lo spacing e la compatibilità con il layout multicols.

## Sezione 2: Blu con background {.sectioncolor-dg-blue bg="assets/test-bg.jpg"}

Questa sezione ha un background e un colore diverso. La pipeline Lua dovrebbe iniettare i parametri corretti.

Il filtro Lua emette:
- `\setsectioncolor[color=dg-blue,bg=assets/test-bg.jpg]` (unico RawBlock dichiarativo)
- La classe `\dghsection` gestisce tutto internamente

### Sottosezione 2.1

Una sottosezione per verificare il comportamento in multicols.

## Sezione 3: Reset al verde {.sectioncolor-dg-green}

Verifica che il colore precedente sia stato resetato. Questa sezione torna al default.

Ulteriori paragrafi per validare continuità del layout.
