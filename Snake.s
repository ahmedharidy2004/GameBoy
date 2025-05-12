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
	EXPORT SNAKE
	EXPORT EXTI15_10_IRQHandler
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
	IMPORT Draw_Ball
	IMPORT TFT_ImageLoop
	IMPORT delay
	IMPORT DIV
	IMPORT WIN
	IMPORT LOSE
	IMPORT DrawScoreDIGIT
	IMPORT DRAWSCORE
	IMPORT SCORE_INIT
	IMPORT IncrementScore
	IMPORT Get_Random_Seed
	IMPORT COLOR_GREEN
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
BAR_SPEED      EQU 10
BAR_LEFT_LIMIT EQU 20
BAR_RIGHT_LIMIT EQU 420
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
RCC_APB2ENR     EQU     0x44
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

; Game Variables
BLOCKS SPACE 1532 ; Defines 383 Double Word for 383 blocks of snake at max (0xXXXXYYYY) 2 bytes for Column and 2 for Row (Each block is 20*20 size)
SIZE DCD 0 ; Length of snake
DIRECTION DCD 0 ; Direction of Snake (0: UP, 1: Left, 2: Down, 3: Right)
FOOD DCD 0 ; Location of Food (0xXXXXYYYY)
LOST DCD 0 ; Set by 1 if LOST
WON DCD 0 ; Set by 1 if WON
; Temporary Variables
INDEX DCD 0
LOCATION DCD 0
; For Random Generation
SEED DCD 0
; Screen Properties
WIDTH EQU 480
HEIGHT EQU 320
ROWS EQU 16 ; Height / 20
COLUMNS EQU 24 ; Width / 20
;WIDTH EQU 320
;HEIGHT EQU 240
;ROWS EQU 12 ; Height / 20
;COLUMNS EQU 16 ; Width / 20
; 
DELAY_INTERVAL  EQU     0x18604  
; Constants for Interrupt
SYSCFG_BASE     EQU     0x40013800
EXTI_BASE       EQU     0x40013C00
NVIC_BASE       EQU     0xE000E000 
NVIC_ISER1      EQU  0x104   ; Interrupt Set-Enable Register 1
SYSCFG_EXTICR4  EQU  0x20    ; External interrupt configuration register 4
NVIC_IPR10      EQU  0x400   ; Interrupt Priority Register 10 (for IRQ40)
SCOREX EQU 400
SCOREY EQU 280
	AREA RESET, CODE, READONLY
GAME_INIT
	PUSH {R0-R4, LR}
	; Initialize Snake Blocks
	LDR R0, =BLOCKS
	MOV R1, #COLUMNS
	MOV R4, #2 ; Temp Value
	UDIV R1, R1, R4 ; R1 = MidPoint X
	LSL R1, R1, #16 ; Make it like 0xXXXX0000
	MOV R2, #ROWS
	UDIV R2, R2, R4 ; R2 = MidPoint Y
	MOV R4, #0x0000FFFF ; Temp Value
	AND R2, R2, R4 ; Makes R2 like 0x0000YYYY
	ORR R1, R1, R2 ; R1 = 0xXXXXYYYY (Center of Screen)
	STR R1, [R0], #4 ; Initially Make the First Block at the Center of Screen
	MOV R1, #1 ; the index of loop
	MOV R2, #0xFFFFFFFF ; the initial value of snake blocks
	MOV R3, #383 ; The total value of blocks of snake
BLOCKSLOOP
	STR R2, [R0], #4 ; Stores Initial Value in the Block and Increments by 4 till the next block as each is a DCD
	ADD R1, R1, #1 ; Increments R1
	CMP R1, R3
	BLT BLOCKSLOOP
	; Initialize Size
	LDR R0, =SIZE
	MOV R1, #1
	STR R1, [R0]
	; Initialize Direction with 0 : UP
	LDR R0, =DIRECTION
	MOV R1, #0
	STR R1, [R0]
	; Initialize Food by Random Position
	BL GenerateFood
	; Initialize Lost State
	LDR R0, =LOST
	MOV R1, #0
	STR R1, [R0]
	; Initialize Won State
	LDR R0, =WON
	MOV R1, #0
	STR R1, [R0]
	; Initialize Temp Variables
	LDR R0, =INDEX
	MOV R1, #0xFFFFFFFF
	STR R1, [R0]
	LDR R0, =LOCATION
	MOV R1, #0xFFFFFFFF
	STR R1, [R0]
	; Initialize Random Variables
	BL UpdateSeed
	; Initialize SCORE
	MOV R11, #SCOREX
	MOV R12, #SCOREY
	MOV R10, #BLACK
	BL SCORE_INIT
	; Initialize Interrupt
	BL SetupInterrupts
	POP {R0-R4, PC}

SNAKE
	; Initialize GPIO
	BL TFT_FillScreen
	BL GAME_INIT
GAMELOOP
	; Check if Won
	BL CheckWin
	; If Won Show Win Screen Repeatedly
	LDR R0, =WON
	LDR R1, [R0]
	CMP R1, #1
	BLEQ WIN
	CMP R1, #1
	BEQ GameContinue
	; Check if Lost
	BL CheckWallCollision
	BL CheckSelfCollision
	; If Lost Show Game Over Screen Repeatedly
	LDR R0, =LOST
	LDR R1, [R0]
	CMP R1, #1
	BLEQ LOSE
	CMP R1, #1
	BEQ GameContinue
	; Check for Food Collision and If Happened then Enlarge Snake, Draw Food, and Increment Score
	BL CheckFoodCollision
	BL DrawFood
	; Draw Score
	;BL COLOR_GREEN
	; Move Snake to New Location Based on its direction
	BL MoveSnake
	; Draw Snake
	BL DrawSnake
	; Update Snake Direction if Reads Input From User
	;BL UpdateSnakeDirection
	; Some Delay
	BL delay
GameContinue
	B GAMELOOP
	
; Highest Priority Interrupt Setup (STM32F401)
SetupInterrupts
    PUSH {R0-R3, LR}
    
    ; 1. Enable SYSCFG Clock (RCC_APB2ENR bit 14)
    LDR R0, =0x40023800      ; RCC_BASE
    LDR R1, [R0, #0x44]      ; APB2ENR offset
    ORR R1, #(1 << 14)       ; SYSCFGEN
    STR R1, [R0, #0x44]
    
    ; 2. Configure GPIOB Pins (PB12-PB15)
    LDR R0, =0x40020400      ; GPIOB_BASE
    ; Enable pull-ups (PUPDR offset 0x0C)
    LDR R1, [R0, #0x0C]
    ORR R1, #(0x55 << 24)    ; 01010101 for PB12-PB15
    STR R1, [R0, #0x0C]
    
    ; 3. Map EXTI Lines to PB12-PB15 (EXTICR4 offset 0x20)
    LDR R0, =0x40013800      ; SYSCFG_BASE
    MOV R1, #0x1111          ; PB12-PB15 mapping
    STR R1, [R0, #0x20]
    
    ; 4. Configure EXTI Trigger (FTSR offset 0x0C)
    LDR R0, =0x40013C00      ; EXTI_BASE
    MOV R1, #0xF000          ; EXTI12-15
    STR R1, [R0, #0x0C]      ; Falling edge trigger
    STR R1, [R0, #0x00]      ; IMR - Unmask interrupts
    
    ; 5. NVIC Configuration (Highest Priority)
    LDR R0, =0xE000E000      ; NVIC_BASE
    ; Set priority to 0 (highest) (IPR10 offset 0x340)
    MOV R1, #0x00
    STR R1, [R0, #0x340]
    ; Enable interrupt (ISER1 offset 0x104)
    MOV R1, #(1 << 8)        ; EXTI15_10 (IRQ40)
    STR R1, [R0, #0x104]
    
    ; Memory barrier to ensure writes complete
    DSB
    ISB
    
    POP {R0-R3, PC}

; Ultra-Fast Interrupt Handler
EXTI15_10_IRQHandler
    PUSH {R0-R1, LR}
    
    ; 1. Clear pending bits immediately (PR offset 0x14)
    LDR R0, =0x40013C00      ; EXTI_BASE
    MOV R1, #0xF000          ; EXTI12-15 mask
    STR R1, [R0, #0x14]      ; Clear by writing 1
    
    ; 2. Call direction update (atomic operation)
    BL UpdateSnakeDirection
    
    ; 3. Return with minimal latency
    POP {R0-R1, PC}

UpdateSnakeDirection ; Reads from PB12 to PB15 (Pull Up) and Updates DIRECTION Variable in Memory
	PUSH {R0-R4, LR}
	LDR R0, =DIRECTION
	LDR R1, [R0]
	LDR R2 , =GPIOB_BASE + GPIO_IDR
	LDR R3, [R2]
	MOV R0, #1
	AND R4, R3, R0, LSL #12 ; Get PB12 in R4 (Right)
	LSR R4, R4, #12
	CMP R4, #0
	MOVEQ R1, #3 ; Direction = Right
	AND R4, R3, R0, LSL #13 ; Get PB13 in R4 (Left)
	LSR R4, R4, #13
	CMP R4, #0
	MOVEQ R1, #1 ; Direction = Left
	AND R4, R3, R0, LSL #14 ; Get PB14 in R4 (UP)
	LSR R4, R4, #14
	CMP R4, #0
	MOVEQ R1, #0 ; Direction = Up
	AND R4, R3, R0, LSL #15 ; Get PB15 in R4 (Down)
	LSR R4, R4, #3
	CMP R4, #0
	MOVEQ R1, #2 ; Direction = Down
	LDR R0, =DIRECTION
	LDR R2, [R0] ; R2 Has Current Direction and R1 has New Direction
	CMP R2, R1
	SUBGE R3, R2, R1 ; R3 = R2 - R1
	SUBLT R3, R1, R2 ; R3 = R1 - R2
	CMP R3, #2
	BEQ UpdateSnakeDirectionContinue
	LDR R0, =DIRECTION
	STR R1, [R0]
UpdateSnakeDirectionContinue
	POP {R0-R4, PC}
	
GETXY ; Uses the INDEX Variable to Store in LOCATION Variable 0xXXXXYYYY
	PUSH {R0-R6, LR}
	LDR R0, =INDEX
	LDR R1, [R0]
	LSR R2, R1, #16 ; R2 = 0x0000XXXX
	MOV R0, #0x0000FFFF
	MOV R6, #20 ; Size of Block
	AND R3, R0, R1 ; R0 = 0x0000YYYY
	MUL R4, R2, R6 ; R4 = 0x0000XXXX (X Coordinates of the Start)
	ADD R4, R4, #10 ; R4 = 0x0000XXXX (CenterX)
	MUL R5, R3, R6 ; R3 = 0x0000YYYY (Y Coordinates of the Start)
	ADD R5, R5, #10 ; R5 = 0x0000YYYY (CenterY)
	LSL R4, R4, #16 ; R4 = 0xXXXX0000
	ORR R1, R4, R5 ; R1 = 0xXXXXYYYY
	LDR R0, =LOCATION
	STR R1, [R0]
	POP {R0-R6, PC}
	
	
DrawSnake
	B SKIPTHISLINE
	LTORG
SKIPTHISLINE
	PUSH {R0-R11, LR}
	MOV R10, #WHITE ; Color of Snake
	LDR R0, =SIZE
	LDR R1, [R0] ; Length of Blocks
	LDR R0, =BLOCKS
	MOV R2, #0 ; Index of Current Block
	MOV R11, #0x0000FFFF ; Stores Temp Value
DrawSnakeLoop
	CMP R2, R1
	BGE DrawSnakeContinue
	LDR R3, [R0], #4 ; Loads Current Block and Shifts to the next one
	LDR R4, =INDEX
	STR R3, [R4]
	BL GETXY
	LDR R4, =LOCATION
	LDR R3, [R4] ; R3 = 0xXXXXYYYY
	LSR R4, R3, #16 ; Stores X of Block in R4
	AND R5, R3, R11 ; Stores Y of Block in R5
	SUB R6, R4, #10 ; R6 Stores the Start X of Block (CenterX - 10px)
	ADD R8, R4, #10 ; R6 Stores the End X of Block (CenterX + 10px)
	SUB R7, R5, #10 ; R7 Stores the Start Y of Block (CenterY - 10px)
	ADD R9, R5, #10 ; R9 Stores the End Y of Block (CenterY + 10px)
	BL DrawRect
	ADD R2, R2, #1 ; Increment Index
	B DrawSnakeLoop
DrawSnakeContinue
	POP {R0-R11, PC}

DeleteLastBlock
	PUSH {R0-R12, LR}
	; Deletes the Last Block from Screen
	LDR R0, =BLOCKS
	LDR R1, =SIZE
	LDR R2, [R1]
	SUB R2, R2, #1 ; R2 Carries the Last Index
	MOV R11, #4 ; 4 Bytes
	MUL	R2, R2, R11 ; R2 = Last Index by Bytes
	LDR R3, [R0, R2] ; Last Block
	LDR R4, =INDEX
	STR R3, [R4]
	BL GETXY
	LDR R4, =LOCATION
	LDR R3, [R4] ; R3 = 0xXXXXYYYY
	LSR R4, R3, #16 ; R4 = 0x0000XXXX
	MOV R5, #0x0000FFFF ; R5 Stores Temp Value
	AND R11, R3, R5 ; R11 = 0x0000YYYY
	MOV R10, #BLACK
	SUB R6, R4, #10
	ADD R8, R4, #10
	SUB R7, R11, #10
	ADD R9, R11, #10
	BL DrawRect
	POP {R0-R12, PC}

MoveSnake
	PUSH {R0-R5, LR}
	LDR R0, =BLOCKS
	LDR R1, =SIZE
	LDR R2, [R1]
	SUB R2, R2, #1 ; R2 Carries the Last Index
	MOV R5, #4 ; 4 Bytes
	MUL R2, R2, R5 ; R2 Carries Last Index in Bytes
	MOV R5, #0x0000FFFF ; R5 Stores Temp Value
	BL DeleteLastBlock
	; Now The Move Logic
MoveSnakeLoop
	CMP R2, #0
	BLE MoveSnakeContinue
	SUB R3, R2, #4 ; R3 = R2 - 4 (The Previous ELement)
	LDR R4, [R0, R3] ; Get the Previous Element
	STR R4, [R0, R2] ; Now Stores the Previous Element in Current Element (Shifting)
	SUB R2, R2, #4 ; Decrements Index
	B MoveSnakeLoop
MoveSnakeContinue
	LDR R1, [R0] ; R1 Has the Start Element
	LSR R3, R1, #16 ; R3 = 0x0000XXXX (Column)
	AND R4, R1, R5 ; R4 = 0x0000YYYY (Row)
	LDR R0, =DIRECTION
	LDR R2, [R0] ; Gets the Direction in R2
	CMP R2, #0 ; UP
	SUBEQ R4, R4, #1
	CMP R2, #1 ; Left
	SUBEQ R3, R3, #1
	CMP R2, #2 ; Down
	ADDEQ R4, R4, #1
	CMP R2, #3 ; Right
	ADDEQ R3, R3, #1
	LSL R3, R3, #16 ; R3 = 0xXXXX0000
	AND R4, R4, R5 ; R4 = 0x0000YYYY
	ORR R1, R3, R4 ; R1 = 0xXXXXYYYY
	LDR R0, =BLOCKS
	STR R1, [R0]
	POP {R0-R5, PC}
	
EnlargeSnake
	B SKIPTHISLINE2
	LTORG
SKIPTHISLINE2
	PUSH {R0-R1, LR}
	LDR R0, =SIZE
	LDR R1, [R0]
	ADD R1, R1, #1
	STR R1, [R0]
	POP {R0-R1, PC}	
	
DrawFood
	PUSH {R0-R12, LR}
	LDR R0, =FOOD
	LDR R1, [R0]
	LSR R2, R1, #16 ; R2 = 0x0000XXXX (Column)
	MOV R3, #0x0000FFFF ; Temp Value
	AND R4, R3, R1 ; R4 = 0x0000YYYY (Row)
	MOV R0, #20 ; Size of Block
	MUL R2, R2, R0 ; R2 = 0x0000XXXX (StartX)
	ADD R2, R2, #10 ; R2 = 0x0000XXXX (CenterX)
	MUL R4, R4, R0 ; R4 = 0x0000YYYY (StartY)
	ADD R4, R4, #10 ; R4 = 0x0000YYYY (CenterY)
	MOV R3, R4 ; R3 = 0x0000YYYY (CenterY)
	MOV R10, #CYAN
	BL Draw_Ball
	POP {R0-R12, PC}
	
RemoveFood
	PUSH {R0-R12, LR}
	LDR R0, =FOOD
	LDR R1, [R0]
	LSR R2, R1, #16 ; R2 = 0x0000XXXX (Column)
	MOV R3, #0x0000FFFF ; Temp Value
	AND R4, R3, R1 ; R4 = 0x0000YYYY (Row)
	MOV R0, #20 ; Size of Block
	MUL R2, R2, R0 ; R2 = 0x0000XXXX (StartX)
	ADD R2, R2, #10 ; R2 = 0x0000XXXX (CenterX)
	MUL R4, R4, R0 ; R4 = 0x0000YYYY (StartY)
	ADD R4, R4, #10 ; R4 = 0x0000YYYY (CenterY)
	MOV R3, R4 ; R3 = 0x0000YYYY (CenterY)
	MOV R10, #BLACK
	BL Draw_Ball
	POP {R0-R12, PC}
	
;----------------------------------------------------------
; UpdateSeed - Properly randomized version
; Returns: R0 = random value, updates SEED in memory
;----------------------------------------------------------
UpdateSeed
    PUSH {R0-R2, LR}
    BL Get_Random_Seed
	LDR R1, =SEED
    STR R0, [R1]
    POP {R0-R2, PC}
		
GenerateFood
	PUSH {R0-R12, LR}
	; Update Seed
	BL UpdateSeed
	; Generate Random Food
	LDR R1, =SEED
	LDR R0, [R1]
	MOV R1, #ROWS
	BL DIV
	MOV R3, R0 ; R3 = Random Row
	LDR R1, =SEED
	LDR R0, [R1]
	MOV R1, #COLUMNS
	BL DIV
	MOV R4, R0 ; R4 = Random Column
	LSL R4, R4, #16 ; R4 = 0xXXXX0000
	MOV R5, #0x0000FFFF
	AND R3, R3, R5 ; R3 = 0x0000YYYY
	ORR R6, R3, R4 ; R6 = 0xXXXXYYYY
	; Check Blocks
	LDR R0, =SIZE
	LDR R3, [R0] ; Size
	LDR R0, =BLOCKS
	MOV R4, #0 ; Index
GenerateFoodBlocksLoop
	CMP R4, R3
	BGE GenerateFoodBlocksLoopContinue
	LDR R2, [R0], #4 ; Loads in R2 Current Block then Shifts
	CMP R2, R6
	BEQ GenerateFood
	ADD R4, R4, #1 ; Increment Index
	B GenerateFoodBlocksLoop
GenerateFoodBlocksLoopContinue
	LDR R0, =FOOD
	STR R6, [R0]
	POP {R0-R12, PC}

CheckFoodCollision
	PUSH {R0-R12, LR}
	LDR R0, =FOOD
	LDR R1, [R0]
	LDR R0, =BLOCKS
	LDR R2, [R0]
	CMP R2, R1
	BLEQ EnlargeSnake
	; Remove Food
	BLEQ RemoveFood
	; Generate Random Food
	BLEQ GenerateFood
	; Increment Score
	BLEQ IncrementScore
	POP {R0-R12, PC}
	
CheckWallCollision
	PUSH {R0-R6, LR}
	LDR R0, =LOST
	LDR R6, [R0] ; Makes R10 the Old Value of LOST
	LDR R0, =BLOCKS
	LDR R1, [R0]
	LSR R3, R1, #16 ; R3 = 0x0000XXXX (Column)
	MOV R5, #0x0000FFFF
	AND R4, R5, R1 ; R4 = 0x0000YYYY (Row)
	CMP R3, #0
	MOVLT R6, #1
	CMP R3, #COLUMNS
	MOVGE R6, #1
	CMP R4, #0
	MOVLT R6, #1
	CMP R4, #ROWS
	MOVGE R6, #1
	LDR R0, =LOST
	STR R6, [R0]
	POP {R0-R6, PC}
	
CheckSelfCollision
	PUSH {R0-R6, LR}
	LDR R0, =LOST
	LDR R6, [R0] ; Makes R10 the Old Value of LOST
	LDR R0, =BLOCKS
	LDR R1, [R0]
	LDR R0, =SIZE
	LDR R2, [R0]
	SUB R2, R2, #1 ; R2 Carries the Last Index
	MOV R3, #4 ; 4 Bytes
	MUL R2, R2, R3 ; R2 Carries Last Index in Bytes
	LDR R0, =BLOCKS
BlocksLoop
	CMP R2, #0
	BLE BlocksLoopContinue
	LDR R3, [R0, R2] ; R3 = 0xXXXXYYYY
	CMP R1, R3
	MOVEQ R6, #1 ; If The Next Block Will be in the same block of existing block then It's Self Collided
	SUB R2, R2, #4 ; Decrements Index
	B BlocksLoop
BlocksLoopContinue
	LDR R0, =LOST
	STR R6, [R0]
	POP {R0-R6, PC}
	
CheckWin
	PUSH {R0-R2, LR}
	LDR R0, =SIZE
	LDR R1, [R0]
	LDR R0, =WON
	LDR R2, [R0]
	MOV R0, #383
	CMP R1, R0
	MOVEQ R2, #1
	LDR R0, =WON
	STR R2, [R0]
	POP {R0-R2, PC}
