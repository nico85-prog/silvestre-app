# Archivio storico — non più aggiornato

## Contatti_Clienti_2026-05-20_import.csv

Snapshot dei contatti clienti importati una tantum su Firestore il 20 maggio 2026.

**NON usare questo file come fonte di verità.**

Da quella data in poi, la **fonte master dei contatti marketing è Firestore**
nella collection `marketing_contacts` del progetto `silvestre-fotoservizi`.
Ogni nuovo cliente che si registra nell'app finisce automaticamente lì
(sync via `AuthState._syncMarketingContact`), e l'operatore gestisce
opt-in/STOP direttamente dal pannello operatore "Crea Promozione".

Questo file resta come backup storico di "com'era la rubrica nel maggio 2026"
nel caso fosse necessario riferimento per audit o ripristino disaster-recovery.

## Per esportare la lista AGGIORNATA

Se in futuro serve un .csv dei contatti correnti (es. backup, audit, fornitura
a un sistema esterno): usare il bottone "Esporta contatti (.csv)" nel pannello
operatore (TODO se non ancora implementato) o eseguire una query Firestore.
