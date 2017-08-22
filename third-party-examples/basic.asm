mensagem db '8086 processor!'

; BIOS call to move the screen
; and change the backgroud
rolar_tela:
        mov     ch,0         ; lin 0
        mov     cl,0         ; col 0
        mov     dh,24        ; lin 24
        mov     dl,79        ; col 79
        mov     bh,1Fh       ; white-blue-blackground
        mov     al,0         ; all screen
        mov     ah,6         ; scroll window up
        int     10h          ; call

; BIOS call to positionate the cursor at center of screen
posiciona_cursor:
         mov     dh,11
         mov     dl,11	
         mov     bh,0	
         mov     ah,2     
         int     10h       

espera_ENTER:
        mov ah,8         ; wait for some key be pressed
        int 21h			 ; wait for some key be pressed
        cmp al,0DH       ; get the ascii of the key
        jne espera_ENTER ; if not ENTER, repeat
