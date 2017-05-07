data1 segment 
    W1_zdanie db 'Polozenie blednego znaku',10,13,'Numer lini $'
    W1_zdanie2 db 'Numer znaku w lini $' 
    wersja db ?
    W1_linia dw 0
    W1_znak_w_lini dw 0  
    W1_OK db 'Wszystkie znaki sa alfanumeryczne$'
	offset_przepisywania dw ?
	input db 200 dup (13)   ;input 
	dlugosci db 200 dup (0)
	nowa_linia db 13,10,'$'
	sciezka db 100 dup(0)
    spacje dw 0
	slowo_spacje db 'Ilosc bialych znakow $'
    wyrazy dw 0
	slowo_wyrazy db 'Ilosc wyrazow $'
    linie dw 0 
	slowo_linie db 'Ilosc lini $'
	zdania dw 0
	slowo_zdania db 'Ilosc zdan $'
    male_litery dw 0
	slowo_male_litery db 'Ilosc malych liter $'
    duze_litery dw 0 
	slowo_duze_litery db 'Ilosc duzych liter $'
    znak_inter dw 0
	slowo_znak_inter db 'Ilosc znakow interpunkcyjnych $'
    cyfry dw 0
	slowo_cyfry db 'Ilosc cyfr $'
	inne dw 0
	slowo_inne db 'Ilosc innych znakow $'
    czy_to_juz_wyraz db 0
	czy_wczesniejszy_znak_byl_koncem db 0
	ok db 'operacja ok$'
    blad db 'wystapil blad $'  
    bufor db  16384 dup('$')  
    ilosc dw ?
    wskaznik dw 20 dup('$')
	new_line1 db 13,10
	new_line2 db 13,10,'$'
data1 ends                        

;-----------------------------------         
stos1	segment stack
	dw	200 dup(?)
top1	dw	?
stos1	ends
;---------------------------------

code1 segment
start:  
    mov ax,seg spacje
    mov ds,ax
	call PARSER_GOOD
	mov ah,ds:[dlugosci]
	cmp ds:[dlugosci],0 ;sprawdzanie dlugosci poszczegolnych danych wejsciowych
	jz bladd           
	mov ah,ds:[dlugosci+1]
	cmp ds:[dlugosci+1],0
	jz bladd    
	mov ah,ds:[dlugosci+2]
	cmp ds:[dlugosci+2],0
	jnz bladd
	mov si,0
	call PRZEPISYWANIE
	mov word ptr ds:[offset_przepisywania],si ;offset 
	xor di,di
	cmp ds:[sciezka+di],'-'
	jnz WERSJA_2
	inc di
	cmp ds:[sciezka+di],'v'
	jnz bladd
	inc di
	mov byte ptr ds:[wersja],1
	mov si,word ptr ds:[offset_przepisywania] 
	call PRZEPISYWANIE; mamy dane si z wczesniejszego PRZEPISYWANIA
	mov word ptr ds:[offset_przepisywania],si 
	mov dx,offset sciezka
	call OTWIERANIE_PLIKU
W1_GLOWNY_PROGRAM: 
    call ODCZYT_Z_PLIKU 
    call ILOSC_DANYCH_ZNAKOW 
    ; z ilosci danych znakow wywali nas i pozniej sprawdzimy gdzie byl blad
    cmp ds:[W1_linia],0
    jnz WYPISZ_WERSJA_1_BLAD
	jmp W1_GLOWNY_PROGRAM 
WYPISZ_WERSJA_1_BLAD:
    mov dx,offset W1_zdanie
    mov ah,9
    int 21h                
    mov dx,offset W1_linia
    call WYPISYWANIE_LICZBY
    mov dx,offset new_line2
    mov ah,9
    int 21h
    mov dx,offset W1_zdanie2
    mov ah,9
    int 21h
    mov bx,ds:[W1_linia] 
    cmp bx,31h
    jnz NAPRAWA
    inc ds:[W1_znak_w_lini]
NAPRAWA:                     
    ;inc ds:[W1_znak_w_lini]
    mov dx,offset W1_znak_w_lini 
    call WYPISYWANIE_LICZBY
    call ZAMKNIECIE_PLIKU
    jmp ZAKONCZ_PROGRAM  
WYPISZ_WERSJA_1_OK:
    mov dx,offset W1_OK
    mov ah,9
    int 21h
    call ZAMKNIECIE_PLIKU
    jmp ZAKONCZ_PROGRAM
WERSJA_2: ; wersja 2 programu   
    mov byte ptr ds:[wersja],2
	mov word ptr ds:[offset_przepisywania],0
	mov si,0
	call PRZEPISYWANIE
	mov word ptr ds:[offset_przepisywania],si
	mov dx,offset sciezka
    call OTWIERANIE_PLIKU 
    ; w ax jest uchwyt pliku
GLOWNY_PROGRAM: ;pobieranie danych z pliku i zapisywanie danych
    call ODCZYT_Z_PLIKU 
    call ILOSC_DANYCH_ZNAKOW
	jmp GLOWNY_PROGRAM
ZAPISYWANIE:   
    cmp ds:[wersja],2
    jz ZAPISYWANIE_W2
    mov dx,offset W1_OK ;jesli w wersji 1 wszystkie znaki byli alfanumeryczne 
    mov ah,9
    int 21h
    call ZAMKNIECIE_PLIKU
    jmp ZAKONCZ_PROGRAM
ZAPISYWANIE_W2: ; wpisywanie do outputu wszystkich danych np ILOSC_DANYCH_ZNAKOW itd
	call ZAMKNIECIE_PLIKU
	mov si,word ptr ds:[offset_przepisywania]
	call PRZEPISYWANIE
	mov dx,offset sciezka
	call tworzenie_pliku
	;--------------------------
    mov dx,offset slowo_duze_litery
	mov cx, 19d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset duze_litery
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;-----------TEST-------- 
	mov dx,offset slowo_male_litery
	mov cx, 19d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset male_litery
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_cyfry
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset cyfry
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_linie
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU  
	mov dx,offset linie
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_spacje
	mov cx, 20d
	call ZAPISYWANIE_DO_PLIKU 
	;dec ds:[spacje]
	
	mov dx,offset spacje
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_zdania
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset zdania
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_znak_inter
	mov cx, 30d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset znak_inter
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_inne
	mov cx, 20d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset inne
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_wyrazy
	mov cx, 14d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset wyrazy
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line1
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU

KONIEC_PLIKU:             
    ;ZAPISZ DO NOWEGO PLIKU ZEBRANE DANE        
    call ZAMKNIECIE_PLIKU
    mov ax,ds:[ilosc]
    jmp ZAKONCZ_PROGRAM



;----------------------------------

;-------------------------------
ILOSC_DANYCH_ZNAKOW PROC
    xor si,si
    mov cx,ds:[ilosc] 
    cmp cx,0
    jz ZAPISYWANIE ; warunek konca, czyli gdy juz nic nie pobralismy z pliku
POBIERANIE_ZNAKU:
    mov ah,ds:[bufor+si]
	cmp ah,33d  ; !
    jz TO_KONIEC_ZDANIA
    cmp ah,46d ; .
    jz TO_KONIEC_ZDANIA
    cmp ah,63d  ; ?
    jz TO_KONIEC_ZDANIA
	
	mov byte ptr ds:[czy_wczesniejszy_znak_byl_koncem],0 ; aktualny znak nie jest znakiem konca lini
	
    cmp ah,97d
    jae CZY_TO_MALA_LITERA
    cmp ah, 65d
    jae CZY_TO_DUZA_LITERA
    cmp ah,48d
    jae CZY_TO_CYFRA
    ;biale znaki 
    cmp ah,10d
    jz TO_NOWA_LINIA 
    cmp ah,32d ; spacja  i mniejsze wartosci to biale znaki
    jbe TO_SPACJA
    cmp ah, 44d ; , 
	jz TO_ZNAK_INTER
TO_NIE_ZWYKLY_ZNAK:
	xor bx,bx 
	mov bx,word ptr ds:[linie]
	mov byte ptr ds:[w1_linia],bl
	cmp ds:[wersja],1
	jz W1_KONIEC_ILOSC_DANYCH_ZNAKOW
    jmp TO_INNY_ZNAK
	
	
    

CZY_TO_MALA_LITERA:
    cmp ah,122d
    jbe TO_MALA_LITERA
    jmp TO_NIE_ZWYKLY_ZNAK
CZY_TO_CYFRA:
    cmp ah, 57d
    jbe TO_CYFRA            
    jmp TO_NIE_ZWYKLY_ZNAK
    
CZY_TO_DUZA_LITERA:
    cmp ah,90d
    jbe TO_DUZA_LITERA    
    jmp TO_NIE_ZWYKLY_ZNAK     
TO_MALA_LITERA:
    inc ds:[male_litery]
    jmp WYRAZ
TO_DUZA_LITERA:
    inc ds:[duze_litery]
    jmp WYRAZ
TO_CYFRA:
    inc ds:[cyfry]
    jmp WYRAZ 
TO_INNY_ZNAK:
	inc ds:[inne]
	jmp WYRAZ
TO_KONIEC_ZDANIA:
    inc ds:[znak_inter]
    mov byte ptr ds:[czy_to_juz_wyraz],0
	cmp ds:[czy_wczesniejszy_znak_byl_koncem],1 ; 1 ze wczesniejszy byl znakiem konca
	jz DALEJ
	inc ds:[zdania]
	mov byte ptr ds:[czy_wczesniejszy_znak_byl_koncem],1
    jmp DALEJ
TO_NOWA_LINIA: 
    inc ds:[linie]           
    ;------
    mov ds:[w1_znak_w_lini],0 ; do wersji 1, przechowywanie znaku w lini w ktorym jestesmy
    ;-----
    mov byte ptr ds:[czy_to_juz_wyraz],0   
    jmp DALEJ
TO_SPACJA:
    inc ds:[spacje]
    mov byte ptr ds:[czy_to_juz_wyraz],0  
    jmp DALEJ
TO_ZNAK_INTER:
	inc ds:[znak_inter]
	mov byte ptr ds:[czy_to_juz_wyraz],0
	jmp DALEJ
WYRAZ:
    mov al,byte ptr ds:[czy_to_juz_wyraz]
    cmp al,1  ;1 czyli jestesmy aktualnie w wyrazie, 0 ze nie jestesmy w wyrazie
    jz DALEJ                           
    mov al,1  ; to juz jest wyraz
    mov byte ptr ds:[czy_to_juz_wyraz],al 
    inc ds:[wyrazy]
 
DALEJ:    
    ;-----
    inc ds:[w1_znak_w_lini]
    ;-----
	inc si
	dec cx
	cmp cx,0
	jnz POBIERANIE_ZNAKU  
	mov bl, ds:[wersja]
	cmp bl,1
	jz WYPISZ_WERSJA_1_OK
	
W1_KONIEC_ILOSC_DANYCH_ZNAKOW:
    inc ds:[w1_linia]      
ret
ILOSC_DANYCH_ZNAKOW ENDP 
;------------------------------------------  
WYPISYWANIE_LICZBY PROC ;w dx offset liczby do wypisania    
    push bx		; wypisuje liczbe albo wpisuje ja do pliku
    push cx    
    mov bx,dx ;offset
    mov ax,ds:[bx]; liczba 
    xor si,si
    inc si
KOLEJNE_CYFRY:
    xor dx,dx
    mov cx,10d
    div cx
    push dx
    cmp ax,0
    jz KROK2
    inc si         
    jmp KOLEJNE_CYFRY
KROK2:
    pop dx 
    add dx,48d 
    cmp ds:[wersja],1
    jnz KROK2_W2
    mov ah,2
    int 21h  
KROK2_W2:
	mov word ptr ds:[bx],dx
	mov dx,bx
	mov cx,1   
	cmp ds:[wersja],1
	jz KROK2_W1
	call ZAPISYWANIE_DO_PLIKU
	jmp KROK2_W1
KROK2_W1:    	
    cmp si,1
    jz KROK3 
    dec si
    jmp KROK2 
KROK3:  
    pop cx
    pop bx
ret
WYPISYWANIE_LICZBY ENDP
;----------------------------------------

;---------------------------------
TWORZENIE_PLIKU PROC
    mov ax,seg sciezka
    mov ds,ax
    ;mov dx,offset do_zapisu
    mov cx,0  
    mov ah,3Ch
    ;mov ah,5Bh ; tworzenie pliku w danym katalogu
    int 21h    ;sprawdza czy istnieje juz taki plik
                ; w ax jest uchwyt 
	jc bladd
    mov word ptr ds:[wskaznik],ax
ret
TWORZENIE_PLIKU ENDP 
;---------------------------------------- 
ZAMKNIECIE_PLIKU PROC
    mov ah,3Eh
    mov bx,ds:[wskaznik] ;indentyfikator pliku
    int 21h 
	jc bladd	
   
ret
ZAMKNIECIE_PLIKU ENDP
;-----------------------------------------
;--------------------------------------------
ZAPISYWANIE_DO_PLIKU PROC              
    mov bx,ds:[wskaznik]  
    mov ah,40h 
    int 21h
	jc bladd
ret
ZAPISYWANIE_DO_PLIKU ENDP 
;--------------------------------------------  
;------------------------------------------
OTWIERANIE_PLIKU proc 
    mov ax, seg sciezka
    mov ds,ax
    mov ah,3Dh   ;funkcja do otwierania pliku
    mov al,0 ;prawo do odczytu
    int 21h  
    jc bladd ;flaga cf mowi czy otworzono plik
    mov word ptr ds:[wskaznik],ax ; zachowanie wskaznika      
ret  
otwieranie_PLIKU endp
;-----------------------------------------
;--------------------------------------- 
ODCZYT_Z_PLIKU proc  ;otwartego pliku
    mov ah,3Fh
    mov bx,word ptr ds:[wskaznik]
    mov cx,16384d ;2^14 elementow
	mov dx,offset bufor
    int 21h 
    jc bladd 
    mov word ptr ds:[ilosc],ax
ret
ODCZYT_Z_PLIKU ENDP
;--------------------------------------

;--------------------------------------------
;------POPRAWNY PARSER------
PARSER_GOOD PROC 
    push ax
    push bx
    push cx
    push dx
    mov dx,offset input
    mov ax,seg input
    mov ds,ax
    xor di,di 
    mov si,82h 
    xor bp,bp ; do liczenia ktory to argument
    xor cx,cx ; do liczenia dlugosci argumentu
    mov al,es:[si]
    cmp al,0
    jz FINISH_PARSER
SPACE:
    mov al,es:[si]
    inc si 
    cmp al,20h  ;czy to dalej spacja
    jz SPACE
	cmp al,08h ;CZY TO TABULATOR
	jz SPACE 
	cmp al,0Dh
	jz FINISH_PARSER
    dec si      ;cofniecie sie do niespacjowego znaku
PARSER: ; POBIERANIE NOWEGO ZNAKU Z ARGUMENTOW
    mov al,es:[si]
    inc si
    
    cmp al,0Dh  ;CZY TO 13 CZYLI KONIEC DANYCH
    jz FINISH_PARSER
    
    cmp al,20h ;CZY TO SPACJA
    jz NEW_LINE
	
	cmp al,08h ;CZY TO TABULATOR
	jz NEW_LINE
	mov ds:[input+di],al
	inc cl
	inc di
	jmp PARSER
; wydrykowanie napisu i przejscie do nowej lini
NEW_LINE:
    mov al, '$'
    mov ds:[input + di],al 
    inc di
    mov dx,offset dlugosci 
    mov ds:[dlugosci+bp],cl
    xor cx,cx  
    inc bp
    mov dx,offset input
    
; Pomijanie spacji I TABULATORA 
SPACE2: ; TUTAJ SPRAWDZA SIE CZY POMIEDZY ARG SA SPACJE
    mov al,es:[si]
    inc si 
    cmp al,20h  ;czy to dalej spacja
    jz SPACE2      
	cmp al,08h ;CZY TO TABULATOR
	jz SPACE2
    dec si
    jmp PARSER
    
FINISH_PARSER: 
   mov ds:[dlugosci+bp],cl            
   mov dx,offset dlugosci
   inc bp
   mov al,'$' 
   mov ds:[input+di],al
   pop dx
   pop cx
   pop bx
   pop ax 
ret
PARSER_GOOD ENDP
;-----------------------------------------
;------------------------------------ 
PRZEPISYWANIE PROC ; w si jest trzymany offset
	xor bp,bp
PRZEPISYWANIE_PETLA:	; przepisywanie z inputu do sciezka, zeby pobrac nazwe pliku
	mov al,byte ptr ds:[input+si]
	cmp al,'$'
	jz KONIEC_PRZEPISYWANIE
	mov byte ptr ds:[sciezka+bp], al
	inc si
	inc bp
	jmp PRZEPISYWANIE_PETLA
	
KONIEC_PRZEPISYWANIE:  
    inc si
ret
PRZEPISYWANIE ENDP
;-----------------------------------------------------
                    
bladd:
    mov dx,offset blad 
    mov ah,9
    int 21h
    
    
ZAKONCZ_PROGRAM:
    mov ax,4c01h
    int 21h


code1 ends
end start
