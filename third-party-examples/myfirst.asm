assume cs:codigo,ds:dados,es:dados,ss:pilha

CR       EQU    0DH ; "carriage return"
LF       EQU    0AH ; "line feed"


; DATA SEGMENT DEFINITION
dados    segment
mensagem db     'Primeiro programa'
fimlinha db     CR,LF,'$'
dados    ends


; STACK SEGMENT DEFINITION SS:SP
pilha    segment stack
         dw     128 dup(?)
pilha    ends
         
; TEXT SEGMENT DEFINITION (CODE) CS and IP
codigo   segment
inicio:
         mov    ax,dados ; ES and DS initialization
         mov    ds,ax    ; 
         mov    es,ax    ; 

; print a message
         lea    dx,mensagem        ; endereco da mensagem em DX
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS

; return the power to DOS OPERATIONAL SYSTEM
fim:
         mov    ax,4c00h           ; funcao retornar ao DOS no AH
         int    21h                ; chamada do DOS

codigo   ends

; just to inform the last line of the file is here
         end    inicio