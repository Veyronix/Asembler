data1 segment  
	input db 200 dup (13)   ;input 
	dlugosci db 200 dup ('$')
	nowa_linia db 13,10,'$'
	sciezka db 100 dup(10),10
    spacje dw 0
	slowo_spacje db 'Ilosc spacji $'
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
    plik db 'nowy.txt',0
    text db 'Hej'
	do_zapisu db 'zapis.txt',0
    sciezka db 'nowy.txt',0 
    ok db 'operacja ok$'
    blad db 'wystapil blad $'  
    bufor db  16384 dup('$')  
    ilosc dw ?
    wskaznik dw 20 dup('$')
	new_line db 13,10
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
    call OTWIERANIE_PLIKU 
    ;call tworzenie_pliku 
    ; w ax jest uchwyt pliku
GLOWNY_PROGRAM:
    call ODCZYT_Z_PLIKU
    ;call ZAPISYWANIE_DO_PLIKU 
    call ILOSC_DANYCH_ZNAKOW
    ;call POSZCZEGOLNE_ZNAKI
	jmp GLOWNY_PROGRAM
ZAPISYWANIE:
	call ZAMKNIECIE_PLIKU
	call tworzenie_pliku
	;--------------------------
    mov dx,offset slowo_duze_litery
	mov cx, 19d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset duze_litery
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;-----------TEST-------- 
	mov dx,offset slowo_male_litery
	mov cx, 19d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset male_litery
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_cyfry
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset cyfry
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_linie
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset linie
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_spacje
	mov cx, 13d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset spacje
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_zdania
	mov cx, 11d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset zdania
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_znak_inter
	mov cx, 30d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset znak_inter
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_inne
	mov cx, 20d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset inne
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU
	;---------------------------------------
	mov dx,offset slowo_wyrazy
	mov cx, 14d
	call ZAPISYWANIE_DO_PLIKU
	mov dx,offset wyrazy
	call WYPISYWANIE_LICZBY
	mov dx,offset new_line
	mov cx,2d
	call ZAPISYWANIE_DO_PLIKU

KONIEC_PLIKU:             
    ;ZAPISZ DO NOWEGO PLIKU ZEBRANE DANE        
    call ZAMKNIECIE_PLIKU
    mov ax,ds:[ilosc]
    jmp ZAKONCZ_PROGRAM
    
    mov ah,9 
    mov dx,offset blad
    int 21h
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
    jmp TO_INNY_ZNAK
	
	
    

CZY_TO_MALA_LITERA:
    cmp ah,122d
    jbe TO_MALA_LITERA
CZY_TO_CYFRA:
    cmp ah, 57d
    jbe TO_CYFRA
    
CZY_TO_DUZA_LITERA:
    cmp ah,90d
    jbe TO_DUZA_LITERA         
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
	inc si
	dec cx
	cmp cx,0
	jnz POBIERANIE_ZNAKU
	;loop POBIERANIE_ZNAKU
       
ret
ILOSC_DANYCH_ZNAKOW ENDP 
;------------------------------------------  
WYPISYWANIE_LICZBY PROC ;w dx offset liczby do wypisania    
    push bx
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
    mov ah,2
    int 21h
	mov word ptr ds:[bx],dx
	mov dx,bx
	mov cx,1
	call ZAPISYWANIE_DO_PLIKU
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
POSZCZEGOLNE_ZNAKI PROC
    xor si,si
    mov dl, ds:[bufor+si] 
znaki:
	cmp si,ds:[ilosc] 
    jz KONIEC_POSZCZEGOLNE_ZNAKI
    mov ah,2
    int 21h  
    inc si
    mov dl,ds:[bufor+si]  
    jmp znaki   
KONIEC_POSZCZEGOLNE_ZNAKI:
ret        
POSZCZEGOLNE_ZNAKI ENDP
;-----------------------------------
;---------------------------------
TWORZENIE_PLIKU PROC
    mov ax,seg do_zapisu
    mov ds,ax
    mov dx,offset do_zapisu
    mov cx,0  
    ;mov ah,3Ch
    mov ah,5Bh ; tworzenie pliku w danym katalogu
    int 21h    ;sprawdza czy istnieje juz taki plik
                ; w ax jest uchwyt  
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
    ;mov ax,seg spacje
    ;mov ds,ax
    ;mov dx,offset spacje
    ;mov cx,3d ;ile bajtow ma zapisac
    ;mov cx,ds:[ilosc]
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
    mov dx,offset sciezka
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
    ;mov cx,100d
	mov dx,offset bufor
    int 21h 
    jc bladd 
    mov word ptr ds:[ilosc],ax
ret
ODCZYT_Z_PLIKU ENDP
;--------------------------------------
;---------------------------------------
SPRAWDZANIE_CZY_OTWORZYLO_PLIK proc 
    mov ax, seg sciezka
    mov ds,ax
    mov dx,offset sciezka
    mov ah,3Dh
    mov al,2 ;prawo do zapisu i odczytu
    int 21h 
  jc error
    mov ah,9
    lea dx,ok
    int 21h
    jmp przeskocz
  error:
    mov ah,9
    lea dx,blad
    int 21h
  przeskocz:
  
  jmp zakoncz_program              
ret
SPRAWDZANIE_CZY_OTWORZYLO_PLIK ENDP  
;--------------------------------------------
;-----------------------------------------
                    
bladd:
    mov dx,offset blad 
    mov ah,9
    int 21h
    
    
ZAKONCZ_PROGRAM:
    mov ax,4c01h
    int 21h


code1 ends
end start
