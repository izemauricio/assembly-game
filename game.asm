; Mauricio Ize - 273168
; x8086

assume ss:PILHA, ds:DADO, es:DADO, cs:CODIGO

CR          EQU        0dh
LF          EQU        0ah
BCKSPC      EQU        08h
ESCAPE      EQU        27
SPACE       EQU        20h
TAB         EQU        9h
ENTERK      EQU        0dh
EOF         EQU        0

PILHA segment stack
    db 100 dup(7)
PILHA ends

DADO segment
    INT_NUM         db 0
    STR_NUM         db 3 dup(0)

    BOOLEOF         db 0
    BUFFER          db 1 dup(0)
    BUFFER2         db 0

    ESPACO0         db 10 dup(0)
    ESPACO1         db 10 dup(1)
    ESPACO2         db 10 dup(2)

    MSG0            db 'Mauricio Ize 273168',CR,LF,'$' ; ascii_string_structure
    MSG1            db 'Digite o nome do arquivo: ','$'
    MSG2            db 'Voce digitou: ','$'
    MSGCLOSE        db '(fechando arquivo)$'
    MSGCLOSE2       db '(fechando arquivo porque leu eof)$'
    MSG_ERRO        db 'Erro ao abrir o arquivo, tente novamente',CR,LF,'$'
    MSG_OK          db 'Tchau!',CR,LF,'$'
    MSG_ERRO_WRITE  db 'Erro ao escrever no arquivo!!',CR,LF,'$'
    MSG_ERROCLOSE   db 'Erro ao fechar arquivo de saida!!',CR,LF,'$'

    FILENAME        db 64 dup('$')
    HANDLER         dw ?
    FILENAME_COUNT db 0

    MSG_P1          db 'PLANETAS: ','$'
    MSG_P2          db 'PLANETA[','$'
    MSG_P3          db ']: ','$'

    FILENAME_O     db 64 dup('$')
    HANDLER_OUT dw ?
    BYTE_OUT db 0

    MSGCSQRT1    db 'RAIZ QUADRADA: ',CR,LF,'$'

    NUM_PLANETAS db 0
    POSICAOX     db 100 dup(0)
    POSICAOY     db 100 dup(0)

    MSG_R1       db 'DISTANCIA E COMBUSTIVEL NECESSARIO: ',CR,LF,'$'

    NUM_ROTAS           db 0

    ; variaveis globais para subrotina para converter byte para string-ascii
    CBYTE2ASCII_NUM db 0
    CBYTE2ASCII_STR db '$$$$'

    ; variaveis globais para subrotina da raiz quadrada
    SQRTARG         dw 0
    SQRTRES         db 0

    ; variavesi globais para funcao que calcula distancia
    X1              db 0
    X2              db 0
    Y1              db 0
    Y2              db 0
    DIST            db 0

    ; variavesi globais para funcao de potencia de 2
    POWERARG db 0
    POWERRES dw 0

    ; argumentos para funcao CALCULA_COST
    P0 		db 0
    P1 		db 0
    COST 	dw 0
    HANDLER_TEMP dw ?
    HANDLER_BKP dw ?
    COST_ERROR            db 'ERRO ERRO ERRO!','$'

     ; variavesi globais para funcao que imprime byte na tela
    THE_BYTE db 0

DADO ends

; CS and IP are automatically initialized to point here
CODIGO segment

INICIO:
	; inicializa segmento
    mov ax, DADO
    mov ds, ax
    mov es, ax

    ; escreve nome e matricula
    lea dx, MSG0
    mov ah, 9
    int 21h

PEDIR_NOME:

    ; escreve mensagem para pedir nome do arquivo
    lea dx, MSG1
    mov ah, 9
    int 21h

    lea di, FILENAME
    mov dl, 0 
    mov FILENAME_COUNT, dl

LER_BYTE:

    ; ler um char, store char em ah, echo char na tela
    mov ah, 1
    int 21h

    ; compara char lido com CR
    cmp al, CR
    je     FILENAME_FINALIZADO

    ; compara char lido com ESC
    cmp al,ESCAPE
    je    FINALIZA_SHORT

    ; compara char lido com BACKSPACE
    cmp al,BCKSPC
    je     BACKSPACE_TREATMENT

    ; coloca char lido na posicao di da memoria
    mov [di], al

    inc di

    mov ah, FILENAME_COUNT
    inc ah
    mov FILENAME_COUNT, ah

    ; repete
    jmp LER_BYTE

FINALIZA_SHORT:
    jmp FINALIZA

BACKSPACE_TREATMENT:

    ; compara di com o endereco da posicao 0 do array de byte FILENAME
    cmp di, offset FILENAME
    je    INICIO_TELA

    ; substitui echo da tela por um espaco
    mov dl, ' '
    mov ah, 2
    int 21h

    ; faz cursor da tela voltar 1 char com backspace-ascii-code
    mov dl, BCKSPC
    mov ah, 2
    int 21h

    ; faz posicao do array voltar 1 posicao
    dec di

    ; repete
    jmp LER_BYTE

INICIO_TELA:

    ; substitui echo da tela atual por um char em branco
    mov dl, ' '
    mov ah, 2
    int 21h

    ; repete
    jmp LER_BYTE

FILENAME_FINALIZADO:

	; verifica se foi digitadoo mais que 4 chars
	mov ah, FILENAME_COUNT
	cmp ah, 5
	jb ADICIONAR_DOT_PLA

	; verifica se tem .pla antes do $
	; arquivo[di]
	cmp byte ptr [di-1], 'a'
	jne ADICIONAR_DOT_PLA
	cmp byte ptr [di-2], 'l'
	jne ADICIONAR_DOT_PLA
	cmp byte ptr [di-3], 'p'
	jne ADICIONAR_DOT_PLA
	cmp byte ptr [di-4], '.'
	jne ADICIONAR_DOT_PLA

	jmp JA_TEM_DOT_PLA

	ADICIONAR_DOT_PLA:
	; arquivo[di]
	mov byte ptr [di], '.'
	inc di
	mov byte ptr [di], 'p'
	inc di
	mov byte ptr [di], 'l'
	inc di
	mov byte ptr [di], 'a'
	inc di

	JA_TEM_DOT_PLA:

    ; coloca $ no final da string formada
    ;mov byte ptr [di], CR
    ;mov byte ptr [di+1], LF
    ;mov byte ptr [di+2], '$'

    ; arruma filename de ascii para asciiz (para poder abrir o arquivo)
    mov byte ptr [di], 0

    ; espera digitar qualquer char
    ; mov ah, 1
    ; int 21h

    jmp ABRIR_ARQUIVO

ABRIR_ARQUIVO:
    ; tenta abrir arquivo para leitura
    mov ah, 3dh
    mov al, 0
    lea dx, FILENAME
    int 21h

    ; verifica por erro na abertura
    jnc ABRIU_SEM_ERRO

    ; deu erro, mostra mensagem de erro e repete
    lea dx, MSG_ERRO
    mov ah, 9
    int 21h

    ; repete
    jmp PEDIR_NOME


ABRIU_SEM_ERRO:

    ; copia handler do arquivo
    mov HANDLER, ax


    ; cria arquivo saida filename precisa ser string-0
    call OPEN_TO_WRITE

    ; Para resolver o problema que o branch está "muito longe"
    jmp PULAISSO1
    TERMINOU_DE_LER_SHORT1:
        jmp TERMINOU_DE_LER

    TERMINOU_DE_LER21:
        jmp TERMINOU_DE_LER
    PULAISSO1:

    ; ler numero de planetas do arquivo
    call NEXT_INT
    cmp BOOLEOF, 1
    je TERMINOU_DE_LER_SHORT1

    ; salva numero de planetas
    mov al, INT_NUM
    mov NUM_PLANETAS, al

    ; escreve 'PLANETAS: '
    lea dx, MSG_P1
    push dx
    call WRITE_STR_OUT

    ; converte byte to ascii string
    mov dh, NUM_PLANETAS
    mov CBYTE2ASCII_NUM, dh
    call CBYTE2ASCII
    lea dx, CBYTE2ASCII_STR
    push dx
    call WRITE_STR_OUT

    ; pula linha
    mov dh, CR
    mov BYTE_OUT, dh
    call WRITE_BYTE
    mov dh, LF
    mov BYTE_OUT, dh
    call WRITE_BYTE

    ; contador de planetas
    mov bx,0

    ; numero de loop
    mov al, INT_NUM
    cbw
    mov cx, ax

LACO_LEITURA:
    push bx

    ; LE POSICAO X DO ASTEIROIDE bx
    call NEXT_INT

    ; se eof, fecha
    cmp BOOLEOF, 1
    je TERMINOU_DE_LER21

    ; salva X na posicao bx da POSICAO
    lea di, POSICAOX
    mov dl, INT_NUM
    mov [di+bx], dl


    ; LE POSICAO Y DO ASTEIROIDE bx
    call NEXT_INT

    ; se eof, fecha
    cmp BOOLEOF, 1
    je TERMINOU_DE_LER21

    ; salva Y na posicao bx
    lea di, POSICAOY
    mov dl, INT_NUM
    mov [di+bx], dl

    ; escreve 'PLANETAS['
    lea dx, MSG_P2
    push dx
    call WRITE_STR_OUT

    ; escreve index do planeta
    pop bx
    mov dh, bl
    push bx
    mov CBYTE2ASCII_NUM, dh
    call CBYTE2ASCII
    lea dx, CBYTE2ASCII_STR
    push dx
    call WRITE_STR_OUT

    ; escreve ']: '
    lea dx, MSG_P3
    push dx
    call WRITE_STR_OUT

    ; escreve string ascii do numero 'X'
    pop bx
    push bx
    lea di, POSICAOX
    mov dh, [di+bx]
    mov CBYTE2ASCII_NUM, dh
    call CBYTE2ASCII
    lea dx, CBYTE2ASCII_STR
    push dx
    call WRITE_STR_OUT

    ; escreve ' '
    mov dh, ' '
    mov BYTE_OUT, dh
    call WRITE_BYTE

    ; escreve string ascii do numero 'Y'
    pop bx
    push bx
    lea di, POSICAOY
    mov dh, [di+bx]
    mov CBYTE2ASCII_NUM, dh
    call CBYTE2ASCII
    lea dx, CBYTE2ASCII_STR
    push dx
    call WRITE_STR_OUT

    ; pula linha
    mov dh, CR
    mov BYTE_OUT, dh
    call WRITE_BYTE
    mov dh, LF
    mov BYTE_OUT, dh
    call WRITE_BYTE
    
    pop bx
    inc bx

    loop LACO_LEITURAK

    ; pula linha
    mov dh, CR
    mov BYTE_OUT, dh
    call WRITE_BYTE
    mov dh, LF
    mov BYTE_OUT, dh
    call WRITE_BYTE

    ; jump problems
	jmp EXIT22
	LACO_LEITURAK:
	jmp LACO_LEITURA
	EXIT22:
    
    ; jump problems
    jmp SAIDA0203
    TERMINOU_DE_LER_SHROT2:
    jmp TERMINOU_DE_LER
    SAIDA0203:

	; jump problems
	jmp SAIDA029039
	LOOPJBREAKSHORT:
	jmp LOOPJBREAK
	SAIDA029039:

	; loop 2 campos de asteroides %%%%%%%%%%%%%%%%

    ; le numero de rotas com campos de asteroires na variavel NUM_ROTAS
    call NEXT_INT
    cmp BOOLEOF, 1
    je TERMINOU_DE_LER_SHROT2
    mov al, INT_NUM
    mov NUM_ROTAS, al
        
    ; escreve 'DISTANCIA E COMBUSTIVEL NECESSARIO: '
    lea dx, MSG_R1
    push dx
    call WRITE_STR_OUT


    ; laco para gravar no arquivo todas as rotas possiveis:
    ; caso NUM_PLANETAS == 3 - i=0 (j=i+1 loopj) inc i (j=i+1 loopj) inc i (j=i+1 loopj)
    ; 0-1
    ; 0-2
    ; 0-3
    ; 1-2
    ; 1-3
    ; 2-3

    ; setup inicial do loopi
    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov cl, NUM_PLANETAS
    LOOPI:

    push ax
    push cx
    push bx

    ; setup inicial do loopj
    cmp cx, 1
    je LOOPJBREAKSHORT
    mov bx, ax ; salva o indice i na variavel bx
    dec cx
    inc ax
    ;mov cx, 5
    ;mov ax, 6
    LOOPJ:

        ; escreve '('
        mov dh, '('
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve o binario em dh no arquivo de saida
        mov dh, bl                  ; coloca numero binario em dh
        mov CBYTE2ASCII_NUM, dh     ; coloca dh no argumento (entrada em CBYTE2ASCII_NUM)
        call CBYTE2ASCII            ; chama a subrotina (saida em CBYTE2ASCII_STR)
        ; salva numero ascii no arquivo de saida
        lea dx, CBYTE2ASCII_STR     ; coloca argumento em dx
        push dx                     ; coloca dx na pilha
        call WRITE_STR_OUT          ; chama a subrotina

        ; escreve '-'
        mov dh, '-'
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve o binario em dh no arquivo de saida
        mov dh, al                  ; coloca numero binario em dh
        mov CBYTE2ASCII_NUM, dh     ; coloca dh no argumento (entrada em CBYTE2ASCII_NUM)
        call CBYTE2ASCII            ; chama a subrotina (saida em CBYTE2ASCII_STR)
        ; salva numero ascii no arquivo de saida
        lea dx, CBYTE2ASCII_STR     ; coloca argumento em dx
        push dx                     ; coloca dx na pilha
        call WRITE_STR_OUT          ; chama a subrotina

        ; escreve ')'
        mov dh, ')'
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve ':'
        mov dh, ':'
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve ' '
        mov dh, ' '
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve a distancia entre planeta[i] e planeta [j]
        push ax
        push bx
        push cx
        push dx
        
        lea di, POSICAOX
        mov dl, [di + bx] ; di = array[0] e bx = indice i
        mov X1, dl

        lea di, POSICAOY
        mov dl, [di + bx] ; di = array[0] e bx = indice i
        mov Y1, dl

        mov bx, ax ; bx recebe indice j

        lea di, POSICAOX
        mov dl, [di + bx] ; di = array[0] e bx = indice j
        mov X2, dl

        lea di, POSICAOY
        mov dl, [di + bx] ; di = array[0] e bx = indice i
        mov Y2, dl

        call CALCULA_DIST

        ; escreve o binario em dh no arquivo de saida
        mov dh, DIST                ; coloca numero binario em dh
        mov CBYTE2ASCII_NUM, dh     ; coloca dh no argumento (entrada em CBYTE2ASCII_NUM)
        call CBYTE2ASCII            ; chama a subrotina (saida em CBYTE2ASCII_STR)
        ; salva numero ascii no arquivo de saida
        lea dx, CBYTE2ASCII_STR     ; coloca argumento em dx
        push dx                     ; coloca dx na pilha
        call WRITE_STR_OUT          ; chama a subrotina

        pop dx
        pop cx
        pop bx
        pop ax

        ; escreve ' '
        mov dh, ' '
        mov BYTE_OUT, dh
        call WRITE_BYTE

        ; escreve o custo entre planeta[i] e planeta [j]
        mov P0, bl ; coloca em p0 indice i
        mov P1, al ; coloca em p1 indice j
        ;mov DIST, DIST

        call CALCULA_COST

        ; escreve o binario em dh no arquivo de saida
        mov dx, COST                ; coloca numero binario em dh
        mov CBYTE2ASCII_NUM, dl     ; coloca dh no argumento (entrada em CBYTE2ASCII_NUM)
        call CBYTE2ASCII            ; chama a subrotina (saida em CBYTE2ASCII_STR)
        ; salva numero ascii no arquivo de saida
        lea dx, CBYTE2ASCII_STR     ; coloca argumento em dx
        push dx                     ; coloca dx na pilha
        call WRITE_STR_OUT          ; chama a subrotina

        ; pula linha
        mov dh, CR
        mov BYTE_OUT, dh
        call WRITE_BYTE
        mov dh, LF
        mov BYTE_OUT, dh
        call WRITE_BYTE

        inc ax

    loop LOOPJSHORT2
    LOOPJBREAK:

    pop bx
    pop cx
    pop ax

    inc ax

    loop LOOPISHORT2

    jmp SAIDA0A92
    LOOPJSHORT2:
    jmp LOOPJ
    LOOPISHORT2:
    jmp LOOPI
    SAIDA0A92:

	TERMINOU_DE_LER:

	jmp FECHAR_ARQUIVO

	FECHAR_ARQUIVO1:
    ; escreve msg0 na tela
    ;lea dx, MSGCLOSE2
    ;mov ah, 9
    ;int 21h

    jmp FINALIZA

	FECHAR_ARQUIVO:

    ; fecha o arquivo
    mov ah, 3eh
    mov bx, HANDLER
    int 21h

    jmp FINALIZA

	FINALIZA:
    call CLOSE_TO_WRITE

	FINALIZADOS:
	lea dx, MSG_OK
    mov ah, 9
    int 21h

    mov ax, 4c00h
    int 21h

; ----------------------------------------------------------------------------------------

    ; Le um conjunto de numeros ascii do arquivo e converte para byte 
    ; Ler "127" (3 bytes) e retorna 127 (1 byte)
    NEXT_INT PROC NEAR

        ; faz back dos regs usados na proc na pilha
        push ax
        push bx
        push cx
        push dx
        push di

        mov ax, 0
        mov bx, 0
        mov cx, 0
        mov dx, 0
        mov di, 0

IGNORA_ATE_ACHAR_NUMERO:

        ; BUFFER = byte lido
        ; BOOLEOF = 1 se EOF
        call NEXT_BYTE
        mov ah, BUFFER
        mov al, BOOLEOF
        cmp al, 1
        jne NAO_DEU_EOF2
        jmp DEU_EOF2

NAO_DEU_EOF2:

        ; repete leitura ate achar um ascii numerico valido

        cmp ah, SPACE
        je IGNORA_ATE_ACHAR_NUMERO

        cmp ah, TAB
        je IGNORA_ATE_ACHAR_NUMERO

        cmp ah, ENTERK
        je IGNORA_ATE_ACHAR_NUMERO

        cmp ah, LF
        je IGNORA_ATE_ACHAR_NUMERO

        cmp ah, CR
        je IGNORA_ATE_ACHAR_NUMERO

        ; se chegou aqui, tenho o inicio de um numero

        lea di, STR_NUM

		; CASA DECIMAL 1:

        ; ascii to int
        sub ah, 48

        ; num_str[0] = int
        mov [di], ah

        ; di = STR_NUM[1]
        inc di

        ; numero de casas decimais++
        inc bh

		; CASA DECIMAL 2:

        ; al tem o next byte lido
        call NEXT_BYTE
        mov ah, BUFFER
        mov al, BOOLEOF
        cmp al, 1
        jne NAO_DEU_EOF3
        mov BOOLEOF, 0
        jmp FINALIZA_MONTAGEM ; se deu eof a partir do segundo decimal, finaliza

		NAO_DEU_EOF3:

        ; SE PROXIMO BYTE FOR ESPACO, TAB OU ENTER FINALIZA MONTAGEM
        cmp ah, SPACE
        je FINALIZA_MONTAGEM

        cmp ah, TAB
        je FINALIZA_MONTAGEM

        cmp ah, CR
        je FINALIZA_MONTAGEM

        cmp ah, LF
        je FINALIZA_MONTAGEM

        ; trato a segunda casa decimal do numero:

        ; ascii to int
        sub ah, 48

        ; num_str[1] = int
        mov [di], ah

        ; di = STR_NUM[2]
        inc di

        ; numero de casas decimais++
        inc bh

		; CASA DECIMAL 3:

        ; verifico se tenho outro numero

        ; al tem o next byte lido
        call NEXT_BYTE
        mov ah, BUFFER
        mov al, BOOLEOF
        cmp al, 1
        jne NAO_DEU_EOF4
        mov BOOLEOF, 0
        jmp FINALIZA_MONTAGEM ; se deu eof a partir do segundo finaliza

		NAO_DEU_EOF4:

        ; SE PROXIMO BYTE FOR ESPACO, TAB OU ENTER FINALIZA MONTAGEM
        cmp ah, SPACE
        je FINALIZA_MONTAGEM

        cmp ah, TAB
        je FINALIZA_MONTAGEM

        cmp ah, CR
        je FINALIZA_MONTAGEM

        cmp ah, LF
        je FINALIZA_MONTAGEM

        ; trato a terceira casa decimal do numero:

        ; ascii to int
        sub ah, 48

        ; num_str[2] = int
        mov [di], ah

        ; di = STR_NUM[3]
        inc di

        ; numero de casas decimais++
        inc bh

        ; vou ter no maximo numero com 3 casas decimais, entao FINALIZA_MONTAGEM

		FINALIZA_MONTAGEM:
        ; tenho STR_NUM="123"
        ; tenho bh=3 se "123";  bh=2 se "12";  bh=1 se "1";  bh=0 se ""
        ; se bh=3: INT_NUM = STR_NUM[0]*100 + STR_NUM[1]*10 + STR_NUM[2]
        ; se bh=2: INT_NUM = STR_NUM[0]*10 + STR_NUM[1]
        ; se bh=1: INT_NUM = STR_NUM[0]

        ; bh==1

		BH1:

        cmp bh, 1
        jne BH2

        lea di, STR_NUM
        mov ch, [di]
        mov INT_NUM, ch
        jmp MONTAGEM_FINALIZADA

		BH2:

        cmp bh, 2
        jne BH3

        lea di, STR_NUM             ; di = STR_NUM[0]
        mov ch, [di]                 ; ch = mem(di)

        mov al, ch
        mov bl, 10
        mul bl
        mov ch, al                    ; ax = ch * 10

        inc di                         ; di = di + 1 OU di = di + 1 byte

        add ch, [di]                ; ch = ch + mem(di)

        mov INT_NUM, ch
        jmp MONTAGEM_FINALIZADA

		BH3:

        cmp bh, 3
        jne MONTAGEM_FINALIZADA

        lea di, STR_NUM             ; di = STR_NUM
        mov ch, [di]                 ; ch = mem(di)

        mov al, ch
        mov bl, 100
        mul bl
        mov ch, al                     ; ch = ch * 100

        inc di                         ; di = STR_NUM+1

        mov dh, [di]                ; dh = mem(STR_NUM+1)

        mov al, dh
        mov bl, 10
        mul bl
        mov dh, al
        add ch, dh                     ; ch = ch + dh

        inc di                         ; di = STR_NUM+2

        add ch, [di]                 ; ch = ch + mem(STR_NUM+2)

        mov INT_NUM, ch             ; mem(INT_NUM) = ch
        jmp MONTAGEM_FINALIZADA


		MONTAGEM_FINALIZADA:

		DEU_EOF2:
        
        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    NEXT_INT ENDP

    ; Le 1 byte do arquivo associado ao handle
    ; Coloca o byte na variavel BUFFER
    ; BOOLEOF = 1 se eof
    NEXT_BYTE PROC NEAR

        ; faz backup de reg usados na proc
        push ax
        push bx
        push cx
        push dx

        ; le 1 byte do arquivo e coloca na variavel buffer
        mov ah, 3fh
        mov bx, HANDLER
        mov cx, 1
        lea dx, BUFFER
        int 21h

        ; VERIFICA EOF
        ; se ax != cx, eof
        cmp ax, cx
        je NOT_EOF

        ; deu eof
        mov ah, 1
        mov BOOLEOF, ah

        jmp FIM_EOF ; pula print

        ; print it eof
        push ax
        push bx
        push cx
        push dx
        mov ah, 2
        mov dl, '<'
        int 21h
        mov ah, 2
        mov dl, '@'
        int 21h
        mov ah, 2
        mov dl, '>'
        int 21h
        pop dx
        pop cx
        pop bx
        pop ax

        jmp FIM_EOF

		; nao deu eof
		NOT_EOF:

        jmp FIM_EOF ; pula print it

        push ax
        push bx
        push cx
        push dx

        mov ah, 2
        mov dl, '['
        int 21h

        mov ah, BUFFER
        cmp ah, CR
        jne PPP2

        mov ah, 2
        mov dl, '@'
        int 21h
        jmp PPP5

		PPP2:

        mov ah, BUFFER
        cmp ah, LF
        jne PPP4

        mov ah, 2
        mov dl, '#'
        int 21h
        jmp PPP5

		PPP4:

        mov ah, 2
        mov dl, BUFFER
        int 21h

		PPP5:

        mov ah, 2
        mov dl, ']'
        int 21h

        pop dx
        pop cx
        pop bx
        pop ax

        mov ah, 0
        mov BOOLEOF, ah

        ; fim da verificao do eof
        FIM_EOF:

        ; restaura reg usados from pilha
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    NEXT_BYTE ENDP

    ; procedure
    PRINT_BUFFER PROC NEAR

        ; faz backup de reg usados na proc
        push ax
        push bx
        push cx
        push dx

        mov ah, 2
        mov dl, BUFFER
        int 21h

        mov ah, 2
        mov dl, LF
        int 21h

        ; restaura reg usados from pilha
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    PRINT_BUFFER ENDP

    ; procedure
    PRINT_BUFFER2 PROC NEAR

        ; faz backup de reg usados na proc
        push ax
        push bx
        push cx
        push dx

        mov ah, 2
        mov dl, BUFFER2
        int 21h

        mov ah, 2
        mov dl, LF
        int 21h

        ; restaura reg usados from pilha
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    PRINT_BUFFER2 ENDP

    ; procedure
    PRINT_BUFFER2_ASCII PROC NEAR

        ; faz backup de reg usados na proc
        push ax
        push bx
        push cx
        push dx

        mov ah, 2
        mov dl, BUFFER2
        add dl, 48
        int 21h

        mov ah, 2
        mov dl, LF
        int 21h

        ; restaura reg usados from pilha
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    PRINT_BUFFER2_ASCII ENDP


    PRINT_STR_NUM PROC NEAR

        ; faz backup de reg usados na proc
        push ax
        push bx
        push cx
        push dx

        lea di, STR_NUM
        add di, 4
        mov byte ptr [di], 'W'
        inc di
        mov byte ptr [di], '$'

        lea dx, STR_NUM
        mov ah, 9
        int 21h

        mov ah, 2
        mov dl, LF
        int 21h

        ; restaura reg usados from pilha
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    PRINT_STR_NUM ENDP

    ; Calcula a raiz quadrada de um numero usando a equacao de pell
    ; SQRTARG WORD - Numero a tirar a raiz quadrada (ex.: 25)
    ; SQRTRES BYTE - Raiz do numero (ex.: 5)

    ; sqrt(16) - 4
    ; sqrt(25) - 5
    ; sqrt((entre 17 e 24)) = 4 se sqrt < 4,5 ou 5 se sqrt > 4,5
    CALCULA_SQRT PROC NEAR
        push ax
        push bx
        push cx
        push dx

        mov ax, SQRTARG    ; numero para tirar raiz
        mov bx, 1         ; numeros primos
        mov cl, 0         ; contador = resposta

LOOPSQRT:
		cmp ax, bx
		jb AXMENORBX	; if ax < bx, JUMP

		sub ax, bx
        inc cl
        inc bx
        inc bx
        cmp ax, 0
        jnz LOOPSQRT

        AXMENORBX:
		sub bx, 1      ; sub bx, 1
		push ax ; push ax, bx, cx, dx
		push bx ; push ax, bx, cx, dx
		push cx ; push ax, bx, cx, dx
		;push dx ; push ax, bx, cx, dx
		mov ax, bx ; div bx por 2
		mov bl, 2
		div bl
		mov bx, 0
		mov dx, 0
		mov dl, al
		;pop dx ; pop ax, bx, cx, dx
		pop cx ; pop ax, bx, cx, dx
		pop bx ; pop ax, bx, cx, dx
		pop ax ; pop ax, bx, cx, dx

		cmp ax, dx        
		ja AXMAIORBX2  ; if ax > bx/2, JUMP        
		jmp SQRT_RETURN  

		AXMAIORBX2:     
		inc cx				
		jmp SQRT_RETURN                         
       
        

        SQRT_RETURN:
        mov SQRTRES, cl

        pop dx
        pop cx
        pop bx
        pop ax

        ret
    CALCULA_SQRT ENDP

    ; Grava um byte no arquivo associado ao handle_out
    ; BYTE_OUT BYTE: Byte a ser gravado no arquivo
    WRITE_BYTE PROC NEAR
        push ax
        push bx
        push cx
        push dx

        mov ah, 40h
        mov bx, HANDLER_OUT
        mov cx, 1
        lea dx, BYTE_OUT
        int 21h

        jnc SEM_ERRO_WRITE_BTE

        ; avisa que deu err ao gravar
        lea dx, MSG_ERRO_WRITE
        mov ah, 9
        int 21h

        SEM_ERRO_WRITE_BTE:

        pop dx
        pop cx
        pop bx
        pop ax

        ret
    WRITE_BYTE ENDP

    ; Converte um numero (byte) para uma string ascii de 4 caracteres (3 chars para o numero e 1 char para o $)
    ; CBYTE2ASCII_NUM - Numero a ser convertido
    ; CBYTE2ASCII_STR - String de saida no formato "1$$$" ou "11$$" ou "111$"
    CBYTE2ASCII PROC NEAR
        push ax
        push bx
        push cx
        push dx

        ; preenche string com $
        lea di, CBYTE2ASCII_STR

        mov byte ptr [di],'$'
        mov byte ptr [di+1],'$'
        mov byte ptr [di+2],'$'
        mov byte ptr [di+3],'$'

        ; conta numeros: 3 = 127  2=12  1=1

        mov al, CBYTE2ASCII_NUM
        mov ah, 0
        mov bh, 10
        mov si, 0

        LOOPZ2:

        mov ah, 0
        mov bh, 10
        div bh
        cmp al, 0 ; ah == 0?
        jz EXIT393
        inc si
        jmp LOOPZ2
        EXIT393:

        ; monta a string
        lea di, CBYTE2ASCII_STR
        mov al, CBYTE2ASCII_NUM ; move o addr ou o conteudo do addr?
        cbw
        mov bh, 10

        LOOPZ23:

        mov ah, 0
        mov bh, 10
        div bh
        add ah, 48
        mov bx, si
        mov [di+bx], ah
        dec si
        cmp al, 0
        jz EXIT3933
        jmp LOOPZ23

        EXIT3933:

        ; string[0] = 1 caso 12
        ; string[1] = 2 caso 12
        ; string[2] = $

        pop dx
        pop cx
        pop bx
        pop ax

        ret
    CBYTE2ASCII ENDP

    ; Fecha o arquivo de saida associado ao handle_out
    CLOSE_TO_WRITE PROC NEAR
        push ax
        push bx
        push cx
        push dx

        ; fecha
        mov ah, 3eh
        lea bx, HANDLER_OUT
        int 21h

        ; verifica por erro no fechamento
        jnc CRIOU_SEM_ERRO22

  

        CRIOU_SEM_ERRO22:

        pop dx
        pop cx
        pop bx
        pop ax

        ret
    CLOSE_TO_WRITE ENDP

    ; Cria arquivo de saida e preenche o handler_out
    OPEN_TO_WRITE PROC NEAR
        push ax
        push bx
        push cx
        push dx

        ; colcoa .res no FILENAME_O
        call PREPARE_FILENAME_O

        ; cria ou trunca
        mov ah, 3ch
        mov cx, 0
        lea dx, FILENAME_O
        int 21h

        ; verifica por erro na abertura
        jnc CRIOU_SEM_ERRO

        ; deu erro, mostra mensagem de erro e repete
        lea dx, MSG_ERRO
        mov ah, 9
        int 21h

        jmp FIMOPENTOWRITE

        ; repete
        ;jmp PEDIR_NOME
        CRIOU_SEM_ERRO:
        ; copia handler
        mov HANDLER_OUT, ax

        ; diz que criou ok
        ;lea dx, MSG_OK
        ;mov ah, 9
        ;int 21h

        FIMOPENTOWRITE:
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    OPEN_TO_WRITE ENDP

    PREPARE_FILENAME_O PROC NEAR
        push ax
        push bx
        push cx
        push dx
        push di
        push si

        ; copia filename sem .pla para FILENAME_O
        lea di, FILENAME
        lea si, FILENAME_O

        REPETE_FILENAMEO:
        cmp byte ptr [di], '.'
        je COLOCA_RES_FILENAME
        mov al, [di]
        mov [si], al
        inc di 
        inc si
        jmp REPETE_FILENAMEO

        COLOCA_RES_FILENAME:
        mov byte ptr [si], '.'
        inc si
        mov byte ptr [si], 'r'
        inc si
        mov byte ptr [si], 'e'
        inc si
        mov byte ptr [si], 's'
        inc si
        mov byte ptr [si], '0'


        pop si
        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    PREPARE_FILENAME_O ENDP

    ; Procedure de teste para passar dois argumentos usando a pilha
    WRITETWOBYTEFROMSTACK PROC NEAR
        push bp
        mov bp, sp

        push ax
        push bx
        push cx
        push dx

        mov dh, [bp+6] ; pega primeiro arg da pilha (mais fundo na pilha)
        mov BYTE_OUT, dh

        mov ah, 40h
        mov bx, HANDLER_OUT
        mov cx, 1
        lea dx, BYTE_OUT
        int 21h

        mov dh, [bp+4] ; pega segundo arg da pilha
        mov BYTE_OUT, dh

        mov ah, 40h
        mov bx, HANDLER_OUT
        mov cx, 1
        lea dx, BYTE_OUT
        int 21h

        pop dx
        pop cx
        pop bx
        pop ax

        pop bp

        ret 4
    WRITETWOBYTEFROMSTACK ENDP

    ; procedure
    ; screve uma string terminada por $ apontada por dx passda pela pilha no arquivo de saida
    WRITE_STR_OUT PROC NEAR
        push bp
        mov bp, sp

        push ax
        push bx
        push cx
        push dx
        push di

        ; conta numero de chars ate encontrar $
        mov bx, 0
        mov di, [bp+4] ; string apontada por di

        LOOOOP:
        mov ch, [bx+di]
        inc bx
        cmp ch, '$'
        jne LOOOOP

        mov cx, bx
        dec cx

        ; int 21 para escrever na saida
        mov ah, 40h
        mov bx, HANDLER_OUT
        mov dx, [bp+4] ; string ds:dx
        int 21h

        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        pop bp

        ret 2
    WRITE_STR_OUT ENDP

    CALCULA_SQUARE PROC NEAR
		push ax
		push bx
		push cx
		push dx
		push di

		MOV AX, 0
		MOV BL, POWERARG
		MOV AL, BL
		IMUL BL
		MOV POWERRES, AX

		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		RET
    CALCULA_SQUARE ENDP

    ; Cria arquivo de saida e preenche o handler_out
    CALCULA_DIST PROC NEAR
        push ax
        push bx
        push cx
        push dx
        push di

        ; DIST = SQRT((x2-x1)² + (y2-y1)²)
        ; complemento de 2 => 0 ate +127 ou -1 até -128

        mov ax, 0
        mov bx, 0
        mov cx, 0
        mov dx, 0

        mov al, X2
        mov bl, X1
        sub al, bl

        mov POWERARG, al
        call CALCULA_SQUARE
        mov dx, POWERRES

        mov ax, 0
        mov bx, 0

        mov al, Y2
        mov bl, Y1
        sub al, bl

        mov POWERARG, al
        call CALCULA_SQUARE
        mov ax, POWERRES 

        add ax, dx

        mov SQRTARG, ax
        call CALCULA_SQRT
        mov ch, SQRTRES

        mov DIST, ch

        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    CALCULA_DIST ENDP

    ; Imprime the_byte na tela
    PRINT_THE_BYTE PROC NEAR
        ;push ax
        ;push bx
        ;push cx
        ;push dx
        ;push di

        ;mov dl, THE_BYTE
		;mov ah, 2
		;int 21h

        ;pop di
        ;pop dx
        ;pop cx
        ;pop bx
        ;pop ax

        ret
    PRINT_THE_BYTE ENDP

    CALCULA_COST PROC NEAR
        push ax
        push bx
        push cx
        push dx
        push di

        mov ax, 0
        mov bx, 0
        mov cx, 0
        mov dx, 0
        mov di, 0

        mov THE_BYTE, '>'
        call PRINT_THE_BYTE

        ; salva handler original
        mov ax, HANDLER
        mov HANDLER_BKP, ax

        ; abre arquivo
	    mov ah, 3dh
	    mov al, 0	
	    lea dx, FILENAME
	    int 21h

	    jnc COST_ABRIU_OK

	    	; print error
	    	mov THE_BYTE, 'E'
        	call PRINT_THE_BYTE

        	; byte to string and print
		    mov CBYTE2ASCII_NUM, al
	        call CBYTE2ASCII           
	        lea dx, CBYTE2ASCII_STR  
		    mov ah, 9
		    int 21h

		    ; retorna
		    jmp COST_RETURN_ERROR

	    COST_ABRIU_OK:

	    mov THE_BYTE, 'K'
    	call PRINT_THE_BYTE

	    mov HANDLER, ax

        ; le numero de planetas e ignora loop 1
		call NEXT_INT
		cmp BOOLEOF, 1
		je CUSTO_EOF
		mov cx, 0
		mov cl, INT_NUM
		COST_LOOP_1:

			mov THE_BYTE, 'A'
    		call PRINT_THE_BYTE

			call NEXT_INT
			cmp BOOLEOF, 1
			je CUSTO_EOF

			call NEXT_INT
			cmp BOOLEOF, 1
			je CUSTO_EOF

		loop COST_LOOP_1

		; le numero de rotas
		call NEXT_INT
		cmp BOOLEOF, 1
		je CUSTO_EOF
		mov cx, 0
		mov cl, INT_NUM

		; se rotas == 0
		cmp cl, 0
		je TEM_ZERO_ROTASSHORT

		; short jump problem
		jmp SAIDAAD39kK9
		
		CUSTO_EOF:
		jmp CUSTO_EOF2

		TEM_ZERO_ROTASSHORT:
		jmp TEM_ZERO_ROTAS2

		SAIDAAD39kK9:

        ; le loop 2
        COST_LOOP_2:

        	mov THE_BYTE, 'B'
    		call PRINT_THE_BYTE

        	push cx

        	; primeiro numero
        	call NEXT_INT
			cmp BOOLEOF, 1
			je CUSTO_EOF
			mov al, INT_NUM ; pi

			; segundo numero
			call NEXT_INT
			cmp BOOLEOF, 1
			je CUSTO_EOF
			mov ah, INT_NUM ; pf

			; terceiro numero
			call NEXT_INT
			cmp BOOLEOF, 1
			je CUSTO_EOF
			mov bl, INT_NUM ; numero de campos

			mov dl, P0
			mov dh, P1



        	; if pi = p0 AND pf = p1 OR pi = p1 AND pf = p0
        	cmp al, dl ; pi == p0
        	jne CUSTO_NAO_IGUAL_1
        	cmp ah, dh ; pf == p1
			jne CUSTO_NAO_IGUAL_1

				; é igual! 1
			    mov THE_BYTE, 'Z'
		    	call PRINT_THE_BYTE

				; cost = dist + 5 * numero de campos
				push ax
			    push bx
			    push cx
			    push dx

			    mov al, 5
			    ; mov bl, 
			    mul bl
			    mov bx, 0
			    mov bl, DIST
			    add ax, bx
			    mov COST, ax

			    pop dx
		        pop cx
		        pop bx
		        pop ax

		        jmp CUSTO_NAO_IGUAL_FINAL33




        	CUSTO_NAO_IGUAL_1:

        	cmp al, dh ; pi == p1
        	jne CUSTO_NAO_IGUAL_FINAL
        	cmp ah, dl ; pf == p0
			jne CUSTO_NAO_IGUAL_FINAL

				; é igual! 2

			    mov THE_BYTE, 'X'
		    	call PRINT_THE_BYTE

				; cost = dist + 5 * numero de campos
				push ax
			    push bx
			    push cx
			    push dx

			    mov al, 5
			    ; mov bl, 
			    mul bl
			    mov bx, 0
			    mov bl, DIST
			    add ax, bx
			    mov COST, ax

			    pop dx
		        pop cx
		        pop bx
		        pop ax

		        jmp CUSTO_NAO_IGUAL_FINAL33

		    ; quando ele der loop de novo, ele vai cair aqui porque ja teve igual e nao vai ter de novo
			CUSTO_NAO_IGUAL_FINAL:
			 mov ax, 0
		     mov al, DIST
		     mov COST, ax

		     jmp SAIDAKJH3

		    CUSTO_NAO_IGUAL_FINAL33:
		    	pop cx
		    	jmp CUSTO_EOF2
		    SAIDAKJH3:
			
			pop cx

        loop COST_LOOP_2S

        jmp SAIDAUY8383
        	COST_LOOP_2S:
        	jmp COST_LOOP_2

        	TEM_ZERO_ROTAS2:
        	mov ax, 0
		    mov al, DIST
		    mov COST, ax
		    jmp CUSTO_EOF2
        SAIDAUY8383:

        CUSTO_EOF2:



        ; fecha arquivo
        mov ah, 3eh
    	mov bx, HANDLER
    	int 21h

    	COST_RETURN_ERROR:

    	mov THE_BYTE, '<'
    	call PRINT_THE_BYTE

        mov ax, HANDLER_BKP
        mov HANDLER, ax

        mov THE_BYTE, '@'
		call PRINT_THE_BYTE

        pop di
        pop dx
        pop cx
        pop bx
        pop ax

        ret
    CALCULA_COST ENDP

CODIGO ends
end INICIO