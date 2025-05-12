	EXPORT WIN
	EXPORT LOSE
	EXPORT ONEWIN
	EXPORT TWOWIN
	EXPORT DRAW_DRAW
	IMPORT delay
	IMPORT DrawRect
	IMPORT TFT_FillScreen
	AREA MYCODE,CODE,READONLY

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
BLUE EQU 0x001F
WHITE EQU 0XFFFF
PINK EQU 0xc814
GREEN EQU 0x0780
CYAN EQU 0x05b9
RED	EQU 0xf800
YELLOW	EQU 0xffc0
ORANGE EQU	0xfc40
DELAY_INTERVAL  EQU     0x18604  
	
WIN
	PUSH {R0-R12, LR}
	LDR R10, =BLACK
	MOV R6, #0
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;----------------- background done
	LDR R10, =WHITE
	MOV R6, #102
	MOV R8, #109
	MOV R7, #141
	MOV R9, #156
	BL DrawRect
	;------------------
	LDR R10, =WHITE
	MOV R6, #110
	MOV R8, #133
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #134
	MOV R8, #141
	MOV R7, #141
	MOV R9, #156
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #118
	MOV R8, #125
	MOV R7, #165
	MOV R9, #180
	BL DrawRect
	;-------------------- done drawing y
	LDR R10, =WHITE
	MOV R6, #150
	MOV R8, #157
	MOV R7, #149
	MOV R9, #172
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #158
	MOV R8, #173
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #174
	MOV R8, #181
	MOV R7, #149
	MOV R9, #172
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #158
	MOV R8, #173
	MOV R7, #173
	MOV R9, #180
	BL DrawRect
	;-------------------- done drawing o
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #197
	MOV R7, #141
	MOV R9, #172
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #198
	MOV R8, #213
	MOV R7, #173
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #214
	MOV R8, #221
	MOV R7, #141
	MOV R9, #172
	BL DrawRect
	;------------------- done drawing U
	LDR R10, =WHITE
	MOV R6, #246
	MOV R8, #253
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #254
	MOV R8, #261
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #262
	MOV R8, #269
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #270
	MOV R8, #277
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #278
	MOV R8, #285
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;------------------- done drawing W
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #173
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #306
	MOV R8, #313
	MOV R7, #149
	MOV R9, #172
	BL DrawRect
	;-------------------done drawing I
	LDR R10, =WHITE
	MOV R6, #334
	MOV R8, #341
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #342
	MOV R8, #349
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #350
	MOV R8, #357
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #358
	MOV R8, #365
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	POP {R0-R12, PC}
LOSE
	PUSH {R0-R12, LR}
	LDR R10, =BLACK
	MOV R6, #0
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;----------BACKGROUND DRAWN
	LDR R10, =WHITE
	MOV R6, #77
	MOV R8, #92
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #69
	MOV R8, #76
	MOV R7, #141
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #77
	MOV R8, #92
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #93
	MOV R8, #100
	MOV R7, #149
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #85
	MOV R8, #92
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-----------------------------G DONE
	LDR R10, =WHITE
	MOV R6, #109
	MOV R8, #116
	MOV R7, #141
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #117
	MOV R8, #132
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #133
	MOV R8, #140
	MOV R7, #141
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #117
	MOV R8, #132
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-------------------------A drawn
	LDR R10, =WHITE
	MOV R6, #149
	MOV R8, #156
	MOV R7, #133
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #157
	MOV R8, #164
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #165
	MOV R8, #172
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #173
	MOV R8, #180
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #181
	MOV R8, #188
	MOV R7, #133
	MOV R9, #172
	BL DrawRect
	;------------------------- M drawn
	LDR R10, =WHITE
	MOV R6, #197
	MOV R8, #228
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #197
	MOV R8, #204
	MOV R7, #133
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #205
	MOV R8, #220
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #205
	MOV R8, #228
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------------E drawn
	LDR R10, =WHITE
	MOV R6, #253
	MOV R8, #260
	MOV R7, #141
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #261
	MOV R8, #276
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #277
	MOV R8, #284
	MOV R7, #141
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #261
	MOV R8, #276
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;------------------------- O drawn
	LDR R10, =WHITE
	MOV R6, #293
	MOV R8, #300
	MOV R7, #133
	MOV R9, #148
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #301
	MOV R8, #308
	MOV R7, #149
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #309
	MOV R8, #316
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #317
	MOV R8, #324
	MOV R7, #149
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #325
	MOV R8, #332
	MOV R7, #133
	MOV R9, #148
	BL DrawRect
	;-------------------------V drawn
	LDR R10, =WHITE
	MOV R6, #341
	MOV R8, #348
	MOV R7, #133
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #349
	MOV R8, #372
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #349
	MOV R8, #364
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #349
	MOV R8, #372
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;------------------------- E drawn
	LDR R10, =WHITE
	MOV R6, #381
	MOV R8, #388
	MOV R7, #133
	MOV R9, #172
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #389
	MOV R8, #404
	MOV R7, #133
	MOV R9, #140
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #405
	MOV R8, #412
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #389
	MOV R8, #404
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #397
	MOV R8, #404
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;-------------------------
	LDR R10, =WHITE
	MOV R6, #405
	MOV R8, #412
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------------R drawn
	POP {R0-R12, PC}
	
ONEWIN
	PUSH {R0-R12, LR}
	LDR R10, =BLACK
	MOV R6, #0
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;----------------- background done
	LDR R10, =WHITE
	MOV R6, #102
	MOV R8, #107
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;------------------
	LDR R10, =WHITE
	MOV R6, #125
	MOV R8, #130
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #102
	MOV R8, #130
	MOV R7, #141
	MOV R9, #146
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #102
	MOV R8, #130
	MOV R7, #175
	MOV R9, #180
	BL DrawRect
	;-------------------- done drawing O
	LDR R10, =WHITE
	MOV R6, #140
	MOV R8, #145
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #145
	MOV R8, #150
	MOV R7, #146
	MOV R9, #150
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #150
	MOV R8, #155
	MOV R7, #150
	MOV R9, #155
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #155
	MOV R8, #160
	MOV R7, #155
	MOV R9, #160
	BL DrawRect
	LDR R10, =WHITE
	MOV R6, #160
	MOV R8, #165
	MOV R7, #160
	MOV R9, #165
	BL DrawRect
	LDR R10, =WHITE
	MOV R6, #165
	MOV R8, #170
	MOV R7, #165
	MOV R9, #170
	BL DrawRect
	
		LDR R10, =WHITE
	MOV R6, #170
	MOV R8, #175
	MOV R7, #170
	MOV R9, #175
	BL DrawRect
	
		LDR R10, =WHITE
	MOV R6, #175
	MOV R8, #180
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------- done drawing N
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #195
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #220
	MOV R7, #140
	MOV R9, #145
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #220
	MOV R7, #175
	MOV R9, #180
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #220
	MOV R7, #157
	MOV R9, #162
	BL DrawRect
	;------------------- done drawing E
	LDR R10, =WHITE
	MOV R6, #246
	MOV R8, #253
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #254
	MOV R8, #261
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #262
	MOV R8, #269
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #270
	MOV R8, #277
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #278
	MOV R8, #285
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;------------------- done drawing W
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #173
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #306
	MOV R8, #313
	MOV R7, #149
	MOV R9, #172
	BL DrawRect
	;-------------------done drawing I
	LDR R10, =WHITE
	MOV R6, #334
	MOV R8, #341
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #342
	MOV R8, #349
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #350
	MOV R8, #357
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #358
	MOV R8, #365
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	POP {R0-R12, PC}
	
TWOWIN
	PUSH {R0-R12, LR}
	LDR R10, =BLACK
	MOV R6, #0
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	BL DrawRect
	;----------------- background done
	LDR R10, =WHITE
	MOV R6, #102
	MOV R8, #137
	MOV R7, #141
	MOV R9, #145
	BL DrawRect
	;------------------
	LDR R10, =WHITE
	MOV R6, #117
	MOV R8, #122
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------- done drawing T
	LDR R10, =WHITE
	MOV R6, #142
	MOV R8, #147
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #157
	MOV R8, #162
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #172
	MOV R8, #177
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;---------------------
	LDR R10, =WHITE
	MOV R6, #142
	MOV R8, #175
	MOV R7, #175
	MOV R9, #180
		BL DrawRect

	;-------------------- done drawing W
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #195
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #210
	MOV R8, #215
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #215
	MOV R7, #141
	MOV R9, #145
	BL DrawRect
	
	LDR R10, =WHITE
	MOV R6, #190
	MOV R8, #215
	MOV R7, #175
	MOV R9, #180
	BL DrawRect
	;------------------- done drawing E
	LDR R10, =WHITE
	MOV R6, #246
	MOV R8, #253
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #254
	MOV R8, #261
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #262
	MOV R8, #269
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #270
	MOV R8, #277
	MOV R7, #165
	MOV R9, #172
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #278
	MOV R8, #285
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;------------------- done drawing W
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #141
	MOV R9, #148
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #294
	MOV R8, #325
	MOV R7, #173
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #306
	MOV R8, #313
	MOV R7, #149
	MOV R9, #172
	BL DrawRect
	;-------------------done drawing I
	LDR R10, =WHITE
	MOV R6, #334
	MOV R8, #341
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	;-------------------
	LDR R10, =WHITE
	MOV R6, #342
	MOV R8, #349
	MOV R7, #149
	MOV R9, #156
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #350
	MOV R8, #357
	MOV R7, #157
	MOV R9, #164
	BL DrawRect
	;--------------------
	LDR R10, =WHITE
	MOV R6, #358
	MOV R8, #365
	MOV R7, #141
	MOV R9, #180
	BL DrawRect
	POP {R0-R12, PC}
DRAW_DRAW
	PUSH {R0-R12, LR}
	BL TFT_FillScreen
	LDR R10, =WHITE
	MOV R6, #115
	MOV R8, #125
	MOV R7, #115
	MOV R9, #205
	BL DrawRect	
	
	MOV R6, #115
	MOV R8, #145
	MOV R7, #115
	MOV R9, #125
	BL DrawRect
	
	MOV R6, #135
	MOV R8, #155
	MOV R7, #125
	MOV R9, #135
	BL DrawRect
	
	MOV R6, #145
	MOV R8, #165
	MOV R7, #135
	MOV R9, #145
	BL DrawRect
	
		MOV R6, #155
	MOV R8, #165
	MOV R7, #135
	MOV R9, #185
	BL DrawRect
	
	MOV R6, #115
	MOV R8, #145
	MOV R7, #195
	MOV R9, #205
	BL DrawRect
	
	MOV R6, #135
	MOV R8, #155
	MOV R7, #185
	MOV R9, #195
	BL DrawRect
	
	MOV R6, #145
	MOV R8, #165
	MOV R7, #175
	MOV R9, #185
	BL DrawRect
	;.....................D DONE
	LDR R10, =WHITE

	; Vertical bar
	MOV R6, #175
	MOV R8, #185
	MOV R7, #115
	MOV R9, #205
	BL DrawRect

	; Top horizontal
	MOV R6, #185
	MOV R8, #205
	MOV R7, #115
	MOV R9, #125
	BL DrawRect

	; Middle horizontal
	MOV R6, #185
	MOV R8, #205
	MOV R7, #155
	MOV R9, #165
	BL DrawRect

	; Right vertical top
	MOV R6, #205
	MOV R8, #215
	MOV R7, #125
	MOV R9, #155
	BL DrawRect

	; Diagonal leg
	MOV R6, #205
	MOV R8, #215
	MOV R7, #165
	MOV R9, #205
	BL DrawRect
	;......................
		LDR R10, =WHITE

	; Left leg
	MOV R6, #230
	MOV R8, #240
	MOV R7, #125
	MOV R9, #205
	BL DrawRect

	; Right leg
	MOV R6, #260
	MOV R8, #270
	MOV R7, #125
	MOV R9, #205
	BL DrawRect

	; Top bar
	MOV R6, #240
	MOV R8, #260
	MOV R7, #115
	MOV R9, #125
	BL DrawRect

	; Middle bar
	MOV R6, #240
	MOV R8, #260
	MOV R7, #160
	MOV R9, #170
	BL DrawRect
	;...............................
		LDR R10, =WHITE

	; Left leg
	MOV R6, #280
	MOV R8, #290
	MOV R7, #115
	MOV R9, #205
	BL DrawRect

	; MIDDLE leg
	MOV R6, #310
	MOV R8, #320
	MOV R7, #115
	MOV R9, #205
	BL DrawRect

	; RIEGHT LEG
	MOV R6, #340
	MOV R8, #350
	MOV R7, #115
	MOV R9, #205
	BL DrawRect

	; Middle bar
	MOV R6, #280
	MOV R8, #350
	MOV R7, #195
	MOV R9, #205
	BL DrawRect

	POP {R0-R12, PC}