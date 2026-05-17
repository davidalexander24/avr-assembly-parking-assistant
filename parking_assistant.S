#define __SFR_OFFSET 0
#include <avr/io.h>

; Pinout:
; HC-SR04 : TRIG = PB1 (D9), ECHO = PB0 (D8)
; LED     : HIJAU = PB2 (D10), KUNING = PB3 (D11), MERAH = PB4 (D12)
; Buzzer  : PD3 (D3)
; I2C LCD : SDA = A4, SCL = A5 (Alamat 0x27 / 0x4E Write)

.equ LCD_ADDR_W, 0x4E
.equ LCD_BL, 0x08
.equ LCD_EN, 0x04
.equ LCD_RS, 0x01

; Alamat SRAM untuk menyimpan data sensor
.equ RISE_LO,   0x100
.equ RISE_HI,   0x101
.equ WIDTH_LO,  0x102
.equ WIDTH_HI,  0x103
.equ IC_FLAGS,  0x104

; Pengaturan frekuensi nada buzzer (Timer2 Fast PWM)
.equ TONE_CAUTION, 124      ; Nada peringatan (~500 Hz)
.equ TONE_STOP,    61       ; Nada bahaya (~1 kHz)

.global main
.global __vector_10         ; Interupsi Input Capture Timer1

; Inisialisasi Sistem
main:
    ; Atur Stack Pointer ke batas akhir RAM
    ldi r16, hi8(RAMEND)
    out SPH, r16
    ldi r16, lo8(RAMEND)
    out SPL, r16

    ; Atur arah pin I/O (Output untuk LED dan Buzzer)
    ldi r16, (1<<PB1) | (1<<PB2) | (1<<PB3) | (1<<PB4)
    out DDRB, r16
    ldi r16, (1<<PD3)
    out DDRD, r16

    ; Konfigurasi Timer1 untuk membaca pulsa ECHO (Prescaler 8)
    ldi r16, (1<<ICNC1) | (1<<ICES1) | (1<<CS11)
    sts TCCR1B, r16

    ; Konfigurasi Timer2 untuk PWM Buzzer (Prescaler 256)
    ldi r16, (1<<COM2B1) | (1<<WGM21) | (1<<WGM20)
    sts TCCR2A, r16
    ldi r16, (1<<WGM22) | (1<<CS22) | (1<<CS21)
    sts TCCR2B, r16
    ldi r16, TONE_CAUTION
    sts OCR2A, r16
    ldi r16, 0
    sts OCR2B, r16

    ; Konfigurasi Bus I2C (TWI) kecepatan 100kHz
    ldi r16, 0
    sts TWSR, r16
    ldi r16, 72
    sts TWBR, r16
    ldi r16, (1<<TWEN)
    sts TWCR, r16

    ; Mulai inisialisasi LCD
    rcall lcd_init

    ; Reset status sensor dan aktifkan interupsi global
    ldi r16, 0
    sts IC_FLAGS, r16
    sei

; Loop Utama Program
loop:
    rcall trigger_sensor
    rcall measure_echo
    rcall calc_distance

    ; Batasi jarak maksimal di 255 cm agar muat 3 digit
    cpi r20, 255
    brsh set_max_dist
    mov r24, r20
    rjmp print_dist
set_max_dist:
    ldi r24, 255

print_dist:
    ; Tampilkan teks "DIST: " di baris 1 LCD
    ldi r16, 0x80           
    rcall lcd_command
    ldi r16, 'D'
    rcall lcd_data
    ldi r16, 'I'
    rcall lcd_data
    ldi r16, 'S'
    rcall lcd_data
    ldi r16, 'T'
    rcall lcd_data
    ldi r16, ':'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data

    push r24                ; Amankan data jarak sebelum dicetak
    rcall print_number
    pop r24

    ldi r16, ' '
    rcall lcd_data
    ldi r16, 'c'
    rcall lcd_data
    ldi r16, 'm'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data

    ; Logika penentuan kondisi berdasarkan jarak (r24)
    cpi r24, 100
    brsh state_safe
    cpi r24, 40
    brsh state_caution
    rjmp state_stop

; Kondisi Aman (Jarak >= 100 cm)
state_safe:
    ldi r16, (1<<PB2)       ; LED Hijau menyala
    out PORTB, r16
    ldi r16, 0              ; Buzzer mati
    sts OCR2B, r16

    ; Tampilkan teks "SAFE" di baris 2 LCD
    ldi r16, 0xC0           
    rcall lcd_command
    ldi r16, 'S'
    rcall lcd_data
    ldi r16, 'A'
    rcall lcd_data
    ldi r16, 'F'
    rcall lcd_data
    ldi r16, 'E'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data

    rcall delay_50ms
    rjmp loop

; Kondisi Waspada (Jarak 40 cm hingga 99 cm)
state_caution:
    ldi r16, (1<<PB3)       ; LED Kuning menyala
    out PORTB, r16

    ; Tampilkan teks "CAUTION" di baris 2 LCD
    ldi r16, 0xC0
    rcall lcd_command
    ldi r16, 'C'
    rcall lcd_data
    ldi r16, 'A'
    rcall lcd_data
    ldi r16, 'U'
    rcall lcd_data
    ldi r16, 'T'
    rcall lcd_data
    ldi r16, 'I'
    rcall lcd_data
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'N'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data

    ; Efek suara bip lambat (50ms nyala, 50ms mati)
    ldi r16, TONE_CAUTION
    sts OCR2A, r16
    ldi r16, TONE_CAUTION/2
    sts OCR2B, r16
    rcall delay_50ms
    ldi r16, 0
    sts OCR2B, r16
    rcall delay_50ms
    rjmp loop

; Kondisi Bahaya / Berhenti (Jarak < 40 cm)
state_stop:
    ldi r16, (1<<PB4)       ; LED Merah menyala
    out PORTB, r16

    ; Tampilkan teks "STOP" di baris 2 LCD
    ldi r16, 0xC0
    rcall lcd_command
    ldi r16, 'S'
    rcall lcd_data
    ldi r16, 'T'
    rcall lcd_data
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'P'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data

    ; Efek suara bip cepat (10ms nyala, 10ms mati)
    ldi r16, TONE_STOP
    sts OCR2A, r16
    ldi r16, TONE_STOP/2
    sts OCR2B, r16
    rcall delay_10ms
    ldi r16, 0
    sts OCR2B, r16
    rcall delay_10ms
    rjmp loop

; Subrutin Konversi Nilai Biner ke Karakter ASCII LCD
print_number:
    ldi r18, 0
calc_100:
    cpi r24, 100
    brlo print_100
    subi r24, 100
    inc r18
    rjmp calc_100
print_100:
    mov r16, r18
    subi r16, -48          ; Tambah 48 untuk ubah angka ke karakter ASCII
    rcall lcd_data

    ldi r18, 0
calc_10:
    cpi r24, 10
    brlo print_10
    subi r24, 10
    inc r18
    rjmp calc_10
print_10:
    mov r16, r18
    subi r16, -48
    rcall lcd_data

    mov r16, r24
    subi r16, -48
    rcall lcd_data
    ret

; Subrutin Trigger Pulsa Sensor HC-SR04
trigger_sensor:
    sbi PORTB, PB1
    rcall delay_10us
    cbi PORTB, PB1
    ret

; Subrutin Polling Manual untuk Menghitung Durasi Pulsa Echo
measure_echo:
    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16
    ldi r16, (1<<TOV1)
    out TIFR1, r16

me_wait_rising:
    in  r17, TIFR1
    sbrc r17, TOV1
    rjmp me_timeout
    in  r17, PINB
    sbrs r17, PB0
    rjmp me_wait_rising

    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16
    ldi r16, (1<<TOV1)
    out TIFR1, r16

me_wait_falling:
    in  r17, TIFR1
    sbrc r17, TOV1
    rjmp me_timeout
    in  r17, PINB
    sbrc r17, PB0
    rjmp me_wait_falling

    lds r24, TCNT1L
    lds r25, TCNT1H
    ret

me_timeout:
    ldi r24, 0xFF
    ldi r25, 0xFF
    ret

; Subrutin Hitung Jarak (Hasil Durasi / 116)
calc_distance:
    ldi r18, 116
    ldi r19, 0
    ldi r20, 0
div_loop:
    sub r24, r18
    sbc r25, r19
    brcs div_done
    inc r20
    breq div_overflow      
    rjmp div_loop
div_overflow:
    ldi r20, 0xFF
div_done:
    ret

; ISR Input Capture (Cara Alternatif Membaca Echo via Interupsi)
__vector_10:
    push r16
    push r17
    push r18
    push r19
    in   r19, SREG
    push r19

    lds r16, ICR1L
    lds r17, ICR1H

    lds r18, IC_FLAGS
    sbrc r18, 1
    rjmp isr_falling

isr_rising:
    sts RISE_LO, r16
    sts RISE_HI, r17
    ori r18, (1<<1)        
    sts IC_FLAGS, r18
    lds r19, TCCR1B
    andi r19, 0xBF         ; Balik trigger interupsi ke falling edge
    sts TCCR1B, r19
    rjmp isr_exit

isr_falling:
    lds r18, RISE_LO
    sub r16, r18
    lds r18, RISE_HI
    sbc r17, r18
    sts WIDTH_LO, r16
    sts WIDTH_HI, r17
    ldi r18, 1             
    sts IC_FLAGS, r18

isr_exit:
    pop r19
    out SREG, r19
    pop r19
    pop r18
    pop r17
    pop r16
    reti

; Driver Utama Komunikasi I2C (TWI)
twi_start:
    ldi r17, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    sts TWCR, r17
ts_wait:
    lds r17, TWCR
    sbrs r17, TWINT
    rjmp ts_wait
    ret

twi_stop:
    ldi r17, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    sts TWCR, r17
stop_wait:
    lds r17, TWCR
    sbrc r17, TWSTO        
    rjmp stop_wait
    ret

twi_write:
    sts TWDR, r16
    ldi r17, (1<<TWINT)|(1<<TWEN)
    sts TWCR, r17
tw_wait:
    lds r17, TWCR
    sbrs r17, TWINT
    rjmp tw_wait
    ret

; Driver Pengiriman Data 4-Bit Ke LCD via PCF8574
lcd_send_nibble:
    mov r19, r16
    andi r19, 0xF0         
    ori r19, LCD_BL        
    or r19, r18            

    ; Pulsa EN Low
    rcall twi_start
    ldi r16, LCD_ADDR_W
    rcall twi_write
    mov r16, r19
    rcall twi_write
    rcall twi_stop

    ; Pulsa EN High (Kirim data)
    rcall twi_start
    ldi r16, LCD_ADDR_W
    rcall twi_write
    mov r16, r19
    ori r16, LCD_EN
    rcall twi_write
    rcall twi_stop

    ; Pulsa EN Low Kembali (Latching data)
    rcall twi_start
    ldi r16, LCD_ADDR_W
    rcall twi_write
    mov r16, r19
    rcall twi_write
    rcall twi_stop

    ret

; Subrutin Mengirim Perintah Instruksi ke LCD
lcd_command:
    push r16
    ldi r18, 0             ; Mode Perintah (RS = 0)
    rcall lcd_send_nibble   
    pop r16
    swap r16               
    ldi r18, 0
    rcall lcd_send_nibble   
    rcall delay_2ms        
    ret

; Subrutin Mengirim Karakter Data Teks ke LCD
lcd_data:
    push r16
    ldi r18, LCD_RS        ; Mode Data Teks (RS = 1)
    rcall lcd_send_nibble
    pop r16
    swap r16
    ldi r18, LCD_RS
    rcall lcd_send_nibble
    rcall delay_100us      
    ret

; Urutan Proses Inisialisasi Mode 4-Bit LCD
lcd_init:
    rcall delay_50ms        

    ldi r18, 0             

    ldi r16, 0x30
    rcall lcd_send_nibble
    rcall delay_10ms        

    ldi r16, 0x30
    rcall lcd_send_nibble
    rcall delay_2ms        

    ldi r16, 0x30
    rcall lcd_send_nibble
    rcall delay_2ms

    ldi r16, 0x20
    rcall lcd_send_nibble
    rcall delay_2ms

    ldi r16, 0x28          ; Setelan: 4-bit, 2 baris, font 5x8
    rcall lcd_command

    ldi r16, 0x0C          ; Layar aktif, kursor mati
    rcall lcd_command

    ldi r16, 0x06          ; Geser kursor otomatis ke kanan
    rcall lcd_command

    ldi r16, 0x01          ; Bersihkan layar LCD
    rcall lcd_command
    rcall delay_2ms        

    ret

; Fungsi-Fungsi Delay Berbasis Frekuensi Clock 16 MHz
delay_10us:
    ldi r16, 53
d10us_loop:
    dec r16
    brne d10us_loop
    ret

delay_100us:
    ldi r17, 10
d100us_outer:
    ldi r16, 53
d100us_inner:
    dec r16
    brne d100us_inner
    dec r17
    brne d100us_outer
    ret

delay_2ms:
    ldi r23, 20
d2ms_loop:
    rcall delay_100us
    dec r23
    brne d2ms_loop
    ret

delay_10ms:
    ldi r17, 40
outer10:
    ldi r21, 250
inner10:
    ldi r22, 16
inner_inner10:
    dec r22
    brne inner_inner10
    dec r21
    brne inner10
    dec r17
    brne outer10
    ret

delay_50ms:
    ldi r23, 5
d50_loop:
    rcall delay_10ms
    dec r23
    brne d50_loop
    ret