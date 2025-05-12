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
	EXPORT __main
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
	IMPORT COLOR_GREEN
	IMPORT COLOR_BLACK
	; Import Games
	IMPORT BOWLING
	IMPORT BRICKBREAKER
	IMPORT FLAPPYBIRD
	IMPORT FRUITNINJA
	IMPORT HOCKEY
	IMPORT SNAKE
	IMPORT SUBWAY
	IMPORT UNDERTALE
	IMPORT FIREDORTIRED
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
SCOREX EQU 420
SCOREY EQU 280
DELAY_INTERVAL  EQU     0x92400



NUM_GAMES       EQU 9        ; Adjust based on your game count
COLOR_NORMAL    EQU 0X0000     ; BLACK
COLOR_NORAML2    EQU 0xFFFF  ; WHITE
COLOR_SELECTED  EQU 0x0780     ; GREEN
SELECTED_INDEX DCD 0        ; Currently highlighted game
PREVIOUS_INDEX DCD 0




	AREA RESET, CODE, READONLY

__main FUNCTION
GAME_MENU
	; Initialize GPIO
	BL GPIO_INIT
	BL TFT_Init
	BL GAME_INIT
	;BL GLOBAL_RESET_INTERRUPTS
	BL GAME_MENU_LOOP
	
	B .

	LTORG
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
GLOBAL_RESET_INTERRUPTS
    PUSH {R0-R3, LR}
    
    ; 1. Disable all interrupts globally
    CPSID I
    
    ; 2. Clear ALL pending interrupts in NVIC (matching your original style)
    LDR R0, =0xE000E000      ; NVIC_BASE
    LDR R1, =0xFFFFFFFF      ; Clear all pending
    STR R1, [R0, #0x280]     ; ICPR0
    STR R1, [R0, #0x284]     ; ICPR1
    
	
    ; 3. Reset EXTI configuration (like your original but more thorough)
    LDR R0, =0x40013C00      ; EXTI_BASE
    MOV R1, #0x00
    STR R1, [R0, #0x00]      ; IMR - Mask ALL (clear all bits)
    STR R1, [R0, #0x08]      ; RTSR - Disable ALL rising
    STR R1, [R0, #0x0C]      ; FTSR - Disable ALL falling
    LDR R1, =0x0000F000      ; Your original PB12-15 mask + our PB5
    STR R1, [R0, #0x14]      ; PR - Clear pending for PB12-15 and PB5
    
    ; 4. Map EXTI5 to PB5 (using your SYSCFG approach)
    LDR R0, =0x40013800      ; SYSCFG_BASE
    LDR R1, [R0, #0x18]      ; EXTICR2 (for EXTI4-7)
    BIC R1, #0x00F0          ; Clear EXTI5 bits (bits 4-7)
    ORR R1, #0x0010          ; Map PB5 to EXTI5 (0001 << 4)
    STR R1, [R0, #0x18]
    
    ; 5. Configure EXTI5 only (keeping your trigger style)
    LDR R0, =0x40013C00      ; EXTI_BASE
    MOV R1, #(1 << 5)        ; EXTI5 mask only
    STR R1, [R0, #0x0C]      ; FTSR - Falling edge
    STR R1, [R0, #0x00]      ; IMR - Unmask ONLY EXTI5
    
    ; 6. NVIC Configuration (like your original but for EXTI9_5)
    LDR R0, =0xE000E000      ; NVIC_BASE
    ; Set priority to 0 (IPR1 offset 0x304, byte 3)
    MOV R1, #0x00
    STRB R1, [R0, #0x307]    ; EXTI9_5 is IPR[1].byte3
    ; Enable interrupt (ISER0 offset 0x100)
    MOV R1, #(1 << 23)       ; EXTI9_5 is IRQ23
    STR R1, [R0, #0x100]
    
    ; Memory barrier (as in your original)
    DSB
    ISB
    
    ; Re-enable interrupts
    CPSIE I
    
    POP {R0-R3, PC}

	
; Corrected EXTI9_5 Interrupt Handler (PB5 only)
	LTORG
EXTI9_5_IRQHandler
    PUSH {R0-R1, LR}
    
    ; 1. Load PR register and check EXTI5
    LDR R0, =0x40013C00      ; EXTI_BASE
    LDR R1, [R0, #0x14]      ; Load PR register
    TST R1, #(1 << 5)        ; Test EXTI5 bit
    BEQ exit_handler         ; Exit if not our interrupt
    
    ; 2. Clear EXTI5 pending bit
    MOV R1, #(1 << 5)
    STR R1, [R0, #0x14]      ; Clear by writing 1
    
    ; 3. Call GAMEMENU
    BL GAME_MENU
    
	
exit_handler
    POP {R0-R1, PC}
	LTORG
GAME_INIT
	PUSH {R0-R1, LR}
	LDR R0, =SELECTED_INDEX
	MOV R1, #0
	STR R1, [R0]
	BL DrawMenuOptions         ; Draw all options with selection highlight
	POP {R0-R1, PC}
	LTORG
GAME_MENU_LOOP
	BL delay
wait_button_press
    LDR R0, =GPIOB_BASE + GPIO_IDR
	LDR R2, [R0]
    ; Check right button
    TST R2, #(1 << 14)
    BLEQ prev_game
	TST R2, #(1 << 15)
    BLEQ next_game
	BL DrawChangedOptions
    TST R2, #(1 << 3)
    BLEQ  start_game
    B GAME_MENU_LOOP
next_game
    PUSH {R0-R2, LR}
    LDR R0, =SELECTED_INDEX
    LDR R1, [R0]
    LDR R2, =PREVIOUS_INDEX
    STR R1, [R2]              ; Save old index

    ADD R1, R1, #1
    CMP R1, #NUM_GAMES
    MOVGE R1, #0
    STR R1, [R0]
    POP {R0-R2, PC}
prev_game
    PUSH {R0-R2, LR}
    LDR R0, =SELECTED_INDEX
    LDR R1, [R0]
    LDR R2, =PREVIOUS_INDEX
    STR R1, [R2]              ; Save old index

    SUB R1, R1, #1
    CMP R1, #0
    MOVLT R1, #8
    STR R1, [R0]
    POP {R0-R2, PC}
start_game
    LDR R0, =SELECTED_INDEX
    LDR R1, [R0]
	
    CMP R1, #0 ; Snake
	BLEQ SNAKE
	CMP R1, #1 ; Flappy Bird
	BLEQ FLAPPYBIRD
	CMP R1, #2 ; Fruit Ninja
	BLEQ FRUITNINJA
	CMP R1, #3 ; Brick Breaker
	BLEQ BRICKBREAKER
	CMP R1, #4 ; FIRED OR TIRED
	BLEQ FIREDORTIRED	
	CMP R1, #5 ; SUBWAY
	BLEQ SUBWAY
	CMP R1, #6 ; Hockey
	BLEQ HOCKEY
	CMP R1, #7 ; BOWLING
	BLEQ BOWLING
	CMP R1, #8 ; Under Tale
	BLEQ UNDERTALE

DrawChangedOptions
    PUSH {R0-R3, LR}
    
    ; Load current and previous indices
    LDR R0, =SELECTED_INDEX
    LDR R1, [R0]              ; R1 = new index
    LDR R0, =PREVIOUS_INDEX
    LDR R2, [R0]              ; R2 = previous index

    ; Draw previous with normal color
	CMP R2,#5
    MOVLT R10, #COLOR_NORMAL
	CMP R2,#5
    MOVGE R10, #COLOR_NORAML2
    MOV R0, R2
    BL DrawGameOptionByIndex

    ; Draw current with selected color
    MOV R10, #COLOR_SELECTED
    MOV R0, R1
    BL DrawGameOptionByIndex

    POP {R0-R3, PC}

DrawGameOptionByIndex
    ; R0 = index, R10 = color
    CMP R0, #0
    BEQ.W DRAW_SNAKE
    CMP R0, #1
    BEQ.W DRAWFLAPPYBIRD
    CMP R0, #2
    BEQ.W DRAW_FRUIT_NINGA
    CMP R0, #3
    BEQ.W DRAW_BREAK_BREAKER
	CMP R0, #4
    BEQ.W FIRED_OR_TIRED_NAME	
	CMP R0, #5
	BEQ.W DRAW_SUBWAY_NAME
    CMP R0, #6
    BEQ.W DRAW_HOCKEY_NAME
    CMP R0, #7
    BEQ.W DRAW_BOWLING_NAME
    CMP R0, #8
    BEQ.W DRAW_UNDERTALE_NAME
    BX LR
	



	
    B GAME_MENU_LOOP
	
DrawMenuOptions
    PUSH {R0-R12, LR}
	BL Draw_GameMenu
	
    LDR R0, =SELECTED_INDEX
    LDR R1, [R0]       ; Selected index

    MOV R2, #0         ; Game index counter

draw_loop
    CMP R2, #NUM_GAMES
    BGE draw_done
	
    ; Choose color
   
	CMP R2,#5
    MOVLT R10, #COLOR_NORMAL
	CMP R2,#5
    MOVGE R10, #COLOR_NORAML2
	 CMP R1, R2
    MOVEQ R10, #COLOR_SELECTED
    ; Call the appropriate draw function
    CMP R2, #0
    BLEQ DRAW_SNAKE
	CMP R2,#1
	BLEQ DRAWFLAPPYBIRD
	CMP R2,#2
	BLEQ DRAW_FRUIT_NINGA
	CMP R2,#3
	BLEQ DRAW_BREAK_BREAKER
	CMP R2,#4
	BLEQ FIRED_OR_TIRED_NAME	
	CMP R2, #5
	BLEQ.W DRAW_SUBWAY_NAME
	CMP R2,#6
	BLEQ DRAW_HOCKEY_NAME
	CMP R2,#7
	BLEQ DRAW_BOWLING_NAME
	CMP R2,#8
	BLEQ DRAW_UNDERTALE_NAME
	ADD R2, R2, #1
    B draw_loop

draw_done
    POP {R0-R12, PC}
	LTORG

DRAW_SUBWAY_NAME
	PUSH{R1-R12, LR}
	MOV R10, R10
	MOV R6, #280
	MOV R7, #83
	MOV R8, #288
	MOV R9, #85
	BL DrawRect
	;---------------------------------
	MOV R6, #277
	MOV R7, #86
	MOV R8, #279
	MOV R9, #88
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #89
	MOV R8, #285
	MOV R9, #91
	BL DrawRect
	;---------------------------------
	MOV R6, #286
	MOV R7, #92
	MOV R8, #288
	MOV R9, #94
	BL DrawRect
	;---------------------------------
	MOV R6, #277
	MOV R7, #95
	MOV R8, #285
	MOV R9, #97
	BL DrawRect
	;--------------------------------- s DRAWN
	MOV R6, #292
	MOV R7, #83
	MOV R8, #294
	MOV R9, #94
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #95
	MOV R8, #300
	MOV R9, #97
	BL DrawRect
	;---------------------------------
	MOV R6, #301
	MOV R7, #83
	MOV R8, #303
	MOV R9, #94
	BL DrawRect
	;--------------------------------- U DONE
	MOV R6, #307
	MOV R7, #83
	MOV R8, #309
	MOV R9, #97
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #83
	MOV R8, #315
	MOV R9, #85
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #89
	MOV R8, #315
	MOV R9, #91
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #95
	MOV R8, #315
	MOV R9, #97
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #86
	MOV R8, #318
	MOV R9, #88
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #92
	MOV R8, #318
	MOV R9, #94
	BL DrawRect
	;--------------------------------- B DEAWN
	MOV R6, #322
	MOV R7, #83
	MOV R8, #324
	MOV R9, #97
	BL DrawRect
	;---------------------------------
	MOV R6, #325
	MOV R7, #92
	MOV R8, #327
	MOV R9, #94
	BL DrawRect
	;---------------------------------
	MOV R6, #328
	MOV R7, #89
	MOV R8, #330
	MOV R9, #91
	BL DrawRect
	;---------------------------------
	MOV R6, #331
	MOV R7, #92
	MOV R8, #333
	MOV R9, #94
	BL DrawRect
	;---------------------------------
	MOV R6, #334
	MOV R7, #83
	MOV R8, #336
	MOV R9, #97
	BL DrawRect
	;--------------------------------- W DRAWN
	MOV R6, #340
	MOV R7, #86
	MOV R8, #342
	MOV R9, #97
	BL DrawRect
	;---------------------------------
	MOV R6, #343
	MOV R7, #83
	MOV R8, #348
	MOV R9, #85
	BL DrawRect
	;---------------------------------
	MOV R6, #343
	MOV R7, #89
	MOV R8, #348
	MOV R9, #91
	BL DrawRect
	;---------------------------------
	MOV R6, #349
	MOV R7, #86
	MOV R8, #351
	MOV R9, #97
	BL DrawRect
	;--------------------------------- A DRAWN
	MOV R6, #355
	MOV R7, #83
	MOV R8, #357
	MOV R9, #88
	BL DrawRect
	;---------------------------------
	MOV R6, #358
	MOV R7, #89
	MOV R8, #366
	MOV R9, #91
	BL DrawRect
	;---------------------------------
	MOV R6, #367
	MOV R7, #83
	MOV R8, #369
	MOV R9, #88
	BL DrawRect
	;---------------------------------
	MOV R6, #361
	MOV R7, #92
	MOV R8, #363
	MOV R9, #97
	BL DrawRect
	;--------------------------------- SUBWAY DONE
	POP{R1-R12, PC}
	
	
DRAW_HOCKEY_NAME
	PUSH{R1-R12, LR}
	MOV R10, R10
	MOV R6, #277
	MOV R7, #119
	MOV R8, #279
	MOV R9, #133
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #125
	MOV R8, #285
	MOV R9, #127
	BL DrawRect
	;---------------------------------
	MOV R6, #286
	MOV R7, #119
	MOV R8, #288
	MOV R9, #131
	BL DrawRect
	;--------------------------------- H DRAWN
	MOV R6, #292
	MOV R7, #122
	MOV R8, #294
	MOV R9, #130
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #119
	MOV R8, #300
	MOV R9, #121
	BL DrawRect
	;---------------------------------
	MOV R6, #301
	MOV R7, #122
	MOV R8, #303
	MOV R9, #130
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #131
	MOV R8, #300
	MOV R9, #133
	BL DrawRect
	;--------------------------------- O DRAWN
	MOV R6, #307
	MOV R7, #122
	MOV R8, #309
	MOV R9, #130
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #119
	MOV R8, #315
	MOV R9, #121
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #131
	MOV R8, #315
	MOV R9, #133
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #122
	MOV R8, #318
	MOV R9, #124
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #128
	MOV R8, #318
	MOV R9, #130
	BL DrawRect
	;--------------------------------- C DRAWN
	MOV R6, #322
	MOV R7, #119
	MOV R8, #324
	MOV R9, #133
	BL DrawRect
	;---------------------------------
	MOV R6, #325
	MOV R7, #125
	MOV R8, #327
	MOV R9, #127
	BL DrawRect
	;---------------------------------
	MOV R6, #328
	MOV R7, #128
	MOV R8, #330
	MOV R9, #130
	BL DrawRect
	;---------------------------------
	MOV R6, #331
	MOV R7, #131
	MOV R8, #333
	MOV R9, #133
	BL DrawRect
	;---------------------------------
	MOV R6, #328
	MOV R7, #122
	MOV R8, #330
	MOV R9, #124
	BL DrawRect
	;---------------------------------
	MOV R6, #331
	MOV R7, #119
	MOV R8, #333
	MOV R9, #121
	BL DrawRect
	;--------------------------------- K DRAWN
	MOV R6, #337
	MOV R7, #119
	MOV R8, #339
	MOV R9, #133
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #119
	MOV R8, #348
	MOV R9, #121
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #125
	MOV R8, #345
	MOV R9, #127
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #131
	MOV R8, #348
	MOV R9, #133
	BL DrawRect
	;--------------------------------- E DRAWN
	MOV R6, #352
	MOV R7, #119
	MOV R8, #354
	MOV R9, #124
	BL DrawRect
	;---------------------------------
	MOV R6, #355
	MOV R7, #125
	MOV R8, #363
	MOV R9, #127
	BL DrawRect
	;---------------------------------
	MOV R6, #364
	MOV R7, #119
	MOV R8, #366
	MOV R9, #124
	BL DrawRect
	;---------------------------------
	MOV R6, #358
	MOV R7, #128
	MOV R8, #360
	MOV R9, #133
	BL DrawRect
	;--------------------------------- HOCKEY DRAWN
	POP{R1-R12, PC}
	
DRAW_BOWLING_NAME
	PUSH{R1-R12, LR}
	MOV R10,R10
	MOV R6, #277
	MOV R7, #155
	MOV R8, #279
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #155
	MOV R8, #285
	MOV R9, #157
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #161
	MOV R8, #285
	MOV R9, #163
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #167
	MOV R8, #285
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #286
	MOV R7, #158
	MOV R8, #288
	MOV R9, #160
	BL DrawRect
	;---------------------------------
	MOV R6, #286
	MOV R7, #164
	MOV R8, #288
	MOV R9, #166
	BL DrawRect
	;--------------------------------- B DRAWN
	MOV R6, #292
	MOV R7, #158
	MOV R8, #294
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #155
	MOV R8, #300
	MOV R9, #157
	BL DrawRect
	;---------------------------------
	MOV R6, #301
	MOV R7, #158
	MOV R8, #303
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #167
	MOV R8, #300
	MOV R9, #169
	BL DrawRect
	;--------------------------------- O DRAWN
	MOV R6, #307
	MOV R7, #155
	MOV R8, #309
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #164
	MOV R8, #312
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #313
	MOV R7, #161
	MOV R8, #315
	MOV R9, #163
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #164
	MOV R8, #318
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #319
	MOV R7, #155
	MOV R8, #321
	MOV R9, #169
	BL DrawRect
	;--------------------------------- W DRAWN
	MOV R6, #325
	MOV R7, #155
	MOV R8, #327
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #328
	MOV R7, #167
	MOV R8, #336
	MOV R9, #169
	BL DrawRect
	;--------------------------------- L DRAWN
	MOV R6, #340
	MOV R7, #155
	MOV R8, #348
	MOV R9, #157
	BL DrawRect
	;---------------------------------
	MOV R6, #343
	MOV R7, #158
	MOV R8, #345
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #167
	MOV R8, #348
	MOV R9, #169
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #352
	MOV R7, #155
	MOV R8, #354
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #355
	MOV R7, #158
	MOV R8, #357
	MOV R9, #160
	BL DrawRect
	;---------------------------------
	MOV R6, #358
	MOV R7, #161
	MOV R8, #360
	MOV R9, #163
	BL DrawRect
	;---------------------------------
	MOV R6, #361
	MOV R7, #155
	MOV R8, #363
	MOV R9, #169
	BL DrawRect
	;--------------------------------- N DRAWN
	MOV R6, #367
	MOV R7, #158
	MOV R8, #369
	MOV R9, #166
	BL DrawRect
	;---------------------------------
	MOV R6, #370
	MOV R7, #155
	MOV R8, #375
	MOV R9, #157
	BL DrawRect
	;---------------------------------
	MOV R6, #370
	MOV R7, #167
	MOV R8, #375
	MOV R9, #169
	BL DrawRect
	;---------------------------------
	MOV R6, #373
	MOV R7, #161
	MOV R8, #378
	MOV R9, #163
	BL DrawRect
	;---------------------------------
	MOV R6, #376
	MOV R7, #164
	MOV R8, #378
	MOV R9, #166
	BL DrawRect
	;--------------------------------- BOWLING DONE
	POP{R1-R12, PC}
	
DRAW_UNDERTALE_NAME 
	PUSH{R1-R12, LR}
	MOV R10, R10
	MOV R6, #277
	MOV R7, #191
	MOV R8, #279
	MOV R9, #202
	BL DrawRect
	;---------------------------------
	MOV R6, #280
	MOV R7, #203
	MOV R8, #285
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #286
	MOV R7, #191
	MOV R8, #288
	MOV R9, #202
	BL DrawRect
	;--------------------------------- U DONE
	MOV R6, #291
	MOV R7, #191
	MOV R8, #294
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #295
	MOV R7, #194
	MOV R8, #297
	MOV R9, #196
	BL DrawRect
	;---------------------------------
	MOV R6, #298
	MOV R7, #197
	MOV R8, #300
	MOV R9, #199
	BL DrawRect
	;---------------------------------
	MOV R6, #301
	MOV R7, #191
	MOV R8, #303
	MOV R9, #205
	BL DrawRect
	;--------------------------------- N DONE
	MOV R6, #307
	MOV R7, #191
	MOV R8, #309
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #191
	MOV R8, #315
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #310
	MOV R7, #203
	MOV R8, #315
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #316
	MOV R7, #194
	MOV R8, #318
	MOV R9, #202
	BL DrawRect
	;---------------------------------D DONE
	MOV R6, #322
	MOV R7, #191
	MOV R8, #333
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #322
	MOV R7, #191
	MOV R8, #324
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #325
	MOV R7, #197
	MOV R8, #330
	MOV R9, #199
	BL DrawRect
	;---------------------------------
	MOV R6, #325
	MOV R7, #203
	MOV R8, #333
	MOV R9, #205
	BL DrawRect
	;--------------------------------- E DONE
	MOV R6, #337
	MOV R7, #191
	MOV R8, #339
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #191
	MOV R8, #345
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #340
	MOV R7, #197
	MOV R8, #345
	MOV R9, #199
	BL DrawRect
	;---------------------------------
	MOV R6, #343
	MOV R7, #200
	MOV R8, #345
	MOV R9, #202
	BL DrawRect
	;---------------------------------
	MOV R6, #346
	MOV R7, #203
	MOV R8, #348
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #346
	MOV R7, #194
	MOV R8, #348
	MOV R9, #196
	BL DrawRect
	;--------------------------------- R DONE
	MOV R6, #352
	MOV R7, #191
	MOV R8, #366
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #358
	MOV R7, #194
	MOV R8, #360
	MOV R9, #205
	BL DrawRect
	;--------------------------------- T DONE
	MOV R6, #370
	MOV R7, #194
	MOV R8, #372
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #373
	MOV R7, #191
	MOV R8, #378
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #373
	MOV R7, #197
	MOV R8, #378
	MOV R9, #199
	BL DrawRect
	;---------------------------------
	MOV R6, #379
	MOV R7, #194
	MOV R8, #381
	MOV R9, #205
	BL DrawRect
	;--------------------------------- A DONE
	MOV R6, #385
	MOV R7, #191
	MOV R8, #387
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #388
	MOV R7, #203
	MOV R8, #396
	MOV R9, #205
	BL DrawRect
	;--------------------------------- L DONE
	MOV R6, #400
	MOV R7, #191
	MOV R8, #402
	MOV R9, #205
	BL DrawRect
	;---------------------------------
	MOV R6, #403
	MOV R7, #191
	MOV R8, #411
	MOV R9, #193
	BL DrawRect
	;---------------------------------
	MOV R6, #403
	MOV R7, #197
	MOV R8, #408
	MOV R9, #199
	BL DrawRect
	;---------------------------------
	MOV R6, #403
	MOV R7, #203
	MOV R8, #411
	MOV R9, #205
	BL DrawRect
	;--------------------------------- UNDERTALE DONE
	POP{R1-R12, PC}
	LTORG
DRAW_SNAKE 
	PUSH{R0-R12, LR}
	MOV R10,R10
	MOV R6, #26
	MOV R7, #88
	MOV R8, #28
	MOV R9, #90
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #85
	MOV R8, #37
	MOV R9, #87
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #91
	MOV R8, #34
	MOV R9, #93
	BL DrawRect
	;---------------------------------
	MOV R6, #35
	MOV R7, #94
	MOV R8, #37
	MOV R9, #96
	BL DrawRect
	;---------------------------------
	MOV R6, #26
	MOV R7, #97
	MOV R8, #34
	MOV R9, #99
	BL DrawRect
	;--------------------------------- S DRAWN
	MOV R6, #41
	MOV R7, #85
	MOV R8, #43
	MOV R9, #99
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #88
	MOV R8, #46
	MOV R9, #90
	BL DrawRect
	;---------------------------------
	MOV R6, #47
	MOV R7, #91
	MOV R8, #49
	MOV R9, #93
	BL DrawRect
	;---------------------------------
	MOV R6, #50
	MOV R7, #85
	MOV R8, #52
	MOV R9, #99
	BL DrawRect
	;---------------------------------N DRAWN
	MOV R6, #56
	MOV R7, #88
	MOV R8, #58
	MOV R9, #99
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #85
	MOV R8, #64
	MOV R9, #87
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #91
	MOV R8, #64
	MOV R9, #93
	BL DrawRect
	;---------------------------------
	MOV R6, #65
	MOV R7, #88
	MOV R8, #67
	MOV R9, #99
	BL DrawRect
	;--------------------------------- A DRAWN
	MOV R6, #71
	MOV R7, #85
	MOV R8, #73
	MOV R9, #99
	BL DrawRect
	;---------------------------------
	MOV R6, #74
	MOV R7, #91
	MOV R8, #76
	MOV R9, #93
	BL DrawRect
	;---------------------------------
	MOV R6, #77
	MOV R7, #88
	MOV R8, #79
	MOV R9, #90
	BL DrawRect
	;---------------------------------
	MOV R6, #80
	MOV R7, #85
	MOV R8, #82
	MOV R9, #87
	BL DrawRect
	;---------------------------------
	MOV R6, #77
	MOV R7, #94
	MOV R8, #79
	MOV R9, #96
	BL DrawRect
	;---------------------------------
	MOV R6, #80
	MOV R7, #97
	MOV R8, #82
	MOV R9, #99
	BL DrawRect
	;--------------------------------- K DRAWN
	MOV R6, #86
	MOV R7, #85
	MOV R8, #88
	MOV R9, #99
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #85
	MOV R8, #97
	MOV R9, #87
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #91
	MOV R8, #94
	MOV R9, #93
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #97
	MOV R8, #97
	MOV R9, #99
	BL DrawRect
	;--------------------------------- SNAKE DRAWN
	POP{R0-R12, PC}
	
DRAWFLAPPYBIRD 
	PUSH{R1-R12, LR}
	
	MOV R10,R10
	MOV R6, #26
	MOV R7, #121
	MOV R8, #28
	MOV R9, #135
	BL DrawRect
	;----------------------------------
	MOV R6, #29
	MOV R7, #121
	MOV R8, #37
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #127
	MOV R8, #34
	MOV R9, #129
	BL DrawRect
	;--------------------------------- F drawn
	MOV R6, #41
	MOV R7, #121
	MOV R8, #43
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #133
	MOV R8, #52
	MOV R9, #135
	BL DrawRect
	;--------------------------------- L drawn
	MOV R6, #56
	MOV R7, #124
	MOV R8, #58
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #127
	MOV R8, #64
	MOV R9, #129
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #121
	MOV R8, #64
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #65
	MOV R7, #124
	MOV R8, #67
	MOV R9, #135
	BL DrawRect
	;--------------------------------- A drawn
	MOV R6, #71
	MOV R7, #121
	MOV R8, #73
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #74
	MOV R7, #121
	MOV R8, #79
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #74
	MOV R7, #127
	MOV R8, #79
	MOV R9, #129
	BL DrawRect
	;---------------------------------
	MOV R6, #80
	MOV R7, #124
	MOV R8, #82
	MOV R9, #126
	BL DrawRect
	;--------------------------------- p drawn
	MOV R6, #86
	MOV R7, #121
	MOV R8, #88
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #121
	MOV R8, #94
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #95
	MOV R7, #124
	MOV R8, #97
	MOV R9, #126
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #127
	MOV R8, #94
	MOV R9, #129
	BL DrawRect
	;--------------------------------- p drawn
	MOV R6, #101
	MOV R7, #121
	MOV R8, #103
	MOV R9, #126
	BL DrawRect
	;---------------------------------
	MOV R6, #104
	MOV R7, #127
	MOV R8, #112
	MOV R9, #129
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #130
	MOV R8, #109
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #113
	MOV R7, #121
	MOV R8, #115
	MOV R9, #126
	BL DrawRect
	;--------------------------------- y drawn
	MOV R6, #125
	MOV R7, #121
	MOV R8, #127
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #121
	MOV R8, #133
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #127
	MOV R8, #133
	MOV R9, #129
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #133
	MOV R8, #133
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #134
	MOV R7, #124
	MOV R8, #136
	MOV R9, #126
	BL DrawRect
	;---------------------------------
	MOV R6, #134
	MOV R7, #130
	MOV R8, #136
	MOV R9, #132
	BL DrawRect
	;--------------------------------- B drawn
	MOV R6, #140
	MOV R7, #121
	MOV R8, #148
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #143
	MOV R7, #124
	MOV R8, #145
	MOV R9, #132
	BL DrawRect
	;---------------------------------
	MOV R6, #140
	MOV R7, #133
	MOV R8, #148
	MOV R9, #135
	BL DrawRect
	;--------------------------------- I drawn
	MOV R6, #152
	MOV R7, #121
	MOV R8, #154
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #155
	MOV R7, #121
	MOV R8, #160
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #155
	MOV R7, #127
	MOV R8, #160
	MOV R9, #129
	BL DrawRect
	;---------------------------------
	MOV R6, #158
	MOV R7, #130
	MOV R8, #160
	MOV R9, #132
	BL DrawRect
	;---------------------------------
	MOV R6, #161
	MOV R7, #124
	MOV R8, #163
	MOV R9, #126
	BL DrawRect
	;---------------------------------
	MOV R6, #161
	MOV R7, #133
	MOV R8, #163
	MOV R9, #135
	BL DrawRect
	;--------------------------------- R drawn
	MOV R6, #167
	MOV R7, #121
	MOV R8, #169
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #170
	MOV R7, #121
	MOV R8, #175
	MOV R9, #123
	BL DrawRect
	;---------------------------------
	MOV R6, #170
	MOV R7, #133
	MOV R8, #175
	MOV R9, #135
	BL DrawRect
	;---------------------------------
	MOV R6, #176
	MOV R7, #124
	MOV R8, #178
	MOV R9, #132
	BL DrawRect
	;--------------------------------- fLAPPY BIRD DRAWN
	POP{R1-R12, PC}
	
		
DRAW_FRUIT_NINGA 
	PUSH{R1-R12, LR}
	MOV R10,R10
	MOV R6, #26
	MOV R7, #157
	MOV R8, #28
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #157
	MOV R8, #37
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #163
	MOV R8, #34
	MOV R9, #165
	BL DrawRect
	;---------------------------------F DRAWN
	MOV R6, #41
	MOV R7, #157
	MOV R8, #43
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #157
	MOV R8, #49
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #163
	MOV R8, #49
	MOV R9, #165
	BL DrawRect
	;---------------------------------
	MOV R6, #47
	MOV R7, #166
	MOV R8, #49
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #50
	MOV R7, #160
	MOV R8, #52
	MOV R9, #162
	BL DrawRect
	;---------------------------------
	MOV R6, #50
	MOV R7, #169
	MOV R8, #52
	MOV R9, #171
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #56
	MOV R7, #157
	MOV R8, #58
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #169
	MOV R8, #64
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #65
	MOV R7, #157
	MOV R8, #67
	MOV R9, #168
	BL DrawRect
	;--------------------------------- U DRAWN
	MOV R6, #71
	MOV R7, #157
	MOV R8, #79
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #74
	MOV R7, #160
	MOV R8, #76
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #71
	MOV R7, #169
	MOV R8, #79
	MOV R9, #171
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #83
	MOV R7, #157
	MOV R8, #97
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #160
	MOV R8, #91
	MOV R9, #171
	BL DrawRect
	;--------------------------------- T DRAWN 
	MOV R6, #107
	MOV R7, #157
	MOV R8, #109
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #110
	MOV R7, #160
	MOV R8, #112
	MOV R9, #162
	BL DrawRect
	;---------------------------------
	MOV R6, #113
	MOV R7, #163
	MOV R8, #115
	MOV R9, #165
	BL DrawRect
	;---------------------------------
	MOV R6, #116
	MOV R7, #157
	MOV R8, #118
	MOV R9, #171
	BL DrawRect
	;--------------------------------- n DRAWN
	MOV R6, #122
	MOV R7, #157
	MOV R8, #130
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #125
	MOV R7, #160
	MOV R8, #127
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #122
	MOV R7, #169
	MOV R8, #130
	MOV R9, #171
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #134
	MOV R7, #157
	MOV R8, #136
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #137
	MOV R7, #160
	MOV R8, #139
	MOV R9, #162
	BL DrawRect
	;---------------------------------
	MOV R6, #140
	MOV R7, #163
	MOV R8, #142
	MOV R9, #165
	BL DrawRect
	;---------------------------------
	MOV R6, #143
	MOV R7, #157
	MOV R8, #145
	MOV R9, #171
	BL DrawRect
	;--------------------------------- N DRAWN
	MOV R6, #149
	MOV R7, #160
	MOV R8, #151
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #152
	MOV R7, #157
	MOV R8, #157
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #152
	MOV R7, #169
	MOV R8, #157
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #158
	MOV R7, #166
	MOV R8, #160
	MOV R9, #168
	BL DrawRect
	;---------------------------------
	MOV R6, #155
	MOV R7, #163
	MOV R8, #160
	MOV R9, #165
	BL DrawRect
	;--------------------------------- G DRAWN
	MOV R6, #164
	MOV R7, #160
	MOV R8, #166
	MOV R9, #171
	BL DrawRect
	;---------------------------------
	MOV R6, #167
	MOV R7, #157
	MOV R8, #172
	MOV R9, #159
	BL DrawRect
	;---------------------------------
	MOV R6, #167
	MOV R7, #163
	MOV R8, #172
	MOV R9, #165
	BL DrawRect
	;---------------------------------
	MOV R6, #173
	MOV R7, #160
	MOV R8, #175
	MOV R9, #171
	BL DrawRect
	;--------------------------------- FRUIT NINGA DRAWN
	POP{R1-R12, PC}
	
		
DRAW_BREAK_BREAKER 
	PUSH{R1-R12, LR}
	MOV R10,R10
	MOV R6, #26
	MOV R7, #193
	MOV R8, #28
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #193
	MOV R8, #34
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #199
	MOV R8, #34
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #205
	MOV R8, #34
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #35
	MOV R7, #196
	MOV R8, #37
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #35
	MOV R7, #202
	MOV R8, #37
	MOV R9, #204
	BL DrawRect
	;--------------------------------- B DRAWN
	MOV R6, #41
	MOV R7, #193
	MOV R8, #43
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #193
	MOV R8, #49
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #199
	MOV R8, #49
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #47
	MOV R7, #202
	MOV R8, #49
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #50
	MOV R7, #205
	MOV R8, #52
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #50
	MOV R7, #196
	MOV R8, #52
	MOV R9, #198
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #56
	MOV R7, #193
	MOV R8, #64
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #196
	MOV R8, #61
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #56
	MOV R7, #205
	MOV R8, #64
	MOV R9, #207
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #68
	MOV R7, #196
	MOV R8, #70
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #71
	MOV R7, #193
	MOV R8, #76
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #71
	MOV R7, #205
	MOV R8, #76
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #77
	MOV R7, #196
	MOV R8, #79
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #77
	MOV R7, #202
	MOV R8, #79
	MOV R9, #204
	BL DrawRect
	;--------------------------------- C DRAWN
	MOV R6, #83
	MOV R7, #193
	MOV R8, #85
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #86
	MOV R7, #199
	MOV R8, #88
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #196
	MOV R8, #91
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #92
	MOV R7, #193
	MOV R8, #94
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #89
	MOV R7, #202
	MOV R8, #91
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #92
	MOV R7, #205
	MOV R8, #94
	MOV R9, #207
	BL DrawRect
	;--------------------------------- K DRAWN
	MOV R6, #104
	MOV R7, #193
	MOV R8, #106
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #193
	MOV R8, #112
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #199
	MOV R8, #112
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #113
	MOV R7, #196
	MOV R8, #115
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #205
	MOV R8, #112
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #113
	MOV R7, #202
	MOV R8, #115
	MOV R9, #204
	BL DrawRect
	;--------------------------------- B DRAWN
	MOV R6, #119
	MOV R7, #193
	MOV R8, #121
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #122
	MOV R7, #193
	MOV R8, #127
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #122
	MOV R7, #199
	MOV R8, #127
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #125
	MOV R7, #202
	MOV R8, #127
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #196
	MOV R8, #130
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #205
	MOV R8, #130
	MOV R9, #207
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #134
	MOV R7, #193
	MOV R8, #136
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #137
	MOV R7, #193
	MOV R8, #145
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #137
	MOV R7, #199
	MOV R8, #142
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #137
	MOV R7, #205
	MOV R8, #145
	MOV R9, #207
	BL DrawRect
	;--------------------------------- E DRAWN
	MOV R6, #149
	MOV R7, #196
	MOV R8, #151
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #152
	MOV R7, #193
	MOV R8, #157
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #152
	MOV R7, #199
	MOV R8, #157
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #158
	MOV R7, #196
	MOV R8, #160
	MOV R9, #207
	BL DrawRect
	;--------------------------------- A DRAWN
	MOV R6, #164
	MOV R7, #193
	MOV R8, #166
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #167
	MOV R7, #199
	MOV R8, #169
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #170
	MOV R7, #196
	MOV R8, #172
	MOV R9, #198
	BL DrawRect
	;---------------------------------
	MOV R6, #173
	MOV R7, #193
	MOV R8, #175
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #170
	MOV R7, #202
	MOV R8, #172
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #173
	MOV R7, #205
	MOV R8, #175
	MOV R9, #207
	BL DrawRect
	;--------------------------------- K DRAWN
	MOV R6, #179
	MOV R7, #193
	MOV R8, #190
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #179
	MOV R7, #193
	MOV R8, #181
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #182
	MOV R7, #199
	MOV R8, #187
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #180
	MOV R7, #205
	MOV R8, #190
	MOV R9, #207
	BL DrawRect
	;--------------------------------- E DRAWN
	MOV R6, #194
	MOV R7, #193
	MOV R8, #196
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #197
	MOV R7, #193
	MOV R8, #202
	MOV R9, #195
	BL DrawRect
	;---------------------------------
	MOV R6, #197
	MOV R7, #199
	MOV R8, #202
	MOV R9, #201
	BL DrawRect
	;---------------------------------
	MOV R6, #200
	MOV R7, #202
	MOV R8, #202
	MOV R9, #204
	BL DrawRect
	;---------------------------------
	MOV R6, #203
	MOV R7, #205
	MOV R8, #205
	MOV R9, #207
	BL DrawRect
	;---------------------------------
	MOV R6, #203
	MOV R7, #196
	MOV R8, #205
	MOV R9, #198
	BL DrawRect
	;--------------------------------- BREAK BREAKER DRAWN
	POP{R1-R12, PC}

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
	
Draw_GameMenu 
	PUSH{R1-R12, LR}
	LDR R10, =WHITE
	MOV R6, #0
	MOV R8, #240
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;---------------------------
	LDR R10, =BLACK
	MOV R6, #240
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;----------BACKGROUND DRAWN
	LDR R10, =BLACK
	MOV R6, #153
	MOV R8, #160
	MOV R7, #24
	MOV R9, #27
	BL DrawRect
	;---------------------- 
	LDR R10, =BLACK
	MOV R6, #149
	MOV R8, #152
	MOV R7, #28
	MOV R9, #39
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #153
	MOV R8, #160
	MOV R7, #40
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #161
	MOV R8, #164
	MOV R7, #32
	MOV R9, #39
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #157
	MOV R8, #160
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;---------------------- G done
	LDR R10, =BLACK
	MOV R6, #169
	MOV R8, #172
	MOV R7, #28
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #173
	MOV R8, #180
	MOV R7, #24
	MOV R9, #27
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #173
	MOV R8, #180
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #181
	MOV R8, #184
	MOV R7, #28
	MOV R9, #43
	BL DrawRect
	;----------------------A done
	LDR R10, =BLACK
	MOV R6, #189
	MOV R8, #192
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #193
	MOV R8, #196
	MOV R7, #28
	MOV R9, #31
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #197
	MOV R8, #200
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #201
	MOV R8, #204
	MOV R7, #28
	MOV R9, #31
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #205
	MOV R8, #208
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------M done
	LDR R10, =BLACK
	MOV R6, #213
	MOV R8, #216
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #217
	MOV R8, #228
	MOV R7, #24
	MOV R9, #27
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #217
	MOV R8, #224
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =BLACK
	MOV R6, #217
	MOV R8, #228
	MOV R7, #40
	MOV R9, #43
	BL DrawRect
	;----------------------E done
	LDR R10, =WHITE
	MOV R6, #257
	MOV R8, #260
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #261
	MOV R8, #264
	MOV R7, #28
	MOV R9, #31
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #265
	MOV R8, #268
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #269
	MOV R8, #272
	MOV R7, #28
	MOV R9, #31
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #273
	MOV R8, #276
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------M done
	LDR R10, =WHITE
	MOV R6, #281
	MOV R8, #284
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #285
	MOV R8, #296
	MOV R7, #24
	MOV R9, #27
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #285
	MOV R8, #292
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #285
	MOV R8, #296
	MOV R7, #40
	MOV R9, #43
	BL DrawRect
	;---------------------- E done
	LDR R10, =WHITE
	MOV R6, #301
	MOV R8, #304
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #305
	MOV R8, #308
	MOV R7, #28
	MOV R9, #31
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #309
	MOV R8, #312
	MOV R7, #32
	MOV R9, #35
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #313
	MOV R8, #316
	MOV R7, #24
	MOV R9, #43
	BL DrawRect
	;---------------------- N done
	LDR R10, =WHITE
	MOV R6, #321
	MOV R8, #324
	MOV R7, #24
	MOV R9, #39
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #325
	MOV R8, #332
	MOV R7, #40
	MOV R9, #43
	BL DrawRect
	;----------------------
	LDR R10, =WHITE
	MOV R6, #333
	MOV R8, #336
	MOV R7, #24
	MOV R9, #39
	BL DrawRect
	;----------------------U done
	POP{R1-R12, PC}
	
		
FIRED_OR_TIRED_NAME 
	PUSH{R1-R12, LR}
	MOV R10, R10
	MOV R6, #26
	MOV R7, #229
	MOV R8, #28
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #235
	MOV R8, #34
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #29
	MOV R7, #229
	MOV R8, #37
	MOV R9, #231
	BL DrawRect
	;--------------------------------- F DRAWN
	MOV R6, #41
	MOV R7, #229
	MOV R8, #49
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #44
	MOV R7, #232
	MOV R8, #46
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #41
	MOV R7, #241
	MOV R8, #49
	MOV R9, #243
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #53
	MOV R7, #229
	MOV R8, #55
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #56
	MOV R7, #229
	MOV R8, #61
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #62
	MOV R7, #232
	MOV R8, #64
	MOV R9, #234
	BL DrawRect
	;---------------------------------
	MOV R6, #56
	MOV R7, #235
	MOV R8, #61
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #62
	MOV R7, #241
	MOV R8, #64
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #59
	MOV R7, #238
	MOV R8, #61
	MOV R9, #240
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #68
	MOV R7, #229
	MOV R8, #79
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #68
	MOV R7, #229
	MOV R8, #70
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #71
	MOV R7, #235
	MOV R8, #76
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #71
	MOV R7, #241
	MOV R8, #79
	MOV R9, #243
	BL DrawRect
	;--------------------------------- E DRAWN
	MOV R6, #83
	MOV R7, #229
	MOV R8, #85
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #86
	MOV R7, #229
	MOV R8, #91
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #92
	MOV R7, #232
	MOV R8, #94
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #86
	MOV R7, #241
	MOV R8, #91
	MOV R9, #243
	BL DrawRect
	;--------------------------------- D DRAWN
	MOV R6, #104
	MOV R7, #232
	MOV R8, #106
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #229
	MOV R8, #112
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #107
	MOV R7, #241
	MOV R8, #112
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #113
	MOV R7, #232
	MOV R8, #115
	MOV R9, #240
	BL DrawRect
	;--------------------------------- O DRAWN
	MOV R6, #119
	MOV R7, #229
	MOV R8, #121
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #122
	MOV R7, #229
	MOV R8, #127
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #232
	MOV R8, #130
	MOV R9, #234
	BL DrawRect
	;---------------------------------
	MOV R6, #122
	MOV R7, #235
	MOV R8, #127
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #125
	MOV R7, #238
	MOV R8, #127
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #128
	MOV R7, #241
	MOV R8, #130
	MOV R9, #243
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #140
	MOV R7, #229
	MOV R8, #154
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #146
	MOV R7, #232
	MOV R8, #148
	MOV R9, #243
	BL DrawRect
	;--------------------------------- T DRAWN
	MOV R6, #158
	MOV R7, #229
	MOV R8, #166
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #161
	MOV R7, #232
	MOV R8, #163
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #158
	MOV R7, #241
	MOV R8, #166
	MOV R9, #243
	BL DrawRect
	;--------------------------------- I DRAWN
	MOV R6, #170
	MOV R7, #229
	MOV R8, #172
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #173
	MOV R7, #229
	MOV R8, #178
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #179
	MOV R7, #232
	MOV R8, #181
	MOV R9, #234
	BL DrawRect
	;---------------------------------
	MOV R6, #173
	MOV R7, #235
	MOV R8, #178
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #176
	MOV R7, #238
	MOV R8, #178
	MOV R9, #240
	BL DrawRect
	;---------------------------------
	MOV R6, #179
	MOV R7, #241
	MOV R8, #181
	MOV R9, #243
	BL DrawRect
	;--------------------------------- R DRAWN
	MOV R6, #185
	MOV R7, #229
	MOV R8, #187
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #188
	MOV R7, #229
	MOV R8, #196
	MOV R9, #231
	BL DrawRect
	;--------------------------------
	MOV R6, #188
	MOV R7, #235
	MOV R8, #193
	MOV R9, #237
	BL DrawRect
	;---------------------------------
	MOV R6, #188
	MOV R7, #241
	MOV R8, #196
	MOV R9, #243
	BL DrawRect
	;--------------------------------- E DRAWN
	MOV R6, #200
	MOV R7, #229
	MOV R8, #202
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #203
	MOV R7, #229
	MOV R8, #208
	MOV R9, #231
	BL DrawRect
	;---------------------------------
	MOV R6, #203
	MOV R7, #241
	MOV R8, #208
	MOV R9, #243
	BL DrawRect
	;---------------------------------
	MOV R6, #209
	MOV R7, #232
	MOV R8, #211
	MOV R9, #240
	BL DrawRect
	;--------------------------------- FIRED OR TIRED DONE
	POP{R1-R12, PC}	
	
	
	
	
	ENDFUNC
	END