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
	IMPORT delay
	IMPORT COLOR_BLACK
	IMPORT DIV
	IMPORT Get_Random_Seed
	IMPORT COLOR_WHITE
	IMPORT COLOR_RED
	IMPORT SET_SCORE
	IMPORT CLEAR_COLOR
	EXPORT UNDERTALE
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
; Variables
SPEAR_SPEED  EQU 3
HEALTH DCD 80
	
rand_seed DCD 0x12345678   ; Initial seed (can be any non-zero value)
SCORE DCD 0

;the starting points of the four positins of shield(up, down, left, right) are fixed along thegame
;when the square is drawn those points will be known
;those the status of shield will be(0:up, 1:down, 2:right, 3:left)
SHIELDSTATUS DCD 0

ATTACK DCD 0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF  ; 0xIDDDD (I = Inversion, D = Distance)
ATTACK_STATUS DCD 0,0,0,0,0,0,0,0 ; direction point (0xD , 0 is up,1 is right , 2 is down , 3 is left)
TIMER DCD 0;
;Basically the idea is that any spear can be spawned in any 4 cardinal directions, thus the spear needs to simply store which direction
;it is going to set it's start position and thus move away from it using SPEAR DISTANCE

;Constants for player
MAX_HEALTH EQU 80
SPEAR_Y EQU 120 ; place holder for starting X,Y depending on where the spear is coming from (1/2 the row or 1/2 the column)
SPEAR_X EQU 208	;Place Holder


MAXDIST_X EQU 189 ;  maximum distance Spear can move
MAXDIST_Y EQU 114 ;

;array of Objects to spawn Coordinates are in X,Y

    AREA MYCODE, CODE, READONLY ; Read-only data section 

incrementScore
	PUSH{R0-R12,LR}
	LDR R0, =SCORE
	LDR R1, [R0]
	ADD R1, R1, #1
	STR R1, [R0]
	MOV R11, #400
	MOV R12, #20
	MOV R10, #BLACK	
	BL SCORE_INIT
	BL CLEAR_COLOR
	LDR R0, =SCORE
	LDR R0, [R0]
	BL SET_SCORE
	POP{R0-R12,PC}
decrementHealth
	PUSH{R0-R12,LR}
	LDR R0, =HEALTH
	LDR R1, [R0]
	SUB R1, R1, #10
	STR R1, [R0]
	CMP R1, #0
	BLE.W GAMEENDED
	MOV R11, #400
	MOV R12, #260
	MOV R10, #BLACK	
	BL SCORE_INIT
	BL CLEAR_COLOR
	LDR R0, =HEALTH
	LDR R0, [R0]
	BL SET_SCORE
	POP{R0-R12,PC}

DrawScoreUpRight
	PUSH{R0-R12,LR}
	MOV R11, #400
	MOV R12, #20
	MOV R10, #BLACK	
	BL SCORE_INIT
	LDR R0, =SCORE
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_WHITE
	POP{R0-R12,PC}
DrawHealthDownRight
	PUSH{R0-R12,LR}
	LDR R0, =HEALTH
	MOV R11, #400
	MOV R12, #260
	MOV R10, #BLACK	
	BL SCORE_INIT
	LDR R0, =HEALTH
	LDR R0, [R0]
	BL SET_SCORE
	BL COLOR_RED
	POP{R0-R12,PC}
	LTORG	
UNDERTALE
	MOV R11, #420
	MOV R12, #20
	MOV R10, #BLACK
	BL SCORE_INIT
	BL TFT_FillScreen
	BL GAME_INIT
	;Prototype game as proof of concept (Just deflect the spears, no score, no health,no enemy, simply detect a gameover if hit)
Mainloop
	BL DrawScoreUpRight
	BL DrawHealthDownRight
	BL ChangeState
	BL Redraw
	B Mainloop
    
ChangeState
	PUSH{R0-R12,LR}
	BL SHIELDMOVEMENT
	MOV R2, #0
	LDR R0, =TIMER
	LDR R0, [R0]
	MOV R3, R0
	MOV R1, #100
	BL DIV
	CMP R0, #0
	MOVEQ R2, #1
	LDR R0, =TIMER 
	ADD R3, R3, #1
	STR R3, [R0]
	MOV R3, #0
	BL Get_Random_Seed
	MOV R1, #5
	BL DIV
	CMP R0, #0
	MOVEQ R3, #1
	AND R4, R2, R3
	CMP R4, #1
	BLEQ SPAWNSPEAR
	BL DetectGameEnd
	
	POP{R0-R12,PC}

	
	
	

Redraw
	PUSH{R0-R12,LR}
	
	BL MOVEMENT
	BL GameHeartShield
	POP{R0-R12,PC}
	;4 STARTING POINTS FOR 4 SHIELD POSITIONS AGREED LATER
SHIELDMOVEMENT
    PUSH{R0-R12,LR}
    LDR R0, =SHIELDSTATUS;INITIALLY UP
    LDR R1, =GPIOB_BASE + GPIO_IDR
CHANGESTAT    ;CHANGE STAT BASED ON BUTTONS CLICKED
    LDR R2, [R0]
    LDR R3, [R1]

	   
	
    ;SHADE OLD POS
	CMP R2, #0
    MOV R11, #225
    MOV R12, #100
    LDR R10, =BLACK
    BLNE DRAWSHIELDUPDOWN
    CMP R2, #1
    MOV R11, #225
    MOV R12, #185
    LDR R10, =BLACK
    BLNE DRAWSHIELDUPDOWN
    CMP    R2, #2
    MOV R11, #180
    MOV R12, #145
    LDR R10, =BLACK
    BLNE DRAWSHIELDLEFTRIGHT
    CMP R2, #3
    MOV R11, #270
    MOV R12, #145
    LDR R10, =BLACK
    BLNE DRAWSHIELDLEFTRIGHT
    TST R3, #(1 << 14);CHECK UP BUTTON PB14
    MOVEQ R4, #0
    STREQ R4, [R0]
	LDR R2, [R0]
	CMP R2, #0
    MOVEQ R11, #225
    MOVEQ R12, #100
    LDREQ R10, =GREEN
    BLEQ DRAWSHIELDUPDOWN
   
    
    TST R3, #(1 << 15);PB15 DOWN CHECK
	MOVEQ R4, #1 
    STREQ R4, [R0]
	LDR R2, [R0]
	CMP R2, #1
    MOVEQ R11,#225
    MOVEQ R12,#185
    LDREQ R10, =GREEN
    BLEQ DRAWSHIELDUPDOWN
  
    TST R3, #(1 << 13);PB13 LEFT CHECK
	MOVEQ R4, #2
    STREQ R4, [R0]
	LDR R2, [R0]
	CMP R2, #2
    MOVEQ R11,#180
    MOVEQ R12, #145
    LDREQ R10, =GREEN
    BLEQ DRAWSHIELDLEFTRIGHT
 
    TST R3, #(1 << 12);PB12 RIGHT CHECK
	MOVEQ R4, #3
    STREQ R4, [R0]
	LDR R2, [R0]
	CMP R2, #3
    MOVEQ R11,#270
    MOVEQ R12,#145
    LDREQ R10, =GREEN
    BLEQ DRAWSHIELDLEFTRIGHT

CHECKFINISHED    
    POP{R0-R12,PC}

	
	;TAKES IN R11, R12 FOR POS AND A COLOR R10
	; Takes R11, R12 = X, Y (Center)
DRAWSHIELDUPDOWN
	PUSH{R0-R12,LR}
	MOV R2, R11
	MOV R3, R12
	
	
	SUB R6, R2, #30
	ADD R8, R6, #60
	SUB R7, R3, #2
	ADD R9, R7, #4
	BL DrawRect
	POP{R0-R12,PC}
	
DRAWSHIELDLEFTRIGHT
	PUSH{R0-R12,LR}
	MOV R2, R11
	MOV R3, R12
	
	
	SUB R6, R2, #2
	ADD R8, R6, #4
	SUB R7, R3, #30
	ADD R9, R7, #60
	BL DrawRect
	POP{R0-R12,PC}
	
	
	
MOVEMENT
	PUSH{R0-R12,LR}
	
	LDR R9, =ATTACK
	LDR R4, =ATTACK_STATUS
	MOV R6, #0
	LDR R1, =0xFFFF
MOVLOOP
	CMP R6,#8
	BGE MOVFINISHED
	ADD R6, R6, #1
	LDR R7,[R9]
	LDR R0, [R4]
	CMP R7, R1
	BNE MOVLOOPCONTINUE2
MOVLOOPCONTINUE
	LDR R7,[R9],#4
	LDR R0, [R4] , #4
	B MOVLOOP
MOVLOOPCONTINUE2
	MOV R10, #BLACK
	LDR R5, [R4] ; R6 = Direction
	LDR R7,[R9] ; R7 = Arrow

	CMP R5, #0
	BEQ MOVEUP
	CMP R5, #1
	BEQ MOVERIGHT
	CMP R5, #2
	BEQ MOVEDOWN
	CMP R5, #3
	BEQ MOVELEFT
MOVEUP
	MOV R11, #SPEAR_X
	MOV R12, #320
	SUB R12, R12, R7
	;BL DRAWUPPOINTEDARROW
	SUB R12, R12, #SPEAR_SPEED
	ADD R7, R7, #SPEAR_SPEED
	MOV R10, #WHITE
	BL DRAWUPPOINTEDARROW
	STR R7, [R9]
	B MOVLOOPCONTINUE

MOVEDOWN
	MOV R11, #SPEAR_X
	MOV R12, R7
	;BL DRAWDOWNPOINTEDARROW
	ADD R12, R12, #SPEAR_SPEED
	ADD R7, R7, #SPEAR_SPEED
	MOV R10, #WHITE
	BL DRAWDOWNPOINTEDARROW
	STR R7, [R9]
	B MOVLOOPCONTINUE
	
MOVERIGHT
	MOV R11, R7
	MOV R12, #SPEAR_Y
	;BL DRAWRIGHTPOINTEDARROW
	ADD R11, R11, #SPEAR_SPEED
	ADD R7, R7, #SPEAR_SPEED
	MOV R10, #WHITE
	BL DRAWRIGHTPOINTEDARROW
	STR R7, [R9]
	B MOVLOOPCONTINUE
	
MOVELEFT
	MOV R11, #480
	MOV R12, #SPEAR_Y
	SUB R11, R11, R7
	;BL DRAWLEFTPOINTEDARROW
	SUB R11, R11, #SPEAR_SPEED
	ADD R7, R7, #SPEAR_SPEED
	MOV R10, #WHITE
	BL DRAWLEFTPOINTEDARROW
	STR R7, [R9]
	B MOVLOOPCONTINUE
	
MOVFINISHED
	POP{R0-R12,PC}

	
SPAWNSPEAR
	PUSH{R0-R12,LR}
	
	LDR R9, =ATTACK
	LDR R4, =ATTACK_STATUS
	MOV R6, #0
	MOV R2, #0xFFFF

SPAWNLOOP
	CMP R6, #8
	BGE SPAWNFINISHED
	ADD R6, R6, #1
	LDR R5, [R9]
	LDR R0, [R4]
	CMP R2, R5
	BEQ SPAWNLOOPCONTINUE2
SPAWNLOOPCONTINUE
	LDR R5, [R9], #4
	LDR R0, [R4], #4
	B SPAWNLOOP

SPAWNLOOPCONTINUE2
	
	BL Get_Random_Seed
	MOV R1, #4
	BL DIV
	; R0 = Direction
	MOV R1, #0
	; R1 = Distance
	LDR R3, =ATTACK
	LDR R5, =ATTACK_STATUS
	MOV R6, #8
	MOV R7, #0xFFFF
CHECKSPAWNLOOP
	CMP R6, #0
	BLE CHECKSPAWNLOOPFINISHED
	SUB R6, R6, #1
	LDR R8, [R3]
	LDR R11, [R5]
	CMP R8, R7
	BEQ CHECKSPAWNLOOPCONTINUE
	CMP R11, R0
	BNE CHECKSPAWNLOOPCONTINUE
	CMP R8, R1
	SUBGE R10, R8, R1
	SUBLT R10, R1, R8
	CMP R10, #70 ; Minimum Distance
	BLE SPAWNFINISHED
CHECKSPAWNLOOPCONTINUE	
	LDR R8, [R3], #4
	LDR R11, [R5], #4
	B CHECKSPAWNLOOP
CHECKSPAWNLOOPFINISHED


	STR R0, [R4]
	MOV R0, #0
	STR R0, [R9]
	
SPAWNFINISHED
	POP{R0-R12,PC}
	
	
DetectGameEnd ;Detect Spearhitting in general (for now)
	PUSH{R0-R12,LR}
	
	LDR R9, =ATTACK
	LDR R4, =ATTACK_STATUS
	MOV R6, #0
	LDR R1, =0xFFFF
HITLOOP
	CMP R6,#8
	BGE.W HITFINISHED
	ADD R6, R6, #1
	LDR R7,[R9]
	LDR R0, [R4]
	CMP R7, R1
	BNE HITLOOPCONTINUE2
HITLOOPCONTINUE
	LDR R7,[R9],#4
	LDR R0, [R4] , #4
	B HITLOOP
HITLOOPCONTINUE2
	LDR R7,[R9] ; R7 = Arrow
	MOV R10, #BLACK
	LDR R5, [R4] ; R5 = Direction
	LDR R0, =SHIELDSTATUS
	LDR R0, [R0]
	
	CMP R5, #0
	BEQ UPHIT
	CMP R5 , #1
	BEQ RIGHTHIT
	CMP R5, #2
	BEQ DOWNHIT
	CMP R5, #3
	BEQ LEFTHIT
	B NONE
UPHIT ;Compare Distance
	MOV R10, #BLACK
	MOV R11, #SPEAR_X
	MOV R12, #320
	SUB R12, R12, R7
	BL DRAWUPPOINTEDARROW
	MOV R11, R12
	MOV R3 , #MAXDIST_Y
	ADD R3, #70
	CMP R0, #1
	MOVEQ R12, #1
	ADDEQ R3, R3, #10
	CMP R11 , R3
	BLE SPEARHIT
	
	B NONE
LEFTHIT
	MOV R10, #BLACK
	MOV R11, #480
	MOV R12, #SPEAR_Y
	SUB R11, R11, R7
	BL DRAWLEFTPOINTEDARROW
	MOV R3 , #MAXDIST_X
	ADD R3, #70
	CMP R0, #3
	MOVEQ R12, #1
	ADDEQ R3, R3, #10
	CMP R11 , R3
	BLE SPEARHIT
	
	B NONE

RIGHTHIT ;Compare Distance
	MOV R10, #BLACK
	MOV R11, R7
	MOV R12, #SPEAR_Y
	BL DRAWRIGHTPOINTEDARROW
	MOV R3 , #MAXDIST_X
	SUB R3, R3 ,#70
	CMP R0, #2
	MOVEQ R12, #1
	SUBEQ R3, R3, #10
	CMP R7 , R3
	BGE SPEARHIT
	
	B NONE
DOWNHIT ;Compare Distance
	MOV R10, #BLACK
	MOV R11, #SPEAR_X
	MOV R12, R7
	BL DRAWDOWNPOINTEDARROW
	MOV R3 , #MAXDIST_Y
	SUB R3, R3 , #70
	CMP R0, #0
	MOVEQ R12, #1
	SUBEQ R3, R3, #10
	
	CMP R7 , R3
	BGE SPEARHIT
	B NONE
SPEARHIT
	MOV R7, #0xFFFF
	STR R7, [R9]
	MOV R7, #0
	STR R7, [R4]
	CMP R12, #1
	BLEQ incrementScore
	BLNE decrementHealth
	B NONE
		LTORG

GAMEENDED
	BL LOSE
	B GAMEENDED ; Infinite Loop
NONE
	ADD R9, R9 , #4
	ADD R4 , R4 , #4
	B HITLOOP
HITFINISHED
	POP{R0-R12,PC}

;DRAW RIGHT POINTED ARROW
;TAKES COLOUR IN R10
;START X IN R11
;START Y IN R12
DRAWRIGHTPOINTEDARROW
    PUSH {R0-R12, LR}
    
    ; Base position
    MOV R2, R11         ; Start X
    MOV R3, R12         ; Start Y
    
    ;DRAW BASE OF ARROW
    MOV R6, R2 
    ADD R7, R3, #10 
    ADD R8, R2, #55
    ADD R9, R3, #25
    BL DrawRect
    
    ;CONTINUE OF DRAW BASE OF ARROW
    ADD R6, R2, #55
    ADD R7, R3, #15 
    ADD R8, R2, #60
    ADD R9, R3, #20
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #40
    ADD R7, R3, #5
    ADD R8, R2, #50
    ADD R9, R3, #10
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #40
    ADD R7, R3, #25
    ADD R8, R2, #50
    ADD R9, R3, #30
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #40
    ADD R7, R3, #0
    ADD R8, R2, #45
    ADD R9, R3, #5
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #40
    ADD R7, R3, #30
    ADD R8, R2, #45
    ADD R9, R3, #35
    BL DrawRect
    
    POP {R0-R12, PC}

;DRAW LEFT POINTED ARROW
;TAKES COLOUR IN R10
;START X IN R11
;START Y IN R12
DRAWLEFTPOINTEDARROW
    PUSH {R0-R12, LR}
    
    ; Base position
    MOV R2, R11         ; Start X
    MOV R3, R12         ; Start Y
    
    ;DRAW BASE OF ARROW
    ADD R6, R2, #5
    ADD R7, R3, #10 
    ADD R8, R2, #60
    ADD R9, R3, #25
    BL DrawRect
    
    ;CONTINUE OF DRAW BASE OF ARROW
    MOV R6, R2
    ADD R7, R3, #15 
    ADD R8, R2, #5
    ADD R9, R3, #20
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #10
    ADD R7, R3, #5
    ADD R8, R2, #20
    ADD R9, R3, #10
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #10
    ADD R7, R3, #25
    ADD R8, R2, #20
    ADD R9, R3, #30
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #15
    ADD R7, R3, #0
    ADD R8, R2, #20
    ADD R9, R3, #5
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #15
    ADD R7, R3, #30
    ADD R8, R2, #20
    ADD R9, R3, #35
    BL DrawRect
    
    POP {R0-R12, PC}














;DRAW UP POINTED ARROW
;TAKES COLOUR IN R10
;START X IN R11
;START Y IN R12
DRAWUPPOINTEDARROW
    PUSH {R0-R12, LR}
    
    ; Base position
    MOV R2, R11         ; Start X
    MOV R3, R12         ; Start Y
    
    ;DRAW BASE OF ARROW
    ADD R6, R2, #10
    ADD R7, R3, #5 
    ADD R8, R2, #25
    ADD R9, R3, #60
    BL DrawRect
    
    ;CONTINUE OF DRAW BASE OF ARROW
    ADD R6, R2, #15
    MOV R7, R3
    ADD R8, R2, #20
    ADD R9, R3, #5
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #5
    ADD R7, R3, #10
    ADD R8, R2, #10
    ADD R9, R3, #20
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #25
    ADD R7, R3, #10
    ADD R8, R2, #30
    ADD R9, R3, #20
    BL DrawRect
    
    ;WINGS OF ARROW
    MOV R6, R2
    ADD R7, R3, #15
    ADD R8, R2, #5
    ADD R9, R3, #20
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #30
    ADD R7, R3, #15
    ADD R8, R2, #35
    ADD R9, R3, #20
    BL DrawRect
    
    POP {R0-R12, PC}

;DRAW DOWN POINTED ARROW  
;TAKES COLOUR IN R10
;START X IN R11
;START Y IN R12
DRAWDOWNPOINTEDARROW
    PUSH {R0-R12, LR}
    
    ; Base position
    MOV R2, R11         ; Start X
    MOV R3, R12         ; Start Y
    
    ;DRAW BASE OF ARROW
    ADD R6, R2, #10
    MOV R7, R3
    ADD R8, R2, #25
    ADD R9, R3, #55
    BL DrawRect
    
    ;CONTINUE OF DRAW BASE OF ARROW
    ADD R6, R2, #15
    ADD R7, R3, #55
    ADD R8, R2, #20
    ADD R9, R3, #60
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #5
    ADD R7, R3, #40
    ADD R8, R2, #10
    ADD R9, R3, #50
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #25
    ADD R7, R3, #40
    ADD R8, R2, #30
    ADD R9, R3, #50
    BL DrawRect
    
    ;WINGS OF ARROW
    MOV R6, R2
    ADD R7, R3, #40
    ADD R8, R2, #5
    ADD R9, R3, #45
    BL DrawRect
    
    ;WINGS OF ARROW
    ADD R6, R2, #30
    ADD R7, R3, #40
    ADD R8, R2, #35
    ADD R9, R3, #45
    BL DrawRect
    
    POP {R0-R12, PC}
	;DRAW HEART FUNCTION 
;TAKES COLOUR IN R10
;START X IN R11
;START Y IN R12
DrawHeart
    PUSH {R0-R12, LR}

    ; Base position
    MOV R2, R11         ; Start X
    MOV R3, R12         ; Start Y

    ; === FIRST ROW (cut corners)
    ADD R6, R2, #8      ; 12 * 2/3
    MOV R7, R3
    ADD R8, R2, #24     ; 36 * 2/3
    ADD R9, R3, #4      ; 6 * 2/3
    BL DrawRect

    ADD R6, R2, #36     ; 54 * 2/3
    MOV R7, R3
    ADD R8, R2, #52     ; 78 * 2/3
    ADD R9, R3, #4
    BL DrawRect

    ; SECOND ROW
    ADD R6, R2, #4
    ADD R7, R3, #4
    ADD R8, R2, #28
    ADD R9, R3, #8
    BL DrawRect

    ADD R6, R2, #32
    ADD R7, R3, #4
    ADD R8, R2, #56
    ADD R9, R3, #8
    BL DrawRect

    ; THIRD ROW
    MOV R6, R2
    ADD R7, R3, #8
    ADD R8, R2, #60
    ADD R9, R3, #12
    BL DrawRect

    ; FOURTH ROW
    MOV R6, R2
    ADD R7, R3, #12
    ADD R8, R2, #60
    ADD R9, R3, #16
    BL DrawRect

    ; FIFTH ROW
    MOV R6, R2
    ADD R7, R3, #16
    ADD R8, R2, #60
    ADD R9, R3, #22
    BL DrawRect

    ; SIXTH ROW
    MOV R6, R2
    ADD R7, R3, #22
    ADD R8, R2, #60
    ADD R9, R3, #26
    BL DrawRect

    ; SEVENTH ROW
    MOV R6, R2
    ADD R7, R3, #26
    ADD R8, R2, #60
    ADD R9, R3, #32
    BL DrawRect

    ; EIGHTH ROW
    ADD R6, R2, #4
    ADD R7, R3, #32
    ADD R8, R2, #56
    ADD R9, R3, #36
    BL DrawRect

    ; NINTH ROW
    ADD R6, R2, #8
    ADD R7, R3, #36
    ADD R8, R2, #52
    ADD R9, R3, #40
    BL DrawRect

    ; TENTH ROW
    ADD R6, R2, #12
    ADD R7, R3, #40
    ADD R8, R2, #48
    ADD R9, R3, #44
    BL DrawRect

    ; ELEVENTH ROW
    ADD R6, R2, #16
    ADD R7, R3, #44
    ADD R8, R2, #44
    ADD R9, R3, #48
    BL DrawRect

    ; TWELFTH ROW
    ADD R6, R2, #20
    ADD R7, R3, #48
    ADD R8, R2, #40
    ADD R9, R3, #52
    BL DrawRect

    ; THIRTEENTH ROW
    ADD R6, R2, #24
    ADD R7, R3, #52
    ADD R8, R2, #36
    ADD R9, R3, #56
    BL DrawRect

    ; FOURTEENTH ROW
    ADD R6, R2, #28
    ADD R7, R3, #56
    ADD R8, R2, #32
    ADD R9, R3, #60
    BL DrawRect

    POP {R0-R12, PC}
	
Draw_background 
    PUSH {R0-R12, LR}
    MOV R6, #0
	MOV R7, #0
	MOV R8, #480
	MOV R9, #320
	MOV R10, #BLACK
	BL DrawRect	
    POP {R0-R12, PC}
	
	
GameHeartShield
	PUSH {R0-R12, LR}
	LDR R10, =RED
    MOV R11, #195
    MOV R12, #115
    BL DrawHeart

	POP {R0-R12, PC}
	
GAME_INIT
	PUSH{R0-R12,LR}
	BL GameHeartShield
	MOV R2, #0
	LDR R1, =0xFFFF
	LDR R0, =ATTACK
ATTACKINITLOOP
	STR R1 , [R0] , #4
	ADD R2, R2, #1
	CMP R2 , #8
	BLT ATTACKINITLOOP
	LDR R0, =ATTACK_STATUS
	MOV R2, #0
	MOV R1, #0
ATTACKINITLOOP12
	ADD R2, R2, #1
	STR R1 , [R0] , #4
	CMP R2 , #8
	BLT ATTACKINITLOOP12
	
	LDR R0, =SPEAR_SPEED
	MOV R1, #10
	STR R1, [R0]
	
	LDR R0, =HEALTH
	MOV R1, #100
	STR R1, [R0]
	LDR R0, =SHIELDSTATUS
	MOV R1, #0
	STR R1, [R0]
	
	MOV R11, #225
	MOV R12, #100
	MOV R10, #GREEN
	BL DRAWSHIELDUPDOWN
	
	
	
	LDR R0, =SCORE
	MOV R1, #0
	STR R1, [R0]
	
	LDR R0, =TIMER
	MOV R1, #0
	STR R1, [R0]
	
	POP{R0-R12,PC}