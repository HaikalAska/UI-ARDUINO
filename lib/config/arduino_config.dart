// ============================================================================
// KONFIGURASI INTEGRASI ARDUINO & PYTHON SERVER (T.H.A.L.I.A)
// ============================================================================
//
// FILE INI KHUSUS DISEDIAKAN UNTUK REKAN TIM YANG MENGERJAKAN ARDUINO + PYTHON!
// ----------------------------------------------------------------------------
// Di sini tempat mengatur koneksi dari Arduino (via Serial USB / COM Port)
// yang dibaca oleh script Python (Flask / FastAPI), lalu dikirim ke aplikasi
// Flutter T.H.A.L.I.A secara real-time (khususnya data Kelembapan Tanah /
// Soil Moisture dan Kelembapan Udara).
//
// Catatan: Sesuai pembagian tugas saat ini, angka Suhu Utama (28°C / Terasa 30°C)
// masih dijaga tetap menggunakan angka dummy stabil (`keepTemperatureDummy = true`).
//
// ============================================================================
// PANDUAN CEPAT UNTUK TEMAN YANG MENGERJAKAN ARDUINO & PYTHON (COPY-PASTE):
// ============================================================================
//
// 1. CONTOH KODE ARDUINO (`sensor_tanah.ino`):
// ----------------------------------------------------------------------------
// ```cpp
// const int SOIL_PIN = A0; // Pin analog sensor kelembapan tanah (Soil Moisture)
//
// void setup() {
//   Serial.begin(9600);
// }
//
// void loop() {
//   int rawValue = analogRead(SOIL_PIN);
//   // Konversi nilai analog (misal 1023 = kering 0%, 300 = basah 100%)
//   int soilPercent = map(rawValue, 1023, 300, 0, 100);
//   soilPercent = constrain(soilPercent, 0, 100);
//
//   // Kirim format JSON ke Serial agar mudah dibaca Python
//   Serial.print("{\"soil_moisture\": ");
//   Serial.print(soilPercent);
//   Serial.println("}");
//
//   delay(2000);
// }
// ```
//
// 2. CONTOH KODE PYTHON SERVER (`server_arduino.py` dengan Flask + pyserial):
// ----------------------------------------------------------------------------
// Install library dulu di terminal:
//   pip install flask flask-cors pyserial
//
// ```python
// import json
// import threading
// import serial
// from flask import Flask, jsonify
// from flask_cors import CORS
//
// app = Flask(__name__)
// CORS(app)
//
// # Ganti 'COM3' sesuai port Arduino di Laptop (Windows: 'COM3'/'COM4', Linux/Mac: '/dev/ttyUSB0')
// SERIAL_PORT = 'COM3'
// BAUD_RATE = 9600
//
// latest_sensor_data = {
//     "soil_moisture": 38,                       # Persentase kelembapan tanah (0 - 100)
//     "humidity": 72,                            # Opsional: Kelembapan udara % (0 - 100)
//     "pressure": 1012,                          # Opsional: Tekanan udara hPa
//     "landslide_risk": "Rendah (Struktur Tanah Padat)" # Opsional: Status risiko lereng
// }
//
// def read_from_arduino():
//     global latest_sensor_data
//     try:
//         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
//         print(f"[OK] Terhubung ke Arduino di {SERIAL_PORT}")
//         while True:
//             line = ser.readline().decode('utf-8', errors='ignore').strip()
//             if line.startswith('{') and line.endswith('}'):
//                 data = json.loads(line)
//                 latest_sensor_data.update(data)
//             elif line.isdigit():
//                 # Jika Arduino hanya mengirim angka saja, misal: 45
//                 latest_sensor_data["soil_moisture"] = int(line)
//     except Exception as e:
//         print(f"[INFO] Arduino belum dicolok / simulasi Python aktif: {e}")
//
// @app.route('/api/sensor', methods=['GET'])
// def get_sensor():
//     return jsonify(latest_sensor_data)
//
// if __name__ == '__main__':
//     t = threading.Thread(target=read_from_arduino, daemon=True)
//     t.start()
//     # host='0.0.0.0' wajib agar HP Android bisa mengakses IP laptop via Wi-Fi/Hotspot yang sama
//     app.run(host='0.0.0.0', port=5000, debug=False)
// ```
//
// 3. LANGKAH MENYAMBUNGKAN KE APLIKASI FLUTTER INI:
// ----------------------------------------------------------------------------
// a) Pastikan HP Android dan Laptop berada di jaringan Wi-Fi / Hotspot yang sama.
// b) Cek IP Laptop kamu (ketik `ipconfig` di CMD Windows, lihat IPv4 Address,
//    misalnya `192.168.1.15`).
// c) Ubah [pythonServerEndpoint] di bawah menjadi `'http://192.168.1.15:5000/api/sensor'`.
// d) Ubah [enableLiveArduinoPolling] menjadi `true`.
// ============================================================================

class ArduinoConfig {
  ArduinoConfig._();

  // ===========================================================================
  // 1. PENGATURAN ENDPOINT PYTHON SERVER (FLASK / FASTAPI)
  // ===========================================================================
  /// URL Endpoint HTTP GET dari server Python yang membaca serial Arduino.
  /// - Gunakan IPv4 Laptop jika memakai HP fisik (misal: `'http://192.168.1.100:5000/api/sensor'`)
  /// - Gunakan `'http://10.0.2.2:5000/api/sensor'` jika memakai Emulator Android.
  static const String pythonServerEndpoint =
      'http://192.168.1.100:5000/api/sensor';

  /// Ubah ke `true` jika server Python + Arduino sudah siap dijalankan.
  /// Jika `false` (atau jika server Python sedang mati/belum aktif), aplikasi
  /// otomatis memakai nilai fallback default tanpa error/crash.
  static const bool enableLiveArduinoPolling = false;

  /// Jeda waktu pengambilan data otomatis dari server Python (dalam detik).
  static const int pollingIntervalSeconds = 3;

  /// Timeout koneksi HTTP ke server Python (dalam detik) agar UI tidak macet
  /// apabila laptop / server Python belum dinyalakan.
  static const int requestTimeoutSeconds = 3;

  // ===========================================================================
  // 2. PENGATURAN PARAMETER DUMMY VS SENSOR ASLI
  // ===========================================================================
  /// Sesuai kesepakatan: suhu utama dibiarkan memakai angka dummy dulu (`28°` &
  /// `Terasa seperti 30°`), sedangkan Kelembapan Tanah (`soil_moisture`) siap
  /// disuplai langsung dari Arduino + Python.
  static const bool keepTemperatureDummy = true;

  /// Nilai awal / fallback Kelembapan Tanah (%) saat Arduino belum tersambung.
  static const int defaultSoilMoisture = 38;

  /// Nilai awal / fallback Kelembapan Udara (%) saat Arduino belum tersambung.
  static const int defaultAirHumidity = 72;

  /// Nilai awal / fallback Tekanan Udara (hPa) saat Arduino belum tersambung.
  static const int defaultAirPressure = 1012;
}
