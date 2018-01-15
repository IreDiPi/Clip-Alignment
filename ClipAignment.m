clc
close all
clear all

%% LETTURA FILE AUDIO

%Primo segnale: audio del video
info = audioinfo('AudioVideo.wav'); %salvo nella variabile info le informazioni del file;
[audio_video,info.SampleRate]=audioread('AudioVideo.wav'); %audio_video = variabile in cui salvo il file letto; in questo caso il file estratto dal video
%info.SampleRate = frequenza di campionamento del file letto.
t=0:seconds(1/info.SampleRate):seconds(info.Duration);
t=t(1:end-1);
% a=info; %In a mi salvo le info acquisite del file AudioVideo

%Leggo secondo file: registrazione dal cellulare
info= audioinfo('AudioCell.wav');
[audio_cell,info.SampleRate]=audioread('AudioCell.wav');
t_cell=0:seconds(1/info.SampleRate):seconds(info.Duration);
t_cell=t_cell(1:end-1);
%% ALLINEAMENTO INIZIALE

l_cut=200*10^5;  %lunghezza taglio per allineare inizio
%l_cut=ceil(abs(info.TotalSamples - a.TotalSamples)*0.1);

% Taglio seganli audio
y_cell_cut=audio_cell(1:l_cut);
y_video_cut=audio_video(1:l_cut);
t_cut=t(1:length(y_video_cut));

% Cross-correlazione
[Rx,lag] = xcorr(y_video_cut,y_cell_cut);  
[~,I]=max(abs(Rx));
lag_diff=lag(I);
time_diff=lag_diff/info.SampleRate;

%plot della cross-correlazione
figure
plot(lag/info.SampleRate,Rx)
xlabel('Lag [s]')
ylabel('A');

% Modifica segnale cell
audio_cell = audio_cell(-lag_diff+1:end);
t_cell = (0:length(audio_cell)-1)/info.SampleRate;
%Stampo il ritardo in secondi
sprintf('Audio registrato dal cellulare in ritardo di %d [s]',time_diff)

% Plot per verificare se il taglio iniziale va bene
figure
%subplot(2,1,1)
plot(t(1:10^6),(audio_cell(1:10^6)-1),'r')
title('ALLINEAMENTO')
hold on
%subplot(2,1,2)
plot(t(1:10^6),(audio_video(1:10^6)+1),'b')
%title('video')
xlabel('Time [s]')
%% ELIMINAZIONE SILENZI
%Scelta parametri
secondi_intervallo=20; %Intervallo sezioni in cui andare a togliere i silenzi
secondi_intervallo_prec=4; %Intervallo di precisione. Deve essere un sottomultiplo di secondi_intervallo
soglia_prec=0.01;  %[s] valore per far entrare controllo di precisione. Superata la soglia si passa a secondi_intervallo_prec
n_campioni_int=secondi_intervallo*info.SampleRate; %numero campioni in un intervallo
n_int=floor(length(audio_video)/n_campioni_int); %numero di intervalli

%Campioni di inizio e fine di ogni intervallo --> Ad ogni intervallo andrò
%a sostituire queti valori
int_start=1; %Inizializzazione campione iniziale
int_end=n_campioni_int; %Campione finale

%Inizializzo deriva
deriva_campioni=0;

%Inizio il ciclo
for i=1:n_int %Ciclo intervalli totali
    
    %Calcolo la Cross-Correlazione
    [Rx,lag] = xcorr(audio_video(int_start:int_end),audio_cell(int_start:int_end));  
    [~,I]=max(abs(Rx));
    lag_diff=lag(I);
    time_diff=lag_diff/info.SampleRate;
    
    lag_vect(i)=lag_diff; %Mi salvo i disallineamenti in lag_vect per calcolarmi poi la differenza
    
    if i>1 %Per fare la differenza devo aver l'indice maggiore di 1
        diff(i)=abs(lag_vect(i)-lag_vect(i-1)); %Mi calcolo le relative differenze in valore assoluto
        
        if abs(diff(i))>soglia_prec*info.SampleRate %Se la differenza calcolata supera la soglia di precisione entro nell'if
            %Se la differenza calcolata è maggiore della soglia definita
            %(0.01) allora lavoro sull'intervallo più preciso 4 secondi
            %definizione intervalli precisi
            int_start_prec=int_start;
            int_end_prec=int_start+secondi_intervallo_prec*info.SampleRate;
            T=finddelay(audio_video(int_start_prec:int_end_prec),audio_cell(int_start_prec:int_end_prec))/info.SampleRate;
            sprintf("Disallineamento trovato %d (in sec %d e T %d) ad intervallo %d",diff(i),diff(i)/44100,T,i) %Stampo tutti i disallineamenti per ogni intervallo
            
            %Dopo aver risettato i parametri iniziali entro nel ciclo for
            for j=1:secondi_intervallo/secondi_intervallo_prec
                %Calcolo la cross-correlazione
                [Rx,lag] = xcorr(audio_video(int_start_prec:int_end_prec),audio_cell(int_start_prec:int_end_prec));  
                [~,I]=max(abs(Rx));
                lag_diff_prec=lag(I);
                time_lag_prec=lag_diff_prec/info.SampleRate;
                lag_vect_prec(j)=lag_diff_prec;
                
                %Calcolo differenza tra i due segnali
                if j==1
                    diff_prec(j)=abs(lag_vect_prec(j)-diff(i));
                else
                    diff_prec(j)=abs(lag_vect_prec(j)-lag_vect_prec(j-1));
                end
                
                %Verifico se la differenza è un Freeze o un disallineamento
                %di clock
                if abs(diff_prec(j))<soglia_prec*info.SampleRate
                    deriva_campioni=deriva_campioni+diff_prec(j); %se risulta minore avrò un disallineamento di clock
                %Se risulta maggiore avrò un freeze
                else 
                    sprintf('Trovato silenzio di %d nell intervallo %d - %d  [s]',time_lag_prec,(int_start_prec/info.SampleRate),(int_end_prec/info.SampleRate))
                end
                
                %T=finddelay(audio_video(int_start_prec:int_end_prec),audio_cell(int_start_prec:int_end_prec))/info.SampleRate
                %Aggiorno risultato senza i silenzi addizionali e con il giusto
                %allineamento di clock
                y_noPause(int_start_prec:int_end_prec) = audio_cell(int_start_prec-lag_diff_prec:int_end_prec-lag_diff_prec);
                
                %preparazione intervalli per prossimo ciclo di precisione
                int_start_prec=int_end_prec+1;
                int_end_prec=int_end_prec+secondi_intervallo_prec*info.SampleRate;
            end
        else
            %Calcolo la deriva
            deriva_campioni=deriva_campioni+diff(i);
        end
    end
    %Aggiorno risultato senza i silenzi addizionali e con il giusto allineamento di clock
    y_noPause(int_start:int_end) = audio_cell(int_start-lag_diff:int_end-lag_diff);
    
    %Aggiornamento intervallo (inizio e fine)
    int_start=int_start+n_campioni_int;
    int_end=int_end+n_campioni_int;   
end
%Verico l'ultimo pezzo fuori dal ciclo.
int_start=int_end+1;
int_end=length(audio_video);
[Rx,lag] = xcorr(audio_video(int_end:end),audio_cell(int_end:end));  
[~,I]=max(abs(Rx));
lag_diff=lag(I);
time_diff=lag_diff/info.SampleRate;

%Aggiornamento file audio finale con l'aggiunta dell'ultimo pezzo
 y_noPause(int_start:length(audio_cell)+lag_diff) = audio_cell(int_start-lag_diff:length(audio_cell));

%% ALLINEO FINE DEL FILE AUDIO DEL CELLULARE & OUTPUT
if length(audio_video)<length(y_noPause)
    y_noPause(length(audio_video)+1:end)=[];
end

%stampa deriva
sprintf('La deriva totale è di %d [ms]',deriva_campioni/info.SampleRate*10^3)

%plot a pezzi
in=1;
fin=10*10^6;
for h=1:(floor(length(y_noPause)/(10*10^6))-1)
        figure
        %subplot(2,1,1)
        %subplot(2,1,2)
        plot(t(in:fin),(y_noPause(in:fin)-0.5),'b')
        title('cell, no pause')
        hold on
        %subplot(2,1,2)
        plot(t(in:fin),(audio_video(in:fin)+0.5),'r')
        title('video')
        %xlabel('Time (s)') 
        in=in+10*10^6;
        fin=fin+10*10^6;
end
figure
%subplot(2,1,1)
%subplot(2,1,2)
plot(t_cell(in+1:length(y_noPause)),(y_noPause(in+1:end)-0.5),'b')
title('cell, no pause')
hold on
%subplot(2,1,2)
plot(t_cell(in+1:length(audio_video)),(audio_video(in+1:end)+0.5),'r')
title('video')
%xlabel('Time (s)') 
in=in+10*10^6;
fin=fin+10*10^6;

%OUTPUT
% audiowrite('Audio_video.wav',audio_video,info.SampleRate)
audiowrite('Audio_cell.wav',y_noPause,info.SampleRate)
