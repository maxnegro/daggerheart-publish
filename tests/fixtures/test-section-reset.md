# Test: Section Transitions and Color Reset

Stress test per verifica che i colori delle sezioni siano resettati correttamente tra transizioni (B1).

## Sezione Red {.sectioncolor-dg-red}

Contenuto della sezione rossa. Il titolo è rosso.

Paragrafo 1.

Paragrafo 2.

## Sezione Blue {.sectioncolor-dg-blue}

Contenuto della sezione blu. Il colore precedente (rosso) dovrebbe essere stato resettato.

Paragrafo 1.

Paragrafo 2.

## Sezione Green {.sectioncolor-dg-green}

Contenuto della sezione verde. Un'altra transizione.

Paragrafo 1.

Paragrafo 2.

## Sezione Purple {.sectioncolor-dg-purple}

E una quarta sezione con colore diverso.

Paragrafo 1.

Paragrafo 2.

## Default Section

Ritorno al colore di default (nessun attributo `sectioncolor`).

Paragrafo 1.

Paragrafo 2.

Questo test verifica che:
1. Ogni sezione ha il colore corretto
2. Il reset del colore avviene al momento giusto
3. Non ci sono effetti residui di sezioni precedenti
