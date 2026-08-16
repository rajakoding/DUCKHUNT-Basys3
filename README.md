# Duck Hunt on FPGA — Xilinx Basys3

A simplified version of the classic **Duck Hunt** game implemented on the **Xilinx Basys3 FPGA** using **VHDL**.

## Background

![Duck Hunt 1984](https://preview.redd.it/40-years-ago-today-duck-hunt-was-released-by-nintendo-in-v0-32fdkd16cyvc1.jpeg?auto=webp&s=54039c6d07ee90ad714924c255c95d4b26509771)

*Figure 1. Duck Hunt (1984). Source: Reddit.com*

**Duck Hunt** is a classic shooting game originally released in 1984 for the Nintendo Entertainment System. Inspired by the original game, our group decided to create a simplified version of Duck Hunt as a final project for the **Advanced Digital Systems** course.

The game was implemented on the **Xilinx Basys3 FPGA board using VHDL**, while maintaining the basic concept of the original game: moving a cursor toward a target and shooting it to earn points.

PS: this project cost half of my sanity

## Game Overview

The game uses a **PC keyboard as the controller** and a **PC monitor as the display output**. The player's score is also displayed on the **seven-segment display** available on the Basys3 board.

The cursor can be controlled using the following keyboard controls:

| Key     | Function          |
| ------- | ----------------- |
| `W`     | Move cursor up    |
| `A`     | Move cursor left  |
| `S`     | Move cursor down  |
| `D`     | Move cursor right |
| `SPACE` | Shoot             |

The player moves the cursor using **W, A, S, and D**, then presses **SPACE** to shoot the target. Successfully hitting a target increases the player's score, which is displayed on the Basys3 seven-segment display.

## Hardware and Software

### Hardware

* Xilinx Basys3 FPGA Board
* USB Keyboard
* PC Monitor

### Software

* VHDL
* Xilinx Vivado

## Project Members

* PURNAMA RAMADHANSYAH — 245150301111018 
* SAMUEL PUTRA HALOMOAN SILITONGA — 245150307111049
* GANDUNG BISMA ALVAREZA P — 245150300111034
* RYAN FADHLURRAHMAN — 245150307111048
* MUHAMAD AL FATIH — 245150301111024
