# Changelog

## [0.0.6] - 2026-08-17

- Modifica l'allineamento degli elenchi puntati e numerati in daggerheart.cls (9225c4c)
- Updated examples (4770969)
- Imposta larghezza predefinita per le immagini in LaTeX su \\linewidth se non specificata (807489f)
- Aggiunta linee guida per la scrittura del codice in AGENTS.md (75fdec4)
- Consenti elenchi puntati immediatamente dopo le righe di testo nei blocchi scalari YAML (0e6e70c)
- Aggiustata generazione dell'indice in caso di cover-page custom (d9cfb4a)
- Aggiunta funzione meta_author_to_latex per gestire la formattazione degli autori. Aggiornato il campo designer in frontpage custom per utilizzare il valore dell'autore se non specificato. (0934c7a)
- Aggiornato il TODO con dettagli per la rifattorizzazione della macro H1. Tabelle: aggiunta funzione per calcolare la lunghezza del testo nelle celle per adattare le dimensioni delle colonne. (f895544)
- Aggiornato il TODO per riflettere l'introduzione della macro unificata \dghsection in daggerheart.cls (34405bb)
- Aggiunti controlli golden per i casi H1 e script di verifica; aggiornato il TODO con vincoli di sicurezza e comportamento attuale (a3f6b8b)
- Aggiunti helper interni per la gestione delle transizioni tra colonne multiple in daggerheart.cls (d9b6917)
- Aggiornamento TODO (e4c68fa)
- Aggiornato il TODO con il completamento della correzione del conflitto tra \onehalfspacing e \baselinestretch. Aggiunta integrazione automatica per il confronto visivo dei PDF nei test e creato uno script per visualizzare le differenze. (45c3528)
- Isolati gli effetti globali di \ColoredTable con \begingroup...\endgroup e aggiornati i task nel TODO (94513b7)
- Test per verifica flusso conversione pre refactor (d8dde9f)
- Corretto un errore di sintassi nel comando di chiusura della sezione di stile. (d5460b1)
- Appunti per miglioramenti futuri (76f7b8c)
- Rinominati i comandi per gli avversari e l'ambiente con il prefisso 'dgh' per una maggiore coerenza e chiarezza nel codice. (ecd5e8a)
- Aggiunti spaziature per le intestazioni di sezione e sottosezione per migliorare la coerenza del layout (a144100)
- Aggiunti comandi pubblici per gestire il comportamento del page-break in modalità a due colonne (3a35625)
- Rimosse definizioni ridondanti di colori e unificati i comandi per una gestione più coerente dei colori delle scatole. (b240dcd)
- Rimossi i toggle numerici per i comandi di abilitazione dell'immagine di copertina frame, sostituiti con condizioni più idiomatiche in LaTeX per migliorare la leggibilità e ridurre la fragilità del codice. (9e4077a)
- Corretto un errore di ortografia nella definizione dell'etichetta di complessità in italiano. (1c77a93)
- Rimosse duplicazioni di codice nella gestione delle sezioni e migliorata la coerenza dei comandi per l'altezza e il sollevamento dello sfondo. (b141627)
- Rinominati i comandi per le pagine complete in `daggerheart` da `\beginFullpage` e `\finishFullpage` a `\dghfullpagestart` e `\dghfullpageend`, introducendo un ambiente `dghfullpage` per una migliore coerenza e compatibilità futura. (4b583d1)
- Unificati i comandi `\adversarystats` e `\environmentstats` utilizzando un renderer generico `\dghstat`, migliorando la coerenza e riducendo la duplicazione di codice. (520dcde)
- Unificati i comandi `\adversary` e `\colossusadversary` in un comando interno `\dgh@entity`, migliorando la coerenza e riducendo la duplicazione di codice. (a40a3fc)
- Ristrutturati gli stili delle scatole condivise per una maggiore coerenza e riutilizzabilità nella classe `daggerheart` (319d420)
- Rimosse dichiarazioni ridondanti e ristrutturato il codice per una migliore leggibilità nella classe `daggerheart` (775596e)
- Aggiornata la classe `daggerheart` per includere la libreria `shadings` in TikZ e rimosse le dichiarazioni ridondanti. (cf7217c)
- Aggiornamento CHANGELOG (c95f77b)

## [0.0.5] - 2026-05-08

- Aggiornati esempi e documentazione. (e5b3011)
- Titolo della TOC in due colonne (be0250b)
- Modifica rappresentazione autori e data in titlepage (65ff18f)
- Aggiunta del supporto per RawInline e Math in LaTeX, e nuove macro per la gestione dei separatori di sezione (cfebb67)
- Rimozione di spaziature non necessarie nei blocchi di testo per una migliore formattazione (d0d0d5e)
- Errore per gli header all'interno di blocchi fullpage (cf4a441)
- Modifica della spaziatura nei blocchi di testo in LaTeX per una migliore formattazione (1903062)
- Feature in italico e grassetto (ddf5b17)
- Supporto per liste puntate nelle feature degli ambienti, usando yaml block scalar (8f19869)
- Changes to support Colossi adversaries and segments (f07deac)

## [0.0.4] - 2026-05-05

- Aggiunta di example-frame.pdf al .gitignore e creazione del file dist/example-frame.pdf (6cf9472)
- Aggiunta del blocco `headerlist` per generare un indice automatico da heading in Markdown (0f2817d)
- Aggiornato CHANGELOG e pulito TODO (9a3a170)

## [0.0.3] - 2026-05-01

- Ultimi ritocchi  alla generazione coverpage stile frame ed esempio relativo (359b79a)
- Supporto build per MacOS e Windows (101a6fe)
- Refactor di \setsectioncolor per diventare una classe di h1 (1a25a4c)
- Giro di pulizia di codice e documentazione + rimozione dead code (e790a08)
- Miglioramenti alla gestione dei blocchi Markdown e supporto per attributi nei div (974f484)
- Prima implementazione framecoverpage completata (d6f3742)
- Lavoro sulla coverpage di frame (7784489)
- Bozza cover page modello frame (2b6e3ec)
- Aggiunta sintassi alternativa per comandi di interruzione di pagina e colonna nel filtro LaTeX (afac059)
- Aggiornato il changelog per la versione 0.0.2. (8b3620b)

## [0.0.2] - 2026-04-30

- Aggiunta della gestione della tabella dei contenuti con profondità configurabile e commentata la rottura di colonna nel template LaTeX. (228db4b)
- Aggiornati i nomi e le descrizioni in italiano per alcuni  avversari ed  ambienti di esempio, inclusi miglioramenti alle macro per la gestione dei tipi e dei ranghi. (74f2a5d)
- Aggiornato l'esempio con una nuova formattazione delle liste e aggiunta di una sezione per le citazioni. (70375a2)
- Migliorata gestione fullpagemap (a5a6e22)
- Forzato pagebreak prima di pagine con mappa a tutta pagina (ec27b2b)
- Aggiornati esempi di rendering per avversari ed ambienti con domande aggiuntive sui tratti (2953543)
- Aggiornato README.md con percorsi di esempio per la build e output predefiniti (bcff172)
- Rinominato file LICENSE in LICENSE.md (1c1df66)
- Aggiornata la nota sui formati supportati dal filtro Lua per chiarire la compatibilità con il plugin 'obsidian fantasy statblocks'. (8244742)

## [0.0.1] - 2026-04-29

- Aggiunti hook gitflow per gestione release (bb59a55)
- Aggiunto file VERSION (f15eddf)
- Updated example.pdf (a78fc84)
- Removed leftover example from early development (52cf044)
- Fix parser for double quotes, question in enviroments and underscore italic (6f695d8)
- Debug and documentation for full page map feature (add67c6)
- Old environment format in example document (72729df)
- Italian translation for adversary and environment blocks + some cleaning up (e6d11e5)
- Rendering debug and new syntax for adversaries and environments (from obsidian plugin) (7f62698)
- Minor edits (2622f93)
- Updated README with preview (cdc6316)
- Updated credits section in README (f65832d)
- Added credits for original work by roland04 (43496ef)
- Better image handling (f63c1f5)
- Example book (5fe1762)
- Migliorata gestione header con background e documentazione (bdc3d54)
- Titoli h1 con background (0973a3a)
- Modifiche al footer (be66b9c)
- Gestione build a partire da una struttura di cartelle (880fc56)
- Import iniziale
