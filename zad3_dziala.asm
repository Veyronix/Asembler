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
	moze db 'dddd'
	stan_Py_Ky db 0
	x1 dw 0
	y1 dw 0
	x2 dw 0 
	y2 dw 0 
	tmp dw 0
	tmpx dw 0
	tmpy dw 0
	stan_Px_Kx_v2 db 0
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
	mov	ax,seg top1
	mov	ss,ax
	mov	sp,offset top1
	mov ax,00h
	mov al,13h ;tryb graficzny
	int 10h

    finit  
    fld ds:[kat]; zaladowanie na st(0) kat,
    fld ds:[x] ;x konca odcinka
    fld ds:[y] ; y konca odcinka
    fld ds:[x] ;x poczatka odcinka
    fld ds:[y] ; y poczatka odcinka
	
	call PARSER_GOOD
	mov ah,ds:[dlugosci]
	mov si,0 ;offset do PRZEPISYWANIE
	call PRZEPISYWANIE ;przepisywanie nazwy pliku
	mov word ptr ds:[offset_przepisywania],si 
	mov dx,offset sciezka
	call OTWIERANIE_PLIKU
GLOWNY_PROGRAM: 
    call ODCZYT_Z_PLIKU ; W ds:[ilosc] jest ilosc znakow
	xor si,si
	dec si
	;-----
	dec ds:[ilosc]
	;------
KOLEJNE_ZNAKI:
	inc si
	cmp si,ds:[ilosc]
	jz KONIEC_KOLEJNE_ZNAKI 
	mov al,byte ptr ds:[bufor+si]

	cmp ds:[bufor+si],114d
	jz OBROT
	cmp ds:[bufor+si],109d
	jz NAPRZOD
	cmp ds:[bufor+si],117d
	jz DO_GORY
	cmp ds:[bufor+si],100d
	jz OPUSC
	jmp KOLEJNE_ZNAKI
OBROT:
	inc si
	cmp ds:[bufor+si],32d;spacja
	jz OBROT


	call ZAMIANA_NA_LICZBE    ;zamiana katu z ASCII na liczbe 

	fild word ptr ds:[bufor_na_liczbe] ;zaladowanie kata na koprocesor
	
    fld ds:[sto80]
    fdivp st(1),st(0) ;podziel alfa/180 i zdejmij st(0)
	
    fldpi ;st(0)=PI
    fmulp st(1),st(0); otrzymanie alfa*PI/180 i zdejmij st(0)  
    faddp st(5),st(0);dodaje do aktualnego katu alfa*PI/180 i usuwam st(0)
	jmp KOLEJNE_ZNAKI
	
	
NAPRZOD:
    inc si
    cmp ds:[bufor+si],32d;spacja
    jz NAPRZOD
    call ZAMIANA_NA_LICZBE
    
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
KRESKA PROC  
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
	fstsw word ptr ds:[zmienna] ; miejsce gdzie zapamietamy rejest stanu koprocesora 
	mov ax,ds:[zmienna] 
	sahf ;przenies AH do rejestru znacznikow 
	ja DEL_X_DOD
	jmp DEL_X_UJ
	;-----

	
	
	
	
DEL_X_DOD:
	mov byte ptr ds:[stan_Px_Kx_v2],0
	jmp PO_DEL_X
DEL_X_UJ:
	mov byte ptr ds:[stan_Px_Kx_v2],1
PO_DEL_X:
	

	fabs ; |Px-Kx|
	fldz 
	fadd st(0),st(2) ; st(0)=Py
 	fsub st(0),st(4) ; st(0)=Py-Ky
	ftst ; porownanie st(0) z zerem
	
	fstsw word ptr ds:[zmienna] 
	mov ax,word ptr ds:[zmienna]
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
	
	fldz

	fadd st(0),st(1) ;st(0)=Py
	fstp ds:[y] ; zapisz do ds:[y] Py i usun ze stosu
	fldz 
	fadd st(0),st(2); st(0)=Px
	fistp ds:[tmpx] ; czesc calkowita Px
	fldz 
	fadd st(0),st(4); st(0)=Kx
	fistp ds:[x2] ; czesc calkowita Kx
	cmp ds:[stan_Px_Kx_v2],1 ;CZY UJEMNE
	jz X_WIEKSZE_Y_i_XUJ
	cmp ds:[stan_Py_Ky],1 ; CZY UJEMNE
	jz X_WIEKSZE_Y_i_XDOD_YUJ
X_WIEKSZE_Y_i_XDOD_YDOD:
PETLA_X_WIEKSZE_Y_i_XDOD_YDOD:
	fld ds:[y]
	fist ds:[tmpy]
	fsub ds:[delta]
	fstp ds:[y]
	call ZAMALUJ_PUNKT
	dec ds:[tmpx]
	mov ax,word ptr ds:[tmpx]
	cmp ax,ds:[x2]
	jnz PETLA_X_WIEKSZE_Y_i_XDOD_YDOD

	jmp KONIEC_KRESKA

X_WIEKSZE_Y_i_XDOD_YUJ:
PETLA_X_WIEKSZE_Y_i_XDOD_YUJ:
	fld ds:[y]
	fist ds:[tmpy]
	fadd ds:[delta]
	fstp ds:[y]
	call ZAMALUJ_PUNKT
	dec ds:[tmpx]
	mov ax,word ptr ds:[tmpx]
	cmp ax,ds:[x2]
	jnz PETLA_X_WIEKSZE_Y_i_XDOD_YUJ

	jmp KONIEC_KRESKA

X_WIEKSZE_Y_i_XUJ:
	cmp ds:[stan_Py_Ky],1
	jz X_WIEKSZE_Y_i_XUJ_YUJ
	
	
	
X_WIEKSZE_Y_I_XUJ_YDOD:
PETLA_X_WIEKSZE_Y_i_XUJ_YDOD:
	fld ds:[y]
	fist ds:[tmpy]
	fsub ds:[delta]
	fstp ds:[y]
	call ZAMALUJ_PUNKT
	inc ds:[tmpx]
	mov ax,word ptr ds:[tmpx]
	cmp ax,ds:[x2]
	jnz PETLA_X_WIEKSZE_Y_i_XUJ_YDOD

	jmp KONIEC_KRESKA
	
X_WIEKSZE_Y_i_XUJ_YUJ:
PETLA_X_WIEKSZE_Y_i_XUJ_YUJ:
	fld ds:[y]
	fist ds:[tmpy]
	fadd ds:[delta]
	fstp ds:[y]
	call ZAMALUJ_PUNKT
	inc ds:[tmpx]
	mov ax,word ptr ds:[tmpx]
	cmp ax,ds:[x2]
	jnz PETLA_X_WIEKSZE_Y_i_XUJ_YUJ

	jmp KONIEC_KRESKA
	
	

X_MNIEJSZE_Y:	;|Px-Kx|<|Py-Ky|

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

	cmp ds:[stan_Px_Kx_v2],1 ;CZY UJEMNE
	jz X_MNIEJSZE_Y_i_XUJ
	cmp ds:[stan_Py_Ky],1 ; CZY UJEMNE
	jz X_MNIEJSZE_Y_i_XDOD_YUJ
	
X_MNIEJSZE_Y_i_XDOD_YDOD:
PETLA_X_MNIEJSZE_Y_i_XDOD_YDOD:
	fld ds:[x]
	fist ds:[tmpx]
	fsub ds:[delta]
	fstp ds:[x]
	call ZAMALUJ_PUNKT
	dec ds:[tmpy]
	mov ax,word ptr ds:[tmpy]
	cmp ax,ds:[y2]
	jnz PETLA_X_MNIEJSZE_Y_i_XDOD_YDOD

	jmp KONIEC_KRESKA


X_MNIEJSZE_Y_i_XDOD_YUJ:
PETLA_X_MNIEJSZE_Y_i_XDOD_YUJ:
	fld ds:[x]
	fist ds:[tmpx]
	fsub ds:[delta]
	fstp ds:[x]
	call ZAMALUJ_PUNKT
	inc ds:[tmpy]
	mov ax,word ptr ds:[tmpy]
	cmp ax,ds:[y2]
	jnz PETLA_X_MNIEJSZE_Y_i_XDOD_YUJ

	jmp KONIEC_KRESKA ; NAPISAC JAKI KONIEC

X_MNIEJSZE_Y_i_XUJ:
	cmp ds:[stan_Py_Ky],1
	jz X_MNIEJSZE_Y_i_XUJ_YUJ

X_MNIEJSZE_Y_i_XUJ_YDOD:
PETLA_X_MNIEJSZE_Y_i_XUJ_YDOD:

	fld ds:[x]
	fist ds:[tmpx]
	fadd ds:[delta]
	fstp ds:[x]
	call ZAMALUJ_PUNKT
	dec ds:[tmpy]
	mov ax,word ptr ds:[tmpy]
	cmp ax,ds:[y2]
	jnz PETLA_X_MNIEJSZE_Y_i_XUJ_YDOD

	jmp KONIEC_KRESKA ; NAPISAC JAKI KONIEC

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

	jmp KONIEC_KRESKA ; NAPISAC JAKI KONIEC
	    
KONIEC_KRESKA:
;AKTUALIZACJA DANYCH NA STOSIE CZYLI Px itd  

	
	fistp ds:[smietnik]
	fistp ds:[smietnik]
	fldz
	fadd st(0),st(2)
	fldz
	fadd st(0),st(2)
	
    
ret
KRESKA ENDP
;-------------------------------
ZAMIANA_NA_LICZBE PROC ;zamienia ciag cyfr w ds:[bufor+si] na liczbe ds:[bufor_na_liczbe]
    mov WORD ptr ds:[bufor_na_liczbe],0
    xor bx,bx
	mov bx,20 ; znacznik konca pobierania ze stosu
	push bx
	xor bx,bx
PETLA_ZAMIANA_NA_LICZBE:
	mov bl,1
	cmp ds:[bufor+si],48d
	jb ZAMIANA_NA_LICZBE_CD
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
	dec si
ret
ZAMIANA_NA_LICZBE ENDP
;----------------------------------
ZAMALUJ_PUNKT PROC ; wspolrzedne punktu brane z ds:[tmpx] i ds:[tmpy]
	cmp ds:[tmpx],0 ; zeby nie rysowac poza ekranem
	jb petla
	cmp ds:[tmpx],320
	ja petla
	cmp ds:[tmpy],0
	jb petla
	cmp ds:[tmpy],200
	ja petla
	
	cmp ds:[stan_piora],0 ;czy zolwik jest polozony czy podniesiony
	jnz petla
	
	mov ax,seg tmpx
	mov ds,ax
	mov ax,0A000h
	mov es,ax
	mov ax,word ptr ds:[tmpy]
	mov di,ax
	shl di,1 ;DI=256*Y
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	shl di,1
	
	shl ax,1 ;AX = 64*Y
	shl ax,1
	shl ax,1
	shl ax,1
	shl ax,1
	shl ax,1
	add di,ax ; DI=256Y+64Y=320Y
	add di,word ptr ds:[tmpx] ;DI = 320Y+X
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


;----------------------------------------
                    
bladd:
    mov dx,offset blad 
    mov ah,9
    int 21h
    
    
ZAKONCZ_PROGRAM:
	in al, 60h
	cmp al,1
    jnz ZAKONCZ_PROGRAM 
	
	mov ax, 3 ;wyjscie z trybu graficznego
	int 10h
	
	mov ax,4c01h
    int 21h


code1 ends
end start
