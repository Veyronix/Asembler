data1 segment
   input db 200 dup (13)   ;input 
   dlugosci db 200 dup ('$') 
   nowa_linia db 13,10,'$' 
   pomoc db ?,'$' 
   zly db "zly argument$" 
data1 ends

stos1	segment stack
	dw	200 dup(?)
top1	dw	?
stos1	ends

code1   segment


;-------POCZATEK---------  
START: 
	mov	ax,seg top1
	mov	ss,ax
	mov	sp,offset top1
    call PARSER_GOOD
    call PRINTER
    mov ax,3  ; WYBIERANIE ARG KTOREGO DL CHCEMY PRINTOWAC
    call WYPISZ_DLUGOSC
    mov ah,4ch
    int 21h 


;------------------------------------ 
; WYPISYWANIE LICZBy W AX
WYPISZ_LICZBE PROC  ; W ax jest liczba

    push bx
    push cx
    push dx 
    push si
    xor si,si
    mov bl,10d
    div bl          
    xor dx,dx
    mov dl,ah
    push dx
    xor cx,cx
    inc cx 
    xor ah,ah 
DOPOKI_TO_ZERO:    
    cmp ax,0
    jz WYPISANIE
    xor ah,ah
    mov bl,10d
    div bl     
    xor dx,dx
    mov dl,ah
    push dx
    inc cx ; moze trzeba pozniej odjac
    jmp DOPOKI_TO_ZERO
WYPISANIE:
    pop ax 
    add ax,48d
    mov ds:[pomoc+si],al
    inc si
    loop WYPISANIE 
    mov al,'$'
    mov ds:[pomoc+si],al
    mov ah,9
    mov dx,offset pomoc
    int 21h   
    pop si
    pop dx
    pop cx
    pop bx
    
ret
WYPISZ_LICZBE ENDP                   
;---------------------------------   


;-----------------------------
;----WYPISYWANIE DLUGOSCI DANEGO ARGUMENTU----
WYPISZ_DLUGOSC PROC ; W AX TRZYMAM SZUKANA DLUGOSC 
    push bx
    push cx
    push dx
    xor si,si
    mov si,ax 
    dec si 
    xor ax,ax 
    mov al,byte ptr ds:[dlugosci+si]
    cmp al, '$' ; JESLI BRAK TAKIEGO ARGUMENTU
    jz zly_arg 
    call WYPISZ_LICZBE
    jmp koniec_dlugosci
zly_arg:
    mov dx, offset zly
    mov ah,9
    int 21h
koniec_dlugosci:      
    pop dx
    pop cx
    pop bx

ret 
WYPISZ_DLUGOSC ENDP 
;----------------------------

;--------------------------------
;---- PRINTER ARGUMENTOW-----
PRINTER PROC
    push ax
    push bx
    push cx
    push dx
    xor si,si
    mov ax,seg input
    mov ds,ax 
    xor di,di        
program: 
    mov al,ds:[input+si]
    cmp al,'$'
    jz WYPISZ
    cmp al,13d
    jz FINISH2
    inc si
    jmp program
WYPISZ:
    mov dx,offset input
    add dx,di
    mov di,si
    inc di
    inc si
    mov ah,9h
    int 21h 
    mov dx,offset nowa_linia
    mov ah,9h
    int 21h
    
    jmp program
FINISH2:
    pop dx
    pop cx
    pop bx
    pop ax 
ret
PRINTER ENDP 
;--------------------------

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
   ; xor di,di ; Musi byc bo inaczej byloby ala1013$ma1013$itd
    dec si
    jmp PARSER
    
FINISH_PARSER: 
   mov ds:[dlugosci+bp],cl            
   mov dx,offset dlugosci
   inc bp
   mov al,'$'
   mov ds:[dlugosci+bp],al 
   mov al,'$'
   mov ds:[input+di],al
   pop dx
   pop cx
   pop bx
   pop ax 
ret
PARSER_GOOD ENDP
;---------------------------
    
code1 ends  
end START
