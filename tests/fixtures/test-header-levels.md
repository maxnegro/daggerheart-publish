# Test: All Heading Levels

Verifica gestione H1-H5, multicols, needspace (B3), e forme con asterisco (A3).

## Level 2: Section

Contenuto di una sezione di livello 2.

### Level 3: Subsection

Contenuto di una sottosezione di livello 3.

#### Level 4: Paragraph

Contenuto di un paragrafo di livello 4. In LaTeX corrisponde a `\paragraph`.

Questo livello dovrebbe ricevere `\needspace{3\baselineskip}` per evitare orphan.

##### Level 5: Subparagraph

Contenuto di un sottoparagrafo di livello 5. In LaTeX è `\subparagraph`.

Anche questo dovrebbe avere `\needspace`.

### Torno a Level 3

Per verificare il comportamento quando risaliamo nella gerarchia.

## Torno a Level 2

E infine un nuovo paragrafo per completare il test.

Questo paragrafo fa parte del nivel 2 e deve mantenere il layout corretto in multicols.
