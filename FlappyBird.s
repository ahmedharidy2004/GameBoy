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
	EXPORT FLAPPYBIRD
	IMPORT DrawRect
	IMPORT Draw_Ball
	IMPORT TFT_Init
	IMPORT GPIO_INIT
	IMPORT COLOR_BLACK
	IMPORT SCORE_INIT
	IMPORT IncrementScore
	IMPORT WIN
	IMPORT LOSE


    AREA MYDATA, DATA, READWRITE
BIRD_S DCD 0
BIRD_Y DCD 160
PIPE1_X	DCD	80
PIPE1_Y	DCD	80
PIPE2_X DCD 200
PIPE2_Y DCD	200
PIPE3_X DCD	300
PIPE3_Y	DCD	150
SPEED DCD 1
rand_seed DCD 0x12345678   ; Initial seed (can be any non-zero value)

;COLOURS
BLACK EQU 0X0000
WHITE EQU 0XFFFF
PINK EQU 0xc814
GREEN EQU 0x0780
CYAN EQU 0x05b9
RED	EQU 0xf800
YELLOW	EQU 0xffc0
ORANGE EQU	0xfc40


BIRDSPEED EQU 6

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

DELAY_INTERVAL  EQU     0x18604  

    AREA RESET, CODE, READONLY
	
; *************************************************************
; Delay Functions 
; *************************************************************
delay
    PUSH {R0, LR}
    LDR R0, =DELAY_INTERVAL
delay_loop
    SUBS R0, R0, #1
    BNE delay_loop
    POP {R0, LR}
    BX LR

FLAPPYBIRD
	PUSH{R0-R12, LR}	
	MOV R10, #CYAN
	BL SCORE_INIT
	;SETUP THE VARIABLES WITH INITIAL VALUES
	BL SETUP_DATA
	;FILL WITH BLACK BACKGROUND
	MOV R6, #0   	;X1
	MOV R7, #0   	;Y1
	MOV R8,	#480	;X2
	MOV R9, #320 	;Y2
	MOV R10, #CYAN	;COLOUR
	BL	DrawRect
	

	;NOW ALL MAIN GRAPHICAL INITIALIZATIONS HAVE BEEN DONE
	;WE WILL LET (BIRD_Y = Y) BE THE BIRD COORDINATES AT ANY INSTANT
	;AND BIRD_STATE AS THE STATE (0 -> DOWN , 1 -> UP)
	
	;MAIN GAME LOOP
GAMELOOP
	BL UPDATESCORE
	BL UPDATE_BIRD_STATE
	BL DRAW_NEW_BIRD
	BL Redraw_Pipe1
	BL CHECK_COLLISION
	CMP R0, #1
	BEQ GAMEOVER
	BL delay
	B GAMELOOP
GAMEOVER
	BL LOSE
	B GAMEOVER
	POP{R0-R12, PC}
	
DRAW_NEW_BIRD
	PUSH{R0-R12, LR}
	
	;REMOVE OLD BIRD
	LDR R10, =CYAN
	LDR R6, =20		;X ALWAYS CONSTANT FOR THE BIRD
	LDR R0, =BIRD_Y ;LOAD BIRD_Y IN R7
	LDR R7, [R0]
	ADD R8, R6, #30
	ADD R9, R7, #30
	BL DrawRect
	LDR R10, =GREEN
	
	;Load Current State in R3
	LDR R0, =BIRD_S
	LDR R3, [R0]
	
	LDR R0, =20
	CMP R3, #0
	BNE	SKIP_DRAW_DOWN
	ADD R1, R7, #BIRDSPEED
	BL DrawPixelatedBirdMirrored
	B SKIP_DRAW_BIRD
SKIP_DRAW_DOWN
	SUB R1, R7, #BIRDSPEED
	BL	DrawPixelatedBirdMirrored
SKIP_DRAW_BIRD
	;Store the New Y of the Bird
	LDR R0, =BIRD_Y
	STR R1, [R0]
	POP{R0-R12, PC}

UPDATE_BIRD_STATE
    PUSH{R0-R12, LR}

    LDR R0, =GPIOB_BASE + GPIO_IDR
    LDR R1, [R0]
    
    ; Check left button (PB12) - active LOW
	LDR R2, =0 ; Assume Idle State at first (GRAVITY)
    TST R1, #(1 << 14)        ; Test bit 12
    MOVEQ R2, #1
	
	;STORE BACK THE NEW STATE
	LDR R0, =BIRD_S
	STR R2, [R0]
	POP {R0-R12, PC}
	
Redraw_Pipe1
	PUSH{R0-R12, LR}
	
	;LOAD SPEED IN R4
	LDR R0, =SPEED
	LDR R4, [R0]
	;LOAD PIPE2_X IN R1
	LDR R0, =PIPE2_X
	LDR R1, [R0]
	;LOAD PIPE2_Y IN R2
	LDR R0, =PIPE2_Y
	LDR R2, [R0]
	
	;REMOVE RIGHT PART OF THE PIPE
	MOV R10, #CYAN
	MOV R6, R1
	ADD	R6, R6, #40
	SUB R6, R6, R4
	MOV R7, #0
	ADD R8, R6, R4
	MOV R9, #320
	BL DrawRect
	MOV R10, #GREEN
	
	SUB R1,R1,R4
	BL Draw_Pipe
	
	;STORE NEW PIPE2_X BACK
	LDR R0, =PIPE2_X
	STR R1, [R0]
	;STORE NEW PIPE2_Y BACK
	LDR R0, =PIPE2_Y
	STR R2, [R0]
	
	;LOAD PIPE3_X IN R1
	LDR R0, =PIPE3_X
	LDR R1, [R0]
	;LOAD PIPE3_Y IN R2
	LDR R0, =PIPE3_Y
	LDR R2, [R0]
	
	;REMOVE RIGHT PART OF THE PIPE
	MOV R10, #CYAN
	MOV R6, R1
	ADD	R6, R6, #40
	SUB R6, R6, R4
	MOV R7, #0
	ADD R8, R6, R4
	MOV R9, #320
	BL DrawRect
	MOV R10, #GREEN
	
	SUB R1,R1,R4
	BL Draw_Pipe
	
	;STORE NEW PIPE3_X BACK
	LDR R0, =PIPE3_X
	STR R1, [R0]
	;STORE NEW PIPE3_Y BACK
	LDR R0, =PIPE3_Y
	STR R2, [R0]
	
	;LOAD PIPE1_X IN R1
	LDR R0, =PIPE1_X
	LDR R1, [R0]
	;LOAD PIPE1_Y IN R2
	LDR R0, =PIPE1_Y
	LDR R2, [R0]
	
	;REMOVE RIGHT PART OF THE PIPE
	MOV R10, #CYAN
	MOV R6, R1
	ADD	R6, R6, #40
	SUB R6, R6, R4
	MOV R7, #0
	ADD R8, R6, R4
	MOV R9, #320
	BL DrawRect
	MOV R10, #GREEN
	
	;CHECK IF PIPE1 CAME TO END OR NOT
	CMP R1, #5
	BGT	SKIP_DRAW_NEW_PIPE
	
	BL IncrementScore
	
	MOV R10, #CYAN
	BL Draw_Pipe
	MOV R10, #GREEN

	MOV R1, #440
	BL GENERATE_RANDOM_100_250
	MOV R2, R5 ; Random Number Generated
	ADD R4, R4, #1  ;INCREASE SPEED
	;STORE P3 IN P2 AND P2 IN P1 AND P1 IN P3
	LDR R0, =PIPE2_X
	LDR R6, [R0]
	LDR R0, =PIPE3_X
	LDR R7, [R0]
	;STORE NEW PIPE1_X BACK
	LDR R0, =PIPE1_X
	STR R6, [R0]
	LDR R0, =PIPE2_X
	STR R7, [R0]
	LDR R0, =PIPE3_X
	STR R1, [R0]
	
	LDR R0, =PIPE2_Y
	LDR R6, [R0]
	LDR R0, =PIPE3_Y
	LDR R7, [R0]
	;STORE NEW PIPE1_Y BACK
	LDR R0, =PIPE1_Y
	STR R6, [R0]
	LDR R0, =PIPE2_Y
	STR R7, [R0]
	LDR R0, =PIPE3_Y
	STR R2, [R0]
	B END_DRAW_PIPE1
SKIP_DRAW_NEW_PIPE
	;THEN WE WILL DECREMENT R1 BY SPEED
	SUB R1,R1,R4
	BL Draw_Pipe
	;STORE NEW PIPE1_X BACK
	LDR R0, =PIPE1_X
	STR R1, [R0]
	;STORE NEW PIPE1_Y BACK
	LDR R0, =PIPE1_Y
	STR R2, [R0]
END_DRAW_PIPE1
	LDR R0, =SPEED
	CMP R4, #13
	MOVGT R4, #13
	STR R4, [R0]
	POP{R0-R12, PC}

;==========================================================
; take R1 ->X1 of pipe
; PIPE WIDTH CONSTANT = 40
; TAKE R2-> Y2 FOR THE FIRST PART OF PIPE 
Draw_Pipe
	PUSH{R0-R12,LR}
	MOV R6, R1;
	MOV R7, #0
	ADD R8,R6, #40
	MOV R9,R2
	BL DrawRect

    SUB R6,R6,#5
    MOV R7,R2
    ADD R8,R6,#45
    ADD R9,R2,#10
    BL DrawRect

	ADD R7,R2,#90
    ADD R9,R7,#10
    BL DrawRect
	MOV R6, R1;
	ADD R7,R2,#100
	ADD R8,R6,#40
	MOV R9, #320
	BL DrawRect
	POP {R0-R12,PC}

; Returns: R5 = random number (32-bit)
GENERATE_RANDOM_100_250
    PUSH {R0-R4, R6-R12, LR}
    ; Load current seed from memory
    LDR R0, =rand_seed
    LDR R1, [R0]
    ; Load multiplier (1664525 = 0x19660D)
    LDR R2, =0x19660D      
    ; Multiply
    MUL R1, R2, R1
    ; Load increment (1013904223 = 0x3C6EF35F)
    LDR R3, =0x3C6EF35F    ; Alternative: MOVW R3, #0xF35F & MOVT R3, #0x3C6E
    ; Add increment
    ADD R1, R1, R3
    ; Store new seed back to memory
    STR R1, [R0]
    ; Return value in R0
    AND R5, R1, #0x0000007F
	ADD R5, R5, #60
    POP {R0-R4, R6-R12, PC}

	B SKIP_THIS_FOOL_LINE2
	LTORG
SKIP_THIS_FOOL_LINE2

DRAWFEET
	PUSH{R0,R12,LR}
	MOV R10, #0x0000     ; Black color
    ADD R6, R11, #18
    ADD R8, R11, #19
    ADD R7, R12, #20
    ADD R9, R12, #21
    BL DrawRect

    ; Foot 2: pixel 6 ? x = 12
    ADD R6, R11, #12
    ADD R8, R11, #13
    ADD R7, R12, #20
    ADD R9, R12, #21
    BL DrawRect
	POP{R0,R12,PC}
	;TAKES START LEFT X IN R0 AND START TOP Y IN R1 
DrawPixelatedBirdMirrored  
    PUSH {R0-R12, LR}
	MOV R11, R0          ; Base X position 
    MOV R12, R1          ; Base Y position
    MOV R10, #0x0000     ; Black color

    ; Row 1: pixels 8 to 11 ? scaled to 16 to 23
    ADD R6, R11, #16
    ADD R8, R11, #23
    ADD R7, R12, #0
    ADD R9, R12, #1
    BL DrawRect

    ; Row 2: 7 to 12 ? scaled to 14 to 25
    ADD R6, R11, #14
    ADD R8, R11, #25
    ADD R7, R12, #2
    ADD R9, R12, #3
    BL DrawRect

    ; Row 3: 6 to 13
    ADD R6, R11, #12
    ADD R8, R11, #27
    ADD R7, R12, #4
    ADD R9, R12, #5
    BL DrawRect

    ; Eye: pixel 10
    MOV R10, #0xFFFF
    ADD R6, R11, #20
    ADD R8, R11, #21
    ADD R7, R12, #4
    ADD R9, R12, #5
    BL DrawRect

    MOV R10, #0x0000

    ; Row 4: 5 to 12
    ADD R6, R11, #10
    ADD R8, R11, #25
    ADD R7, R12, #6
    ADD R9, R12, #7
    BL DrawRect

    ; Row 5: 4 to 12
    ADD R6, R11, #8
    ADD R8, R11, #25
    ADD R7, R12, #8
    ADD R9, R12, #9
    BL DrawRect

    ; Row 6: 3 to 12
    ADD R6, R11, #6
    ADD R8, R11, #25
    ADD R7, R12, #10
    ADD R9, R12, #11
    BL DrawRect

    ; Row 7: 2 to 11
    ADD R6, R11, #4
    ADD R8, R11, #23
    ADD R7, R12, #12
    ADD R9, R12, #13
    BL DrawRect

    ; Row 8: 1 to 10
    ADD R6, R11, #2
    ADD R8, R11, #21
    ADD R7, R12, #14
    ADD R9, R12, #15
    BL DrawRect

    ; Row 9: 0 to 9
    ADD R6, R11, #0
    ADD R8, R11, #19
    ADD R7, R12, #16
    ADD R9, R12, #17
    BL DrawRect

    ; Tail: pixel 2 ? scaled to x = 4
    MOV R10, #0xFFFF
    ADD R6, R11, #4
    ADD R8, R11, #5
    ADD R7, R12, #16
    ADD R9, R12, #17
    BL DrawRect

    MOV R10, #0x0000

    ; Left leg: pixel 8 ? x = 16
    ADD R6, R11, #16
    ADD R8, R11, #17
    ADD R7, R12, #18
    ADD R9, R12, #19
    BL DrawRect

    ; Right leg: pixel 5 ? x = 10
    ADD R6, R11, #10
    ADD R8, R11, #11
    ADD R7, R12, #18
    ADD R9, R12, #19
    BL DrawRect
	BL DRAWFEET
	
    POP {R0-R12, PC}	

SETUP_DATA
	PUSH{R0-R12, LR}
	LDR R0, =BIRD_S
	LDR R1, =0
	STR R1, [R0]
	
	LDR R0, =BIRD_Y
	LDR R1, =160
	STR R1, [R0]
	
	LDR R0, =PIPE1_X
	LDR R1, =80
	STR R1, [R0]
	
	LDR R0, =PIPE1_Y
	LDR R1, =100
	STR R1, [R0]

	LDR R0, =PIPE2_X
	LDR R1, =240
	STR R1, [R0]
	
	LDR R0, =PIPE2_Y
	LDR R1, =200
	STR R1, [R0]
	
	LDR R0, =PIPE3_X
	LDR R1, =420
	STR R1, [R0]
	
	LDR R0, =PIPE3_Y
	LDR R1, =150
	STR R1, [R0]
	
	LDR R0, =SPEED
	LDR R1, =2
	STR R1, [R0]
	
	LDR R0, =rand_seed
	LDR R1, =0x12345678
	STR R1, [R0]
	POP{R0-R12, PC}
	
	;==============================================
CHECK_COLLISION
    PUSH {R1-R12, LR}
    
	MOV R0, #40
	LDR R5,=BIRD_Y
	LDR R1,[R5]
  
  
	LDR R5,=PIPE1_X
	LDR R2,[R5]

	LDR R5,=PIPE1_Y
	LDR R3,[R5]

    ; Bird parameters
    
    ; 1. Check collision with ground (assuming ground at Y=320)
    ADD R6, R1, #20      ; Bird bottom edge (Y + radius)
    CMP R6, #320
    BGE collision       ; Hit ground
    
    ; 2. Check collision with ceiling (Y=0)
    mov R6, R1     ; Bird top edge (Y - radius)
    cmp R6,#0
    BLE collision       ; Hit ceiling
    
    ; 3. Check if bird is within pipe X range
    ; Pipe right edge = Pipe X + PIPE_WIDTH (assuming 50)
    mov R6,R2
    CMP R6,#48
    BGE no_collision

    MOV R6,R3
    CMP R1,R6
    BLE collision
    
    ADD R6,R6,#80
    ADD R1,R1,#20
    CMP R1,R6
    BGE collision

    
no_collision
    MOV R0, #0          ; No collision
    B collision_end
    
collision
    MOV R0, #1          ; Collision detected
collision_end
    POP {R1-R12, PC}

UPDATESCORE
	PUSH{R0-R12, LR}
	MOV R11, #5
	MOV R12, #5
	BL COLOR_BLACK
	POP{R0-R12, PC}