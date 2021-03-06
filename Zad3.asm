.387


data1 segment 
	ok db 'operacja ok$'
    blad db 'wystapil blad $'  
    bufor db  16384 dup('$')  
    ilosc dw ? 
    sciezka db 100 dup(0)
    wskaznik dw 20 dup('$')
	new_line1 db 13,10
	new_line2 db 13,10,'$'  
	dlugosci db 200 dup (0)
	offset_przepisywania dw ?
	x dd 154.0
	y dd 100.0
	kolor db 7
	testy dw 0  
	input db 200 dup (13)   ;input
	stan_piora db 0 ; 0-opuszczone 1-podniesione
	kat dd 0.0                         
	bufor_na_liczbe dw 0 
	sto80 dd 180.0
	zmienna dw 0
	smietnik dd 0.0
	delta dd 0.0
	stan_Px_Kx db 0 ;0 dodatnie 1 ujemne
	stan_Py_Ky db 0
	x1 dw 0
	y1 dw 0
	x2 dw 0 
	y2 dw 0 
	tmp dw 0
	tmpx dw 0
	tmpy dw 0
data1 ends                        

;-----------------------------------         
stos1	segment stack
	dw	200 dup(?)
top1	dw	?
stos1	ends
;---------------------------------

code1 segment
start: 

    mov ax,seg ok
    mov ds,ax  
 
	mov ax,00h
	mov al,13h
	int 10h
	
	;mov ax, 3
	;int 10h

	;mov ax,4C00h
	;int 21h
	
    finit  
    fld ds:[kat]; zaladowanie na st(0) kat,st(1)=PI,
    fld ds:[x] ;x konca odcinka
    fld ds:[y] ; y konca odcinka
    fld ds:[x] ;x poczatka odcinka
    fld ds:[y] ; y poczatka odcinka
	
	call PARSER_GOOD
	mov ah,ds:[dlugosci]
	mov si,0 ;offset do PRZEPISYWANIE
	call PRZEPISYWANIE
	mov word ptr ds:[offset_przepisywania],si 
	mov dx,offset sciezka
	call OTWIERANIE_PLIKU
GLOWNY_PROGRAM: 
    call ODCZYT_Z_PLIKU ; W ds:[ilosc] jest ilosc znakow
	xor si,si
	dec si
KOLEJNE_ZNAKI:
	inc si
	cmp si,ds:[ilosc]
	jz KONIEC_KOLEJNE_ZNAKI 
	mov al,byte ptr ds:[bufor+si]
	cmp ds:[bufor+si],10d ;koniec pliku, moze
	jz KONIEC_KOLEJNE_ZNAKI 
	cmp ds:[bufor+si],32d;spacja 
	jz KOLEJNE_ZNAKI
	cmp ds:[bufor+si],114d
	jz OBROT
	cmp ds:[bufor+si],109d
	jz NAPRZOD
	cmp ds:[bufor+si],117d
	jz DO_GORY
	cmp ds:[bufor+si],100d
	jz OPUSC
OBROT:
	inc si
	cmp ds:[bufor+si],32d;spacja
	jz OBROT
	cmp ds:[bufor+si],45d; -
	jz OBROT_MINUS
	call ZAMIANA_NA_LICZBE    
	mov al,byte ptr ds:[bufor_na_liczbe]
	;add ds:[kat],al 
	;-------------
	;dolozenie kata na koprocesor
	;---------------------     
	fild word ptr ds:[bufor_na_liczbe]
    fld ds:[sto80]
    fdivp st(1),st(0) ;podziel alfa/180 i zdejmij st(0)

    fldpi ;st(0)=PI
    fmulp st(1),st(0); otrzymanie alfa*PI/180 i zdejmij st(0)  
    faddp st(5),st(0);dodaje do aktualnego katu alfa*PI/180 i usuwam st(0)
	
	jmp KOLEJNE_ZNAKI
	
OBROT_MINUS:
	
NAPRZOD:
    inc si
    cmp ds:[bufor+si],32d;spacja
    jz NAPRZOD
    call ZAMIANA_NA_LICZBE
    mov al,byte ptr ds:[bufor_na_liczbe]
    call KRESKA
	jmp KOLEJNE_ZNAKI
DO_GORY:
	mov byte ptr ds:[stan_piora],1
	jmp KOLEJNE_ZNAKI
OPUSC:
	mov byte ptr ds:[stan_piora],0
	jmp KOLEJNE_ZNAKI
	
KONIEC_KOLEJNE_ZNAKI:

    call ZAMKNIECIE_PLIKU
    jmp ZAKONCZ_PROGRAM  



;-----------------------------------
KRESKA PROC  ; w al jest wartosc ile isc naprzod
    ;fild word ptr ds:[bufor_na_liczbe]   ;ile ide na przod
	fldz ; st(0)=0.0
	fadd st(0),st(5) ; st(0)=kat
    fsincos ;st(0)=cos(st(0)), st(1)=sin(st(0))  fsincos przesuwa stos o dwa rejestry, nie nadpisuje st(1)
	fild word ptr ds:[bufor_na_liczbe]
	
	fmul st(1),st(0) ; st(1)=x*cos(kat)
	fmulp st(2),st(0) ; st(2)=x*sin(kat) i usuniecie st(0)

	fsubp st(4),st(0); Ky=Ky-x*cosalfa , minus bo w dol jest plus, odwrotnie niz w ukladzie wspolrzednych
	faddp st(4),st(0) ; Kx=Kx+x*sinalfa

	fldz
	fadd st(0),st(2) ; st(0)=Px
 	fsub st(0),st(4) ; st(0)=Px-Kx
	ftst ; porownanie st(0) z zerem
	fstsw word ptr ds:[zmienna] 
	mov ax,ds:[zmienna]
	sahf
	ja DEL_X_DOD
	jmp DEL_X_UJ
	;-----

	
	
	
	
DEL_X_DOD:
	mov byte ptr ds:[stan_Px_Kx],0
	jmp PO_DEL_X
DEL_X_UJ:
	mov byte ptr ds:[stan_Px_Kx],1
PO_DEL_X:
	fabs ; |Px-Kx|
	fldz 
	fadd st(0),st(2) ; st(0)=Py
 	fsub st(0),st(4) ; st(0)=Py-Ky
	ftst ; porownanie st(0) z zerem
	fstsw word ptr ds:[zmienna] 
	mov ax,ds:[zmienna]
	sahf
	ja DEL_Y_DOD
	jmp DEL_Y_UJ
DEL_Y_DOD:
	mov byte ptr ds:[stan_Py_Ky],0
	jmp PO_DEL_Y
DEL_Y_UJ:
	mov byte ptr ds:[stan_Py_Ky],1
PO_DEL_Y:
	fabs ; wartosc bezwgledna z st(0)
	
;Sprawdzenie ktora roznica na modul jest wieksza	
	fcom st(1) ; porownanie Px-Kx z Py-Ky
	fstsw word ptr ds:[zmienna] 
	mov ax,ds:[zmienna]
	sahf
	ja X_MNIEJSZE_Y
X_WIEKSZE_Y: ;|Px-Kx|>|Py-Ky|
	fdivrp st(1),st(0) ;st(1)=|Py-Ky|/|Px-Kx| i usun st(0)
	fstp ds:[delta]
	mov ax, 3
	int 10h

	mov ax,4C00h
	int 21h
	jmp KONIEC_KRESKA
	
	
X_MNIEJSZE_Y:	;|Px-Kx|<|Py-Ky|
	;mov ax, 3
	;int 10h
	;mov dx,offset ok
	;mov ah,9
	;int 21h
	;mov ax,4C00h
	;int 21h
	fdivp st(1),st(0) ; st(0)=|Kx-Px|/|Ky-Py| i usun st(0)
	fstp ds:[delta]
	fldz ;st(0)=0.0
	fadd st(0),st(2) ; st(0)=Px
	fstp ds:[x] ;zapisz do ds:[x] Px i usun ze stosu
	fldz
	fadd st(0),st(1) ;st(0)=Py
	fistp ds:[tmpy] ;czesc calkowita Py
	fldz 
	fadd st(0),st(3); st(0)=Ky
	fistp ds:[y2] ;czesc calkowita Ky
	cmp ds:[stan_Px_Kx],1 ;CZY UJEMNE
	jz X_MNIEJSZE_Y_i_XUJ
	cmp ds:[stan_Py_Ky],1 ; CZY UJEMNE
	jz X_MNIEJSZE_Y_i_XDOD_YUJ
	
X_MNIEJSZE_Y_i_XDOD_YDOD:


X_MNIEJSZE_Y_i_XDOD_YUJ:

X_MNIEJSZE_Y_i_XUJ:
	cmp ds:[stan_Py_Ky],1
	jz X_MNIEJSZE_Y_i_XUJ_YUJ
X_MNIEJSZE_Y_i_XUJ_YDOD:


X_MNIEJSZE_Y_i_XUJ_YUJ:

PETLA_X_MNIEJSZE_Y_i_XUJ_YUJ: ; oryginał
	fld ds:[x]
	fist ds:[tmpx]
	fadd ds:[delta]
	fstp ds:[x]
	call ZAMALUJ_PUNKT
	inc ds:[tmpy]
	mov ax,word ptr ds:[tmpy]
	cmp ax,ds:[y2]
	jnz PETLA_X_MNIEJSZE_Y_i_XUJ_YUJ
	mov ax,4C00h
	int 21h
	jmp KONIEC_KRESKA ; NAPISAC JAKI KONIEC
	    
KONIEC_KRESKA:
;AKTUALIZACJA DANYCH NA STOSIE CZYLI Px itd    
    
ret
KRESKA ENDP
;-------------------------------
ZAMIANA_NA_LICZBE PROC ;zamienia ciag cyfr w ds:[bufor+si] na liczbe ds:[bufor_na_liczbe]
    mov byte ptr ds:[bufor_na_liczbe],0
    xor bx,bx
	mov bx,20 ; znacznik konca pobierania ze stosu
	push bx
	xor bx,bx
PETLA_ZAMIANA_NA_LICZBE:
	mov bl,1
	cmp ds:[bufor+si],32d
	jz ZAMIANA_NA_LICZBE_CD
	mov bl,byte ptr ds:[bufor+si]
	sub bl,48; zamiana z ASCII NA cyfre
	push bx
	xor bx,bx
	inc si
	jmp PETLA_ZAMIANA_NA_LICZBE
ZAMIANA_NA_LICZBE_CD:
	xor ax,ax
	pop ax
	cmp ax,20
	jz KONIEC_ZAMIANA_NA_LICZBE
	mul bl 
	add ds:[bufor_na_liczbe],ax
	mov al,bl 
	mov cl,10
	mul cl    
	mov bl,al
	jmp ZAMIANA_NA_LICZBE_CD
KONIEC_ZAMIANA_NA_LICZBE:
	mov al,byte ptr ds:[bufor_na_liczbe]
ret
ZAMIANA_NA_LICZBE ENDP
;----------------------------------
ZAMALUJ_PUNKT PROC ; wspolrzedne punktu brane z ds:[tmpx] i ds:[tmpy]
	mov ax,seg tmpx
	mov ds,ax
	mov ax,0A000h
	mov es,ax
	mov ax,word ptr ds:[tmpy]
	mov di,ax
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	
	shl ax,1
	shl ax,1
	shl ax,1
	shl ax,1
	shl ax,1
	shl ax,1
	add di,ax
	add di,word ptr ds:[tmpx]
	mov al,byte ptr ds:[kolor]
	mov byte ptr es:[di],al
petla:
	;in al, 60h
	;cmp al,1
	;jne petla
ret
ZAMALUJ_PUNKT ENDP
;-------------------------------


;---------------------------------

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
;----------------------------------------------------------
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

    ;cmp ds:[wersja],1

    ;jnz KROK2_W2

    mov ah,2

    int 21h  

KROK2_W2:

	mov word ptr ds:[bx],dx

	mov dx,bx

	mov cx,1   

	;cmp ds:[wersja],1

	;jz KROK2_W1

	;call ZAPISYWANIE_DO_PLIKU

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
                    
bladd:
    mov dx,offset blad 
    mov ah,9
    int 21h
    
    
ZAKONCZ_PROGRAM:
    mov ax,4c01h
    int 21h


code1 ends
end start
