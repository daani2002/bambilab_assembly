DEF LD 0x80     ;LED-ek címe
DEF SW 0x81     ;kapcsolók címe
DEF BT 0x84     ;nyomógomb regiszter
DEF BTIF 0x86   ;változás figyelõ regiszter

main: mov r2, SW
      mov r3, r2
      and r3, #0x0F  ;kapcsoló alsó 4 bitje: op2
      and r2, #0xF0  ;kapcsoló felsõ 4 bitje: op1
      swp r2 
      mov LD, r7
       
loop: mov r0, BT    ;nyomógombok beolvasása
      mov r1, BTIF  ;megváltozott nyomógombnál a megfelelõ BTIF bit 1-lesz
      mov BTIF, r1  ;jelzés(ek) törlése (az törlõdik, ahova 1-et írunk!)
      and r0, r1    ;azon bit lesz 1, amelyhez tartozó gombot lenyomták
      tst r0, #0x01 ;BT0 lenyomásának tesztelése (Z=0, ha lenyomták)
      jz tst_BT1    ;következõ BT tesztelése, ha nincs BT0 lenyomás
      jsr sum       ; a BT0 lenyomása esetén végrehajtandó szubrutin
                    ; végrehajtása
      jmp main      ;egyszerre csak 1 gomb lenyomását vesszük figyelembe

tst_BT1: tst r0, #0x02
         jz tst_BT2
         jsr substract
         jmp main
        
tst_BT2: tst r0, #0x04
         jz tst_BT3
         jsr mul
         jmp main

tst_BT3: tst r0, #0x08
         jz main
         jsr div
         jmp main
         
sum:     mov r7, r3 ;op2
         mov r6, r2 ;op1
         add r7, r6 ;op1+op2
         rts
      
substract:  mov r7, r3  ;op2
            mov r6, r2  ;op1
            sub r6, r7  ;op1-op2
            jc error    ;hibajelzés
            rts         

mul:    mov r7, r3  ;op2
        mov r6, r2  ;op1
        mov r8, #0x00  ;r8-ba fogunk összegezni
add1:   sr0 r7      ;r7 legalsó bitje kerül a C-be
        jnc add2    ;ha nem 1-es volt, vizsgáljuk a következõ bitet
        add r8, r6  ;ha 1-es volt, hozzáadjuk r8-hoz r6 1-szeresét
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
        sl0 r9
        sl0 r9
        sl0 r9
        add r8, r9
                
mul_ret:mov r7, r8    
        rts
                
div:    mov r11, #0x00
        mov r7, r2  ;osztandó(maradék)
        mov r6, r3  ;osztó
        tst r6, #0xFF
        jz error
        mov r10, r7
        mov r8, r6  ;ez lehet nem kell!!
harmadik:
        swp r8
        sr0 r8
        sub r10, r8
        jc  masodik
        or r11, #0x08
        mov r7, r10
masodik:sr0 r8
        mov r10, r7
        sub r10, r8
        jc elso
        or r11, #0x04
        mov r7, r10
elso:   sr0 r8
        mov r10, r7
        sub r10, r8
        jc  nulladik
        or  r11, #0x02
        mov r7, r10
nulladik:sr0 r8
        mov r10, r7
        sub r10, r8
        jc  div_ret
        or  r11, #0x01
        mov r7, r10
div_ret:        
        mov r6, r11
        swp r6      ;az egészrész a felsõ 4 bitre kerül
        add r7, r6
        rts

error:  mov r7, #0xFF
        rts

     
DATA ; adatszegmens kijelölése
; A hétszegmenses dekóder szegmensképei (0-9, A-F) az adatmemóriában.
sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71         
         