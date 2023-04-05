DEF LD 0x80     ;LED-ek címe
DEF SW 0x81     ;kapcsolók címe
DEF BT 0x84     ;nyomógomb regiszter
DEF BTIF 0x86   ;változás figyelo regiszter
DEF DIG0 0x90    ;display 0.digit
DEF DIG1 0x91    ;display 1.digit
DEF DIG2 0x92    ;display 2.digit
DEF DIG3 0x93    ;display 3.digit

main: mov r2, SW
      mov r3, r2
      and r3, #0x0F  ;kapcsoló alsó 4 bitje: op2
      and r2, #0xF0  ;kapcsoló felso 4 bitje: op1
      swp r2 
      ;mov r6, r2     ;a muveletvégzo szubrutinok bemenetei
      ;mov r7, r3
      ;jsr lat9
      ;jsr display    ;hétszegmens kijelzore író szubrutin
      ;mov LD, r6
       
loop: mov r0, BT    ;nyomógombok beolvasása
      mov r1, BTIF  ;megváltozott nyomógombnál a megfelelo BTIF bit 1-lesz
      mov BTIF, r1  ;jelzés(ek) törlése (az törlodik, ahova 1-et írunk!)
      and r0, r1    ;azon bit lesz 1, amelyhez tartozó gombot lenyomták
      tst r0, #0x01 ;BT0 lenyomásának tesztelése (Z=0, ha lenyomták)
      jz tst_BT1    ;következo BT tesztelése, ha nincs BT0 lenyomás
      mov r6, r2     ;a muveletvégzo szubrutinok bemenetei
      mov r7, r3
      jsr sum       ; a BT0 lenyomása esetén végrehajtandó szubrutin
                    ; végrehajtása
      jsr bin2bcd
      jmp kijel
      ;jsr display
      ;jmp main      ;egyszerre csak 1 gomb lenyomását vesszük figyelembe

tst_BT1: tst r0, #0x02
         jz tst_BT2
         mov r6, r2     ;a muveletvégzo szubrutinok bemenetei
          mov r7, r3
         jsr substract
         cmp r6, #0xEE
         jz  kijel
         jsr bin2bcd
         jmp kijel
         ;jsr display
         ;jmp main
        
tst_BT2: tst r0, #0x04
         jz tst_BT3
         mov r6, r2     ;a muveletvégzo szubrutinok bemenetei
         mov r7, r3
         jsr mul
         jsr bin2bcd
         jmp kijel
         ;jsr display
         ;jmp main

tst_BT3: tst r0, #0x08
         jz kijel
         mov r6, r2     ;a muveletvégzo szubrutinok bemenetei
         mov r7, r3
         jsr div
kijel:   jsr display
         jmp main

;lat9:   cmp

sum:     add r6, r7 ;op1+op2
         rts
      
substract:  sub r6, r7  ;op1-op2
            jc error    ;hibajelzés
            rts         

mul:    mov r8, #0x00  ;r8-ba fogunk összegezni
add1:   sr0 r7      ;r7 legalsó bitje kerül a C-be
        jnc add2    ;ha nem 1-es volt, vizsgáljuk a következo bitet
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
        mov r9, r6
        sl0 r9
        sl0 r9
        sl0 r9
        add r8, r9
                
mul_ret:mov r6, r8    
        rts
                
div:    mov r11, #0x00
        tst r7, #0xFF
        jz error
        mov r10, r6 ;r6 osztandó, r7 osztó
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
        swp r7      ;az egészrész a felso 4 bitre kerül
        add r6, r7
        rts

error:  mov r6, #0xEE   ;hibás eredmény esetén az EE jelzést adjuk
        rts

display: mov r10, r0    ;r0-ban van a lenyomott gomb értéke
         tst r10, #0x08 ;vizsgálom, hogy osztás volt-e
         jz  notdiv     ;ha nem osztás van, DIG1 pontja világít
         mov r8, #0x02  ;a DIG1 pontja világítson  
         jmp withdiv
notdiv:  mov r9, r6
         sub r9, #0xEE  ;ha hibajelzés volt, nem kell bcd konverzió
         jz  withdiv
         ;jsr bin2bcd
         mov r8, #0x00
withdiv: mov r7, SW     ;bemenetek beolvasása
         mov r10, r7    ;az r10-ben vizsgálom, hogy a bemenetek nagyobbak-e, mint 9
         and r10, #0x0F ;második bemenet (b)
         cmp r10, #0x0a
         jc notberr    ;ha nem >=10, akkor nincs hiba a b-vel
         mov r10, #0x0E
         and r7, #0xF0
         or  r7, r10
notberr: mov r9, r7
         and r9, #0xF0
         cmp r9, #0xA0
         jc notaerr
         mov r9, #0xE0
         and r7, #0x0F
         or  r7, r9
notaerr: mov r10, #sgtbl
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

bin2bcd: mov r7, #0x0A  ;10-zel osztok a bcd átalakításhoz
         jsr div        ;meghívom az osztást, r6 az osztandó, r7(10) az osztó
         mov r9, r6     ;r6 alsó 4 bitjén a maradék, felso 4 bitjén az egészrész
         swp r6         ;alulra kerül az egészrész
         and r6, #0x0F
         mov r7, #0x0A
         jsr div
         and r6, #0x0F
         swp r6
         or  r6, r9
         rts

DATA ; adatszegmens kijelölése
; A hétszegmenses dekóder szegmensképei (0-9, A-F) az adatmemóriában.
sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71         
         