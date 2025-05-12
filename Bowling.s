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
	EXPORT BOWLING
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
	;IMPORT Draw_Ball
	IMPORT TFT_ImageLoop
	IMPORT delay
	IMPORT ONEWIN
	IMPORT TWOWIN
	IMPORT DrawScoreDIGIT
	IMPORT DRAWSCORE
	IMPORT SCORE_INIT
	IMPORT CLEAR_COLOR
	IMPORT SET_SCORE
	IMPORT IncrementScore
	IMPORT COLOR_GREEN
	IMPORT COLOR_BLACK
	IMPORT DIV
	IMPORT DRAW_DRAW
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
	
	
BALLS      DCD 0,0,0,0,0,0,0,0,0,0,0 ; x y of each ball
BALL_DIRECTION DCD 3,3,3,3,3,3,3,3,3,3,3 ; (O Idle, 1 Up, 2 UL, 3 UR)
	
	
SCORE1 DCD 0 ; Score of Player 1(Increments with Each Hit)
SCORE2 DCD 0 ; Score of Player 2(Increments with Each Hit)
ENDGAME DCD 0 ; Determines Game State (0 Active, 1 Win, 2 Lose)	
SCORE1X EQU 420
SCORE2X EQU 0
SCOREY EQU 0
BorderRight EQU 312 ; Edge of Right Border
BorderLeft EQU 168 ; Edge of Left Border
DELAY_INTERVAL  EQU     0x18604  

PIN_STATE DCD 0,0,0,0,0,0,0,0,0,0 ;1 up 0 down to indicate score
THROW_COUNT DCD 0  ;2 throws each frame     
FRAME_COUNT DCD 0  ;10 frames

	AREA RESET, CODE, READONLY


; Functions for Players Score
DrawScore1
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCORE1X
	MOV R12, #SCOREY
	BL SCORE_INIT
	LDR R0, =SCORE1
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_GREEN
	POP {R0-R12, PC}
	
DrawScore2
	PUSH {R0-R12, LR}
	MOV R10, #BLACK
	MOV R11, #SCORE2X
	MOV R12, #SCOREY
	BL SCORE_INIT
	LDR R0, =SCORE2
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_GREEN
	POP {R0-R12, PC}
	
	
incrementScore
	PUSH {R0-R12, LR}
	LDR R2,=FRAME_COUNT
	LDR R2, [R2]
	MOV R0, R2
	MOV R1, #2
	BL DIV
	CMP R0, #1         ;Check if odd frame
	BEQ IncrementScore2
	
IncrementScore1

	LDR R0, =SCORE1
	LDR R0, [R0]
	ADD R0, R0, #1
	LDR R1, =SCORE1
	STR R0, [R1]
	B incrementScoreFinished
IncrementScore2
    LDR R0, =SCORE2
	LDR R0, [R0]
	ADD R0, R0, #1
	LDR R1, =SCORE2
	STR R0, [R1]
incrementScoreFinished	
	MOV R11, #SCORE1X
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	BL CLEAR_COLOR
	MOV R11, #SCORE2X
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	BL CLEAR_COLOR
    POP {R0-R12, PC}


; Function Draw Ball Edited for 15p Radius
Draw_Ball
    PUSH {R0-R12, LR}
    ; R2, R3: Center (X, Y)
    ; R10: Color

    ; ==== Center horizontal band ====
    SUB R6, R2, #12     ; X1 = center - 11
    SUB R7, R3, #3      ; Y1 = center - 3
    ADD R8, R2, #12     ; X2 = center + 11
    ADD R9, R3, #3      ; Y2 = center + 3
    BL DrawRect

    ; ==== Middle vertical band ====
    SUB R6, R2, #3
    SUB R7, R3, #10
    ADD R8, R2, #3
    ADD R9, R3, #10
    BL DrawRect

    ; ==== Top rounded part ====
    SUB R6, R2, #4
    SUB R7, R3, #13
    ADD R8, R2, #4
    SUB R9, R3, #11
    BL DrawRect

    SUB R6, R2, #7
    SUB R7, R3, #11
    ADD R8, R2, #7
    SUB R9, R3, #9
    BL DrawRect

    SUB R6, R2, #9
    SUB R7, R3, #9
    ADD R8, R2, #9
    SUB R9, R3, #7
    BL DrawRect

    ; ==== Bottom rounded part ====
    SUB R6, R2, #4
    ADD R7, R3, #11
    ADD R8, R2, #4
    ADD R9, R3, #13
    BL DrawRect

    SUB R6, R2, #7
    ADD R7, R3, #9
    ADD R8, R2, #7
    ADD R9, R3, #11
    BL DrawRect

    SUB R6, R2, #9
    ADD R7, R3, #7
    ADD R8, R2, #9
    ADD R9, R3, #9
    BL DrawRect

    ; ==== Side fill (for curvature realism) ====
    SUB R6, R2, #11
    SUB R7, R3, #7
    ADD R8, R2, #11
    SUB R9, R3, #2
    BL DrawRect

    SUB R6, R2, #11
    ADD R7, R3, #2
    ADD R8, R2, #11
    ADD R9, R3, #7
    BL DrawRect

    POP {R0-R12, PC}
RESET_GAME
	PUSH {R0-R12, LR}
	;Initilizing balls
	BL BALL_INIT
	; Initializing Score player1
	MOV R11, #SCORE1X
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	;LDR R0, =SCORE
	LDR R0, [R0]
	BL SET_SCORE
	;Initializing Score player2
	MOV R11, #SCORE2X
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	;LDR R0, =SCORE
	LDR R0, [R0]
	BL SET_SCORE
	; Initializing Game State as Active
	LDR R0, =ENDGAME
	MOV R1, #0
	STR R1, [R0]
	; Check Hits
	LDR R0, =THROW_COUNT
	LDR R1, =FRAME_COUNT
	LDR R2, [R0] ; Throws
	LDR R3, [R1]
	CMP R2, #1
	ADDEQ R3, R3, #1
	MOVEQ R2, #0
	STR R2, [R0]
	STR R3, [R1]
	POP {R0-R12, PC}
GAME_INIT
	PUSH {R0-R12, LR}
	; Initialize Score
	LDR R0, =SCORE1
	MOV R1, #0
	STR R1, [R0]
	LDR R0, =SCORE2
	STR R1, [R0]
	LDR R0, =FRAME_COUNT
	MOV R1, #0
	STR R1, [R0]
	LDR R0, =THROW_COUNT
	STR R1, [R0]
	BL RESET_GAME
	POP {R0-R12, PC}

; Ball initialization function
; Initializes ball positions and directions from BALLS and BALL_DIRECTION arrays

BALL_INIT    ;change to reset balls
     PUSH{R0-R12, LR}
     
     ;set initial coords for pins and store in array
     LDR R0,=BALLS        
     MOV R2,#240  ;x
     MOV R3,#280  ;y
     LSL R2,R2,#16 ; x as high y as low
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R3,#133
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     ;second row
     MOV R3,#97
     
     MOV R2,#222
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#258
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     ;third row
     MOV R3,#61
     MOV R2,#204
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#240
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#276
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     ;last row
     MOV R3,#25
     MOV R2,#186
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#222
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#258
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0],#4
     
     MOV R2,#294
     LSL R2,R2,#16
     ORR R1,R2,R3
     STR R1,[R0]
     
     MOV R4,#11
     LDR R5,=BALL_DIRECTION        
DIRECTION_LOOP
     MOV R6,#0
     STR R6,[R5],#4
     SUB R4,R4,#1
     CMP R4,#0
     BGT  DIRECTION_LOOP
     
     MOV R4,#10
     LDR R5,=PIN_STATE
PIN_STATE_LOOP        ;set all pins to standing at first
     MOV R6,#1
     STR R6,[R5],#4
     SUB R4,R4,#1
     CMP R4,#0
     BGT PIN_STATE_LOOP
     POP {R0-R12, PC}
	
DRAW_BALLS
    PUSH {R0-R12, LR}
    MOV R5, #11        ; Ball count
    LDR R0, =BALLS     ; Pointer to ball array
    MOV R1, #0         ; Ball index

LOAD_BALLS
	CMP R1, #11
	BGE LOAD_BALLS_Continue
	LDR R4, [R0], #4
	LDR R5, =0xFFFFFFFF
	CMP R4, R5
	BEQ LOAD_BALLS_Continue
	LSR R2, R4, #16 ; R2 = 0x0000XXXX
	MOV R3, #0x0000FFFF
	AND R3, R3, R4 ; R3 = 0x0000YYYY

    ; Set color based on ball index
    CMP R1, #0
    MOVEQ R10, #ORANGE     ; Ball 0 is the player ball
    MOVNE R10, #GREEN      ; Other balls (pins)
    BL Draw_Ball
    ADD R1, R1, #1 ; Increment Index
    B LOAD_BALLS
LOAD_BALLS_Continue
    POP {R0-R12, PC}

BOWLING
	PUSH{R0-R12, LR}
	BL TFT_FillScreen
	BL GAME_INIT
	B SKIP_THIS_FOOL_LINE
	LTORG
SKIP_THIS_FOOL_LINE

GAMELOOP	 
	LDR R0, =ENDGAME
	LDR R0, [R0]
	CMP R0, #1
	BEQ GAMEFINISHED
	BL MoveBalls ; Move Balls
	BL DrawBorders
	BL DRAW_BALLS
	BL MoveBall
	BL CHECK_COLLISIONS	
	BL CHECK_WALL_COLLISION
	BL ERASE_HIT_PINS ; Handle Out of Bound PINS	
	BL DrawScore1
	BL DrawScore2
    B GAMELOOP

	POP{R0-R12, PC}
GAMEFINISHED
	PUSH{R0-R12, LR}
	LDR R0, =ENDGAME
	LDR R1, [R0]
	CMP R1, #1
	BNE GAMEFINISHED_FINISHED
	LDR R0, =SCORE1
	LDR R1, [R0]
	LDR R0, =SCORE2
	LDR R2, [R0]
	CMP R1, R2	
	BLEQ DRAW_DRAW
	BLGT ONEWIN
	BLLT TWOWIN
	B GAMEFINISHED
GAMEFINISHED_FINISHED
	POP{R0-R12, PC}	
MoveBall
	PUSH {R0-R12, LR}
	; PB12 Right
	; PB13 Left
	; PB14 Throw
	LDR R0, =BALLS
	LDR R1, [R0]
	LSR R2, R1, #16 ; R2 = Ball X
	MOV R4, #0x0000FFFF ; Temp Variable
	AND R3, R4, R1 ; R3 = Ball Y
	LDR R0, =BALL_DIRECTION
	LDR R4, [R0] ; R4 = Ball Direction
	LDR R0 , =GPIOB_BASE + GPIO_IDR
	LDR R5, [R0] ; R5 = PINB
	MOV R10, #BLACK ; For Removing Balls
	CMP R4, #0
	BNE MoveBallFinished ; Skips Reading if the Ball is Moving
	
	TST R5, #(1 << 12) ; Check if PB12 is Pressed (Right)
	BEQ MoveRightCheck
	TST R5, #(1 << 13) ; Check if PB13 is Pressed (Left)
	BEQ MoveLeftCheck
	B MoveBallContinue
MoveRightCheck
	MOV R6, #BorderRight
	SUB R6, R6, R2
	CMP R6, #12
	BLE MoveBallContinue
	BL Draw_Ball
	ADD R2, R2, #10 ; Moves 2px
	B MoveBallContinue
MoveLeftCheck
	SUB R6, R2, #BorderLeft
	CMP R6, #12
	BLE MoveBallContinue
	BL Draw_Ball
	SUB R2, R2, #10 ; Moves 2px

MoveBallContinue
	; Store New Ball Coordinates
	LSL R2, R2, #16 ; R2 = 0xXXXX0000
	ORR R1, R2, R3
	LDR R0, =BALLS
	STR R1, [R0]
CHECK_THROW_BUTTON ; Detect Button Press
	LDR R0, =THROW_COUNT
	LDR R1, [R0]
	TST R5, #(1 << 3) ; Check if PB3 is Pressed (Throw Ball)
	MOVEQ R4, #1 ; Set Direction of Ball to Up
	ADDEQ R1, R1, #1
	LDR R0, =BALL_DIRECTION
	STR R4, [R0]
	LDR R0, =THROW_COUNT
	STR R1, [R0]
MoveBallFinished
	POP {R0-R12, PC}
	
RESET_BALL
	B SKIP_THIS_FOOL_LINE2
	LTORG
SKIP_THIS_FOOL_LINE2
	PUSH {R0-R12, LR}
	LDR R0,=BALLS		
	LDR R1, [R0]
	MOV R2, #0x0000FFFF
	AND R1, R1, R2 ; R1 = Y
	MOV R2, #335
	CMP R1, R2
	BLT RESET_BALL_CONTINUE
	LDR R1, =BALL_DIRECTION
	LDR R2, [R1], #4
	MOV R6, #10
BALLS_Loop
	CMP R6, #0
	BLE BALLS_Loop_Continue
	SUB R6, R6, #1
	LDR R2, [R1]
	CMP R2, #0
	BNE RESET_BALL_CONTINUE
	B BALLS_Loop
BALLS_Loop_Continue
	MOV R2,#240  ;x
	MOV R3,#280  ;y
	LSL R2,R2,#16 ; x as high y as low
	ORR R1,R2,R3
	STR R1,[R0]
	LDR R0, =BALL_DIRECTION
	MOV R1, #0
	STR R1, [R0]
RESET_BALL_CONTINUE
	POP {R0-R12, PC}
	
MoveBalls
	PUSH {R0-R12, LR}	
	LDR R0, =BALLS
	LDR R5, =BALL_DIRECTION
	MOV R6, #11
MOVE_BALLS_LOOP
    LDR R1, [R0]     ;GET COORDS
    LSR R2, R1, #16 ; R2 = Ball X
    MOV R4, #0x0000FFFF ; Temp Variable
    AND R3, R4, R1 ; R3 = Ball Y
    LDR R4,[R5], #4  ;GET DIR
	MOV R10, #BLACK ; For Removing Ball
    CMP R4,#0        ;SKIP
    BEQ CONTINUELOOP
    
	; Remove Old Ball
	BL Draw_Ball
	
    CMP R4,#1        ;MOVE UP
    BEQ MOVE_UP
    
    CMP R4,#2        ;UP LEFT
    BEQ MOVE_UL
    
    CMP R4,#3        ;UP LEFT
    BEQ MOVE_UR
    
    
	B UPDATE_POS
MOVE_UP
	SUB R3,R3,#BALL_SPEED
	B UPDATE_POS

MOVE_UL
	SUB R3,R3,#BALL_SPEED
	SUB R2,R2,#BALL_SPEED
	B UPDATE_POS

MOVE_UR
	SUB R3,R3,#BALL_SPEED
	ADD R2,R2,#BALL_SPEED
UPDATE_POS
; SET NEW POSITION
    LSL R2,R2,#16
    ORR R1,R2,R3
    STR R1,[R0]
    
CONTINUELOOP
	LDR R1, [R0], #4 ; Shifts Ball to next ball
    SUB R6, R6, #1    
    CMP R6,#0
    BGT MOVE_BALLS_LOOP
    
    POP {R0-R12, PC}

;DRAW WHITE BORDERS OF BORDERL * BORDERW
DrawBorders
	PUSH{R0-R12, LR}
	;left Border
	MOV R6, #140   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#160 	;X2
	MOV R9, #320 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	;Right Border
	MOV R6, #320   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#340	;X2
	MOV R9, #320 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	POP{R0-R12, PC}

CHECK_WALL_COLLISION
	B SKIP_THIS_FOOL_LINE3
	LTORG
SKIP_THIS_FOOL_LINE3
    PUSH {R0-R12, LR}
    LDR R0,=BALLS
    LDR R1,=BALL_DIRECTION
    MOV R6,#11
    
WALL_COL_LOOP
    LDR R4, [R0], #4
    LSR R2, R4, #16 ; R2 = 0x0000XXXX
    MOV R3, #0x0000FFFF
    AND R3, R3, R4 ; R3 = 0x0000YYYY
	
	LDR R5, [R1]
	CMP R5, #0
	BEQ WALL_COL_LOOP_CONTINUE
	
    MOV R7,#3
	SUB R8, R2, #BorderLeft
    CMP R8,#15    ;left Boarder if hit go right  dir 3
    STRLE R7,[R1]
    
    MOV R7,#2
	MOV R8, #BorderRight
	SUB	R8, R8, R2
    CMP R8,#15    ;right Boarder if hit go left  dir 2
    STRLE R7,[R1]
WALL_COL_LOOP_CONTINUE
    LDR R5, [R1], #4
    SUB R6, R6, #1	
    CMP R6,#0
    BGT WALL_COL_LOOP
CHECK_WALL_COLLISION_CONTINUE
    POP {R0-R12, PC}

CheckDistance ; R0, R1 = X1, Y1 - R2, R3 = X2, Y2 => Result in R4 (0 false, 1 true)
	PUSH {R0-R3, R5-R12, LR}
	MOV R4, #0 ; False as Default
	CMP R0, R2
	SUBGE R5, R0, R2
	SUBLT R5, R2, R0
	; R5 = ABS(X1 - X2)
	CMP R5, #28 ; X2 - X1 Maximum
	BGE CheckDistanceContinue
	CMP R1, R3
	SUBGE R6, R1, R3
	SUBLT R6, R3, R1
	; R6 = ABS(Y1 - Y2)
	CMP R6, #28 ; Y2 - Y1 Maximum
	BGE CheckDistanceContinue
	MOV R4, #1
CheckDistanceContinue
	POP {R0-R3, R5-R12, PC}
	
CHECK_COLLISIONS
    PUSH {R0-R12, LR}
	LDR R10, =BALLS
	LDR R11, =BALL_DIRECTION
	MOV R6, #11
CHECK_COLLISIONS_LOOP
	CMP R6, #0
	BLE CHECK_COLLISIONS_DONE
	SUB R6, R6, #1 ; Decrement Index
	LDR R1, [R11] ; R1 = Direction
	CMP R1, #0
	BEQ CHECK_COLLISIONS_LOOP_CONTINUE
	LDR R7, [R10] ; R7 = Ball

	LDR R8, =BALLS
	LDR R9, =BALL_DIRECTION
	MOV R12, #11
CHECK_COLLISIONS_SUBLOOP
	CMP R12, #0
	BLE CHECK_COLLISIONS_LOOP_CONTINUE
	SUB R12, R12, #1 ; Decrement Index
	; Get X1, Y1
	LSR R0, R7, #16 ; R0 = X1
	MOV R1, #0x0000FFFF ; Temp Variable
	AND R1, R1, R7 ; R1 = Y1
	
	LDR R4, [R8] ; R4 = Ball
	CMP R7, R4
	BEQ CHECK_COLLISIONS_SUBLOOP_CONTINUE
	LSR R2, R4, #16 ; R2 = X2
	MOV R3, #0x0000FFFF ; Temp Variable
	AND R3, R3, R4 ; R3 = Y2
	; Check if Ball is Out of Bound
	MOV R5, #335
	CMP R3, R5
	BGE CHECK_COLLISIONS_SUBLOOP_CONTINUE
	
	BL CheckDistance
	CMP R4, #0
	BEQ CHECK_COLLISIONS_SUBLOOP_CONTINUE
	CMP R3, R1
	BGE CHECK_COLLISIONS_SUBLOOP_CONTINUE
	CMP R0, R2
	SUBGE R4, R0, R2
	MOVGE R5, #0 ; Ball Hits from Down Right
	SUBLT R4, R2, R0
	MOVLT R5, #1 ; Ball Hits from Down Left
	; Now R1 will Represent the New Direction of Ball
	LDR R1, [R9]
	CMP R4, #5
	MOVLE R1, #1
	STRLE R1, [R9]
	BLE CHECK_COLLISIONS_SUBLOOP_CONTINUE
	CMP R5, #0
	MOVEQ R1, #2 ; Direction : UL
	CMP R5, #1
	MOVEQ R1, #3 ; Direction : UR
	STR R1, [R9]
CHECK_COLLISIONS_SUBLOOP_CONTINUE
	LDR R4, [R8], #4
	LDR R4, [R9], #4
	B CHECK_COLLISIONS_SUBLOOP
CHECK_COLLISIONS_LOOP_CONTINUE
	LDR R1, [R10], #4
	LDR R1, [R11], #4
	B CHECK_COLLISIONS_LOOP
CHECK_COLLISIONS_DONE
    POP {R0-R12, PC}



ERASE_HIT_PINS
	PUSH {R0-R12, LR}
	LDR R0, =BALLS
	LDR R1, =BALL_DIRECTION
	MOV R6, #11
	MOV R8, #0 ;Count of Balls Down
ERASE_HIT_PINS_LOOP
	CMP R6, #0
	BLE ERASE_HIT_PINS_CONTINUE
	SUB R6, R6, #1 ; Decrements Index
	LDR R4, [R0]
	LSR R2, R4, #16 ; R2 = 0x0000XXXX
	MOV R3, #0x0000FFFF ; Temp Variable
	AND R3, R3, R4 ; R3 = 0x0000YYYY
	LDR R4, [R1] ; R4 = Ball Direction
	MOV R5, #335
	LDR R9, [R1]
	MOV R10, R0 ; R10 = Ball
	CMP R3, R5
	MOVGE R4, #0 ; Make Ball Idle
	ADDGE R8, R8, #1 ; Increment Count of Down Balls
	STR R4, [R1], #4
	LDR R4, [R0], #4
	BLT ERASE_HIT_PINS_LOOP
	LDR R11, =0xFFFFFFFF
	STR R11, [R10]
	CMP R6, #10
	BGE ERASE_HIT_PINS_LOOP
	CMP R9, #0
	BLNE incrementScore
	B ERASE_HIT_PINS_LOOP
ERASE_HIT_PINS_CONTINUE	
	CMP R8, #11
	BLGE RESET_GAME
	BL RESET_BALL
	LDR R0, =BALL_DIRECTION
	MOV R2, #0 ; Number of NonIdle Balls
	MOV R6, #11
CheckFrameLoop
	CMP R6, #0
	BLE CheckFrameLoopContinue
	SUB R6, R6, #1 ; Decrement Index
	LDR R1, [R0], #4
	CMP R1, #0
	ADDNE R2, R2, #1
	B CheckFrameLoop
CheckFrameLoopContinue
	CMP R2, #0
	BNE ERASE_HIT_PINS_FINISHED
	LDR R0, =THROW_COUNT
	LDR R1, =FRAME_COUNT
	LDR R1, [R1]
	LDR R0, [R0]
	CMP R0, #2
	ADDEQ R1, R1, #1
	MOVEQ R0, #0
	BLEQ RESET_GAME
	LDR R3, =THROW_COUNT
	STR R0, [R3]
	LDR R3, =ENDGAME
	LDR R0, [R3]
	CMP R1, #10
	MOVGE R0, #1
	STR R0, [R3]
	LDR R3, =FRAME_COUNT
	STR R1, [R3]
ERASE_HIT_PINS_FINISHED
	POP {R0-R12, PC}