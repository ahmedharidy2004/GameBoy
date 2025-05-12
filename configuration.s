	EXPORT GPIO_INIT
	EXPORT GPIOX_ONEREAD
	EXPORT GPIOX_READ
	EXPORT GPIOX_SETHIGH
	EXPORT GPIOX_SETLOW
	EXPORT TFT_Init
	EXPORT TFT_WriteCommand
	EXPORT TFT_WriteData
	EXPORT TFT_FillScreen
	EXPORT DrawRect
	EXPORT Draw_Ball
	EXPORT TFT_ImageLoop
	EXPORT delay
	EXPORT DIV
	EXPORT Get_Random_Seed
	EXPORT TFT_DrawImage
	AREA MYCODE,CODE,READONLY

; Define register base addresses
RCC_BASE        EQU     0x40023800
GPIOA_BASE      EQU     0x40020000
GPIOB_BASE		EQU		0x40020400
GPIOC_BASE		EQU		0x40020800
GPIOD_BASE		EQU		0x40020C00
GPIOE_BASE		EQU		0x40021000
; Clock Variables
RCC_CR          EQU     0x00       ; RCC Clock Control Register
RCC_PLLCFGR     EQU     0x04       ; RCC PLL Configuration Register
RCC_CFGR        EQU     0x08       ; RCC Clock Configuration Register
FLASH_ACR       EQU     0x40023C00 ; Flash Access Control Register

; Clock Configuration Constants
HSI_VALUE       EQU     16000000   ; 16 MHz internal RC
SYSCLK_FREQ     EQU     84000000   ; Target system clock
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
	
DELAY_INTERVAL  EQU     0x261664 ; About 140ms

;DELAY_INTERVAL  EQU     0x4C2CC8 ; About 280ms

;DELAY_INTERVAL  EQU     0x6CD242 ; About 400ms	
;----------------------------------------------------------
; Get_Random_Seed - Properly randomized version
; Returns: R0 = random value, updates SEED in memory
;----------------------------------------------------------
Get_Random_Seed
    PUSH {R1-R2, LR}
    
    ; 1. Get SysTick value (24-bit decrementing counter)
    LDR R0, =0xE000E018      ; SysTick->VAL
    LDR R0, [R0]             ; Current countdown value    
    POP {R1-R2, PC}

SetupClocks
    PUSH {R0-R3, LR}
    
    ; 1. Enable HSI (16MHz internal RC)
    LDR R0, =0x40023800      ; RCC_BASE
    LDR R1, [R0, #0x00]      ; RCC_CR
    ORR R1, #(1 << 0)        ; HSION
    STR R1, [R0, #0x00]
    
    ; Wait for HSI ready (with timeout)
    MOV R2, #0xFFFF
HSI_Ready
    LDR R1, [R0, #0x00]      ; RCC_CR
    TST R1, #(1 << 1)        ; HSIRDY
    BNE HSI_Ready_Done
    SUBS R2, #1
	
    BNE HSI_Ready
    B Clock_Init_Done        ; Just return if HSI fails
    
HSI_Ready_Done
    ; 2. Configure Flash latency
    LDR R0, =0x40023C00      ; FLASH_ACR
    MOV R1, #0x00000202      ; PRFTEN | 2 wait states
    STR R1, [R0]

    ; 3. Try PLL configuration
    LDR R0, =0x40023800      ; RCC_BASE
    MOV R1, #0               ; Clear config
    ORR R1, #(16 << 0)       ; PLLM=16 (16MHz/16=1MHz)
    ORR R1, #(168 << 6)      ; PLLN=168 (1MHz*168=168MHz)
    ORR R1, #(1 << 22)       ; PLLSRC=HSI
    STR R1, [R0, #0x04]      ; RCC_PLLCFGR

    ; 4. Enable PLL with timeout
    MOV R2, #0xFFFF
    LDR R1, [R0, #0x00]      ; RCC_CR
    ORR R1, #(1 << 24)       ; PLLON
    STR R1, [R0, #0x00]
    
PLL_Ready
    LDR R1, [R0, #0x00]      ; RCC_CR
    TST R1, #(1 << 25)       ; PLLRDY
    BNE PLL_Ready_Done
    SUBS R2, #1
    BNE PLL_Ready
    B Setup_HSI_Only         ; Fallback to HSI if PLL fails
    
PLL_Ready_Done
    ; 5. Switch to PLL with timeout
    MOV R2, #0xFFFF
    LDR R1, [R0, #0x08]      ; RCC_CFGR
    ORR R1, #(0x02 << 0)     ; SW = PLL
    STR R1, [R0, #0x08]
    
Clock_Switch
    LDR R1, [R0, #0x08]      ; RCC_CFGR
    AND R1, #(0x03 << 2)     ; SWS mask
    CMP R1, #(0x02 << 2)     ; PLL?
    BEQ Clock_Switch_Done
    SUBS R2, #1
    BNE Clock_Switch
    ; Fall through to HSI if timeout
    
Setup_HSI_Only
    ; 6. Fallback: Configure HSI as system clock
    LDR R0, =0x40023800      ; RCC_BASE
    LDR R1, [R0, #0x08]      ; RCC_CFGR
    BIC R1, #(0x03 << 0)     ; SW = HSI (00)
    STR R1, [R0, #0x08]
    
    ; Set safe prescalers for HSI (16MHz)
    BIC R1, #(0x07 << 10)    ; APB1 = /1 (16MHz)
    BIC R1, #(0x07 << 13)    ; APB2 = /1 (16MHz)
    STR R1, [R0, #0x08]
    
    ; Reduce flash latency for 16MHz
    LDR R0, =0x40023C00      ; FLASH_ACR
    MOV R1, #0x00000101      ; PRFTEN | 1 wait state
    STR R1, [R0]
    
Clock_Switch_Done
Clock_Init_Done
    POP {R0-R3, PC}
;----------------------------------------------------------
; Init_SysTick - Configures SysTick as 24-bit decrementing counter
; Input: None
; Clobbers: R0-R1
;----------------------------------------------------------
Init_SysTick
    PUSH {R0-R1, LR}
    
    ; 1. Set reload value (max 24-bit: 0xFFFFFF)
    LDR R0, =0xE000E014      ; SysTick->LOAD
    LDR R1, =0x00FFFFFF      ; Count from 16,777,215 to 0
    STR R1, [R0]
    
    ; 2. Clear current value (write any value)
    LDR R0, =0xE000E018      ; SysTick->VAL
    MOV R1, #0
    STR R1, [R0]             ; Clears counter
    
    ; 3. Enable with processor clock (no interrupt)
    LDR R0, =0xE000E010      ; SysTick->CTRL
    MOV R1, #0x00000005      ; ENABLE=1, CLKSOURCE=1 (processor clock)
    STR R1, [R0]
    
    POP {R0-R1, PC}
; *************************************************************
; GPIO Initialization
; *************************************************************
GPIO_INIT
	PUSH {R0-R12,LR}
	; Enable clocks for GPIOA,B,C
	LDR R0, =RCC_BASE + RCC_AHB1ENR
	LDR R1, [R0]
	ORR R1, R1, #0x1F
	STR R1, [R0]

	; Configure A to be output and C, D, B to be an input
	LDR R0, =GPIOA_BASE + GPIO_MODER
	LDR R1, =0x55555555  
	STR R1, [R0]

	LDR R0, =GPIOB_BASE + GPIO_MODER
	LDR R1, =0x00000000 
	STR R1, [R0]

	LDR R0, =GPIOC_BASE + GPIO_MODER
	LDR R1, =0x00000000 
	STR R1, [R0]

	LDR R0, =GPIOD_BASE + GPIO_MODER
	LDR R1, =0x00000000
	STR R1, [R0]

	; Configure speed for GPIOA,B,C (Medium Speed)
	LDR R0, =GPIOA_BASE + GPIO_OSPEEDR
	LDR R1, =0x55555555
	STR R1, [R0]

	LDR R0, =GPIOB_BASE + GPIO_OSPEEDR
	LDR R1, =0x55555555
	STR R1, [R0]

	LDR R0, =GPIOC_BASE + GPIO_OSPEEDR
	LDR R1, =0x55555555
	STR R1, [R0]
	
	;Configure Pullup For Port B as Input
	LDR R0, =GPIOB_BASE + GPIO_PUPDR
	LDR R1, =0x55555555
	STR R1, [R0]

	; Setup Clocks
	BL SetupClocks
	; Setup Systick
	BL Init_SysTick
	POP {R0-R12,PC}
	LTORG

GPIOX_ONEREAD ;Where R0 is the data being read , R1 is the port (A,B,C) R1 = 0,1,2 , R2 is the bit number wanted {Index}

	PUSH {R3-R12,LR}

	LDR R3 , =GPIOA_BASE + GPIO_IDR
	MOV R5 , #0x0400
	MUL R5 , R1 , R5
	ADD R3 , R5 , R3
	LDR R4 , [R3]
	LSR R0 , R4 , R2
	BFC R0 , #1 , #31 ; Bit field clear for everything except the wanted number

	POP {R3-R12,PC}


GPIOX_READ ; Where R0 is the data, R1 is the port {A=0 , B=1 , C=2}
	PUSH {R2-R12,LR}

	LDR R3 , =GPIOA_BASE + GPIO_IDR
	MOV R5 , #0x0400
	MUL R5 , R1 , R5
	ADD R3 , R5 , R3
	LDR R4 , [R3]
	LSL R4 , #16
	LSR R4 , #16
	POP {R3-R12,PC}


GPIOX_SETHIGH ; R0 is the data being sethigh(F sets an entire byte, 1 sets the first bit), R1 is the port (A,B,C) , R2 is the bit number wanted to start from

	PUSH {R3-R12,LR}

	LDR R3 , =GPIOA_BASE + GPIO_ODR
	MOV R5 , #0x0400
	MUL R5 , R1 , R5
	ADD R3 , R5 , R3

	LDR R4 , [R3]
	LSL R0 , R0 , R2
	ORR R4 , R4 , R0
	STR R4 , [R3]

	POP {R3-R12,PC}

GPIOX_SETLOW ; R0 is the data being cleared (F clears an entire byte, 1 clears the first bit) , R1 is the port (A,B,C) , R2 is the bit number wanted to start from

	PUSH {R3-R12,LR}

	LDR R3 , =GPIOA_BASE + GPIO_ODR
	MOV R5 , #0x0400
	MUL R5 , R1 , R5
	ADD R3 , R5 , R3

	LDR R4 , [R3]
	LSL R0 , R0 , R2
	EOR R0 , R0 , #0xFFFFFFFF
	AND R4 , R0
	STR R4 , [R3]

	POP {R3-R12,PC}
; *************************************************************
; TFT Initialization
; *************************************************************
TFT_Init
	PUSH {R0-R2, LR}

	; Reset sequence
	LDR R1, =GPIOA_BASE + GPIO_ODR
	LDR R2, [R1]

	; Reset low
	BIC R2, R2, #TFT_RST
	STR R2, [R1]
	BL delay

	; Reset high
	ORR R2, R2, #TFT_RST
	STR R2, [R1]
	BL delay

	; Set Pixel Format (16-bit)
	MOV R0, #0x3A
	BL TFT_WriteCommand
	MOV R0, #0x55
	BL TFT_WriteData
	 ;memory accsess
	MOV R0, #0x36       ; MADCTL command
	BL TFT_WriteCommand
	MOV R0, #0x28       ; Parameter value (see explanation below)
	BL TFT_WriteData

	; Sleep Out
	MOV R0, #0x11
	BL TFT_WriteCommand
	BL delay

	; Enable Color Inversion
	; MOV R0, #0x21      ; Command for Color Inversion ON
	; BL TFT_WriteCommand


	; Display ON
	MOV R0, #0x29
	BL TFT_WriteCommand

	POP {R0-R2, LR}
	BX LR

; *************************************************************
; TFT Write Command (R0 = command)
; *************************************************************
TFT_WriteCommand
	PUSH {R1-R2, LR}

	; Set CS low
	LDR R1, =GPIOA_BASE + GPIO_ODR
	LDR R2, [R1]
	BIC R2, R2, #TFT_CS
	STR R2, [R1]

	; Set DC (RS) low for command
	BIC R2, R2, #TFT_DC
	STR R2, [R1]

	; Set RD high (not used in write operation)
	ORR R2, R2, #TFT_RD
	STR R2, [R1]

	; Send command (R0 contains command)
	BIC R2, R2, #0xFF   ; Clear data bits PA0-PA7
	AND R0, R0, #0xFF   ; Ensure only 8 bits
	ORR R2, R2, R0      ; Combine with control bits
	STR R2, [R1]

	; Generate WR pulse (low > high)
	BIC R2, R2, #TFT_WR
	STR R2, [R1]
	ORR R2, R2, #TFT_WR
	STR R2, [R1]

	; Set CS high
	ORR R2, R2, #TFT_CS
	STR R2, [R1]

	POP {R1-R2, LR}
	BX LR

; *************************************************************
; TFT Write Data (R0 = data)
; *************************************************************
TFT_WriteData
	PUSH {R1-R2, LR}

	; Set CS low
	LDR R1, =GPIOA_BASE + GPIO_ODR
	LDR R2, [R1]
	BIC R2, R2, #TFT_CS
	STR R2, [R1]

	; Set DC (RS) high for data
	ORR R2, R2, #TFT_DC
	STR R2, [R1]

	; Set RD high (not used in write operation)
	ORR R2, R2, #TFT_RD
	STR R2, [R1]

	; Send data (R0 contains data)
	BIC R2, R2, #0xFF   ; Clear data bits PA0-PA7
	AND R0, R0, #0xFF   ; Ensure only 8 bits
	ORR R2, R2, R0      ; Combine with control bits
	STR R2, [R1]

	; Generate WR pulse
	BIC R2, R2, #TFT_WR
	STR R2, [R1]
	ORR R2, R2, #TFT_WR
	STR R2, [R1]

	; Set CS high
	ORR R2, R2, #TFT_CS
	STR R2, [R1]

	POP {R1-R2, LR}
	BX LR

;FillScreen
TFT_FillScreen
	PUSH {R6-R10, LR}
	MOV R6, #0
	MOV R8, #480
	MOV R7, #0
	MOV R9, #320
	MOV R10, #0x0000 ; Black
	BL DrawRect
	POP {R6-R10, PC}
; *************************************************************
; *************************************************************
; DrawRect - Draws a rectangle with specified color and coordinates
; Input:
;   R10 = 16-bit color
;   R6 = Column Start (X1)
;   R7 = Row Start (Y1)
;   R8 = Column End (X2)
;   R9 = Row End (Y2)
; Note: This actually draws a rectangle, despite the name "DrawPixel"
DrawRect
	PUSH {R0-R12, LR}

	; Save color
	MOV R5, R10

	; Set Column Address (X1 to X2)
	MOV R0, #0x2A        ; Column address set command
	BL TFT_WriteCommand

	; Send X1 (16-bit)
	MOV R0, R6, LSR #8   ; X1 high byte
	BL TFT_WriteData
	MOV R0, R6           ; X1 low byte
	AND R0, R0, #0xFF
	BL TFT_WriteData

	; Send X2 (16-bit)
	MOV R0, R8, LSR #8   ; X2 high byte
	BL TFT_WriteData
	MOV R0, R8           ; X2 low byte
	AND R0, R0, #0xFF
	BL TFT_WriteData

	; Set Page Address (Y1 to Y2)
	MOV R0, #0x2B        ; Page address set command
	BL TFT_WriteCommand

	; Send Y1 (16-bit)
	MOV R0, R7, LSR #8   ; Y1 high byte
	BL TFT_WriteData
	MOV R0, R7           ; Y1 low byte
	AND R0, R0, #0xFF
	BL TFT_WriteData

	; Send Y2 (16-bit)
	MOV R0, R9, LSR #8   ; Y2 high byte
	BL TFT_WriteData
	MOV R0, R9           ; Y2 low byte
	AND R0, R0, #0xFF
	BL TFT_WriteData

	; Memory Write
	MOV R0, #0x2C        ; Memory write command
	BL TFT_WriteCommand

	; Calculate number of pixels (area)
	SUB R3, R8, R6       ; width = X2 - X1
	ADD R3, R3, #1       ; width + 1
	SUB R4, R9, R7       ; height = Y2 - Y1
	ADD R4, R4, #1       ; height + 1
	MUL R3, R3, R4       ; total pixels = width * height

	; Prepare color bytes
	MOV R1, R5, LSR #8   ; High byte
	AND R2, R5, #0xFF    ; Low byte

FillRectLoop
	; Write high byte
	MOV R0, R1
	BL TFT_WriteData

	; Write low byte
	MOV R0, R2
	BL TFT_WriteData

	SUBS R3, R3, #1
	BNE FillRectLoop

	POP {R0-R12, PC}

; *************************************************************
; Draw Ball
; *************************************************************
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


; *************************************************************
; TFT Draw Image (R1 = X, R2 = Y, R3 = Image Address)
; *************************************************************
TFT_DrawImage
    PUSH {R0,R4-R12, LR}

    ; Load image width and height
    LDR R4, [R3], #4  ; Load width  (R3 = Width)
    LDR R5, [R3], #4  ; Load height (R4 = Height)

    ; =====================
    ; Set Column Address (X Start, X End)
    ; =====================
    MOV R0, #0x2A
    BL TFT_WriteCommand
	LSR R6, R1, #8
    MOV R0, R6
    BL TFT_WriteData
    AND R0, R1, #0xFF  ; X Start
    BL TFT_WriteData
	ADD R6, R1, R4
	SUB R6, R6, #1
	LSR R0, R6, #8
    BL TFT_WriteData
	ADD R6, R1, R4
	SUB R6, R6, #1
	AND R0, R6, #0xFF
    BL TFT_WriteData
	
;    ADD R0, R1, R4
;    SUB R0, R0, #1  ; X End = X + Width - 1
    ; =====================
    ; Set Page Address (Y Start, Y End)
    ; =====================
    MOV R0, #0x2B
    BL TFT_WriteCommand
	LSR R6, R2, #8
    MOV R0, R6
    BL TFT_WriteData
	MOV R6, #0xFF
	AND R6, R6, R2
    MOV R0, R6  ; Y Start
    BL TFT_WriteData
	ADD R6, R2, R5
	SUB R6, R6, #1
	LSR R6, R6, #8
    MOV R0, R6
    BL TFT_WriteData
	ADD R6, R2, R5
	SUB R6, R6, #1
	MOV R9, #0xFF
	AND R0, R9, R6
;    ADD R0, R2, R5
;    SUB R0, R0, #1  ; Y End = Y + Height - 1
    BL TFT_WriteData

    ; =====================
    ; Start Writing Pixels
    ; =====================
    MOV R0, #0x2C
    BL TFT_WriteCommand

    ; =====================
    ; Send Pixel Data (BGR565)
    ; =====================
    MUL R6, R4, R5  ; Total pixels = Width × Height
TFT_ImageLoop
    LDRH R0, [R3], #2  ; Load one pixel (16-bit BGR565)
	MOV R1, R0, LSR #8 ; Extract high byte
	AND R2, R0, #0xFF  ; Extract low byte


    MOV R0, R1         ; Send High Byte first
    BL TFT_WriteData
    MOV R0, R2         ; Send Low Byte second
    BL TFT_WriteData

    SUBS R6, R6, #1
    BNE TFT_ImageLoop

    POP {R0,R4-R12, LR}
    BX LR

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
; *************************************************************
; Divide Function
; *************************************************************
DIV ; Divide Module Takes First Number: R0, Second Number: R1, Puts Result in R2 and Remainder in R0 => R2 = R0 / R1 , R0 = R0 % R1
	PUSH {R1,R3, LR}
	UDIV R2, R0, R1 ; R2 = R0 / R1
	MUL R3, R2, R1 ; R3 = R2 * R1
	SUB R0, R0, R3 ; R0 = R0 % R1
	POP {R1,R3, PC}
