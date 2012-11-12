;*******************************************************************************
; --- CORDIC TRIG LIBRARY ---
;
; FILE NAME:        trig.asm
; AUTHOR:           Patrick Fairbank
; LAST MODIFIED:    Jan. 16, 2008
;
; DESCRIPTION:      This file contains functions implementing the COORDIC
;                   algorithm.
;
; USAGE:            Add this file to your project.
;
; LICENSE:          Users are free to use, modify, and distribute this code
;                   as they see fit.
;******************************************************************************/

#include "P18F8722.inc"

    ; Import the address the compiler uses to store 32-bit return values
    EXTERN AARGB3


    UDATA_ACS

; Variable declarations
i       RES 1
j       RES 1
quad    RES 1
x       RES 2
y       RES 2
ang     RES 2
dy      RES 2
dx      RES 2


    IDATA

; Table of arctan values
atans   DW D'16384', D'9672', D'5110', D'2594', D'1302', D'652', D'326', D'163'
        DW D'81', D'41', D'20', D'10', D'5', D'3', D'1'


    CODE

; Calculates the sine and cosine of the given angle
sin_cos:

  ; Set up the stack
  movff FSR2L, POSTINC1
  movff FSR1L, FSR2L

  ; Initialize x to 18218
  movlw 0x2a
  movwf x
  movlw 0x47
  movwf x+1

  ; Initialize y to 0
  clrf y
  clrf y+1

  ; Initialize ang to passed parameter
  movlw 0xfd
  movff PLUSW2, ang
  movlw 0xfe
  movff PLUSW2, ang+1

  ; Initialize quad to 0
  clrf quad

  ; Check if the angle is greater than 16383 (90deg)
sc_check_greaterthan:
  btfss ang+1, 7
  btfss ang+1, 6
  bra sc_check_lessthan
  bra sc_adjust_quad2
  
  ; Check if the angle is less than -16384 (-90deg)
sc_check_lessthan:
  btfsc ang+1, 7
  btfsc ang+1, 6
  bra sc_setup_end

  ; If the angle is in quadrant 3, adjust it to quadrant 4
sc_adjust_quad3:
  negf ang
  bc sc_negate_quad3
  comf ang+1
  bra sc_adjust_end

  ; If the low byte negation causes a carry, negate the upper byte
sc_negate_quad3:
  negf ang+1
  bra sc_adjust_end

  ; If the angle is in quadrant 2, adjust it to quadrant 1
sc_adjust_quad2:
  comf ang
  comf ang+1

  ; Toggle the sign bit and set the 'quad' flag
sc_adjust_end:
  btg ang+1, 7
  setf quad

  ; Multiply the angle by 2 to get better resolution
sc_setup_end:
  bcf STATUS, 0
  rlcf ang
  rlcf ang+1

  ; Set up the main loop
sc_loop_start:
  clrf i
  banksel atans
  lfsr FSR0, atans

    ; The main loop label
sc_loop:
    movff x, dy
    movff x+1, dy+1
    movff i, j
    movf j
    bz sc_bs_x_done

      ; Loop to shift dy right
sc_bs_x_loop:
      bcf STATUS, 0
      rrcf dy+1
      rrcf dy
      btfsc x+1, 7
      bsf dy+1, 7
      decfsz j
      bra sc_bs_x_loop

    ; Calculate what needs to be added to x
sc_bs_x_done:
    movff y, dx
    movff y+1, dx+1
    movff i, j
    movf j
    bz sc_do_rotation

      ; Loop to shift dx right
sc_bs_y_loop:
      bcf STATUS, 0
      rrcf dx+1
      rrcf dx
      btfsc y+1, 7
      bsf dx+1, 7
      decfsz j
      bra sc_bs_y_loop

    ; Perform adding operations on x, y and ang
sc_do_rotation:
    btfss ang+1, 7
    bra sc_sub_angle

    ; If ang is negative
    movf POSTINC0, W
    addwf ang
    movf POSTINC0, W
    addwfc ang+1
    movf dx, W
    addwf x
    movf dx+1, W
    addwfc x+1
    movf dy, W
    subwf y
    movf dy+1, W
    subwfb y+1
    bra sc_loop_bottom

    ; If ang is positive
sc_sub_angle:
    movf POSTINC0, W
    subwf ang
    movf POSTINC0, W
    subwfb ang+1
    movf dx, W
    subwf x
    movf dx+1, W
    subwfb x+1
    movf dy, W
    addwf y
    movf dy+1, W
    addwfc y+1

    ; Increment the counter and exit the loop if done
sc_loop_bottom:
    incf i
    movlw 0x0f
    cpfseq i
    bra sc_loop

  ; Negate x if it was initially in quadrant 2 or 3
sc_finished:
  btfss quad, 7
  bra sc_output
  negf x
  bc sc_negate_x
  comf x+1
  bra sc_output

  ; If the low byte negation causes a carry, negate the upper byte
sc_negate_x:
  negf x+1

  ; Output the calculated x and y values
sc_output:
  movff y, AARGB3
  movff y+1, AARGB3+1
  movff x, AARGB3+2
  movff x+1, AARGB3+3

  ; Restore the stack to its previous state
  movf POSTDEC1
  movff INDF1, FSR2L

  return


; Calculates the magnitude and direction of the given ordered pair
atan2_sqrt:

  ; Set up the stack
  movff FSR2L, POSTINC1
  movff FSR1L, FSR2L

  ; Initialize x to passed parameter
  movlw 0xfb
  movff PLUSW2, x
  movlw 0xfc
  movff PLUSW2, x+1
;  movff POSTINC2, x
;  movff POSTDEC2, x+1

  ; Initialize y to passed parameter
  movlw 0xfd
  movff PLUSW2, y
  movlw 0xfe
  movff PLUSW2, y+1
;  movlw 0x03
;  movff PLUSW2, y+1
;  movlw 0x02
;  movff PLUSW2, y

  ; Initialize ang to 0
  clrf ang
  clrf ang+1

  ; Initialize quad to 0
  clrf quad

  ; If the point is in quadrant 2 or 3, make x positive and set flag
as_check_negative:
  btfss x+1, 7
  bra as_shift_x
  setf quad
  negf x
  bc as_negate_x
  comf x+1
  bra as_shift_x

  ; If the low byte negation causes a carry, negate the upper byte
as_negate_x:
  negf x+1

  ; Divide the x coordinate by 2 to prevent overflowing
as_shift_x:
  bcf STATUS, 0
  rrcf x+1
  rrcf x

  ; Divide the y coordinate by 2 to prevent overflowing
as_shift_y:
  bcf STATUS, 0
  rrcf y+1
  rrcf y
  btfsc y+1, 6
  bsf y+1, 7

  ; Set up the main loop
as_loop_start:
  clrf i
  banksel atans
  lfsr FSR0, atans

    ; The main loop label
as_loop:
    movff x, dy
    movff x+1, dy+1
    movff i, j
    movf j
    bz as_bs_x_done

      ; Loop to shift dy right
as_bs_x_loop:
      bcf STATUS, 0
      rrcf dy+1
      rrcf dy
      btfsc x+1, 7
      bsf dy+1, 7
      decfsz j
      bra as_bs_x_loop

    ; Calculate what needs to be added to x
as_bs_x_done:
    movff y, dx
    movff y+1, dx+1
    movff i, j
    movf j
    bz as_do_rotation

      ; Loop to shift dx right
as_bs_y_loop:
      bcf STATUS, 0
      rrcf dx+1
      rrcf dx
      btfsc y+1, 7
      bsf dx+1, 7
      decfsz j
      bra as_bs_y_loop

    ; Perform adding operations on x, y and ang, shifting the atans right one
as_do_rotation:
    movff POSTINC0, PRODL
    movff POSTINC0, PRODH
    bcf STATUS, 0
    rrcf PRODH
    rrcf PRODL
    btfsc  y+1, 7
    bra as_sub_angle

    ; If y is positive
    movf PRODL, W
    addwf ang
    movf PRODH, W
    addwfc ang+1
    movf dx, W
    addwf x
    movf dx+1, W
    addwfc x+1
    movf dy, W
    subwf y
    movf dy+1, W
    subwfb y+1
    bra as_loop_bottom

    ; If y is negative
as_sub_angle:
    movf PRODL, W
    subwf ang
    movf PRODH, W
    subwfb ang+1
    movf dx, W
    subwf x
    movf dx+1, W
    subwfb x+1
    movf dy, W
    addwf y
    movf dy+1, W
    addwfc y+1

    ; Increment the counter and exit the loop if done
as_loop_bottom:
    incf i
    movlw 0x0e
    cpfseq i
    bra as_loop

  ; Multiply the x value by 19898 and divide by 2^14 to scale it
as_scale_x:
  movff x, dx
  movff x+1, dx+1
  movlw 0xba
  mulwf dx
  movff PRODH, x
  movlw 0x4d
  mulwf dx+1
  movff PRODH, dy
  movff PRODL, x+1
  movlw 0xba
  mulwf dx+1
  movf PRODL, W
  addwf x, F
  movf PRODH, W
  addwfc x+1, F
  clrf WREG
  addwfc dy, F
  movlw 0x4d
  mulwf dx
  movf PRODL, W
  addwf x, F
  movf PRODH, W
  addwfc x+1, F
  clrf WREG
  addwfc dy, F
  movlw 0x06
  movwf j
as_scale_bs_loop:
    bcf STATUS, 0
    rrcf dy
    rrcf x+1
    rrcf x
    decfsz j
    bra as_scale_bs_loop

  ; Check if the quadrant was originally changed
as_check_quad:
  btfss quad, 7
  bra as_output
  btfss ang+1,7
  bra as_adjust_quad1

  ; If the angle is in quadrant 4, adjust it to quadrant 3
as_adjust_quad4:
  negf ang
  bc as_negate_quad4
  comf ang+1
  bra as_adjust_end

  ; If the low byte negation causes a carry, negate the upper byte
as_negate_quad4:
  negf ang+1
  bra as_adjust_end

  ; If the angle is in quadrant 1, adjust it to quadrant 2
as_adjust_quad1:
  comf ang
  comf ang+1

  ; Toggle the sign bit
as_adjust_end:
  btg ang+1, 7

  ; Output the calculated angle and hypotenuse values
as_output:
  movff ang, AARGB3
  movff ang+1, AARGB3+1
  movff x, AARGB3+2
  movff x+1, AARGB3+3

  ; Restore the stack to its previous state
  movf POSTDEC1
  movff INDF1, FSR2L

  return


    ; Export the functions to the linker
    GLOBAL sin_cos
    GLOBAL atan2_sqrt

    END
