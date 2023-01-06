
; "Christmas tree goes to a party"
; 846 bytes intro by Frog for DIHALT'2023 Winter
;
; https://enlight.ru/roi
; frog@enlight.ru
;

                include "vectrex.i"

frames_c        	equ	$C880

tree_motion_counter        equ     $C882

sine_c            equ    $C884

sine            equ    $fc6d        ; sine table from BIOS 

;***************************************************************************
                org     0

                db      "g GCE 1982", $80 	; 'g' is copyright sign
                dw      $f600            	; music from the rom ($F600 - no music) 
                db      $FC, $30, 33, -$46	; height, width, rel y, rel x
title:          db      "HAPPY NEW YEAR!", $80	; app title, ending with $80
                db      0                 	; end of header

                jsr    $f92e
                
             

; copy curves/dots data to RAM (to make it changeable)

                lda    #16

                ldu    #dots    ; source
                ldx    #$C890    ; destination
                jsr    Move_Mem_a            ; A - byte count, U - source, X - destination





                clr    sine_c

                clr    frames_c
                ldd    #$8080                ; X0. Start beyond of screen
                std     tree_motion_counter  


mainloop:
    
                jsr     DP_to_C8
                ldu     #music6                ;  (#music6)  #$f600 - no music

                jsr     Init_Music_chk          ; Initialize the music

                jsr     Wait_Recal        	; recalibrate CRT, reset beam to 0,0.  D, X - trashed

                jsr     Do_Sound

                tst     Vec_Music_Flag          ; Loop if music is still playing
                bne     stillplaying
                inc     Vec_Music_Flag            ; restart music

                
stillplaying:

             
; intro title

                ldu    #title
                ldd    #(-127*256+(-54))    ; Y,X
                jsr    Print_Str_d

; draw floor
                lda     #$ff              	; scale (max possible)
                sta     <VIA_t1_cnt_lo

                ldd     #(-60*256+(-60)) 	; Y,X
                jsr     Moveto_d

                ldd     #(0*256+(127)) 		; Y,X
                jsr     Draw_Line_d






; ----------------- DRAW CURVES --------------------
                ldu    #curves                    ; curves parameters

nextcurve:
               
    





                jsr     Reset0Ref               ; recalibrate crt (x,y = 0)
                lda     #$CE                    ; /Blank low, /ZERO high
                sta     <VIA_cntl               ; enable beam, disable zeroing


                lda     #20   ; Y
                ldb    tree_motion_counter

                jsr     Moveto_d                ; start from this point

                jsr	Intensity_5F

        
; --------------------------------
; Draw_Curve begin
                jsr    init_curve


                ldb    #10                    ; display bright "star" dot on top of fir-tree
delay_star:     decb
                bne     delay_star



                
                incb
                stb     <VIA_port_b        	; MUX disable, ~RAMP enable. Start integration


nextchunk:
                ldd	,u++                    ; load delay from table (b - delay, a - x)
                beq    end_curve                ; delay=0,x=0 exits loop (end curve)

delay:          decb
                bne     delay
                
                sta     <VIA_port_a        ; put X to DAC

                bra    nextchunk        

end_curve:

                ldb     #$81              	; ramp off, MUX off
                stb     <VIA_port_b

                lda     #$98
                sta     <VIA_aux_cntl      	; restore usual AUX setting (enable PB7 timer, SHIFT mode 4)

; Draw_Curve end


; draw bright end dot

               
              
; end dots brightness control using sine table from bios
              ;  ldb     #30                    
                ldb    sine_c
                cmpb    #32
                bne    skip_reset_sine
                clr    sine_c
skip_reset_sine:
                clra
                addd    #sine 		; index to addr
; b - offset in sine

                tfr    d,y

                ldb    ,y    
                lsrb
                lsrb
               
               


repeat_dot:     decb
                bne     repeat_dot         ; (hold dot long enough)

                clr     <VIA_shift_reg  	; Blank beam in VIA shift register

             
                lda    ,u
                cmpa    #$ee                ; are all curves displayed?
                bne    nextcurve


                inc    frames_c
                inc    sine_c

                lda    #$1
                bita    frames_c
                bne    even
                dec    tree_motion_counter    ; move slowly (/2)
even:


skip_curve:

                jsr    draw_trunk


                jsr     Reset0Ref               ; recalibrate crt (x,y = 0)



; draw falling snow

                dec    $c891

  
; make snow moving left/right +/- 1
                ldb    #30        ;x

                lda    #$8
                bita    frames_c
                bne    even2
                ldb    #31        ;x
even2:

                lda    #20    ;y

                jsr    Moveto_d

          
                ldx   #$c890
                jsr    Dot_List_Reset



                jmp    mainloop





; ============= Trunk curve 
draw_trunk:

            

; ----------------------- LEFT trunk curve
               
                lda     #65   ; Y
                ldb     #-5    ; X
                jsr     Moveto_d                ; start from this point


                ldx    frames_c


                jsr    init_curve

                incb
                stb     <VIA_port_b        	; MUX disable, ~RAMP enable. Start integration

    
                ldd    #$0f28                ;ef19
delay2:         decb
                bpl     delay2
                
                sta     <VIA_port_a        ; put X to DAC


                tfr x,d                    ; x coord of foot
       
                sbca #40
                asla
                asla

        

                sta     <VIA_port_a        ; put X to DAC

                ldb    #4                        ; foot Y

       

       
            

delay4:         decb
                bpl     delay4

                ldb     #$81              	; ramp off, MUX off
                stb     <VIA_port_b

                lda     #$98
                sta     <VIA_aux_cntl      	; restore usual AUX setting (enable PB7 timer, SHIFT mode 4)


; draw bright end dot
                ldb     #30                     ; end dot brightness (hold dot long enough)


repeat_dot2b:   decb
                bne     repeat_dot2b

                clr     <VIA_shift_reg  	; Blank beam in VIA shift register


; ------------------------ RIGHT trunk curve

                jsr     Reset0Ref               ; recalibrate crt (x,y = 0)
               
                lda     #20   ; Y


                ldb    tree_motion_counter

                jsr     Moveto_d                ; start from this point



                jsr    init_curve

                incb
                stb     <VIA_port_b        	; MUX disable, ~RAMP enable. Start integration

 
                ldd    #$a927                ;#$0919 
delay2b:         decb
                bpl     delay2b
                
                sta     <VIA_port_a        ; put X to DAC


                tfr    x,d                    ; x coord of foot
    
    
                asla
                asla

                nop

                sta     <VIA_port_a        ; put X to DAC

                ldb    #4


     
               
      


delay4b:         decb
                bpl     delay4b

                ldb     #$81              	; ramp off, MUX off
                stb     <VIA_port_b

                lda     #$98
                sta     <VIA_aux_cntl      	; restore usual AUX setting (enable PB7 timer, SHIFT mode 4)



; draw bright end dot
                ldb     #30                     ; end dot brightness (hold dot long enough)

repeat_dot2:     decb
                bne     repeat_dot2

                clr     <VIA_shift_reg  	; Blank beam in VIA shift register



                rts

; 
init_curve:



; params: y - coeff. to make curves look different

                ldd     #$1881
                stb     <VIA_port_b        	; disable MUX, disable ~RAMP
                sta     <VIA_aux_cntl      	; AUX: shift mode 4. PB7 not timer controlled. PB7 is ~RAMP



                lda     #-80              	; Y -120 "scale"?
                sta     <VIA_port_a        	; Y to DAC

                decb                      	; b now $80              ??
                stb     <VIA_port_b        	; enable MUX             ??

                clrb
                inc     <VIA_port_b        	; MUX off, only X on DAC now
                stb     <VIA_port_a        	; X to DAC


                lda     #$ff
                sta     <VIA_shift_reg     	; pattern (enable first to display top "star" dot)




                rts


; snow  { mode, y, x }
dots:
                db    0,0,-60
                db    0,-20,25
                db    0,30,10
                db    0,30,30

                db    0,50,-10

                db    1            ; end of dots list

                

;
; [ {deviation_x,count}, ... ,{0,0}, ...$ee ]
; 0,0 - end of curve, $ee - end of sequence
curves:

; branches


;-----
                db    -1  ,1
                db    -126  ,1
                db   0,0

                db    1  ,1
                db    126  ,1
                db   0,0
;-----
                db    -80  ,3
                db   0,0

                db    80  ,3
                db   0,0

;-----
                db    -90  ,2
                db   0,0

                db    90  ,2
                db   0,0

;-----
                db    -120  ,7
                db   0,0

                db    120  ,7
                db   0,0
;-----
                db    -1  ,1
                db    -50  ,1
                db    -126  ,1
                db   0,0

                db    1  ,1
                db    50  ,1
                db    126  ,1
                db   0,0

;-----
                db    -126  ,10
                db   0,0

                db    126  ,10
                db   0,0
;-----
                db    -1  ,1
                db    -10  ,1
                db    -40  ,1
                db    -80  ,1
                db    -126  ,1
                db   0,0

                db    1  ,1
                db    10  ,1
                db    40  ,1
                db    80  ,1
                db    126  ,1
                db   0,0

;-----
                db    -20  ,2
                db    -126  ,10
                db   0,0

                db    20  ,2
                db    126  ,10
                db   0,0
;-----
                db    -1  ,1
                db    -10  ,1
                db    -80  ,1
                db    -126  ,1
                db   0,0

                db    1  ,1
                db    10  ,1
                db    80  ,1
                db    126  ,1
                db   0,0
;-----
                db    -20  ,2
                db    -126  ,14
                db   0,0

                db    20  ,2
                db    126  ,14
                db   0,0

;-----
                db    -20  ,1
                db    -20  ,1
                db    -30  ,1
                db    -40  ,1
                db    -126  ,4
                db   0,0

                db    20  ,1
                db    20  ,1
                db    30  ,1
                db    40  ,1
                db    126  ,4
                db   0,0

;-----
                db    -1  ,2
                db    -10  ,1
                db    -20  ,1
                db    -50  ,1
                db    -80  ,1
                db    -126  ,1
                db   0,0

                db    1  ,2
                db    10  ,1
                db    20  ,1
                db    50  ,1
                db    80  ,1
                db    126  ,1
                db   0,0

;-----
                db    -20  ,2
                db    -20  ,1
                db    -126  ,14
                db   0,0

                db    20  ,2
                db    20  ,1
                db    126  ,14
                db   0,0

;----- /_ _\

                db    -1  ,2
                db    -10  ,2
                db    -20  ,2
                db    -50  ,2
                db    -70  ,2
                db    -90  ,1
                db    -110  ,1
                db    126  ,1
                db   0,0

                db    1  ,2
                db    10  ,2
                db    20  ,2
                db    50  ,2
                db    70  ,2
                db    90  ,1
                db    110  ,1
                db    -126  ,1
                db   0,0

;-----
                db    -20  ,3
                db    -25  ,6
                db    -126  ,14
                db   0,0

                db    20  ,3
                db    25  ,6
                db    126  ,14
                db   0,0
;-----
                db    -27  ,1
                db    -35  ,1
                db    -126  ,20
                db   0,0

                db    27  ,1
                db    35  ,1
                db    126  ,20
                db   0,0
;-----
                db    -27  ,1
                db    -35  ,2
                db    -126  ,24
                db   0,0

                db    27  ,1
                db    35  ,2
                db    126  ,24
                db   0,0


;-----
                db    -1  ,3
                db    -10  ,3
                db    -20  ,3
                db    -50  ,3
                db    -70  ,2
                db    -90  ,1
                db    126  ,1
                db   0,0

                db    1  ,3
                db    10  ,3
                db    20  ,3
                db    50  ,3
                db    70  ,2
                db    90  ,1
                db    -126  ,1
                db   0,0

;-----
                db    -27  ,5
                db    -25  ,8
                db    -126  ,14
                db   0,0

                db    27  ,5
                db    25  ,8
                db    126  ,14
                db   0,0

;-----
                db    -27  ,5
                db    -35  ,2
                db    -126  ,24
                db   0,0

                db    27  ,5
                db    35  ,2
                db    126  ,24
                db   0,0

;-----

                db    -1  ,4
                db    -10  ,4
                db    -20  ,4
                db    -50  ,5
                db    -70  ,1
                db    126  ,1
                db   0,0

                db    1  ,4
                db    10  ,4
                db    20  ,4
                db    50  ,5
                db    70  ,1
                db    -126  ,1
                db   0,0

;-----
                db    -25  ,5
                db    -23  ,5
                db    -20  ,3
                db    -30  ,1
                db    -126  ,10
                db   0,0

                db    25  ,5
                db    23  ,5
                db    20  ,3
                db    30  ,1
                db    126  ,10
                db   0,0

;-----
                db    -1  ,5
                db    -10  ,5
                db    -20  ,5
                db    -40  ,6
                db   0,0

                db    1  ,5
                db    10  ,5
                db    20  ,5
                db    40  ,6
                db   0,0

;-----
                db    -1  ,5
                db    -20  ,5
                db    -35  ,5
                db    -50  ,8
                db   0,0

                db    1  ,5
                db    20  ,5
                db    35  ,5
                db    50  ,8
                db   0,0

;-----
                db    -1  ,5
                db    -10  ,5
                db    -10  ,6
                db    -20  ,7
                db   0,0

                db    1  ,5
                db    10  ,5
                db    10  ,6
                db    20  ,7
                db   0,0

;-----

                db    $ee    ; no more curves
                db    $ee    ; no more curves
                db    $ee    ; no more curves




