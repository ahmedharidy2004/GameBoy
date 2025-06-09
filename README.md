# 🎮 #GameBoy  
**Embedded Gaming Console with Classic Games using ARM Assembly and STM32**

---

## 📜 Overview

**#GameBoy** is a retro-style embedded gaming console built using the **STM32F401RCT6** microcontroller and developed entirely in **32-bit ARM Assembly**. It features a collection of classic-inspired games rendered on a 3.5" TFT LCD and controlled using physical push buttons.

This project demonstrates advanced **bare-metal programming**, low-level I/O handling, and real-time game mechanics on ARM Cortex-M4 — **with no OS or high-level libraries**.

---

## 🎮 Included Games

| Game             | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| **Snake**        | Classic snake movement logic with randomized apples                         |
| **BrickBreaker** | 3-level blocks with dynamic ball movement                                   |
| **FlappyBird**   | Navigate through randomized pipes with increasing speed                     |
| **Hocky**        | Two-player hockey game – first to get 7 points wins                         |
| **Bowling**      | Retro-style two-player bowling with multiple rounds                         |
| **FruitNinja**   | Collect falling fruits but avoid the bombs!                                 |
| **Subway**       | Avoid trains and collect as many coins as possible                          |
| **Undertale**    | Protect the heart from oncoming obstacles – a reflex-based survival game    |
| **FiredOrTired** | Two-player battle – don’t fall off and try to eliminate your opponent       |

---

## 🧰 Hardware Requirements

| Component        | Specification                                       |
|------------------|-----------------------------------------------------|
| **MCU**          | STM32F401RCT6 (Black Pill – ARM Cortex-M4 @ 84 MHz) |
| **Display**      | ILI9486 (3.5" TFT LCD – 8-bit parallel interface)   |
| **Input**        | Push buttons (up to 8 for gameplay)                 |
| **Debugger**     | ST-Link V2 (for programming and debugging)          |

---

## 🔧 Development Setup

- **Programming Language**: 32-bit ARM Assembly
- **IDE**: [Keil µVision](https://www.keil.com/)
- **Toolchain**: Keil ARM Compiler
- **Display Interface**: GPIO (FSMC or bit-banged parallel)
- **Input Interface**: GPIO with polling or interrupt support

---

## 📋 Features

- 🔧 Bare-metal game engine (no external libraries)
- 🎮 Suite of classic-style games with unique mechanics
- 👥 Two-player gameplay supported in select games
- 🖼️ Optimized graphics for 8-bit rendering on ILI9486
- ⏱️ Real-time input handling via polling and interrupts
- 🧩 Modular code structure for easy game development and expansion

---

## 🚀 Getting Started

1. Connect your STM32F401RCT6 board via ST-Link.
2. Open the project in **Keil µVision**.
3. Build the project using the Keil ARM Compiler.
4. Flash the firmware onto the board.
5. Play the games using physical push buttons!
