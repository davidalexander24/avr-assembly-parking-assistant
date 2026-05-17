# Parking Assistant Documentation

## Project Overview

Parking Assistant adalah sistem bantuan parkir berbasis embedded system yang menggunakan sensor ultrasonik HC-SR04 untuk mendeteksi jarak kendaraan terhadap objek di sekitarnya secara real-time. Sistem memberikan informasi jarak melalui LCD I2C serta indikator LED dan buzzer sebagai peringatan tambahan.

---

# Hardware Components

- Arduino Uno
- HC-SR04 Ultrasonic Sensor
- LCD I2C 16x2
- Green LED
- Yellow LED
- Red LED
- Buzzer
- Resistor
- Breadboard dan jumper wires

---

# Pin Configuration

| Component | Pin |
|---|---|
| HC-SR04 Trigger | D9 |
| HC-SR04 Echo | D8 |
| Green LED | D10 |
| Yellow LED | D11 |
| Red LED | D12 |
| Buzzer | D3 |
| LCD SDA | A4 |
| LCD SCL | A5 |

---

# System Workflow

1. Sensor HC-SR04 mendeteksi jarak objek.
2. Mikrokontroler menghitung jarak berdasarkan sinyal echo.
3. Data jarak ditampilkan pada LCD I2C.
4. Sistem menentukan status:
   - Safe
   - Caution
   - Stop
5. LED dan buzzer aktif sesuai kondisi jarak.

---

# Parking Conditions

| Distance | Status |
|---|---|
| > 100 cm | Safe |
| 40 - 100 cm | Caution |
| < 40 cm | Stop |

---

# Physical Circuit

![image](https://hackmd.io/_uploads/SyIxgIvJGe.png)

---

# Wokwi Simulation

https://wokwi.com/projects/464276552516298753

# Demo Video

https://youtu.be/kH2r50AA-uY