#picaxe 20M2
;
; "Hello, World!" example
; using
; PICAXE BASIC routines for controling LCD 1602 display with HD44780 driver.
; 
; Tested with: PICAXE 20M2. 
; 
; author:  Martin Pokorny
; version: 2017-09-01
;

; --- LCD 1602 with HD44780 driver in 4 bit mode
; dirsB => pinB.7 : pinB.6 : pinB.5 : pinB.4: pinB.3 : pinB.2 : pinB.1 : pinB.0
;let dirsB = %00111111  ; set port B pins mode (1=output, 0=input)
let dirsB = %11111111  ; set port B pins mode (1=output, 0=input)

symbol D4 = outpinB.0 
symbol D5 = outpinB.1
symbol D6 = outpinB.2
symbol D7 = outpinB.3
                  ; RW=0! -- write; RW is wired to GND for "write" ... 
symbol RS = B.4	  ; RS=0 -- command, RS=1 --character (see lcd_4bm_send*)
symbol E = B.5	  ; E=1 -- active. (see lcd_pulse_E)

symbol lcd_data = b4   ; input data parameter for lcd_* routines 
                       ; (can be command or character)
; --- 

; -------------------------- Hello, World! example

symbol i = b5
symbol text_start = 0
table text_start, ("Hello, World!")
symbol text_lenght = 13
symbol text_end = 12 ; = text_start + text_lenght - 1  !

symbol val = w3

; --- 

setup:
  gosub lcd_4bm_init 
  
  lcd_data = 1
  gosub lcd_move_to_col_at_first_line  
  gosub print_text_to_lcd   ; Hello, World!
  
  val = 0
    
main_loop:
  lcd_data = 0
  gosub lcd_move_to_col_at_second_line  
  gosub print_val_to_lcd
  
  val = val + 1
  if val = 100 then 
    val = 0    
  endif
  
  ;end
  pause 990
  goto main_loop
  
; ---

print_text_to_lcd:
  for i = text_start to text_end
    readtable i, lcd_data
    gosub lcd_4bm_send_char
  next i
  return

print_val_to_lcd:
  lcd_data = val / 10 // 10 + "0"
  gosub lcd_4bm_send_char
  lcd_data = val // 10 + "0"
  gosub lcd_4bm_send_char
  
  return
  
; --------------------------


; --- LCD 1602 with HD44780 driver in 4 bit mode

lcd_4bm_send_cmd:
  low RS	; RS=0 -- command
  gosub lcd_4bm_send
  return    
    
lcd_4bm_send_char:
  high RS	; RS=1 -- character
  gosub lcd_4bm_send
  return
    
lcd_4bm_send:
  ; 1. Msb of lcd_data
  gosub lcd_Msb_to_Dx_pins
  gosub lcd_pulse_E

  ; 2. lsb of lcd_data
  gosub lcd_lsb_to_Dx_pins
  gosub lcd_pulse_E

  return    

lcd_pulse_E:
  ; E minimal pulse width (high) = 250 ns (for 5V)
  ; E minimal cycle time = 500 ns (for 5V)  
  high E
  pauseus 1    ; 1 = 10 us for 4 MHz / 5 us for 8MHz / ...
  low E 
  pauseus 1
  return

; set four lsb bits of lcd_data variable
lcd_lsb_to_Dx_pins:
  D4 = lcd_data      ; this take only last bit from lcd_data
  D5 = lcd_data / %10    ; (lcd_data / %10 ~~ lcd_data >> 1 ...)
  D6 = lcd_data / %100
  D7 = lcd_data / %1000
  return

; set four Msb bits of lcd_data variable
lcd_Msb_to_Dx_pins:
  D4 = lcd_data / %10000
  D5 = lcd_data / %100000
  D6 = lcd_data / %1000000
  D7 = lcd_data / %10000000
  return

; Init 4 bit interface mode.
; See page 46 of HD44780 datasheet for more details...
lcd_4bm_init:
  pause 50
  
  low RS	; (RS=0 -- command)
  lcd_data = %0011 
  gosub lcd_lsb_to_Dx_pins
  gosub lcd_pulse_E
  pause 5   ; wait for more than 4.1 ms
  gosub lcd_pulse_E
  pauseus 200   ; wait for more than 100 us 
  gosub lcd_pulse_E
  
  lcd_data = %0010
  gosub lcd_lsb_to_Dx_pins
  gosub lcd_pulse_E
  
  ; -- 4 bit mode is ready now
  ; initialization...
  ; %001L NF** -- "Function set"
  lcd_data = %00101000	; = two lines, font 5x8 dots
  gosub lcd_4bm_send_cmd
  
  ; %00000001 -- "Clear"
  lcd_data = %00000001
  gosub lcd_4bm_send_cmd
  
  ; %0000 01IS -- "Entry mode set"
  lcd_data = %00000110	; = left to right, without display shift
  gosub lcd_4bm_send_cmd
  
  ; %0000 1DCB  -- "Display on/off control"
  lcd_data = %00001100	; = display on, without cursor, without blinking
  gosub lcd_4bm_send_cmd
  
  #rem
    -- legend:  (see HD44780 datasheet ...)
    D - 1 = display on, 0 = display off
    I - 1 = cursor increment by 1 to the right, 0 = to the left
    S - display shift...  0 = without shift (see datasheet for details)
    C - 1 = cursor visible, 0 = hidden
    B - 1 = cursor blinking, 0 = without blinking
    L - 1 = 8.bit mode, 0 = 4.bit mode
    N - number of lines; 1 = 2 lines, 0 = 1 line
        For N = 1, font is always 5x8 dots
    F - font selection; 0 = 5x8 dots, 1 = 5x10 dots
    * = doesn't matter
  #endrem
  
  return
  
lcd_clear:
  lcd_data = %00000001
  gosub lcd_4bm_send_cmd
  return

; example:
;   lcd_data = 5
;   gosub lcd_move_to_col_at_second_line;  
;   ; --> ... command = %11000101 (%101 + %11000000)
; -->
; |
; |....._
lcd_move_to_col_at_second_line:
  lcd_data = lcd_data + %11000000
  gosub lcd_4bm_send_cmd
  return
  
lcd_move_to_col_at_first_line:
  lcd_data = lcd_data + %10000000
  gosub lcd_4bm_send_cmd
  return
  
lcd_move_to_right:  
  lcd_data = %00010000
  gosub lcd_4bm_send_cmd
  return
  
lcd_move_to_left:  
  lcd_data = %00010100
  gosub lcd_4bm_send_cmd
  return

