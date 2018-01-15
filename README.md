# Clip-Alignment
Progetto per il corso "Elaborazione dell'Audio Digitale" a.a 2017/2018

Funzioni del programma:
Sezione 1  --> Lettura file audio con relative informazioni
Sezione 2  --> Allineamento iniziale di due audio disallineati attraverso il calcolo della cross-correlazioni (funzione x-corr)
Sezione 3  --> Ciclo iterativo per: eliminazione silenzi addizionali ("freeze") nel file audio del cellulare; deriva (disallineamento dei clock)
Sezione 4 --> Allineamento fine dei file output e scrittura del file finale

Procedura di installazione
- Inserire i file audio estratti nella stessa cartella in cui è salvato il file matlab (.m)
- Formato file audio: wav
- Nomi file audio: "AudioCell" e "VideoCell"

Scelta dei parametri (variabili)
- secondi_intervallo=20
	Intervallo sezioni in cui andare a togliere i silenzi
- secondi_intervallo_prec=4
	Intervallo di precisione. Deve essere un sottomultiplo del parametro sopra indicato "secondi_intervallo=20"
- soglia_prec=0.01
  Se il disallineamento supera la soglia di 0.01ms verifico in un ciclo interno e cerco il "freeze"

Criticità:
Valore della deriva finale un po' elevato
  
