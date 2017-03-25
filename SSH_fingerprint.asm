.286
data1 segment
    input db 150 dup (?)  ; buffor?
    ruchy db 70 dup (?)  
    tablica db 170 dup (0)
    zle db "Zle dane wejsciowe$"
    tytul db "+-----------------+",13,10,'$'
    znak db '|$'
	jaka_cyfra db 1 dup (?) 
	zaczecie_kodu db 1 dup(?)
	ilosc_wejsc db " .o+=*B0X@%&#/^$"
data1 ends                        

;-----------------------------------         
stos1	segment stack
	dw	200 dup(?)
top1	dw	?
stos1	ends
;---------------------------------

code1 segment
    
;-------------------------------
JAKI_KOD  PROC ;sprawdzanie czy db kod jest
    push ax
    push bx
    push cx
    push dx
CZY_TO_1_LUB_0:
	mov ax,seg jaka_cyfra
	mov ds,ax
    mov bx,0
    mov al,es:[si]
    inc si
    mov ds:[jaka_cyfra],al
    cmp al,0Dh
    jz ZLE_FINISH
    
    cmp al,20h
    jz CZY_TO_1_LUB_0
    cmp al,49d  ;to i ponizej sprawdza czy to znak jest 1 lub 0
    jz KOLEJNA
	
    cmp al,48d
    jZ KOLEJNA
	
	jmp ZLE_FINISH
KOLEJNA:   ; czy kolejnym znakiem jest spacja
    mov al,es:[si]
    inc si
    
    cmp al, 0Dh
    jz ZLE_FINISH
    
    cmp al,20h
    jnz ZLE_FINISH
    
    
SPACJE:  ; pozostale spacje miedzy pierwszym arg a drugim
    mov al,es:[si]
    mov bx,si
    inc si    
    cmp al,0Dh
    jz ZLE_FINISH
    
    cmp al,20h
    jz SPACJE
    
    dec si
    mov byte ptr ds:[zaczecie_kodu],bl
    mov cx, 32 
CZY_DB_KOD:       ;32 znaki bez spacji ma byc
    mov al,es:[si]
    
    inc si
    inc di
    cmp al,20h
    jz ZLE_FINISH
    
    cmp al,0Dh
    jz ZLE_FINISH
    
    cmp al,57d
    jbe CZY_TO_CYFRA
    
    cmp al, 102d
    jbe CZY_TO_MALA_LITERA
    
    jmp ZLE_FINISH
CZY_TO_CYFRA:
    cmp al,48d
    jb ZLE_FINISH
    jmp ZNAK_JEST_OK
CZY_TO_MALA_LITERA:
    cmp al,97d
    jb ZLE_FINISH
         
ZNAK_JEST_OK:   
    loop CZY_DB_KOD
    
SZUKANIE_0Dh:   
    mov al,es:[si]
    
    cmp al,20h
    jz SZUKANIE_0Dh

    cmp al,0Dh
    jnz ZLE_FINISH 
    pop dx
    pop cx
    pop bx
    pop ax
	
ret 
JAKI_KOD ENDP 
;--------------------

;-------------------
HEX_TO_BIN PROC 
    push ax
    push bx
    push cx
    push dx             
    mov cx,15
    xor ax,ax 
	mov al, ds:[zaczecie_kodu]  ; POCZATEK DRUGIEGO ARGUMENTU
	mov si,ax 
	xor ax,ax 
	mov dx,offset input
    mov di,dx 
BRANIE_KOLEJNYCH_ZNAKOW:   
    mov al,es:[si]  ;POBIERANIE PIERWSZEGO ZNAKU
    inc si
    cmp al,20h
    jz KONIEC_HEX
	cmp al,0Dh
	jz KONIEC_HEX
    sub al,48d ; CZY TO CYFRA 1 2 3 4 itd
    cmp al,10d
    jl ZNAKI
    add al,48d 
    sub al,87d ; czy to liczba a b c itd  
ZNAKI:
    mov ah,es:[si]; POBIERANIE DRUGIEGO ZNAKU
    inc si
    cmp ah,20h
    jz KONIEC_HEX
	cmp ah,0Dh
	jz KONIEC_HEX
    sub ah,48d ; CZY TO CYFRA 1 2 3 4 itd
    cmp ah,10d
    jl ZNAKI2
    add ah,48d 
    sub ah,87d
ZNAKI2:
    shl al,4   ; bo u gory jest .286 I PRZESUWANIE ABY DODAC DRUGI ZNAK
    ;shl ah,1
    ;shl ah,1 
    ;shl ah,1
    ;shl ah,1
    add al,ah ;DODAWANIE ZNAKOW DO SIEBIE
    mov byte ptr ds:[input+di], al ;WSTAWIANIE DO TABLICY SUME
    xor ax,ax
    inc di
    jmp BRANIE_KOLEJNYCH_ZNAKOW ;POPIERANIE KOLEJNYCH DWOCH WARTOSCI
KONIEC_HEX:
    pop dx
    pop cx
    pop bx
    pop ax 
ret  
HEX_TO_BIN ENDP
;-------------------------------

;----------------------------  
;---WYZNACZNIE KIERUNKU Z BINARNEGO----
KIERUNKI PROC 
    push ax
    push bx
    push cx
    push dx
    
    xor si,si
    xor bx,bx 
    dec bx
    mov cx,16 ;aby pobrac 16 bajtow
    push cx
    mov cx,4 ; z kazdego bajtu tworzymy 4 ruchy
PETLA_RUCH:  ;petla w ktorej bierze sie odpowiednio kolejne elementy
    inc bx
    mov ax,cx
    pop cx
    cmp cx,0  ;CZY POBRANO WSZYSTKIE 16 BAJTOW
    jz koniec_ruchAAA
    dec cx
    push cx 
    mov ax,4
    mov cx,ax
PETLA_WEW:  ; petla na tworzenie ruchow z pierwszego 
    cmp cx,0
    jz PETLA_RUCH 
    mov ax,seg input
    mov ds,ax
    dec cx
    xor ax,ax
    mov al,byte ptr ds:[input+bx]
    push bx
    mov bx,2
    div bx
    pop bX
    push bx
    mov bx,2
    push dx
    div bx
    shl dx,1
    pop bx
    add dx,bx
    pop bx
    mov byte ptr ds:[input+bx],al ; Wkladanie pozostalosci liczby
    mov ax,seg ruchy
    mov ds,ax
    mov ax,dx 
    xor dx,dx
JAKI_KROK: ; TO I PONIZEJ OKRESLAJA KIERUNEK RUCHU
    cmp al,0d
    jz GORA_LEWO
    cmp al,1d
    jz GORA_PRAWO
    cmp al,2d
    jz  DOL_LEWO
    cmp al,3d
    jz  DOL_PRAWO
    
PRAWO:
    mov al,byte ptr ds:[input+bx]
    dec bx
    cmp al,0
    jz GORA_PRAWO
    
    cmp al,1
    jz DOL_PRAWO 
LEWO:
    mov al,byte ptr ds:[input+bx]
    dec bx
    cmp al,0
    jz GORA_LEWO
    
    cmp al,1
    jz DOL_LEWO
GORA_LEWO: ; 00   ruch to 0
    mov al,48d
    mov ds:[ruchy+si],al
    inc si
     jmp PETLA_WEW
GORA_PRAWO: ;01  ruch to 1
    mov al,49d
    mov ds:[ruchy+si],al
    inc si 
    jmp PETLA_WEW
DOL_LEWO:   ;10 RUCH TO 2
    mov al,50d
    mov ds:[ruchy+si],al
    inc si 
    jmp PETLA_WEW
DOL_PRAWO:  ;11 RUCH TO 3
    mov al,51d
    mov ds:[ruchy+si],al
    inc si
    jmp PETLA_WEW
koniec_ruchAAA:
    pop dx
    pop cx
    pop bx
    pop ax
ret
KIERUNKI ENDP
;-------------------------------

;--------------------------------
TAB1 PROC ; CHODZENIE PO TABLICY WG DANYCH WEJSCIOWYCH(KIERUNKOW)
    push ax
    push bx
    push cx
    push dx
    mov si,4d ;y
    mov dx,8d ;x
    xor bx,bx
    mov bx,76d ;srodek   bx to polozenie
    xor di,di ; dx to kolejne ruchy
    dec di
PETLA_TAB:
    inc di
    cmp di,64d
    jz KONIEC_TAB;koniec chodzenia po tablicy 
    mov ax,seg ruchy
    mov ds,ax
    mov al, byte ptr ds:[ruchy+di] 
    mov cx,seg tablica
    mov ds,cx
    mov ah, byte ptr ds:[jaka_cyfra]; 0 LUB 1!!!!!!!!
    sub ah,48d 
    cmp al,48d
    jz GL
    cmp al,49d
    jz GP
    cmp al,50d
    jz D_L
    cmp al,51d
    jz DP
GL:           
    dec si
    dec dx 
    cmp dx,16d
    ja ZA_LEWO_GL
    cmp si,8d
    ja  ZA_GORE_GL
    sub bx, 18d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB   
GP:
    inc dx
    dec si
    cmp dx,16d
    ja ZA_PRAWO_GP
    cmp si,8d
    ja ZA_GORE_GP
    sub bx,16d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
    
D_L:
    dec dx
    inc si
    cmp dx,16d
    ja ZA_LEWO_DL
    cmp si, 8d
    ja ZA_DOL_DL
    add bx,16d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
DP:
    inc si
    inc dx
    cmp dx,16d
    ja ZA_PRAWO_DP
    cmp si,8d
    ja ZA_DOL_DP
    add bx,18d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
ZA_PRAWO_DP:
    cmp si,8d
    ja ZA_ROG_DP
    cmp ah,1
    jz ZA_PRAWO_DP_1
    
    dec dx
    add bx,17d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB               
    ZA_PRAWO_DP_1:
        dec dx
        dec dx
        add bx,16d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB 
        
ZA_DOL_DP:
    cmp ah,1
    jz ZA_DOL_DP_1
    dec si
    add bx,1d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB 
    ZA_DOL_DP_1:
        dec si
        dec si
        sub bx,16d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB  
ZA_LEWO_DL:
    cmp si, 8d
    ja ZA_ROG_DL 
    cmp ah,1
    jz ZA_LEWO_DL_1
    inc dx
    add bx, 17d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
    ZA_LEWO_DL_1:
        inc dx
        inc dx
        add bx, 18d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB
    
ZA_DOL_DL:
    cmp ah,1
    jz ZA_DOL_DL_1
    dec si
    sub bx, 1d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
    ZA_DOL_DL_1:
        dec si 
        dec si
        sub bx, 18d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB
        
         
ZA_LEWO_GL:
    cmp si,8d
    ja ZA_ROG_GL 
    cmp ah,1
    jz ZA_LEWO_GL_1
    inc dx
    sub bx, 17d ; 
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB 
    ZA_LEWO_GL_1:
        inc dx
        inc dx
        sub bx,16d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB 
    
ZA_GORE_GL: 
    cmp ah,1
    jz ZA_GORE_GL_1
    inc si
    sub bx,1d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB  
    ZA_GORE_GL_1:
        inc si
        inc si
        add bx,16d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB
   
ZA_PRAWO_GP:
    cmp si,8d
    ja ZA_ROG_GP 
    cmp ah,1
    jz ZA_PRAWO_GP_1
    dec dx
    sub bx,17d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB
    ZA_PRAWO_GP_1:
        dec dx
        dec dx 
        sub bx,18d
        inc byte ptr ds:[tablica+bx]
ZA_GORE_GP:
    cmp ah,1
    jz ZA_GORE_GP_1
    inc si
    add bx,1d
    inc byte ptr ds:[tablica+bx]
    jmp PETLA_TAB  
    ZA_GORE_GP_1:
        inc si
        inc si
        add bx,18d
        inc byte ptr ds:[tablica+bx]
        jmp PETLA_TAB

ZA_ROG_GL:
    cmp ah,1
    jz ZA_ROG_GL_1
    inc si
    inc dx
    inc ds:[tablica+bx]
    jmp PETLA_TAB
    ZA_ROG_GL_1:
        inc si
        inc si
        inc dx
        inc dx
        add bx,18d
        inc ds:[tablica+bx]
        jmp PETLA_TAB
ZA_ROG_GP:
    cmp ah,1
    jz ZA_ROG_GP_1
    dec dx
    inc si
    inc ds:[tablica+bx]
    jmp PETLA_TAB 
    ZA_ROG_GP_1:
        dec dx
        dec dx
        inc si
        inc si
        add bx,16d
        inc ds:[tablica+bx]
        jmp PETLA_TAB
ZA_ROG_DL:
    cmp ah,1
    jz ZA_ROG_DL_1
    dec si
    inc dx
    inc ds:[tablica+bx]
    jmp PETLA_TAB
    ZA_ROG_DL_1:
        dec si
        dec si
        inc dx
        inc dx
        sub bx,16d
        inc ds:[tablica+bx]
        jmp PETLA_TAB
ZA_ROG_DP: 
    cmp ah,1
    jz ZA_ROG_DP_1
    dec si
    dec dx
    inc ds:[tablica+bx]
    jmp PETLA_TAB 
    ZA_ROG_DP_1: 
        dec si
        dec si
        dec dx
        dec dx
        sub bx,18d
        inc ds:[tablica+bx]
        jmp PETLA_TAB
    
KONIEC_TAB: ;KONIEC CHODZENIA PO TABLICY

    
    mov al,210d ; ZNAK E
    mov byte ptr ds:[tablica+bx],al
    xor di,di
    
    mov ax,seg tytul ;WYPISANIE PIERWSZEGO POZIOMU
    mov ds,ax
    mov dx,offset tytul
    mov ah,09h
    int 21h  
    xor dx,dx 
    xor di,di
    xor si,si
    mov cx,17d ;ILOSC ELEMENTOW W WIERSZU
    mov bx,9d  ;ILOSC WIERSZY
WYPISZ_TAB1: ;PRINTOWANIE ZNAKU " | "
    mov ax,seg znak
    mov ds, ax
    mov dx,offset znak ;
    mov ah,9h
    int 21h
    xor dx,dx
    xor ax,ax
    
WYPISZ_TAB: ;WYPISANIE KOLEJNYCH POZIOMOW
    mov al,byte ptr ds:[tablica+di]
    call JAKI_ZNAK 
    mov al,dl
    mov ds:[input+si],al 
    inc di
    inc si
    loop WYPISZ_TAB
    mov al,'|'
    mov ds:[input+si],al
    inc si     
    mov al,13d          
    mov ds:[input+si],al
    inc si
    mov al,10d          
    mov ds:[input+si],al
    inc si
    mov al,'$'          
    mov ds:[input+si],al
    mov ax,seg input
    mov ds,ax
    mov dx,offset input
    xor si,si 
    mov ah,09h
    int 21h 
    mov cx,17d
    dec bx
    cmp bx,0d
    jnz WYPISZ_TAB1 ; WYPISYWANIE WSZYSTKICH POZIOMOW 
    mov ax,seg tytul
    mov ds, ax
    mov dx,offset tytul
    mov ah,9h
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    
ret
TAB1 ENDP
;------------------------

;-------------------
JAKI_ZNAK PROC  ; ZAMIANA ILOSCI WEJSC NA ZNAK
    mov dl,'S'
    cmp di,76d
    jz JAKI_ZNAK_KONIEC
    mov dl,'E'
    cmp al,100d
    ja JAKI_ZNAK_KONIEC
    mov dl,'^'
    cmp al,13d
    ja JAKI_ZNAK_KONIEC
    push si  
    mov si,ax
    mov dl,byte ptr ds:[ilosc_wejsc+si]
    pop si
JAKI_ZNAK_KONIEC:    
ret
JAKI_ZNAK ENDP
;----------------------------

;-----------------------
START:
    mov	ax,seg top1
	mov	ss,ax
	mov	sp,offset top1


    mov ax,seg input
    mov ds,ax
	mov dx,offset input
    mov di,dx 
    mov ah,62
    int 21h
    mov si,82h 
    xor di,di
    mov cx,15
    xor ax,ax
	call JAKI_KOD
	xor ax,ax
	
    call HEX_TO_BIN
    call KIERUNKI
    call TAB1 
    
    mov ah,4ch  ; KONIEC PROGRAMU
    int 21h
    
    
ZLE_FINISH: ; ZLE DANE WEJSCIOWE
    mov ax,seg zle
    mov ds,ax
    mov dx,offset zle
    mov ah,09h
    int 21h
    
    mov ah,4ch
    int 21h

code1 ends
end START
end
