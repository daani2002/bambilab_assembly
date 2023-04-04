DEF LD 0x80     ;LED-ek c�me
DEF SW 0x81     ;kapcsol�k c�me
DEF BT 0x84     ;nyom�gomb regiszter
DEF BTIF 0x86   ;v�ltoz�s figyel� regiszter
DEF DIG0 0x90    ;display 0.digit
DEF DIG1 0x91    ;display 1.digit
DEF DIG2 0x92    ;display 2.digit
DEF DIG3 0x93    ;display 3.digit

main: mov r2, SW
      mov r3, r2
      and r3, #0x0F  ;kapcsol� als� 4 bitje: op2
      and r2, #0xF0  ;kapcsol� fels� 4 bitje: op1
      swp r2 
      ;jsr display    ;h�tszegmens kijelz�re �r� szubrutin
      ;mov LD, r6
       
loop: mov r0, BT    ;nyom�gombok beolvas�sa
      mov r1, BTIF  ;megv�ltozott nyom�gombn�l a megfelel� BTIF bit 1-lesz
      mov BTIF, r1  ;jelz�s(ek) t�rl�se (az t�rl�dik, ahova 1-et �runk!)
      and r0, r1    ;azon bit lesz 1, amelyhez tartoz� gombot lenyomt�k
      tst r0, #0x01 ;BT0 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
      jz tst_BT1    ;k�vetkez� BT tesztel�se, ha nincs BT0 lenyom�s
      jsr sum       ; a BT0 lenyom�sa eset�n v�grehajtand� szubrutin
                    ; v�grehajt�sa
      jsr display
      jmp main      ;egyszerre csak 1 gomb lenyom�s�t vessz�k figyelembe

tst_BT1: tst r0, #0x02
         jz tst_BT2
         jsr substract
         jsr display
         jmp main
        
tst_BT2: tst r0, #0x04
         jz tst_BT3
         jsr mul
         jsr display
         jmp main

tst_BT3: tst r0, #0x08
         jz main
         jsr div
         jsr display
         jmp main
         
sum:     mov r7, r3 ;op2
         mov r6, r2 ;op1
         add r6, r7 ;op1+op2
         rts
      
substract:  mov r7, r3  ;op2
            mov r6, r2  ;op1
            sub r6, r7  ;op1-op2
            jc error    ;hibajelz�s
            rts         

mul:    mov r7, r3  ;op2
        mov r6, r2  ;op1
        mov r8, #0x00  ;r8-ba fogunk �sszegezni
add1:   sr0 r7      ;r7 legals� bitje ker�l a C-be
        jnc add2    ;ha nem 1-es volt, vizsg�ljuk a k�vetkez� bitet
        add r8, r6  ;ha 1-es volt, hozz�adjuk r8-hoz r6 1-szeres�t
add2:   sr0 r7
        jnc add4
        mov r9, r6
        sl0 r9
        add r8, r9
add4:   sr0 r7
        jnc add8
        mov r9, r6
        sl0 r9
        sl0 r9
        add r8, r9
add8:   sr0 r7
        jnc mul_ret
        mov r9, r6
        sl0 r9
        sl0 r9
        sl0 r9
        add r8, r9
                
mul_ret:mov r6, r8    
        rts
                
div:    mov r11, #0x00
        mov r6, r2  ;osztand�(marad�k)
        mov r7, r3  ;oszt�
        tst r7, #0xFF
        jz error
        mov r10, r6
        mov r8, r7  ;ez lehet nem kell!!
harmadik:
        swp r8
        sr0 r8
        sub r10, r8
        jc  masodik
        or r11, #0x08
        mov r6, r10
masodik:sr0 r8
        mov r10, r6
        sub r10, r8
        jc elso
        or r11, #0x04
        mov r6, r10
elso:   sr0 r8
        mov r10, r6
        sub r10, r8
        jc  nulladik
        or  r11, #0x02
        mov r6, r10
nulladik:sr0 r8
        mov r10, r6
        sub r10, r8
        jc  div_ret
        or  r11, #0x01
        mov r6, r10
div_ret:        
        mov r7, r11
        swp r7      ;az eg�szr�sz a fels� 4 bitre ker�l
        add r6, r7
        rts

error:  mov r6, #0xFF
        rts

display: mov r7, SW
         mov r8, #0x00
         mov r10, r0    ;r0-ban van a lenyomott gomb �rt�ke
         tst r10, #0x08 ;vizsg�lom, hogy oszt�s volt-e
         jz  disp_norm
         mov r8, #0x02  ;a DIG1 pontja vil�g�tson
disp_norm: 
         mov r10, #sgtbl
         mov r9, r6
         and r9, #0x0F
         add r10, r9
         mov r10, (r10)
         mov DIG0, r10
         
         mov r10, #sgtbl
         mov r9, r6
         and r9, #0xF0
         swp r9
         add r10, r9
         mov r10, (r10)
         tst r8, #0x02
         jz D1_mov
         add r10, #0x80
D1_mov:  mov DIG1, r10
         
         mov r9, r7
         and r7, #0x0F
         mov r10, #sgtbl
         add r10, r7
         mov r10, (r10)
         mov DIG2, r10
         
         and r9, #0xF0
         mov r7, r9
         swp r7
         mov r10, #sgtbl
         add r10, r7
         mov r10, (r10)
         mov DIG3, r10
         
         rts


DATA ; adatszegmens kijel�l�se
; A h�tszegmenses dek�der szegmensk�pei (0-9, A-F) az adatmem�ri�ban.
sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71         
         