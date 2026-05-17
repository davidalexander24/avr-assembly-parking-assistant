# Parking Assistant

## Introduction to the Problem and the Solution

Proses parkir kendaraan sering kali menjadi sulit, terutama pada area yang sempit atau padat kendaraan. Keterbatasan jarak pandang pengemudi dapat menyebabkan kesalahan dalam memperkirakan jarak antara kendaraan dan objek di sekitarnya sehingga meningkatkan risiko terjadinya benturan saat parkir. Untuk mengatasi permasalahan tersebut, proyek ini mengimplementasikan sebuah Parking Assistant berbasis embedded system menggunakan mikrokontroler AVR dan sensor ultrasonik HC-SR04. Sistem dirancang untuk mendeteksi jarak kendaraan terhadap objek secara real-time dan memberikan peringatan kepada pengemudi melalui tampilan LCD, LED, dan buzzer. Jarak yang terdeteksi akan ditampilkan pada LCD I2C beserta status kondisi parkir seperti **Safe**, **Caution**, dan **Stop**. Selain itu, LED indikator dan buzzer digunakan sebagai peringatan tambahan, di mana frekuensi bunyi buzzer akan semakin cepat ketika kendaraan semakin dekat dengan objek.

---

## Hardware Design and Implementation Details

### Komponen yang Digunakan
- Arduino Uno / ATmega328P
- Sensor Ultrasonik HC-SR04
- LCD I2C 16x2
- LED Hijau
- LED Kuning
- LED Merah
- Buzzer
- Resistor
- Breadboard dan kabel jumper

### Konfigurasi Pin

| Komponen | Pin |
|---|---|
| HC-SR04 Trigger | PB1 (D9) |
| HC-SR04 Echo | PB0 (D8 / ICP1) |
| LED Hijau | PB2 (D10) |
| LED Kuning | PB3 (D11) |
| LED Merah | PB4 (D12) |
| Buzzer | PD3 (D3 / OC2B) |
| LCD SDA | A4 |
| LCD SCL | A5 |

### Cara Kerja Sistem

Sensor ultrasonik HC-SR04 digunakan untuk mendeteksi jarak kendaraan terhadap objek di sekitarnya. Sensor memancarkan gelombang ultrasonik melalui pin trigger dan menerima pantulan gelombang melalui pin echo. Mikrokontroler AVR kemudian menghitung waktu pantulan tersebut untuk menentukan jarak objek dalam satuan sentimeter. Data jarak yang diperoleh diproses oleh mikrokontroler dan ditampilkan pada LCD I2C. Sistem juga menggunakan LED dan buzzer sebagai indikator tambahan:
- LED hijau menunjukkan kondisi aman
- LED kuning menunjukkan kondisi hati-hati
- LED merah menunjukkan kondisi berhenti

Buzzer menghasilkan pola bunyi dengan frekuensi yang semakin cepat ketika kendaraan semakin dekat dengan objek.

---

## Software Implementation Details

Program pada sistem dikembangkan menggunakan bahasa Assembly AVR. Program mengimplementasikan beberapa konsep embedded systems seperti GPIO, timer, interrupt, PWM, dan komunikasi I2C.

### Pengukuran Sensor

Sensor HC-SR04 diaktifkan menggunakan sinyal trigger singkat. Durasi sinyal echo kemudian diukur menggunakan Timer1 Input Capture Interrupt agar hasil pengukuran lebih akurat.

### Perhitungan Jarak

Data pulse width dari sinyal echo dikonversi menjadi nilai jarak dalam satuan sentimeter menggunakan rumus perhitungan sensor ultrasonik.

### Komunikasi LCD I2C

LCD menggunakan komunikasi I2C melalui modul PCF8574 sehingga penggunaan pin pada mikrokontroler menjadi lebih efisien. LCD menampilkan informasi jarak dan status kondisi parkir secara real-time.

### Sistem Peringatan

Sistem memiliki tiga kondisi utama:
- **Safe**: kendaraan berada pada jarak aman
- **Caution**: kendaraan mulai mendekati objek
- **Stop**: kendaraan berada sangat dekat dengan objek

PWM digunakan untuk menghasilkan pola bunyi buzzer dengan frekuensi berbeda pada setiap kondisi.

---

## Test Results and Performance Evaluation

Pengujian sistem dilakukan menggunakan simulasi Wokwi dan implementasi rangkaian fisik secara langsung. Hasil pengujian menunjukkan bahwa sensor HC-SR04 mampu mendeteksi jarak objek dan menampilkan hasil pengukuran secara real-time pada LCD. Sistem juga berhasil mengubah status kondisi parkir secara otomatis berdasarkan jarak objek yang terdeteksi. LED indikator bekerja sesuai dengan kondisi sistem:
- LED hijau menyala pada kondisi aman
- LED kuning menyala pada kondisi hati-hati
- LED merah menyala pada kondisi berhenti

Buzzer juga berhasil menghasilkan pola bunyi yang berbeda sesuai kondisi jarak. Frekuensi bunyi menjadi semakin cepat ketika kendaraan semakin dekat dengan objek. Fitur Timer1 Input Capture Interrupt berhasil meningkatkan akurasi pembacaan sinyal echo, sedangkan PWM mampu menghasilkan output suara buzzer yang stabil. Komunikasi I2C pada LCD juga berjalan dengan baik selama proses pengujian. Sistem berhasil bekerja dengan stabil dan mampu memberikan bantuan parkir secara real-time.

---

## Conclusion and Future Work

Smart Parking Assistant System berhasil dirancang dan diimplementasikan menggunakan mikrokontroler AVR dan bahasa Assembly. Sistem mampu mendeteksi jarak objek secara real-time dan memberikan informasi serta peringatan kepada pengguna melalui LCD, LED, dan buzzer. Proyek ini berhasil mengimplementasikan berbagai konsep embedded systems. Untuk pengembangan selanjutnya, sistem dapat ditingkatkan dengan menambahkan lebih banyak sensor agar area deteksi lebih luas, menambahkan fitur komunikasi wireless, atau mengembangkan sistem parkir otomatis yang lebih canggih.
