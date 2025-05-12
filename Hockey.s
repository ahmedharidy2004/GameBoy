; Pin Co
;   +--------- TFT ---------+
;   |      D0   =  PA0      |
;   |      D1   =  PA1      |
;   |      D2   =  PA2      |
;   |      D3   =  PA3      |
;   |      D4   =  PA4      |
;   |      D5   =  PA5      |
;   |      D6   =  PA6      |
;   |      D7   =  PA7      |
;   |-----------------------|
;   |      RST  =  PA8      |
;   |      BCK  =  PA9      |
;   |      RD   =  PA10     |
;   |      WR   =  PA11     |
;   |      RS   =  PA12     |
;   |      CS   =  PA15     |
;   +-----------------------+
;IMPORT killua
	EXPORT HOCKEY
	IMPORT GPIO_INIT
	IMPORT GPIOX_ONEREAD
	IMPORT GPIOX_READ
	IMPORT GPIOX_SETHIGH
	IMPORT GPIOX_SETLOW
	IMPORT TFT_Init
	IMPORT TFT_WriteCommand
	IMPORT TFT_WriteData
	IMPORT TFT_FillScreen
	IMPORT Draw_Ball
	IMPORT DrawRect
	IMPORT TFT_ImageLoop
	IMPORT delay
	IMPORT ONEWIN
	IMPORT TWOWIN
	IMPORT DrawScoreDIGIT
	IMPORT DRAWSCORE
	IMPORT SCORE_INIT
	IMPORT IncrementScore
	IMPORT COLOR_WHITE
	IMPORT COLOR_BLACK
	IMPORT COLOR_BLUE
	IMPORT COLOR_RED
	IMPORT CLEAR_COLOR
	IMPORT SET_SCORE
	IMPORT Get_Random_Seed
	IMPORT DIV
	AREA MYDATA, DATA, READWRITE

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
; Constants for Movements

; Define register base addresses
RCC_BASE        EQU     0x40023800
GPIOA_BASE      EQU     0x40020000
GPIOB_BASE		EQU		0x40020400
GPIOC_BASE		EQU		0x40020800
GPIOD_BASE		EQU		0x40020C00
GPIOE_BASE		EQU		0x40021000

; Define register offsets
RCC_AHB1ENR     EQU     0x30
GPIO_MODER      EQU     0x00
GPIO_OTYPER     EQU     0x04
GPIO_OSPEEDR    EQU     0x08
GPIO_PUPDR      EQU     0x0C
GPIO_IDR        EQU     0x10
GPIO_ODR        EQU     0x14

; Control Pins on Port E
TFT_RST         EQU     (1 << 8)
TFT_RD          EQU     (1 << 10)
TFT_WR          EQU     (1 << 11)
TFT_DC          EQU     (1 << 12)
TFT_CS          EQU     (1 << 15)


; Variables of the Game
BAR1 DCD 0x00F00118 ; Coordinates of Bar1 (Down) Y = 280
BAR1_STATE DCD 0 ; State of Bar1 (0 IDLE - 1 RIGHT - 2 LEFT) 
BAR2 DCD 0x00F00028 ; Coordinates of Bar2 (Up) Y = 40
BAR2_STATE DCD 0 ; State of Bar2 (0 IDLE - 1 RIGHT - 2 LEFT)
BAR_SPEED EQU 2 ; Bar Speed = 2px
BALL DCD 0x00F000A0 ; Center of Ball 0xXXXXYYYY
BALL_STATE DCD 0 ; Ball State (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
BALL_SPEED EQU 2 ; Ball Speed = 2px
GOAL EQU 240 ; Center of Goal of Width 60px (210 - 270)
SCORE1 DCD 0 ; Score of Player1 (Increments with Each Goal)
SCORE2 DCD 0 ; Score of Player1 (Increments with Each Goal)
SCOREX EQU 390
SCORE1Y EQU 200
SCORE2Y EQU 120
BORDER EQU 15 ; 15px Border
BAR_LEFT_LIMIT EQU 30 ; Border + Width / 2
BAR_RIGHT_LIMIT EQU 415
DELAY_INTERVAL  EQU     0x18604  

	AREA RESET, CODE, READONLY

; Functions for 2 Players Score
DrawScore1
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCOREX
	MOV R12, #SCORE1Y
	BL SCORE_INIT
	LDR R0, =SCORE1
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_BLUE
	POP {R0-R12, PC}
DrawScore2
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCOREX
	MOV R12, #SCORE2Y
	BL SCORE_INIT
	LDR R0, =SCORE2
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_RED
	POP {R0-R12, PC}
IncrementScore1
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCOREX
	MOV R12, #SCORE1Y
	BL SCORE_INIT
	LDR R1, =SCORE1
	LDR R0, [R1]
	ADD R0, R0, #1
	STR R0, [R1]
	BL SET_SCORE
	BL CLEAR_COLOR
	BL COLOR_BLUE
	BL RESET_GAME
	POP {R0-R12, PC}
IncrementScore2
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCOREX
	MOV R12, #SCORE2Y
	BL SCORE_INIT
	LDR R1, =SCORE2
	LDR R0, [R1]
	ADD R0, R0, #1
	STR R0, [R1]
	BL SET_SCORE
	BL CLEAR_COLOR
	BL COLOR_RED
	BL RESET_GAME
	POP {R0-R12, PC}
RemoveBall
	PUSH {R0-R12, LR}
	LDR R0, =BALL
	LDR R1, [R0]
	LSR R2, R1, #16
	MOV R3, #0x0000FFFF
	AND R3, R3, R1
	MOV R10, #BLACK
	BL Draw_Ball
	POP {R0-R12, PC}	
RESET_GAME
	PUSH {R0-R12, LR}
	; Initialize BAR1 & BAR2 & Their States	
	LDR R0, =BAR1_STATE
	MOV R1, #0x00 ; Initially Idle
	STR R1, [R0]	
	LDR R0, =BAR2_STATE
	MOV R1, #0x00 ; Coordinates of Bar1 (Down) Y = 280
	STR R1, [R0]
	BL UPDATE_BARS ; To Remove Old Bars
	LDR R0, =BAR1
	LDR R1, =0x00DC0113 ; Coordinates of Bar1 (Down) Y = 280
	STR R1, [R0]
	LDR R0, =BAR2
	LDR R1, =0x00DC0023 ; Coordinates of Bar2 (Up) Y = 40
	STR R1, [R0]

	; Initialize Ball & Ball State
	BL RemoveBall
	
	LDR R0, =BALL
	LDR R1, =0x00F000A0 ; Center of Ball 0xXXXXYYYY
	STR R1, [R0]
	BL Get_Random_Seed ; R0 = Random Value
	MOV R1, #6 ; Number of States
	BL DIV ; R0 has random value now 0 - 5
	MOV R1, R0
	LDR R0, =BALL_STATE
	STR R1, [R0]
	; Draw Borders and Goals
	BL DrawBorders
	BL DrawGoals	
	; Draw Scores
	BL DrawScore1
	BL DrawScore2
	POP {R0-R12, PC}
GAME_INIT
	PUSH {R0-R12, LR}
	BL TFT_FillScreen
	; Initialize Score
	LDR R0, =SCORE1
	MOV R1, #0
	STR R1, [R0]
	LDR R0, =SCORE2
	STR R1, [R0]	
	; RESET HOCKEY
	BL RESET_GAME
	POP {R0-R12, PC}
DrawBars
	PUSH {R0-R12, LR}
	; Draw Player 1
	LDR R0, =BAR1
	LDR R1, [R0] ; R1 = 0xXXXXYYYY
	LDR R0, =BAR1_STATE
	LDR R2, [R0] ; R2 = State
	LSR R6, R1, #16 ; R6 = 0x0000XXXX
	CMP R2, #1
	ADD R6, R6, #BAR_SPEED
	CMP R2, #2
	SUB R6, R6, #BAR_SPEED
	ADD	R8, R6, #40 ; Width of Bar = 40px
	MOV R5, #0x0000FFFF ; Temp Variable
	AND R7, R1, R5 ; R7 = 0x0000YYYY
	ADD R9, R7, #10 ; Height of Bar = 10px
	MOV R10, #BLUE
	BL DrawRect
	; Draw Player 2
	LDR R0, =BAR2
	LDR R1, [R0] ; R1 = 0xXXXXYYYY
	LDR R0, =BAR2_STATE
	LDR R2, [R0] ; R2 = State
	LSR R6, R1, #16 ; R6 = 0x0000XXXX
	CMP R2, #1
	ADD R6, R6, #BAR_SPEED
	CMP R2, #2
	SUB R6, R6, #BAR_SPEED
	ADD	R8, R6, #40 ; Width of Bar = 40px
	MOV R5, #0x0000FFFF ; Temp Variable
	AND R7, R1, R5 ; R7 = 0x0000YYYY
	ADD R9, R7, #10 ; Height of Bar = 10px
	MOV R10, #RED
	BL DrawRect
	POP {R0-R12, PC}
HOCKEY
	PUSH{R0-R12, LR}	
	BL GAME_INIT
	B SKIP_THIS_FOOL_LINE
	LTORG
SKIP_THIS_FOOL_LINE
;MAIN GAME LOOP
GAMELOOP
	; Draw Score
	BL CHECK_WIN
	BL DrawScore1
	BL DrawScore2
	BL UPDATE_BARS_STATES
	BL DrawBars	
	BL CheckGoalsCollision
	BL CheckWallsCollision
	BL CheckBarsCollision
	BL DRAW_NEW_BALL
	B GAMELOOP

	POP{R0-R12, PC}

CHECK_WIN
	PUSH {R0-R12, LR}
	LDR R0, =SCORE1
	LDR R1, [R0]
	LDR R0, =SCORE2
	LDR R2, [R0]
	CMP R1, #7
	BLEQ ONEWIN ; Should Be WIN1
	BEQ CHECK_WIN
	CMP R2, #7
	BLEQ TWOWIN ; Should Be WIN2
	BEQ CHECK_WIN
	POP {R0-R12, PC}

;DRAW WHITE BORDERS OF BORDERL * BORDERW
DrawBorders
    PUSH{R0-R12, LR}
    ;left Border
    MOV R6, #0       ;X1
    MOV R7, #0       ;Y1
    MOV R8, #BORDER         ;X2
    MOV R9, #157     ;Y2
    MOV R10, #RED    ;COLOUR
    BL DrawRect

    MOV R6, #0       ;X1
    MOV R7, #163       ;Y1
    MOV R8,    #BORDER         ;X2
    MOV R9, #320     ;Y2
    MOV R10, #BLUE    ;COLOUR
    BL DrawRect
    ;Top Border
    MOV R6, #0       ;X1
    MOV R7, #0       ;Y1
    MOV R8,    #GOAL - 30    ;X2
    MOV R9, #BORDER      ;Y2
    MOV R10, #RED    ;COLOUR
    BL DrawRect
    MOV R6, #GOAL + 30       ;X1
    MOV R7, #0       ;Y1
    MOV R8,    #480    ;X2
    MOV R9, #BORDER      ;Y2
    MOV R10, #RED    ;COLOUR
    BL DrawRect
    ;Right Borders
    MOV R6, #480 - BORDER       ;X1
    MOV R7, #0       ;Y1
    MOV R8,    #480    ;X2
    MOV R9, #157     ;Y2
    MOV R10, #RED    ;COLOUR
    BL DrawRect

    MOV R6, #480 - BORDER       ;X1
    MOV R7, #163      ;Y1
    MOV R8,    #480    ;X2
    MOV R9, #320     ;Y2
    MOV R10, #BLUE    ;COLOUR
    BL DrawRect
    ;Bottom Border
    MOV R6, #0       ;X1
    MOV R7, #320 - BORDER       ;Y1
    MOV R8,    #GOAL - 30    ;X2
    MOV R9, #320      ;Y2
    MOV R10, #BLUE    ;COLOUR
    BL DrawRect

    MOV R6, #GOAL + 30       ;X1
    MOV R7, #320 - BORDER       ;Y1
    MOV R8,    #480    ;X2
    MOV R9, #320      ;Y2
    MOV R10, #BLUE    ;COLOUR
    BL DrawRect
    POP{R0-R12, PC}
	
DrawGoals
	PUSH{R0-R12, LR}
	; Top Goal
	MOV R6, #GOAL - 30   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#GOAL + 30 	    ;X2
	MOV R9, #BORDER 	;Y2
	MOV R10, #BLACK ;COLOUR
	BL	DrawRect
	; Bottom Goal
	MOV R6, #GOAL - 30   	;X1
	MOV R7, #320 - BORDER   	;Y1
	MOV R8,	#GOAL + 30	;X2
	MOV R9, #320      ;Y2
	MOV R10, #BLACK	;COLOUR
	BL	DrawRect
	POP{R0-R12, PC}
DRAW_NEW_BALL
	PUSH{R0-R12,LR}
	B SKIP_THIS_FOOL_LINE2
	LTORG
SKIP_THIS_FOOL_LINE2
	; Get Data from Memory in Predefined Registers
	LDR R0, =BALL
	LDR R1, [R0]
	LSR R2, R1, #16
	MOV R5, #0x0000FFFF ; Temp Variable
	AND R3, R1, R5
	LDR R0, =BALL_STATE
	LDR R4, [R0]
	
	;Remove old ball
	MOV R10, #BLACK
	BL Draw_Ball
	MOV R10, #WHITE

	CMP R4, #0
	BNE	SKIP_DRAW_U
	SUB R3, R3, #BALL_SPEED	;Y
	BL Draw_Ball

SKIP_DRAW_U
	CMP R4, #1
	BNE	SKIP_DRAW_UL
	SUB R2, R2, #BALL_SPEED		;X
	SUB R3, R3, #BALL_SPEED		;Y
	BL Draw_Ball

SKIP_DRAW_UL
	CMP R4, #2
	BNE	SKIP_DRAW_UR
	ADD R2, R2, #BALL_SPEED
	SUB R3, R3, #BALL_SPEED
	BL Draw_Ball

SKIP_DRAW_UR
	CMP R4, #3
	BNE	SKIP_DRAW_D
	ADD R3, R3, #BALL_SPEED
	BL Draw_Ball

SKIP_DRAW_D
	CMP R4, #4
	BNE	SKIP_DRAW_DL
	SUB R2, R2, #BALL_SPEED
	ADD R3, R3, #BALL_SPEED
	BL Draw_Ball

SKIP_DRAW_DL
	CMP R4, #5
	BNE SKIP_DRAW_DR
	ADD R2, R2, #BALL_SPEED
	ADD R3, R3, #BALL_SPEED
	BL Draw_Ball
SKIP_DRAW_DR
	; Store Data In Memory from PreDefined Registers
	LSL R2, R2, #16 ; R2 = 0xXXXX0000
	MOV R4, #0x0000FFFF ; Temp Variable
	AND R3, R3, R4 ; R3 = 0x0000YYYY
	ORR R1, R3, R2 ; R1 = 0xXXXXYYYY
	LDR R5, =BALL
	STR R1, [R5]
	POP{R0-R12,PC}

UPDATE_BARS
	PUSH {R0-R12, LR}
	; Bar1
	LDR R0, =BAR1
	LDR R1, [R0]
	LSR R2, R1, #16 ; X
	MOV R3, #0x0000FFFF
	AND R3, R3, R1 ; Y
	LDR R0, =BAR1_STATE
	LDR R4, [R0]
	; Remove Old Bar
	MOV R6, R2
	ADD R8, R6, #40
	MOV R7, R3
	ADD R9, R7, #10
	MOV R10, #BLACK
	BL DrawRect
	; Update Bar 1
	CMP R4, #1
	ADDEQ R2, R2, #BAR_SPEED
	CMP R4, #2
	SUBEQ R2, R2, #BAR_SPEED
	LSL R2, R2, #16
	ORR R1, R2, R3
	LDR R0, =BAR1
	STR R1, [R0]
	; Bar2
	LDR R0, =BAR2
	LDR R1, [R0]
	LSR R2, R1, #16 ; X
	MOV R3, #0x0000FFFF
	AND R3, R3, R1 ; Y
	LDR R0, =BAR2_STATE
	LDR R4, [R0]
	; Remove Old Bar
	MOV R6, R2
	ADD R8, R6, #40
	MOV R7, R3
	ADD R9, R7, #10
	MOV R10, #BLACK
	BL DrawRect
	; Update Bar 2
	CMP R4, #1
	ADDEQ R2, R2, #BAR_SPEED
	CMP R4, #2
	SUBEQ R2, R2, #BAR_SPEED
	LSL R2, R2, #16
	ORR R1, R2, R3
	LDR R0, =BAR2
	STR R1, [R0]
	POP {R0-R12, PC}

UPDATE_BARS_STATES
	PUSH {R0-R12,LR}
	MOV R11, #0 ; To Be 1 on Any Click
	LDR R0, =BAR1
	LDR R1, [R0]
	LSR R1, R1, #16 ; R1 = Bar X
	; Pull Up Resistor Be 0 on Click
	LDR R0, =GPIOB_BASE + GPIO_IDR
	LDR R2, [R0]
	; PB12 BAR1 Right
	; PB13 BAR1 Left
	; PB14 BAR2 Right
	; PB15 BAR2 Left
	MOV R3, #0 ; Assume Idle State at first
	TST R2, #(1 << 12)        ; Test bit 12
	MOVEQ R11, #1
	BEQ move_bar_right1

	TST R2, #(1 << 13)        ; Test bit 13
	MOVEQ R11, #1
	BEQ move_bar_left1	
	
	B update_bar_done1
move_bar_left1
	CMP R1, #BAR_LEFT_LIMIT
	MOVGT R3, #2
	B update_bar_done1

move_bar_right1
	MOV R2, #BAR_RIGHT_LIMIT
	CMP R1, R2
	MOVLT R3, #1

update_bar_done1
	LDR R0, =BAR1_STATE
	STR R3, [R0]
	; Now Update Bar 2
	LDR R0, =BAR2
	LDR R1, [R0]
	LSR R1, R1, #16 ; R1 = Bar X
	; Pull Up Resistor Be 0 on Click
	LDR R0, =GPIOB_BASE + GPIO_IDR
	LDR R2, [R0]
	; PB12 BAR1 Right
	; PB13 BAR1 Left
	; PB14 BAR2 Right
	; PB15 BAR2 Left
	MOV R3, #0 ; Assume Idle State at first
	TST R2, #(1 << 14)        ; Test bit 14
	MOVEQ R11, #1
	BEQ move_bar_right
	TST R2, #(1 << 15)        ; Test bit 15
	MOVEQ R11, #1
	BEQ move_bar_left

	B update_bar_done
move_bar_left
	CMP R1, #BAR_LEFT_LIMIT
	MOVGT R3, #2
	B update_bar_done

move_bar_right
	MOV R2, #BAR_RIGHT_LIMIT
	CMP R1, R2
	MOVLT R3, #1

update_bar_done
	LDR R0, =BAR2_STATE
	STR R3, [R0]
	CMP R11, #1
	BLEQ UPDATE_BARS
	POP {R0-R12,PC}

ReverseHorizontal ; R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
	PUSH {R0-R12, LR} 
	LDR R2, =BALL_STATE
	LDR R4, [R2]
	CMP R4, #1
	MOVEQ R4, #2
	BEQ ReverseHorizontalContinue
	CMP R4, #2
	MOVEQ R4, #1
	BEQ ReverseHorizontalContinue
	CMP R4, #4
	MOVEQ R4, #5
	BEQ ReverseHorizontalContinue
	CMP R4, #5
	MOVEQ R4, #4
ReverseHorizontalContinue
	LDR R2, =BALL_STATE
	STR R4, [R2]
	POP {R0-R12, PC}
ReverseVertical ; R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
	PUSH {R0-R12, LR} 
	LDR R2, =BALL_STATE
	LDR R4, [R2]
	ADD R0, R4, #3
	MOV R1, #6
	BL DIV
	MOV R4, R0 ; R4 = (R4 + 3) % 6
	LDR R2, =BALL_STATE
	STR R4, [R2]
	POP {R0-R12, PC}
ReverseDiagonal ; R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR) R7 for Hit (0 Hit for Right of Bar, 1 Hit from Left of Bar)
	PUSH {R0-R12, LR} 
	LDR R2, =BALL_STATE
	LDR R4, [R2]
	; If was Falling Diagonally Then Just Reverse Vertically
	CMP R4, #4
	MOVEQ R4, #1
	BEQ ReverseDiagonalContinue
	CMP R4, #1
	MOVEQ R4, #4
	BEQ ReverseDiagonalContinue
	CMP R4, #5
	MOVEQ R4, #2
	BEQ ReverseDiagonalContinue
	CMP R4, #2
	MOVEQ R4, #5
	BEQ ReverseDiagonalContinue
	; If was Falling Vertically Then Reverse Diagonally
	BL ReverseVertical
	LDR R0, =BALL_STATE
	LDR R4, [R0]
	CMP R7, #0
	ADDEQ R4, R4, #2
	CMP R7, #1
	ADDEQ R4, R4, #1
ReverseDiagonalContinue
	LDR R2, =BALL_STATE
	STR R4, [R2]
	POP {R0-R12, PC}

CheckGoalsCollision
	PUSH {R0-R12, LR} 
	B SKIP_THIS_FOOL_LINE3
	LTORG
SKIP_THIS_FOOL_LINE3
	; Store Data In Memory from PreDefined Registers
	LDR R0, =BALL
	LDR R0, [R0]
	LSR R2, R0, #16 ; R2 = X
	MOV R5, #0x0000FFFF ; Temp Variable
	AND R3, R0, R5 ; R3 = Y
	; Check for Top Goal
	CMP R3, #25
	BGT CheckGoalsCollisionContinue1
	MOV R5, #GOAL
	CMP R2, R5
	SUBGE R5, R2, R5
	SUBLT R5, R5, R2
	CMP R5, #30
	BGE CheckGoalsCollisionContinue1
	BL IncrementScore1
	B CheckGoalsCollisionContinue
CheckGoalsCollisionContinue1
	; Check for Bottom Goal
	MOV R5, #320
	SUB R5, R5, R3
	CMP R5, #25
	BGT CheckGoalsCollisionContinue
	MOV R5, #GOAL
	CMP R2, R5
	SUBGE R5, R2, R5
	SUBLT R5, R5, R2
	CMP R5, #30
	BGE CheckGoalsCollisionContinue
	BL IncrementScore2
CheckGoalsCollisionContinue
	POP {R0-R12, PC}

CheckWallsCollision
	PUSH {R0-R12, LR} 
	; Store Data In Memory from PreDefined Registers
	LDR R0, =BALL
	LDR R0, [R0]
	LSR R2, R0, #16 ; R2 = X
	MOV R5, #0x0000FFFF ; Temp Variable
	AND R3, R0, R5 ; R3 = Y
	; Check for Horizontal Walls
	CMP R2, #25 ; Padding + Ball Radius
	BLLE ReverseHorizontal ; If difference between center of ball and the sum of its radius and padding is less than the sum then a collision happened
	MOV R0, #480
	SUBS R5, R0, R2
	CMP R5, #25
	BLLE ReverseHorizontal
	; Check for Vertical Walls
	CMP R3, #25
	BLLE ReverseVertical ; If difference between center of ball and the sum of its radius and padding is less than the sum then a collision happened
	MOV R0, #320
	SUBS R5, R0, R3
	CMP R5, #25
	BLLE ReverseVertical
	; Store Data In Memory from PreDefined Registers
	POP {R0-R12, PC}
CheckBarsCollision
	PUSH {R0-R12, LR} 
	; Store Data In Memory from PreDefined Registers
	; Check Collision with Bar1
	LDR R5, =BAR1
	LDR R5, [R5]      ; Load BAR1 value
	LSR R0, R5, #16   ; R0= BAR X

	LDR R5, =BALL
	LDR R5,[R5]
	LSR R2, R5, #16 ; R2 = Ball X
	MOV R4, #0x0000FFFF ; Temp Variable
	AND R3, R5, R4 ; R3 = Ball Y
	LDR R5, =BALL_STATE
	LDR R4, [R5] ; R4 = BALL_STATE
	LDR R5, =BAR1
	LDR R5, [R5]
	MOV R6, #0x0000FFFF ; Temp Variable
	AND R5, R5, R6 ; R5 = BAR Y
	; Center of Bar is X = R0, Y = R5 + 5 , Assume Bar width is 40px
	ADD R0, R0, #20 ; Make R0 is Center of Bar (X)
	ADD R5, R5, #5 ; Y of Bar Center
	SUB R6, R5, R3
	CMP R6, #0
	BLT CheckBarCollisionContinue ; Ball is Below Bottom Bar
	CMP R6, #15 ; +5 px above center of bar and 10px radius of ball
	BGT CheckBarCollisionContinue1
	CMP R2, R0
	SUBGE R6, R2, R0
	MOVGE R7, #0 ; If Ball at Right of Bar
	SUBLT R6, R0, R2
	MOVLT R7, #1 ; If Ball at Left of Bar
	CMP R6, #5
	MOVLE R4, #0 ; Set Direction to UP if Centers Touched Directly
	LDR R5, =BALL_STATE
	STRLE R4, [R5]
	BLE CheckBarCollisionContinue
	CMP R6, #23
	BLLE ReverseDiagonal ; Reverse Direction Diagonally (R4 State, R7 Place of Hit)
	BLE CheckBarCollisionContinue
CheckBarCollisionContinue1
; Work on Top Bar (BAR2)
	LDR R5, =BAR2
	LDR R5,[R5]
	LSR R0, R5, #16 ; R0 = X
	LDR R5, =BALL
	LDR R5,[R5]
	LSR R2, R5, #16 ; R2 = Ball X
	LDR R5, =BALL
	LDR R5,[R5]
	MOV R4, #0x0000FFFF ; Temp Variable
	AND R3, R5, R4 ; R3 = Ball Y
	LDR R5, =BALL_STATE
	LDR R4, [R5]
	LDR R5, =BAR2
	LDR R5, [R5]
	MOV R6, #0x0000FFFF ; Temp Variable
	AND R5, R5, R6 ; R5 =Y
	; Center of Bar is X = R0, Y = R5 , Assume Bar width is 40px
	ADD R0, R0, #20 ; Make R0 is Center of Bar (X)
	ADD R5, R5, #5 ; Y of Bar Center
	SUB R6, R3, R5
	CMP R6, #0
	BLT CheckBarCollisionContinue ; Ball is Above Top Bar
	CMP R6, #15 ; +5 px below center of bar and 10px radius of ball
	BGT CheckBarCollisionContinue
	CMP R2, R0
	SUBGE R6, R2, R0
	MOVGE R7, #0 ; If Ball at Right of Bar
	SUBLT R6, R0, R2
	MOVLT R7, #1 ; If Ball at Left of Bar
	CMP R6, #7
	MOVLE R4, #3 ; Set Direction to DOWN if Centers Touched Directly
	LDR R5, =BALL_STATE
	STRLE R4, [R5]
	BLE CheckBarCollisionContinue
	CMP R6, #23
	BLLE ReverseDiagonal ; Reverse Direction Diagonally (R4 State, R7 Place of Hit)

CheckBarCollisionContinue
	; Store Data In Memory from PreDefined Registers
	POP {R0-R12, PC}