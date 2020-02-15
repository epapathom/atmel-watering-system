; ----------------------------------------------------------------------

; Authors : Evangelos Papathomas, Nikolaos Katomeris

; ------------------------DESCRIPTION-----------------------------------

; This program is written for LAB 3
;	It simulates a plant watering system. The duration and the 
;	frequency of the waterings is based on the enviromental 
;	temperature and humidity values. In this simulation, there
;	are 8 predefined combinations of these values that the user
;	can choose.
;	
;	More specifically, the available programs are:
;		1. For temperatures above 30 Celsius
;		2. For temperatures between 20 and 30 Celsius
;		3. For temperatures between 10 and 20 Celsius
;		4. For temperatures bellow 10 Celsius
;	for humidity values bellow 50% or above 50%.
;
;	At start, the user chooses one of the above programs by pressing
;		-SW0 for the 1st
;		-SW1 for the 2nd
;		-SW2 for the 3rd
;		-SW3 for the 4th
;	Then, the user can choose a humidity value bellow 50% by pressing
;	SW4. If not, the simulation will assume humidity above 50%.
;
;	By pressing SW6 the simulation will start.
;	In order to change the simulation program the user can press SW7.
;	Pressing SW5 will set the simulation to "low battery state".
;
;	***How to "read" the simulation***
;	While the simulation is running:
;	-LED7-LED6 print the current number of watering of one day.
;	-LED3-LED0 print the current value of the watering timer of the 
;	 current watering. The timer changes each second simulating minutes.
;	-LED5-LED4 remain turned on between two consecutive waterings
;	 for n*2 seconds simulating 4*n hours of non-watering.

; ---Date---
; Created: 12/18/2017 15:52:26

.include "m16def.inc"

;---REGISTER DEFINITIONS-------------------------

.DEF STACK_TEMP_REG = r13
.DEF HUMIDITY_REG = r14					; Register for the humidity condition
.DEF CLEAR_REG = r15					; 0x00 (similar to clr)
.DEF COM_CLEAR_REG = r16				; 0xFF
.DEF TEMP_REG = r17						; Free register, for temp values
.DEF DELAY_REG1 = r18					; Used by the delay routines
.DEF DELAY_REG2 = r19					; Used by the delay routines
.DEF DELAY_REG3 = r20					; Used by the delay routines
.DEF PROCESS_COUNTER_REG = r21			; Used for counting the waterings
.DEF PROCESS_COUNTER_SHIFTED_REG = r22	; For outputing the timer on LED7-6
.DEF TIMER_REG = r23					; Register used for the timer
.DEF OUTPUT_REG1 = r24					; Register for the LED output

.cseg

	;---STACK POINTER INITIATION---
	SPI_INIT:
	ldi TEMP_REG,low(RAMEND)
	out spl,TEMP_REG
	ldi TEMP_REG,high(RAMEND)
	out sph,TEMP_REG

	;---DO NOT CHANGE these regs---
	ldi COM_CLEAR_REG, 0xFF ; Clear Ports
	clr CLEAR_REG; Clear
	
	;---SET I/O---
	out ddrd, CLEAR_REG ; SET AS INPUT PORTD
	out ddrb, COM_CLEAR_REG ; SET AS OUTPUT PORTB

	;---TURN OFF ALL LEDS---
	out portb, COM_CLEAR_REG

	start: 

		;---WAITING FOR TEMPERATURE INPUT---
		WaitForInput:
			clr HUMIDITY_REG
			sbis pind, 0		; If SW0 is pressed go to ReleaseSW0
				rjmp ReleaseSW0
			sbis pind, 1		; If SW1 is pressed go to ReleaseSW1
				rjmp ReleaseSW1
			sbis pind, 2		; If SW2 is pressed go to ReleaseSW2
				rjmp ReleaseSW2
			sbis pind, 3		; If SW3 is pressed go to ReleaseSW3
				rjmp ReleaseSW3
			rjmp WaitForInput	; else: continue waiting for SW0/1/2/3


		;---CHECK IF BUTTONS ARE RELEASED AND IF MORE BUTTONS ARE PRESSED---
		ReleaseSW0:
			sbis pind, 0			; If SW0 is still pressed continue looping
				rjmp ReleaseSW0
			StartProcess0:			; else:
				sbis pind, 4		; If SW4 is pressed call ReleaseSW4
					rcall ReleaseSW4
				sbis pind, 6		; If SW6 is pressed go to ZERO
					rjmp ZERO	
				rjmp StartProcess0 	; else: continue waiting for 4 or 6
		ReleaseSW1:
			sbis pind, 1			; If SW1 is still pressed continue looping
				rjmp ReleaseSW1
			StartProcess1:			; else:
				sbis pind, 4		; If SW4 is pressed call ReleaseSW4
					rcall ReleaseSW4
				sbis pind, 6		; If SW6 is pressed go to ONE
					rjmp ONE
				rjmp StartProcess1	; else: continue waiting for 4 or 6
		ReleaseSW2:
			sbis pind, 2			; If SW2 is still pressed continue looping
				rjmp ReleaseSW2
			StartProcess2:			; else:
				sbis pind, 4		; If SW4 is pressed call ReleaseSW4
					rcall ReleaseSW4
				sbis pind, 6		; If SW6 is pressed go to TWO
					rjmp TWO
				rjmp StartProcess2	; else: continue waiting for 4 or 6
		ReleaseSW3:
			sbis pind, 3			; If SW3 is still pressed continue looping
				rjmp ReleaseSW3
			StartProcess3:			; else:
				sbis pind, 4		; If SW4 is pressed call ReleaseSW4
					rcall ReleaseSW4
				sbis pind, 6		; If SW6 is pressed go to THREE
					rjmp THREE
			rjmp StartProcess3		; else: continue waiting for 4 or 6
		; Method that changes humidity reg's value
		ReleaseSW4:
			sbis pind, 4			; If SW4 is still pressed continue looping
				rjmp ReleaseSW4
			mov HUMIDITY_REG, COM_CLEAR_REG ; Change HUMIDITY_REG's value
			ret

		;---SIMULATIONS---
		ZERO:
			sbis pind, 6 ; Wait for SW6 to be released
				rjmp ZERO
			clr PROCESS_COUNTER_REG
			PrintLED0:
			inc PROCESS_COUNTER_REG ; Increment process counter.
			cpi PROCESS_COUNTER_REG, 4	; If it passed the last watering of the day
			breq ResetWateringCounter0	; Reset the watering counter
			mov PROCESS_COUNTER_SHIFTED_REG, PROCESS_COUNTER_REG
			rcall ShiftCounter			; Prepare to output the watering counter on LED7-6
			rcall ResetWateringTime 	; Reset timer.
				WateringTime0:
					inc TIMER_REG
					clr OUTPUT_REG1
					or OUTPUT_REG1, PROCESS_COUNTER_SHIFTED_REG ;Combine process counter with the timer.
					or OUTPUT_REG1, TIMER_REG ;Combine process counter with the timer.
					com OUTPUT_REG1
					out portb, OUTPUT_REG1 	; Output to LEDs.
					rcall Delay1 			; Delay 1 second.
					sbrc HUMIDITY_REG, 1 	; If humidity_reg != 0 -> humidity > 50%
						ldi TEMP_REG, 12
					sbrs HUMIDITY_REG, 1	; else
						ldi TEMP_REG, 10
					cp TIMER_REG, TEMP_REG	; If all seconds passed, go to the next process.
					breq PAUSE0 			; If not, continue counting seconds.
					rjmp WateringTime0

		PAUSE0:
			ldi OUTPUT_REG1, 0b11001111 ; Turn on LED5 and LED4 between to succesional processes.
			out portb, OUTPUT_REG1
			rcall Delay4 				; Wait for 8 hours but in this case 4 seconds as asked.
			out portb, COM_CLEAR_REG
			rjmp PrintLED0		

		;---RESET WATERING COUNTER---
		ResetWateringCounter0:
			mov PROCESS_COUNTER_REG, CLEAR_REG
			rjmp WaitForInput
		
		ONE:
			sbis pind, 6
				rjmp ONE
			clr PROCESS_COUNTER_REG
			PrintLED1:
			inc PROCESS_COUNTER_REG ; Increment process counter.
			cpi PROCESS_COUNTER_REG, 3
			breq ResetWateringCounter
			mov PROCESS_COUNTER_SHIFTED_REG, PROCESS_COUNTER_REG
			rcall ShiftCounter
			rcall ResetWateringTime ; Reset timer.
				WateringTime1:
					inc TIMER_REG
					clr OUTPUT_REG1
					or OUTPUT_REG1, PROCESS_COUNTER_SHIFTED_REG ;Combine process counter with the timer.
					or OUTPUT_REG1, TIMER_REG 	;Combine process counter with the timer.
					com OUTPUT_REG1
					out portb, OUTPUT_REG1 		; Output to LEDs.
					rcall Delay1 				; Delay 1 second.
					sbrc HUMIDITY_REG, 1 		; If humidity_reg != 0 -> humidity > 50%
						ldi TEMP_REG, 6
					sbrs HUMIDITY_REG, 1 		; else
						ldi TEMP_REG, 4
					cp TIMER_REG, TEMP_REG		; If all seconds passed, go to the next process.
					breq PAUSE1 				; If not, continue counting seconds.
					rjmp WateringTime1
		
		PAUSE1:
			ldi OUTPUT_REG1, 0b11001111 ; Turn on LED5 and LED4 between to succesional processes.
			out portb, OUTPUT_REG1
			rcall Delay6 				; Wait for 12 hours but in this case 4 seconds as asked.
			out portb, COM_CLEAR_REG
			rjmp PrintLED1			

		TWO:
			sbis pind, 6
				rjmp TWO
			clr PROCESS_COUNTER_REG
			PrintLED2:
			inc PROCESS_COUNTER_REG ; Increment process counter.
			cpi PROCESS_COUNTER_REG, 2
			breq ResetWateringCounter
			mov PROCESS_COUNTER_SHIFTED_REG, PROCESS_COUNTER_REG
			rcall ShiftCounter
			rcall ResetWateringTime ; Reset timer.
				WateringTime2:
					inc TIMER_REG
					clr OUTPUT_REG1
					or OUTPUT_REG1, PROCESS_COUNTER_SHIFTED_REG ;Combine process counter with the timer.
					or OUTPUT_REG1, TIMER_REG ;Combine process counter with the timer.
					com OUTPUT_REG1
					out portb, OUTPUT_REG1 ; Output to LEDs.
					rcall Delay2 ; Delay 1 second.
					sbrc HUMIDITY_REG, 1 ; If humidity_reg != 0 -> humidity > 50%
						ldi TEMP_REG, 3
					sbrs HUMIDITY_REG, 1 ; else
						ldi TEMP_REG, 1
					cp TIMER_REG, TEMP_REG ; If all seconds passed, go to the next process.
					breq PAUSE2 ;If not, continue counting seconds.
					rjmp WateringTime2

		PAUSE2:
			ldi OUTPUT_REG1, 0b11001111 ; Turn on LED5 and LED4 between to succesional processes.
			out portb, OUTPUT_REG1
			rcall Delay12 ; Wait for 24 hours but in this case 4 seconds as asked.
			out portb, COM_CLEAR_REG
			rjmp PrintLED2

		;---RESET WATERING COUNTER---
		ResetWateringCounter:
			mov PROCESS_COUNTER_REG, CLEAR_REG
			rjmp WaitForInput

		THREE:
			sbis pind, 6
				rjmp THREE
			clr PROCESS_COUNTER_REG
			PrintLED3:
			inc PROCESS_COUNTER_REG ; Increment process counter.
			cpi PROCESS_COUNTER_REG, 2
			breq ResetWateringCounter
			mov PROCESS_COUNTER_SHIFTED_REG, PROCESS_COUNTER_REG
			rcall ShiftCounter
			rcall ResetWateringTime ; Reset timer.
				WateringTime3:
					inc TIMER_REG
					clr OUTPUT_REG1
					or OUTPUT_REG1, PROCESS_COUNTER_SHIFTED_REG ;Combine process counter with the timer.
					or OUTPUT_REG1, TIMER_REG ;Combine process counter with the timer.
					com OUTPUT_REG1
					out portb, OUTPUT_REG1 ; Output to LEDs.
					rcall Delay1 ; Delay 1 second.
					sbrc HUMIDITY_REG, 1 ; If humidity_reg != 0 -> humidity > 50%
						ldi TEMP_REG, 1
					sbrs HUMIDITY_REG, 1 ; else
						ldi TEMP_REG, 1
					cp TIMER_REG, TEMP_REG ; If all seconds passed, go to the next process.
					breq PAUSE3 ;If not, continue counting seconds.
					rjmp WateringTime3
		
		PAUSE3:
			ldi OUTPUT_REG1, 0b11001111 ; Turn on LED5 and LED4 between to succesional processes.
			out portb, OUTPUT_REG1
			rcall Delay12 ; Wait for 24 hours but in this case 4 seconds as asked.
			out portb, COM_CLEAR_REG
			rjmp PrintLED3		
				
		;---RESET WATERING TIME---
		ResetWateringTime:
			mov TIMER_REG, CLEAR_REG
			ret

	 	;---For outputing to the right LEDs (LED7 and LED6).---
		ShiftCounter:
			lsl PROCESS_COUNTER_SHIFTED_REG
			lsl PROCESS_COUNTER_SHIFTED_REG
			lsl PROCESS_COUNTER_SHIFTED_REG
			lsl PROCESS_COUNTER_SHIFTED_REG
			lsl PROCESS_COUNTER_SHIFTED_REG
			lsl PROCESS_COUNTER_SHIFTED_REG
			ret

		;--For simulating the "Low battery" state.
		Blink_LEDs:
			out portb, CLEAR_REG
			rcall Delay1
			out portb, COM_CLEAR_REG
			rcall Delay1
			rjmp Blink_LEDs

		SW5_Pressed:
			pop STACK_TEMP_REG
			pop STACK_TEMP_REG
			Released5:
				sbis pind, 5
					rjmp Released5
				rjmp Blink_LEDs
			
		SW7_Pressed:
			pop STACK_TEMP_REG
			pop STACK_TEMP_REG
			Released7:
				sbis pind, 7
					rjmp Released7
				out portb, COM_CLEAR_REG
				jmp WaitForInput		

		;---TIME DELAYS---
		Delay1:
			ldi  DELAY_REG1, 21
			ldi  DELAY_REG2, 75
			ldi  DELAY_REG3, 191
		L1: 
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L1
			dec  DELAY_REG2
			brne L1
			dec  DELAY_REG1
			brne L1
			ret

		Delay2:
			ldi  DELAY_REG1, 62
			ldi  DELAY_REG2, 225
			ldi  DELAY_REG3, 64
		L2: 
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L3
			dec  DELAY_REG2
			brne L3
			dec  DELAY_REG1
			brne L3
			ret

		Delay3:
			ldi  DELAY_REG1, 62
			ldi  DELAY_REG2, 225
			ldi  DELAY_REG3, 64
		L3:
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L3
			dec  DELAY_REG2
			brne L3
			dec  DELAY_REG1
			brne L3
			ret

		Delay4:
			ldi  DELAY_REG1, 82
			ldi  DELAY_REG2, 43
			ldi  DELAY_REG3, 0
		L4: 
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L4
			dec  DELAY_REG2
			brne L4
			dec  DELAY_REG1
			brne L4
			ret
			
		Delay6:
			ldi  DELAY_REG1, 122
			ldi  DELAY_REG2, 193
			ldi  DELAY_REG3, 130
		L6: 
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L6
			dec  DELAY_REG2
			brne L6
			dec  DELAY_REG1
			brne L6
			ret
			
		Delay10:
			ldi  DELAY_REG1, 203
			ldi  DELAY_REG2, 236
			ldi  DELAY_REG3, 133
		L10: 
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L10
			dec  DELAY_REG2
			brne L10
			dec  DELAY_REG1
			brne L10
			ret
		
		Delay12:
			ldi  DELAY_REG1, 244
			ldi  DELAY_REG2, 130
			ldi  DELAY_REG3, 6
		L12:
			sbis pind, 5
				rjmp SW5_Pressed
			sbis pind, 7
				rjmp SW7_Pressed
			dec  DELAY_REG3
			brne L12
			dec  DELAY_REG2
			brne L12
			dec  DELAY_REG1
			brne L12
			ret