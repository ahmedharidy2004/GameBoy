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
	EXPORT BRICKBREAKER
	IMPORT GPIO_INIT
	IMPORT GPIOX_ONEREAD
	IMPORT GPIOX_READ
	IMPORT GPIOX_SETHIGH
	IMPORT GPIOX_SETLOW
	IMPORT TFT_Init
	IMPORT TFT_WriteCommand
	IMPORT TFT_WriteData
	IMPORT TFT_FillScreen
	IMPORT DrawRect
	IMPORT TFT_ImageLoop
	IMPORT delay
	IMPORT WIN
	IMPORT LOSE
	IMPORT DrawScoreDIGIT
	IMPORT DRAWSCORE
	IMPORT SCORE_INIT
	IMPORT IncrementScore
	IMPORT COLOR_WHITE
	IMPORT COLOR_BLACK
	IMPORT DIV
	AREA MYDATA, DATA, READWRITE

;COLOURS
BLACK EQU 0X0000
WHITE EQU 0XFFFF
PINK EQU 0xc814
GREEN EQU 0x0780
CYAN EQU 0x05b9
RED	EQU 0xf800
YELLOW	EQU 0xffc0
ORANGE EQU	0xfc40
; Constants for Movements
BAR_SPEED      EQU 15
BAR_LEFT_LIMIT EQU 25
BAR_RIGHT_LIMIT EQU 410
BALL_SPEED		EQU 10

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

; Array of Bricks (44 bricks as 11 per row)
Bricks DCB 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
; Variables of the Game
BAR_X DCD 240 ; Start of Bar (X)
BAR_Y EQU 270 ; Start of Bar (Y)
BAR_STATE DCD 0 ; 0 for Idle, 1 for Left, 2 for Right
BALL_X DCD 240 ; Center of Ball (X)
BALL_Y DCD 160 ; Center of Ball (Y)
BALL_STATE DCD 0 ; Ball State (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
SCORE DCD 0 ; Score of Player (Increments with Each Hit)
ENDGAME DCD 0 ; Determines Game State (0 Active, 1 Win, 2 Lose)	
SCOREX EQU 400
SCOREY EQU 280
DELAY_INTERVAL  EQU     0x18604  

	AREA RESET, CODE, READONLY

Draw_Ball
	PUSH {R0-R12, LR}
	; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	; 1ST RECTANGLE

	SUBS R6, R2, #3	    ; SET X1
	SUBS R7, R3, #1	    ; SET Y1
	ADDS R8, R6, #7	    ; SET X2
	ADDS R9, R7, #3	    ; SET Y2

	BL DrawRect

	; 2ND RECTANGLE
	ADDS R6, R6, #1	; SET X1
	SUBS R7, R7, #1	; SET Y1
	ADDS R8, R6, #5	; SET X2
	ADDS R9, R7, #5	; SET Y2

	BL DrawRect

	; 3RD RECTANGLE
	ADDS R6, R6, #1	; SET X1
	SUBS R7, R7, #1	; SET Y1
	ADDS R8, R6, #3	; SET X2
	ADDS R9, R7, #7	; SET Y2

	BL DrawRect
	POP {R0-R12, PC}
	

GAME_INIT
	PUSH {R0-R12, LR}
	; Initializing Bar Position and State (Start X = 220, Start Y = 270, State = 0 : IDLE)
	LDR R0, =BAR_X
	MOV R1, #225
	STR R1, [R0]
	LDR R0, =BAR_Y
	MOV R1, #270
	STR R1, [R0]
	LDR R0, =BAR_STATE
	MOV R1, #0
	STR R1, [R0]
	; Initializing Ball Posision and State (X = 240, Y = 160, State = 0 : UP)
	LDR R0, =BALL_X
	MOV R1, #240
	STR R1, [R0]
	LDR R0, =BALL_Y
	MOV R1, #160
	STR R1, [R0]
	LDR R0, =BALL_STATE
	MOV R1, #0
	STR R1, [R0]
	; Initializing Score
	MOV R11, #SCOREX
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	; Initializing Game State as Active
	LDR R0, =ENDGAME
	MOV R1, #0
	STR R1, [R0]
	; Init Color
	BL COLOR_WHITE
	POP {R0-R12, PC}
BRICKBREAKER
	PUSH{R0-R12, LR}
	;FILL WITH BLACK BACKGROUND
	MOV R6, #0   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#480	;X2
	MOV R9, #320 	;Y2
	MOV R10, #BLACK	;COLOUR
	BL	DrawRect

	BL DrawBorders

	;DRAW THE INITIAL BOUNCE BAR ASSUME INITIAL COORDINATES (220, 270) AND DIMENSIONS BARL*BARW {Y2 = 290 } 
	MOV R6, #225   	;X1
	MOV R7, #275   	;Y1
	MOV R8,	#270	;X2
	MOV R9, #280 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect

	;DRAW THE BALL WITH RADIUS 10PX AT THE CENTER OF THE SCREEN WITH INTIAL DIRECTION DOWNWARD
	MOV R2, #240	;X
	MOV R3, #160	;Y
	MOV R10, #WHITE	;COLOUR
	BL	Draw_Ball  ;takes R10 ,R11 (X,Y) --- R0->colour
; Setup All Bricks Initially
SetupBricks
    PUSH {R4-R5, R9}   ; Save only necessary registers
    LDR  R4, =Bricks       ; Base address
    MOV  R9, #0            ; Index = 0
    MOV  R5, #3            ; Brick value = 3
	
SetupBricksLoop
    STRB R5, [R4], #1      ; Store 3 and increment address
    ADD  R9, R9, #1        ; Increment index
    CMP  R9, #44           ; Compare to total elements (44)
    BLT  SetupBricksLoop    ; Loop if index < 44

    POP {R4-R5, R9}    ; Restore registers and return
	;WE WILL CHECK THE DIMENSIONS AND WE MAY ADD MORE LEVELS
	;NOW ALL GRAPHICAL INITIALIZATIONS HAVE BEEN DONE
	;WE WILL LET (R0 = X) BE THE BAR COORDINATES AT ANY INSTANT - R1 FOR NEXT DIRECTION (0 IDLE - 1 LEFT - 2 RIGHT)
	;(R2 = X, R3 = Y) BE THE BALL COORDINATES AT ANY INSTANT - R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
	BL GAME_INIT
	B SKIP_THIS_FOOL_LINE
	LTORG
SKIP_THIS_FOOL_LINE
;MAIN GAME LOOP
GAMELOOP
	BL CheckEndGame ; R11 if 0 so continue, if 1 so win, if 2 then lost	
	LDR R0, =ENDGAME
	LDR R11, [R0]
	CMP R11, #1
	BLEQ WIN
	BEQ ContinueLoopIfFinished
	CMP R11, #2
	BLEQ LOSE
	BEQ ContinueLoopIfFinished
	; If none happened then Continue Game
	; Draw Score
	BL COLOR_WHITE
	BL UPDATE_BAR_STATE
	BL DRAW_NEW_BAR
	BL CheckBrickCollision
	BL CheckWallsCollision
	BL CheckBarCollision
	BL DrawBricks
	BL DRAW_NEW_BALL
ContinueLoopIfFinished
	B GAMELOOP

	POP{R0-R12, PC}

;DRAW WHITE BORDERS OF BORDERL * BORDERW
DrawBorders
	PUSH{R0-R12, LR}
	;left Border
	MOV R6, #0   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#9 	    ;X2
	MOV R9, #320 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	;Top Border
	MOV R6, #0   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#480	;X2
	MOV R9, #9      ;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	;Right Border
	MOV R6, #471   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#480	;X2
	MOV R9, #320 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	POP{R0-R12, PC}

DRAW_NEW_BALL
	PUSH{R0-R12,LR}
	B SKIP_THIS_FOOL_LINE2
	LTORG
SKIP_THIS_FOOL_LINE2
	; Get Data from Memory in Predefined Registers
	LDR R5, =BAR_X
	LDR R0, [R5]
	LDR R5, =BAR_STATE
	LDR R1, [R5]
	LDR R5, =BALL_X
	LDR R2, [R5]
	LDR R5, =BALL_Y
	LDR R3, [R5]
	LDR R5, =BALL_STATE
	LDR R4, [R5]
	
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
	LDR R5, =BALL_X
	STR R2, [R5]
	LDR R5, =BALL_Y
	STR R3, [R5]
	POP{R0-R12,PC}

	B SKIP_THIS_FOOL_LINE3
	LTORG
	
DRAW_NEW_BAR
	PUSH{R0-R12, LR}
SKIP_THIS_FOOL_LINE3
	; Get Data from Memory in Predefined Registers
	LDR R0, =BAR_STATE
	LDR R1, [R0]
	
	LDR R0, =BAR_X
	LDR R6, [R0]
	ADD R8, R6, #45
	LDR R7, =BAR_Y
	ADD R9, R7, #10
	LDR R10, =WHITE
	
	CMP R1, #0
	BEQ	SKIP_DRAW_BAR;SKIP IF IDLE
	
	;REMOVE OLD BOUNCE BAR BY FILLING THE BACKGROUND WITH BLACK
	LDR R10, =BLACK
	BL DrawRect
	LDR R10,=WHITE
	
	CMP R1, #1
	BNE SKIP_DRAW_LEFT
	SUB R6, R6, #BAR_SPEED
	ADD R8, R6, #45
SKIP_DRAW_LEFT
	CMP R1, #2
	BNE	SKIP_DRAW_BAR
	ADD R6, R6, #BAR_SPEED
	ADD R8, R6, #45
SKIP_DRAW_BAR
	BL DrawRect
	; Store Data In Memory from PreDefined Registers
	LDR R0, =BAR_X
	STR R6, [R0]
	POP{R0-R12, PC}

UPDATE_BAR_STATE
	PUSH {R0-R12,LR}
	LDR R0, =BAR_X
	LDR R1, [R0]
	; Pull Up Resistor Be 0 on Click
	LDR R0, =GPIOB_BASE + GPIO_IDR
	LDR R2, [R0]

	; Check RIGHT button (PB12) - active LOW
	MOV R3, #0 ; Assume Idle State at first
	TST R2, #(1 << 12)        ; Test bit 12
	BEQ move_bar_right

	; Check LEFT button (PB13) - active LOW
	TST R2, #(1 << 13)        ; Test bit 13
	BEQ move_bar_left

	B update_bar_done
move_bar_left
	CMP R1, #BAR_LEFT_LIMIT
	MOVHS R3, #1
	B update_bar_done

move_bar_right
	MOV R2, #BAR_RIGHT_LIMIT
	CMP R1, R2
	MOVLT R3, #2

update_bar_done
	LDR R0, =BAR_STATE
	STR R3, [R0]
	POP {R0-R12,PC}

; Draw Bricks from Memory
DrawBricks
	PUSH {R0-R12, LR}
	B SKIP_THIS_FOOL_LINE4
	LTORG
SKIP_THIS_FOOL_LINE4
	; Get Data from Memory in Predefined Registers
	LDR R5, =BAR_X
	LDR R0, [R5]
	LDR R5, =BAR_STATE
	LDR R1, [R5]
	LDR R5, =BALL_X
	LDR R2, [R5]
	LDR R5, =BALL_Y
	LDR R3, [R5]
	LDR R5, =BALL_STATE
	LDR R4, [R5]
	
	LDR R4, =Bricks
	MOV R0, #0 ; Index of Iteration
	MOV R1, #8 ; Byte Value for multiplication
	MOV R6, #10 ; Column Start
	MOV R7, #10 ; Row Start
	MOV R8, #50 ; Column End
	MOV R9, #30 ; Row End
	MOV R11, #470 ; Temp Value for Comparing
	MOV R5, #0 ; Set R5 as Zero Initially
DrawBricksLoop
	CMP R0, #43
	BGT EndDrawBricks ; If Drawn the 44 Bricks End the Function
	LDRB R5, [R4], #1 ; Read the Level of the brick then shifts R4
	; Get The Color Based on Level
	CMP R5, #3
	MOVEQ R10, #GREEN
	CMP R5, #2
	MOVEQ R10, #ORANGE
	CMP R5, #1
	MOVEQ R10, #RED
	CMP R5, #0
	MOVEQ R10, #BLACK
	; Draw Rectangle
	BL DrawRect
	MOV R6, R8
	ADD R6, R6, #2 ; Give 2px horizontal padding
	ADD R8, R6, #40 ; Make width 40 px
	ADD R0, R0, #1 ; Get the Next Index
	CMP R6, R11
	MOVGE R6, #10
	MOVGE R8, #50
	MOVGE R7, R9
	ADDGE R7, R7, #2 ; Make 2px vertical padding
	ADDGE R9, R7, #20
	B DrawBricksLoop
EndDrawBricks	
	POP {R0-R12, PC}

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
	CMP R4, #5
	MOVEQ R4, #2
	BEQ ReverseDiagonalContinue
	; If was Falling Vertically Then Reverse Diagonally
	CMP R7, #0
	MOVEQ R4, #2
	CMP R7, #1
	MOVEQ R4, #1
ReverseDiagonalContinue
	LDR R2, =BALL_STATE
	STR R4, [R2]
	POP {R0-R12, PC}
	;WE WILL LET (R0 = X) BE THE BAR COORDINATES AT ANY INSTANT - R1 FOR NEXT DIRECTION (0 IDLE - 1 LEFT - 2 RIGHT)
	;(R2 = X, R3 = Y) BE THE BALL COORDINATES AT ANY INSTANT - R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
CheckBrickCollision
	PUSH {R0-R12, LR} 
	B SKIP_THIS_FOOL_LINE5
	LTORG
SKIP_THIS_FOOL_LINE5
	; Get Data from Memory in Predefined Registers
	LDR R5, =BAR_X
	LDR R0, [R5]
	LDR R5, =BAR_STATE
	LDR R1, [R5]
	LDR R5, =BALL_X
	LDR R2, [R5]
	LDR R5, =BALL_Y
	LDR R3, [R5]
	LDR R5, =BALL_STATE
	LDR R4, [R5]
CheckUpCollision
	SUB R5, R3, #10 ; Puts Top of Ball in R5
	MOV R6, #0 ; Here I'll Store the Row
	MOV R7, #0 ; Here I'll Store the Column
	MOV R8, #0 ; Here I'll Store the Index
	MOV R9, #11 ; Number of Bricks
	MOV R11, #1 ; To be Set 0 if Collided
	PUSH {R0-R2}
	MOV R0, R5
	MOV R1, #23 ; Height of Brick + Padding
	BL DIV
	MOV R6, R2
	POP {R0-R2}
	PUSH {R0-R2}
	MOV R0, R2
	MOV R1, #43 ; Width of Brick + Padding
	BL DIV
	MOV R7, R2
	POP {R0-R2}
	MUL R8, R6, R9
	ADD R8, R8, R7 ; R8 = 11 * R6 + R7
	CMP R8, #43
	BGT CheckLeftCollision
	; Time to Get the Brick Hit
	LDR R5, =Bricks
	LDRB R6, [R5, R8]
	CMP R6, #1
	BLEQ IncrementScore
	CMP R6, #0
	SUBGT R6, R6, #1
	STRB R6, [R5, R8]
	MOVGT R11, #0
	BLGT ReverseVertical
	CMP R11, #0
	BLEQ CheckBrickCollisionContinue
CheckLeftCollision
	SUB R5, R2, #10 ; Puts Left of Ball in R5
	MOV R6, #0 ; Here I'll Store the Row
	MOV R7, #0 ; Here I'll Store the Column
	MOV R8, #0 ; Here I'll Store the Index
	MOV R9, #11 ; Number of Bricks
	MOV R11, #1 ; To be Set 0 if Collided
	PUSH {R0-R2}
	MOV R0, R5
	MOV R1, #43 ; Width of Brick + Padding
	BL DIV
	MOV R7, R2
	POP {R0-R2}
	PUSH {R0-R2}
	MOV R0, R3
	MOV R1, #23 ; Height of Brick + Padding
	BL DIV
	MOV R6, R2
	POP {R0-R2}
	MUL R8, R6, R9
	ADD R8, R8, R7 ; R8 = 11 * R6 + R7
	CMP R8, #43
	BGT CheckRightCollision
	; Time to Get the Brick Hit
	LDR R5, =Bricks
	LDRB R6, [R5, R8]
	CMP R6, #1
	BLEQ IncrementScore
	CMP R6, #0
	SUBGT R6, R6, #1
	STRB R6, [R5, R8]
	MOVGT R11, #0
	BLGT ReverseHorizontal
	CMP R11, #0
	BLEQ CheckBrickCollisionContinue
CheckRightCollision
	ADD R5, R2, #10 ; Puts Right of Ball in R5
	MOV R6, #0 ; Here I'll Store the Row
	MOV R7, #0 ; Here I'll Store the Column
	MOV R8, #0 ; Here I'll Store the Index
	MOV R9, #11 ; Number of Bricks
	MOV R11, #1 ; To be Set 0 if Collided
	PUSH {R0-R2}
	MOV R0, R5
	MOV R1, #43 ; Width of Brick + Padding
	BL DIV
	MOV R7, R2
	POP {R0-R2}
	PUSH {R0-R2}
	MOV R0, R3
	MOV R1, #23 ; Height of Brick + Padding
	BL DIV
	MOV R6, R2
	POP {R0-R2}
	MUL R8, R6, R9
	ADD R8, R8, R7 ; R8 = 11 * R6 + R7
	CMP R8, #43
	BGT CheckBottomCollision
	; Time to Get the Brick Hit
	LDR R5, =Bricks
	LDRB R6, [R5, R8]
	CMP R6, #1
	BLEQ IncrementScore
	CMP R6, #0
	SUBGT R6, R6, #1
	STRB R6, [R5, R8]
	MOVGT R11, #0
	BLGT ReverseHorizontal
	CMP R11, #0
	BLEQ CheckBrickCollisionContinue
CheckBottomCollision
	ADD R5, R3, #10 ; Puts Bottom of Ball in R5
	MOV R6, #0 ; Here I'll Store the Row
	MOV R7, #0 ; Here I'll Store the Column
	MOV R8, #0 ; Here I'll Store the Index
	MOV R9, #11 ; Number of Bricks
	MOV R11, #1 ; To be Set 0 if Collided
	PUSH {R0-R2}
	MOV R0, R5
	MOV R1, #23 ; Height of Brick + Padding
	BL DIV
	MOV R6, R2
	POP {R0-R2}
	PUSH {R0-R2}
	MOV R0, R2
	MOV R1, #43 ; Width of Brick + Padding
	BL DIV
	MOV R7, R2
	POP {R0-R2}
	MUL R8, R6, R9
	ADD R8, R8, R7 ; R8 = 11 * R6 + R7
	CMP R8, #43
	BGT CheckBrickCollisionContinue
	; Time to Get the Brick Hit
	LDR R5, =Bricks
	LDRB R6, [R5, R8]
	CMP R6, #1
	BLEQ IncrementScore
	CMP R6, #0
	SUBGT R6, R6, #1
	STRB R6, [R5, R8]
	MOVGT R11, #0
	BLGT ReverseVertical
CheckBrickCollisionContinue
	POP {R0-R12, PC}
	
CheckWallsCollision
	PUSH {R0-R12, LR} 
	B SKIP_THIS_FOOL_LINE6
	LTORG
SKIP_THIS_FOOL_LINE6
	; Store Data In Memory from PreDefined Registers
	LDR R5, =BAR_X
	LDR R0, [R5]
	LDR R5, =BAR_STATE
	LDR R1, [R5]
	LDR R5, =BALL_X
	LDR R2, [R5]
	LDR R5, =BALL_Y
	LDR R3, [R5]
	LDR R5, =BALL_STATE
	LDR R4, [R5]
	; Check for Horizontal Walls
	CMP R2, #20 ; Padding + Ball Radius
	BLLE ReverseHorizontal ; If difference between center of ball and the sum of its radius and padding is less than the sum then a collision happened
	MOV R0, #480
	SUBS R5, R0, R2
	CMP R5, #20
	BLLE ReverseHorizontal
	; Check for Top Wall
	CMP R3, #20
	BLLE ReverseVertical ; If difference between center of ball and the sum of its radius and padding is less than the sum then a collision happened
	; Store Data In Memory from PreDefined Registers
	POP {R0-R12, PC}
;WE WILL LET (R0 = X) BE THE BAR COORDINATES AT ANY INSTANT - R1 FOR NEXT DIRECTION (0 IDLE - 1 LEFT - 2 RIGHT)
;(R2 = X, R3 = Y) BE THE BALL COORDINATES AT ANY INSTANT - R4 FOR STATE (0 U - 1 UL - 2 UR - 3 D - 4DL - 5 DR)
CheckBarCollision
	; Store Data In Memory from PreDefined Registers
	LDR R5, =BAR_X
	LDR R0, [R5]
	LDR R5, =BAR_STATE
	LDR R1, [R5]
	LDR R5, =BALL_X
	LDR R2, [R5]
	LDR R5, =BALL_Y
	LDR R3, [R5]
	LDR R5, =BALL_STATE
	LDR R4, [R5]
	; Center of Bar is X = R0, Y = 275 , Assume Bar width is 45px
	PUSH {R0-R12, LR} 
	ADD R0, R0, #22 ; Make R0 is Center of Bar (X)
	MOV R5, #275 ; Y of Bar Center
	;MOV R5, #195
	SUB R6, R5, R3
	CMP R6, #0
	BLT CheckBarCollisionContinue
	CMP R6, #15 ; +5 px above center of bar and 10px radius of ball
	BGT CheckBarCollisionContinue
	CMP R2, R0
	SUBGE R6, R2, R0
	MOVGE R7, #0 ; If Ball at Right of Bar
	SUBLT R6, R0, R2
	MOVLT R7, #1 ; If Ball at Left of Bar
	CMP R6, #7
	MOVLE R4, #0 ; Set Direction to UP if Centers Touched Directly
	LDR R5, =BALL_STATE
	STRLE R4, [R5]
	BLE CheckBarCollisionContinue
	CMP R6, #23
	BLLE ReverseDiagonal ; Reverse Direction Diagonally (R4 State, R7 Place of Hit)
CheckBarCollisionContinue
	; Store Data In Memory from PreDefined Registers
	POP {R0-R12, PC}
CheckEndGame ; Sets R11 with 0 By default and 1 if win, 2 if lost
	PUSH {R0-R12, LR}
	LDR R2, =BALL_Y
	LDR R3, [R2]
	MOV R11, #0 ; Sets Default value to 0
	LDR R4, =Bricks
	MOV R10, #0 ; Index of Loop
	MOV R8, #0 ; Number of Remaining Bricks
CheckEndGameLoop
	LDRB R5, [R4], #1 ; Gets value of Byte
	CMP R5, #0
	ADDNE R8, R8, #1 ; Increments R8 by 1
	ADD R10, R10, #1
	CMP R10, #43
	BLE CheckEndGameLoop
	CMP R8, #0
	MOVEQ R11, #1 ; No Bricks Remaining then a Win happened
	MOV R1, #BAR_Y + 30 ; Bottom of Bar + 30PX Padding
	SUB R1, R1, R3
	CMP R1, #10
	MOVLT R11, #2 ; If Ball Passed the Bar and didn't collide with it
	LDR R10, =ENDGAME
	STR R11, [R10]
	POP {R0-R12, PC}