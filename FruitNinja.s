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
	;IMPORT delay
	IMPORT WIN
	IMPORT LOSE
	IMPORT DrawScoreDIGIT
	IMPORT DRAWSCORE
	IMPORT SCORE_INIT
	IMPORT IncrementScore
	IMPORT DIV
	IMPORT Get_Random_Seed
	IMPORT COLOR_WHITE
	EXPORT FRUITNINJA
    AREA MYDATA, DATA, READWRITE  ; Read-Write data section 
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
BAR_SPEED      EQU 30
BAR_LEFT_LIMIT EQU 30
BAR_RIGHT_LIMIT EQU 405

;Object Dimensions
Straw_Width EQU 9
Straw_Height EQU 8	
Bomb_Dim EQU 16
Lemon_Width EQU 9
Lemon_Height EQU 7
Orange_Width EQU 16
Orange_Height EQU 10	
	
chooseturn DCD 0
rand_seed DCD 0x12345678   ; Initial seed (can be any non-zero value)
SCORE DCD 0
;array of Objects to spawn Coordinates are in X,Y
Objects DCD 0xFFFF, 0xFFFF,0xFFFF,0xFFFF , 0xFFFF , 0xFFFF , 0xFFFF ,0xFFFF , 0xFFFF, 0xFFFF,0xFFFF,0xFFFF , 0xFFFF , 0xFFFF , 0xFFFF ,0xFFFF ; (0xYYYY)
Objects_Data DCD 0xFF, 0xFF,0xFF,0xFF , 0xFF , 0xFF , 0xFF ,0xFF , 0xFF, 0xFF,0xFF,0xFF , 0xFF , 0xFF , 0xFF ,0xFF ; (0xXT) X:Column, T:Type
Object_Speed DCD 50 ;

;bar Variables
BAR_X DCD 70 ; Start of Bar (X)
BAR_Y EQU 200 ; Start of Bar (Y)
SCREEN_Y EQU 320;
BAR_STATE DCD 1 ; 0 for Idle, 1 for Left, 2 for Right

LOST DCD 0
MISSES DCB 0 ;Number of Missed fruits {If missed 3 or more then game over}
DELAY_INTERVAL EQU 0xDB624
    AREA MYCODE, CODE, READONLY ; Read-only data section 
        
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

FRUITNINJA
	BL GPIO_INIT
	BL TFT_Init
	BL GAME_INIT
;BL Initial Screen Drawing Function
Mainloop
	
	BL COLOR_WHITE
	BL UpdateState
	BL Redraw
	BL delay
	B Mainloop
    
	
Redraw
	PUSH{R0-R12,LR}
	BL DRAW_NEW_BAR
	LDR R5, =LOST
	CMP R5, #1
	BEQ SKIPAFTERLOSE
	BL Movement
SKIPAFTERLOSE
	POP{R0-R12,PC}
	
UpdateState
	PUSH{R0-R12,LR}
	BL UPDATE_BAR_STATE
	
	LDR R0, =chooseturn 
	LDR R1,[R0]
	ADD R1, #1
	CMP R1, #9
	MOVEQ R1, #0
	STR R1, [R0]
	BNE skipchoosing
	BL Spawn_Object
skipchoosing
	BL CheckHit
	POP{R0-R12,PC}
	
	
CheckHit
	PUSH{R0-R12,LR}
	LDR R9, =Objects
	LDR R4, =Objects_Data
	MOV R10,#0
	MOV R12, #0XFFFF
CHECKLOOP
	CMP R10, #16
	BEQ.W CHECKFINISHED
	ADD R4, R4, #4
	ADD R9, R9, #4
	ADD R10, R10 ,#1
	CMP R5, R12
	BEQ CHECKLOOP
	SUB R9,#4
	SUB R4, #4
	LDR R1 , [R9]
	LDR R8,  [R4]
	;LOAD the r2, r3 values and the type in the r6
	LSR R2, R8, #4
	MOV R12, #35
	MUL R2, R2, R12
	ADD R2, #15
	MOV R12, #0XFFFF
	MOV R3, R1
	MOV R7, #0X0F
	MOV R12, #0
	AND R6, R8, R7
	CMP R6, #0
	ADDEQ R12, R3, #10
	CMP R6, #1
	ADDEQ R12, R3, #20
	CMP R6, #2
	ADDEQ R12, R3, #15
	CMP R6, #3
	ADDEQ R12, R3, #30
     MOV  R7, #BAR_Y
	 SUB R7, R7, #10
	CMP R12, R7
	MOV R7, #0XF
	MOV R12, #0XFFFF
	BEQ CHECKCOLLISION
	ADD R4, R4, #4
	ADD R9, R9, #4
	B CHECKLOOP
	
	
CHECKCOLLISION
	PUSH{R10, R5, R7,R11, R12, R9}
	MOV R10, #0
	MOV R5, #0
	MOV R7, #0
	MOV R11, #0
	MOV R12, #0
	MOV R9, #0
	LDR R5, =BAR_X
	LDR R5, [R5]
	ADD R10, R5, #45
	
	
	CMP R6, #0
	ADDEQ R7, R2, #9
	SUBEQ R11, R2, #9
	CMP R6, #1
	ADDEQ R7, R2, #16
	SUBEQ R11, R2, #16
	CMP R6, #2
	ADDEQ R7, R2, #9
	SUBEQ R11, R2, #9
	CMP R6, #3
	ADDEQ R7, R2, #16
	SUBEQ R11, R2, #16
	
	
	CMP  R7, R5
	ADDGE R12, #5
	CMP  R7, R10
	ADDLE R12, #5
	
	CMP R11, R5
	ADDGE R9, #5
	CMP R11, R10
	ADDLE R9, #5
	MOV R11, #0
	
	CMP R12, #10
	ADDEQ R11, R11, #1
	CMP  R9, #10
	ADDEQ R11, R11, #1
	CMP R11, #1
	
	
	POP{R10, R5, R7, R11, R12, R9}
	BLT MISSING
	
	CMP R6, #0
	BLEQ Shade_Lemon
	BLEQ IncrementScore
	BEQ DELETEOBJECT
	
	CMP R6, #1
	BLEQ Shade_Fruit_Orange
	BLEQ IncrementScore
	BEQ DELETEOBJECT
	
	
	CMP R6, #2
	BLEQ Shade_Strawberry
	BLEQ IncrementScore
	BEQ DELETEOBJECT
	
	CMP R6, #3
	BLEQ Draw_Bomb_SHADED
	BLEQ.W GameOver
	BEQ CHECKFINISHED
	
	
	ADD R4, R4 , #4
	ADD R9, R9, #4
	B CHECKLOOP
	
DELETEOBJECT
	PUSH{R7}
	CMP R6, #0
	BLEQ Shade_Lemon
	CMP R6, #1
	BLEQ Shade_Fruit_Orange
	CMP R6, #2
	BLEQ Shade_Strawberry
	CMP R6, #3
	BLEQ Shade_Bomb
	MOV R7, #0XFFFF
	STR R7, [R9]
	MOV R7, #0XFF
	STR R7, [R4]

	ADD R4, R4 , #4
	ADD R9, R9, #4
	POP{R7}
	B CHECKLOOP

MISSING
	PUSH{R5, R7, R10}
	MOV R5, #0
	MOV R7, #0
	MOV R10, #0
	CMP R6, #3
	BEQ SKIPINCMISSING
	LDR R5, =MISSES
	LDR R7, [R5]
	ADD R7, R7, #1	
	STR R7,[R5] 
SKIPINCMISSING
	CMP R7, #10
	BLEQ GameOver
	BEQ.W CHECKFINISHED
	POP{R5, R7, R10}
	B DELETEOBJECT	

CHECKFINISHED
	POP{R0-R12,PC}
	
	
	
	
	
Movement
	PUSH{R0-R12, LR}
	MOV R12, #0
	LDR R9, =Objects
	LDR R4, =Objects_Data

OtherObject	
	MOV R2, #0xFFFF
	CMP R12, #16
	BEQ MOVFINISHED
	LDR R5, [R9], #4
	LDR R7, [R4], #4
	ADD R12, #1
	CMP R5, R2
	BEQ OtherObject
	SUB R9 ,R9, #4
	SUB R4, R4 , #4

	MOV R10, #0x0F
	AND R6, R7, R10
	LSR R7, R7, #4
	MOV R11 , #35
	MUL R2, R11 , R7
	ADD R2 , #15
	MOV R3, R5 
	
	CMP R6, #0
	BLEQ Shade_Lemon
	CMP R6, #2
	BLEQ Shade_Strawberry
	cmp r6, #1
	BLEQ Shade_Fruit_Orange
	CMP R6, #3
	BLEQ Shade_Bomb
	
	LDR R10, =Object_Speed 
	LDR R10, [R10]
	ADD R3, R3, R10
	STR R3, [R9]
	
	CMP R6, #0
	BLEQ Draw_Fruit_Lemon
	CMP R6, #1
	BLEQ Draw_Fruit_Orange
	cmp r6, #2
	BLEQ Draw_Fruit_Strawberry
	CMP R6, #3
	BLEQ Draw_Bomb
	
	ADD R9, #4
	ADD R4, #4
	B OtherObject

MOVFINISHED
	POP{R0-R12,PC}

Spawn_Object
	PUSH {R0-R12,LR}
SelectCol
	;random selection of cols through the randomizer 
	LDR R9, =Objects
	LDR R8, =Objects_Data
	MOV R6, #0
	MOV R2, #0xFFFF
SELECTIONLOOP
	CMP R6, #16
	BEQ ChooseFinished
	LDR R5, [R9], #4
	ADD R8, #4
	ADD R6, R6 ,#1
	CMP R5, R2
	BNE SELECTIONLOOP
	SUB R9, R9 , #4
	SUB R8, #4
	
	BL Get_Random_Seed
	MOV R1, #12
	BL DIV
	ADD R0, R0, #1 ; R0 = 1 - 12
	MOV R11, R0 ;R11 now holds the column , R12 now holds the Index
	LSL R11, R11 , #4 ; 0xX0 where X is the column.
		

	
	; where  to start drawing and which of the 15 cols  and 4 fruits
	MOV R10, #35
	
	BL Get_Random_Seed 
	MOV R1, #4
	BL DIV
	MOV R6, R0
	

	;SUB R4, #4
	ORR R11, R6, R11
	STR R11, [R8]
	
	LSR R11,R11,#4
	MUL R10, R10 ,R11
	ADD R10, #15 ;Offset to make sure no one spawns at X = 0
	MOV R2, R10
	MOV R3, #0
	STR R3, [R9]
	
	CMP R6, #0
	BLEQ Draw_Fruit_Lemon
	CMP R6, #1
	BLEQ Draw_Fruit_Orange
	CMP R6, #2
	BLEQ Draw_Fruit_Strawberry
	CMP R6, #3
	BLEQ Draw_Bomb

ChooseFinished
	POP {R0-R12,PC}


	
GameOver
	BL LOSE
	B GameOver
	POP{R0-R12,PC}
	LTORG


Draw_background 
     PUSH {R0-R12, LR}
    MOV R6, #0
	MOV R7, #0
	MOV R8, #480
	MOV R9, #320
	MOV R10, #CYAN
	BL DrawRect	
    POP {R0-R12, PC}
	
Draw_Fruit_Lemon
	PUSH {R0-R12, LR}
    ; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	LDR R10, =YELLOW
	SUBS R6, R2, #5
	ADDS R8, R6, #10
	ADDS R7, R3, #0
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10, =YELLOW
	SUBS R6, R6, #4
	ADDS R8, R8, #4
	ADDS R7, R9, #1
	ADDS R9, R7, #15
	BL DrawRect
	
	
	LDR R10, =YELLOW
	ADDS R6, R6, #6
	SUBS R8, R8, #6
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10, =YELLOW
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
    POP {R0-R12, PC}

	
Shade_Lemon
	PUSH {R0-R12, LR}
    ; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	LDR R10, =CYAN
	SUBS R6, R2, #5
	ADDS R8, R6, #10
	ADDS R7, R3, #0
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10,=CYAN
	SUBS R6, R6, #4
	ADDS R8, R8, #4
	ADDS R7, R9, #1
	ADDS R9, R7, #15
	BL DrawRect
	
	
	LDR R10,=CYAN
	ADDS R6, R6, #6
	SUBS R8, R8, #6
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10,=CYAN
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
    POP {R0-R12, PC}

Draw_Fruit_Strawberry
	PUSH {R0-R12, LR}
    ; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	
	LDR R10, =GREEN
	SUBS R6, R2, #1
	ADDS R8, R6, #2
	ADDS R7, R3, #0
	ADDS R9, R7, #4
	BL DrawRect
	
	LDR R10, =GREEN
	SUBS R6, R6, #4
	ADDS R8, R6, #10
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10, =RED
	SUBS R6, R6, #4
	ADDS R8, R8, #4
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	

	LDR R10, =RED
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10, =RED
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10, =RED
	ADDS R6, R6, #2
	SUBS R8, R8, #2
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	POP {R0-R12, PC}

Shade_Strawberry
	PUSH {R0-R12, LR}
    ; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	
	LDR R10, =CYAN
	SUBS R6, R2, #1
	ADDS R8, R6, #2
	ADDS R7, R3, #0
	ADDS R9, R7, #4
	BL DrawRect
	
	LDR R10, =CYAN
	SUBS R6, R6, #4
	ADDS R8, R6, #10
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10, =CYAN
	SUBS R6, R6, #4
	ADDS R8, R8, #4
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	

	LDR R10, =CYAN
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10, =CYAN
	ADDS R6, R6, #3
	SUBS R8, R8, #3
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	LDR R10, =CYAN
	ADDS R6, R6, #2
	SUBS R8, R8, #2
	ADDS R7, R9, #1
	ADDS R9, R7, #2
	BL DrawRect
	
	POP {R0-R12, PC}

Draw_Fruit_Orange
	PUSH {R0-R12, LR}
    	; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	; 1ST RECTANGLE
    LDR R10, =GREEN
	SUBS R6, R2, #6
	ADDS R8, R6, #12
	SUBS R7, R3, #5
	ADDS R9, R7, #8
	BL DrawRect
	
	LDR R10, =ORANGE
	SUBS R6, R6, #10
	ADDS R8, R8, #10
	ADDS R7, R7, #10
	ADDS R9, R7, #20
	BL DrawRect
	LDR R10, =ORANGE
	ADDS R6, R6, #4
	SUBS R8, R8, #4
	ADDS R7, R7, #20
	ADDS R9, R7, #5
	BL DrawRect
	POP {R0-R12, PC}

Shade_Fruit_Orange
	PUSH {R0-R12, LR}
    	; R7: HEIGHT Y1
	; R6: WIDTH X1
	; R9: HEIGHT Y2
	; R8: WIDTH X2
	; R2, R3: (X, Y) Center point
	; R10: COLOR
	; 1ST RECTANGLE
    LDR R10, =CYAN
	SUBS R6, R2, #6
	ADDS R8, R6, #12
	SUBS R7, R3, #5
	ADDS R9, R7, #8
	BL DrawRect
	
	LDR R10, =CYAN
	SUBS R6, R6, #10
	ADDS R8, R8, #10
	ADDS R7, R7, #10
	ADDS R9, R7, #20
	BL DrawRect
	LDR R10, =CYAN
	ADDS R6, R6, #4
	SUBS R8, R8, #4
	ADDS R7, R7, #20
	ADDS R9, R7, #5
	BL DrawRect
	POP {R0-R12, PC}

Draw_Bomb
    PUSH {R0-R12, LR}
	LDR R10, =YELLOW
	SUBS R6, R2, #2
	ADDS R8, R6, #2
	ADDS R7, R3, #0
	ADDS R9, R7, #6
	BL DrawRect
	
	LDR R10, =BLACK
	SUBS R6, R6, #5
	ADDS R8, R8, #5
	ADDS R7, R7, #7
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10, =BLACK
	SUBS R6, R6, #10
	ADDS R8, R8, #10
	ADDS R7, R9, #0
	ADDS R9, R9,#20
	BL DrawRect
	
	LDR R10, =BLACK
	ADDS R6, R6, #4
	SUBS R8, R8, #4
	ADDS R7, R9, #0
	ADDS R9, R9, #3
	BL DrawRect
	POP {R0-R12, PC}


Draw_Bomb_SHADED
    PUSH {R0-R12, LR}
	LDR R10, =BLACK
	SUBS R6, R2, #2
	ADDS R8, R6, #2
	ADDS R7, R3, #0
	ADDS R9, R7, #6
	BL DrawRect
	
	LDR R10, =BLACK
	SUBS R6, R6, #5
	ADDS R8, R8, #5
	ADDS R7, R7, #7
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10, =BLACK
	SUBS R6, R6, #10
	ADDS R8, R8, #10
	ADDS R7, R9, #0
	ADDS R9, R9,#20
	BL DrawRect
	
	LDR R10, =BLACK
	ADDS R6, R6, #4
	SUBS R8, R8, #4
	ADDS R7, R9, #0
	ADDS R9, R9, #3
	BL DrawRect
	POP {R0-R12, PC}

Shade_Bomb
    PUSH {R0-R12, LR}
	LDR R10, =CYAN
	SUBS R6, R2, #2
	ADDS R8, R6, #2
	ADDS R7, R3, #0
	ADDS R9, R7, #6
	BL DrawRect
	
	LDR R10,=CYAN
	SUBS R6, R6, #5
	ADDS R8, R8, #5
	ADDS R7, R7, #7
	ADDS R9, R7, #3
	BL DrawRect
	
	LDR R10,=CYAN
	SUBS R6, R6, #10
	ADDS R8, R8, #10
	ADDS R7, R9, #0
	ADDS R9, R9,#20
	BL DrawRect
	
	LDR R10, =CYAN
	ADDS R6, R6, #4
	SUBS R8, R8, #4
	ADDS R7, R9, #0
	ADDS R9, R9, #3
	BL DrawRect
	POP {R0-R12, PC}
	

	

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
	LDR R10, =CYAN
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

GAME_INIT
	PUSH{R0-R12,LR}
	MOV R11, #420
	MOV R12, #260
	MOV R10, #CYAN
	BL SCORE_INIT
	BL Draw_background
	LDR R0 , =Objects
	MOV R6, #0
ObjectsInitLoop
	LDR R1, =0xFFFF
	STR R1, [R0] ,#4
	ADD R6, R6 , #1
	CMP R6, #16
	BNE ObjectsInitLoop
	
	LDR R0 , =Objects_Data
	MOV R6, #0
ObjectsDataInitLoop
	LDR R1, =0xFFFF
	STR R1, [R0] ,#4
	ADD R6, R6 , #1
	CMP R6, #16
	BNE ObjectsDataInitLoop
	
	MOV R1, #5
	LDR R0, =Object_Speed
	STR R1, [R0]
	
	MOV R1, #0
	LDR R0, =MISSES
	STR R1, [R0]
	LDR R0, =BAR_STATE
	MOV R1, #0
	STR R1, [R0]
	LDR R0, =LOSE
	STR R1, [R0] 
	
	MOV R1, #50
	LDR R0, =BAR_X
	STR R1, [R0]
	
	MOV R6, #50   	;X1
	MOV R7, #200  	;Y1
	MOV R8,	#95	;X2
	MOV R9, #210 	;Y2
	MOV R10, #WHITE	;COLOUR
	BL	DrawRect
	LDR R0, =rand_seed
	LDR R1, [R0]
	LDR R1, =12345678
	STR R1, [R0]
	LDR R0, =chooseturn 
	MOV R1, #0
	STR R1, [R0]
	POP{R0-R12,PC}
