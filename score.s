	EXPORT DrawScoreDIGIT
	EXPORT DRAWSCORE
	EXPORT SCORE_INIT
	EXPORT IncrementScore
	EXPORT COLOR_PINK
	EXPORT COLOR_CYAN
	EXPORT COLOR_RED
	EXPORT COLOR_YELLOW
	EXPORT COLOR_ORANGE
	EXPORT COLOR_GREEN
	EXPORT COLOR_BLACK
	EXPORT COLOR_WHITE
	EXPORT COLOR_BLUE
	IMPORT DrawRect
	EXPORT CLEAR_COLOR
	EXPORT SET_SCORE
	AREA MYDATA, DATA, READWRITE
SCOREX DCD 0
SCOREY DCD 0
SCORE DCD 0
COLOR DCD 0
BG DCD 0
	AREA MYCODE,CODE,READONLY

;COLOURS
BLACK EQU 0X0000
BLUE EQU 0x001F
WHITE EQU 0XFFFF
PINK EQU 0xc814
GREEN EQU 0x0780
CYAN EQU 0x05b9
RED	EQU 0xf800
YELLOW	EQU 0xffc0
ORANGE EQU	0xfc40
DELAY_INTERVAL  EQU     0x18604  

COLOR_BLUE
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #BLUE
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_PINK
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #PINK
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_CYAN
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #CYAN
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 	
COLOR_RED
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #RED
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_YELLOW
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #YELLOW
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_ORANGE
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #ORANGE
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_GREEN
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #GREEN
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_WHITE
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #WHITE
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC} 
COLOR_BLACK
	PUSH {R0-R1, LR}
	LDR R0, =COLOR
	MOV R1, #BLACK
	STR R1, [R0]
	BL DrawScoreDIGIT
	POP {R0-R1, PC}
SET_SCORE ; R0 = Score
	PUSH {R0-R1, LR}
	LDR R1, =SCORE
	STR R0, [R1]
	POP {R0-R1, PC}
SCORE_INIT ; R10 = BG, R11 = X, R12 = Y
	PUSH {R0-R12, LR}
	LDR R0, =SCORE
	MOV R1, #0
	STR R1, [R0]
	LDR R0, =SCOREX
	STR R11, [R0]
	LDR R0, =SCOREY
	STR R12, [R0]
	LDR R0, =BG
	STR R10, [R0]
	POP {R0-R12, PC}
CLEAR_COLOR
	PUSH {R0-R12, LR}
	LDR R10, =SCOREX
	LDR R6, [R10]
	LDR R10, =SCOREY
	LDR R7, [R10]
	ADD R8, R6, #70
	ADD R9, R7, #70
	LDR R10, =BG
	LDR R10, [R10]
	BL DrawRect
	POP {R0-R12, PC}
IncrementScore
	PUSH {R0-R1, LR}
	BL CLEAR_COLOR
	LDR R0, =SCORE
	LDR R1, [R0]
	ADD R1, R1, #1
	STR R1, [R0]
	POP {R0-R1, PC}
; Reads from SCORE in Memory
; R5 = number from 0 to 999
; R11= start coordinate x
;R12 = start coordinate y
DrawScoreDIGIT
    PUSH {R0-R12, LR}
	LDR R0, =COLOR
	LDR R10, [R0]
	LDR R0, =SCOREX
	LDR R0, [R0]
	LDR R1, =SCOREY
	LDR R1, [R1]

	LDR R9, =SCORE
	LDR R5, [R9]
    MOV R3, R5
    ; Split into hundreds, tens, units
    MOV R4, #100
    UDIV R6, R3, R4      ; R6 = hundreds
    MLS R3, R6, R4, R3   ; R3 = remainder

    MOV R4, #10
    UDIV R7, R3, R4      ; R7 = tens
    MLS R8, R7, R4, R3   ; R8 = units (R3 = remainder from above)

    ; Condition: if >= 100 ? draw 3 digits
    CMP R5, #100
    BGE DrawAllThree

    ; Condition: if >= 10 ? draw tens and units
    CMP R5, #10
    BGE DrawTwoDigits

    ; Otherwise ? draw only one digit
DrawOneDigit
    MOV R2, R8           ; Units only
    BL DrawDigit
    B EndDrawDigits

DrawTwoDigits
    MOV R2, R7           ; Tens
    BL DrawDigit
    ADD R0, R0, #25

    MOV R2, R8           ; Units
    BL DrawDigit
    B EndDrawDigits

DrawAllThree
    MOV R2, R6           ; Hundreds
    BL DrawDigit
    ADD R0, R0, #25

    MOV R2, R7           ; Tens
    BL DrawDigit
    ADD R0, R0, #25

    MOV R2, R8           ; Units
    BL DrawDigit

EndDrawDigits
    POP {R0-R12, PC}

	
; Draw a digit (0–9) at position (R0 = X, R1 = Y), R2 = digit (0–9), R10 = color
DrawDigit
	B SKIP_THIS_FOOL_LINE
	LTORG
SKIP_THIS_FOOL_LINE
    PUSH {R0-R12, LR}
	LDR R10, =COLOR
	LDR R10, [R10]
    ; Base coordinates in R11 (X), R12 (Y)
    MOV R11, R0
    MOV R12, R1
    CMP R2, #0
    BEQ.W Digit0
    CMP R2, #1
    BEQ.W Digit1
    CMP R2, #2
	BEQ Digit2
    CMP R2, #3
	BEQ.W Digit3
	CMP R2,#4
	BEQ.W Digit4
	CMP R2, #5
	BEQ.W Digit5
	CMP R2, #6
	BEQ.W Digit6
	CMP R2, #7
	BEQ.W Digit7
	CMP R2, #8
	BEQ.W Digit8
	CMP R2, #9
	BEQ.W Digit9

; Define each digit drawing below using Y = 190 to Y = 240 range
; You can adjust X padding and thickness if needed
Digit0
    ; Top
    ADD R6, R11, #0    ; X1
    ADD R8, R11, #20   ; X2
    ADD R7, R12, #0    ; Y1
    ADD R9, R12, #6    ; Y2
    BL DrawRect
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    B EndDigit

Digit1
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit2
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit3
	B SKIP_THIS_FOOL_LINE2
	LTORG
SKIP_THIS_FOOL_LINE2
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit4
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #0
    ADD R9, R12, #24
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #40
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    B EndDigit

Digit5
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit6
    ; Like 5, with bottom-left bar
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit7
	B SKIP_THIS_FOOL_LINE3
	LTORG
SKIP_THIS_FOOL_LINE3
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit8
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #24
    ADD R9, R12, #40
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit

Digit9
    ; Top
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #0
    ADD R9, R12, #6
    BL DrawRect
    ; Top-left
    ADD R6, R11, #0
    ADD R8, R11, #6
    ADD R7, R12, #6
    ADD R9, R12, #24
    BL DrawRect
    ; Top-right
    ADD R6, R11, #14
    ADD R8, R11, #20
    ADD R7, R12, #6
    ADD R9, R12, #40
    BL DrawRect
    ; Middle
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #18
    ADD R9, R12, #24
    BL DrawRect
    ; Bottom
    ADD R6, R11, #0
    ADD R8, R11, #20
    ADD R7, R12, #34
    ADD R9, R12, #40
    BL DrawRect
    B EndDigit
EndDigit
    POP {R0-R12, PC}

DRAWSCORE 
	B SKIP_THIS_FOOL_LINE4
	LTORG
SKIP_THIS_FOOL_LINE4
	PUSH{R0-R12,LR}
	LDR R10, =BLACK
	MOV R6, #0
	MOV R7, #0
	MOV R8, #480
	MOV R9, #320
	BL DrawRect
	;----------------- background done
	
	; Center calculation
	; Screen width = 480, text width ˜ 333 (435-102)
	; To center: start at (480-333)/2 = 73.5 ˜ 74
	; This means the leftmost point (Y character) should start at 74
	; And the rightmost point (E character end) should be at 74+333 = 407
	
	; Y character
	LDR R10, =WHITE
    MOV R6, #74      ; Left X (was 102, now 74)
    MOV R8, #84      ; Right X (was 112, now 84)
    MOV R7, #140      ; Top Y
    MOV R9, #156      ; Bottom Y
    BL DrawRect       ; Upper left diagonal

	LDR R10, =WHITE
    MOV R6, #94      ; Left X (was 122, now 94)
    MOV R8, #104      ; Right X (was 132, now 104)
    MOV R7, #140      ; Top Y
    MOV R9, #156      ; Bottom Y
    BL DrawRect       ; Upper right diagonal

	LDR R10, =WHITE
    MOV R6, #84      ; Left X (was 112, now 84)
    MOV R8, #94      ; Right X (was 122, now 94)
    MOV R7, #156      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Vertical stem

	; O character
	LDR R10, =WHITE
    MOV R6, #114      ; Left X (was 142, now 114) 
    MOV R8, #134      ; Right X (was 162, now 134)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #114      ; Left X (was 142, now 114)
    MOV R8, #119      ; Right X (was 147, now 119)
    MOV R7, #148      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #129      ; Left X (was 157, now 129)
    MOV R8, #134      ; Right X (was 162, now 134)
    MOV R7, #148      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Right vertical

	LDR R10, =WHITE
    MOV R6, #114      ; Left X (was 142, now 114)
    MOV R8, #134      ; Right X (was 162, now 134)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	; U character
	LDR R10, =WHITE
    MOV R6, #144      ; Left X (was 172, now 144)
    MOV R8, #154      ; Right X (was 182, now 154)
    MOV R7, #140      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #154      ; Left X (was 182, now 154)
    MOV R8, #174      ; Right X (was 202, now 174)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	LDR R10, =WHITE
    MOV R6, #174      ; Left X (was 202, now 174)
    MOV R8, #184      ; Right X (was 212, now 184)
    MOV R7, #140      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Right vertical

	; R character
	LDR R10, =WHITE
    MOV R6, #194      ; Left X (was 222, now 194)
    MOV R8, #204      ; Right X (was 232, now 204)
    MOV R7, #140      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #204      ; Left X (was 232, now 204)
    MOV R8, #214      ; Right X (was 242, now 214)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #214      ; Left X (was 242, now 214)
    MOV R8, #224      ; Right X (was 252, now 224)
    MOV R7, #148      ; Top Y
    MOV R9, #156      ; Bottom Y
    BL DrawRect       ; Upper right

	LDR R10, =WHITE
    MOV R6, #204      ; Left X (was 232, now 204)
    MOV R8, #214      ; Right X (was 242, now 214)
    MOV R7, #156      ; Top Y
    MOV R9, #164      ; Bottom Y
    BL DrawRect       ; Middle horizontal

	LDR R10, =WHITE
    MOV R6, #214      ; Left X (was 242, now 214)
    MOV R8, #224      ; Right X (was 252, now 224)
    MOV R7, #164      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Lower right diagonal
	
	; S character
	LDR R10, =WHITE
    MOV R6, #247      ; Left X (was 275, now 247)
    MOV R8, #267      ; Right X (was 295, now 267)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #247      ; Left X (was 275, now 247)
    MOV R8, #257      ; Right X (was 285, now 257)
    MOV R7, #148      ; Top Y
    MOV R9, #156      ; Bottom Y
    BL DrawRect       ; Upper-left vertical

	LDR R10, =WHITE
    MOV R6, #247      ; Left X (was 275, now 247)
    MOV R8, #267      ; Right X (was 295, now 267)
    MOV R7, #156      ; Top Y
    MOV R9, #164      ; Bottom Y
    BL DrawRect       ; Middle horizontal

	LDR R10, =WHITE
    MOV R6, #257      ; Left X (was 285, now 257)
    MOV R8, #267      ; Right X (was 295, now 267)
    MOV R7, #164      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Lower-right vertical

	LDR R10, =WHITE
    MOV R6, #247      ; Left X (was 275, now 247)
    MOV R8, #267      ; Right X (was 295, now 267)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	; C character
	LDR R10, =WHITE
    MOV R6, #277      ; Left X (was 305, now 277)
    MOV R8, #297      ; Right X (was 325, now 297)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #277      ; Left X (was 305, now 277)
    MOV R8, #287      ; Right X (was 315, now 287)
    MOV R7, #148      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #277      ; Left X (was 305, now 277)
    MOV R8, #297      ; Right X (was 325, now 297)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	; O character
	LDR R10, =WHITE
    MOV R6, #307      ; Left X (was 335, now 307)
    MOV R8, #327      ; Right X (was 355, now 327)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #307      ; Left X (was 335, now 307)
    MOV R8, #312      ; Right X (was 340, now 312)
    MOV R7, #148      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #322      ; Left X (was 350, now 322)
    MOV R8, #327      ; Right X (was 355, now 327)
    MOV R7, #148      ; Top Y
    MOV R9, #172      ; Bottom Y
    BL DrawRect       ; Right vertical

	LDR R10, =WHITE
	MOV R6, #307      ; Left X (was 335, now 307)
    MOV R8, #327      ; Right X (was 355, now 327)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	; R character
	LDR R10, =WHITE
    MOV R6, #337      ; Left X (was 365, now 337)
    MOV R8, #347      ; Right X (was 375, now 347)
    MOV R7, #140      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #347      ; Left X (was 375, now 347)
    MOV R8, #357      ; Right X (was 385, now 357)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #357      ; Left X (was 385, now 357)
    MOV R8, #367      ; Right X (was 395, now 367)
    MOV R7, #148      ; Top Y
    MOV R9, #156      ; Bottom Y
    BL DrawRect       ; Upper right

	LDR R10, =WHITE
    MOV R6, #347      ; Left X (was 375, now 347)
    MOV R8, #357      ; Right X (was 385, now 357)
    MOV R7, #156      ; Top Y
    MOV R9, #164      ; Bottom Y
    BL DrawRect       ; Middle horizontal

	LDR R10, =WHITE
    MOV R6, #357      ; Left X (was 385, now 357)
    MOV R8, #367      ; Right X (was 395, now 367)
    MOV R7, #164      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Lower right diagonal

	; E character
	LDR R10, =WHITE
    MOV R6, #377      ; Left X (was 405, now 377)
    MOV R8, #387      ; Right X (was 415, now 387)
    MOV R7, #140      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Left vertical

	LDR R10, =WHITE
    MOV R6, #387      ; Left X (was 415, now 387)
    MOV R8, #407      ; Right X (was 435, now 407)
    MOV R7, #140      ; Top Y
    MOV R9, #148      ; Bottom Y
    BL DrawRect       ; Top horizontal

	LDR R10, =WHITE
    MOV R6, #387      ; Left X (was 415, now 387)
    MOV R8, #397      ; Right X (was 425, now 397)
    MOV R7, #156      ; Top Y
    MOV R9, #164      ; Bottom Y
    BL DrawRect       ; Middle horizontal

	LDR R10, =WHITE
    MOV R6, #387      ; Left X (was 415, now 387)
    MOV R8, #407      ; Right X (was 435, now 407)
    MOV R7, #172      ; Top Y
    MOV R9, #180      ; Bottom Y
    BL DrawRect       ; Bottom horizontal

	POP{R0-R12,PC}