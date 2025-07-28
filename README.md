# 🛡️ WhatsApp Defender Ultra - Anti Bug System

Sistem pertahanan WhatsApp yang canggih dengan fitur auto block, delete, dan logging untuk melindungi dari berbagai jenis bug dan serangan.

## ✨ Fitur Utama

### 🔍 Deteksi Bug Canggih
- **LID Vulnerability** - Deteksi serangan Link ID
- **CVE-2025-30401** - File attachment spoofing
- **CVE-2025-30259** - PDF exploit detection
- **Text Bomb** - Pesan teks berbahaya
- **Emoji Bomb** - Spam emoji berlebihan
- **Media Bug** - File media berbahaya
- **Contact Bug** - VCard exploit
- **Location Bug** - Koordinat tidak valid
- **Interactive Bug** - Pesan interaktif berbahaya
- **Poll Bug** - Poll spam
- **Crash Bug** - Pattern yang menyebabkan crash
- **Lag Bug** - Pattern yang menyebabkan lag

### ⚡ Performa Unlimited
- **Multi-threading** - Pemrosesan paralel
- **Clustering** - Distribusi beban ke multiple cores
- **Queue System** - Antrian pesan untuk efisiensi maksimal
- **Memory Optimization** - Manajemen memori otomatis
- **CPU Scaling** - Penyesuaian otomatis berdasarkan beban

### 🛡️ Sistem Pertahanan
- **Auto Block** - Blokir pengirim otomatis
- **Auto Delete** - Hapus pesan berbahaya
- **Real-time Logging** - Log semua aktivitas
- **Whitelist** - Perlindungan untuk nomor tertentu
- **Emergency Stop** - Hentikan sistem darurat

### 📊 Monitoring & Analytics
- **Performance Monitor** - Monitor performa sistem
- **Statistics** - Statistik lengkap
- **JSON Logging** - Log dalam format JSON
- **Python Backup Monitor** - Monitor cadangan dengan Python

## 🚀 Instalasi

### Prerequisites
- Node.js v20+ (support v20, v21, v22, v23, v24)
- Python 3.8+ (untuk monitoring cadangan)
- RAM minimal 16GB (disarankan)
- CPU minimal 4 cores (disarankan)

### Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Install Python dependencies (optional)
pip install -r requirements.txt
```

## ⚙️ Konfigurasi

Edit file `config.js` untuk menyesuaikan pengaturan:

```javascript
export const config = {
  // Bot settings
  botName: 'WhatsApp Defender Ultra',
  sessionName: './session',
  
  // Performance settings - Unlimited
  maxConcurrentMessages: 100000,
  messageProcessingDelay: 0,
  blockDelay: 0,
  deleteDelay: 0,
  
  // Auto actions
  autoActions: {
    block: true,
    delete: true,
    log: true,
    notify: false
  },
  
  // Whitelist nomor yang tidak akan diblock
  whitelist: [
    // '6281234567890@s.whatsapp.net'
  ]
}
```

## 🎯 Cara Penggunaan

### 1. Jalankan Bot Utama
```bash
npm start
# atau
node index.js
```

### 2. Jalankan Defender Saja
```bash
npm run defender
# atau
node Defender.js
```

### 3. Jalankan Ultra Defender
```bash
npm run ultra
# atau
node DefendUltra.js
```

### 4. Jalankan Performance Monitor
```bash
npm run performance
# atau
node Performa.js
```

### 5. Jalankan Python Monitor (Backup)
```bash
python Performa.py
```

## 🔗 Koneksi WhatsApp

Bot menggunakan **Pairing Code** untuk koneksi:

1. Jalankan bot
2. Masukkan nomor WhatsApp (format: 62xxx)
3. Dapatkan pairing code
4. Buka WhatsApp > Settings > Linked Devices > Link a Device
5. Masukkan pairing code

## 📋 Log Format

### Terminal Log
```
🚨 BUG DETECTED 🚨
LID: 6281234567890
GROUP/PRIVATE: PRIVATE
TIPE: LID_VULNERABILITY
WAKTU: 2025-01-XX XX:XX:XX
SEVERITY: critical
PATTERNS: LID
MESSAGE_TYPE: conversation
────────────────────────────────────
```

### JSON Log (./logs/defender.json)
```json
{
  "timestamp": "2025-01-XX",
  "lid": "6281234567890",
  "chatType": "PRIVATE",
  "bugType": "LID_VULNERABILITY",
  "messageType": "conversation",
  "severity": "critical",
  "patterns": ["LID"],
  "messageId": "message_id",
  "processed": true
}
```

## 📁 Struktur File

```
whatsapp-defender/
├── Defender.js          # Logika deteksi bug utama
├── DefendUltra.js       # Sistem deteksi canggih dengan clustering
├── Performa.js          # Monitor performa Node.js
├── Performa.py          # Monitor performa Python (backup)
├── config.js            # Konfigurasi sistem
├── index.js             # Entry point utama
├── handler.js           # Handler event WhatsApp
├── package.json         # Dependencies Node.js
├── requirements.txt     # Dependencies Python
├── logs/                # Folder log
│   ├── defender.json    # Log deteksi bug
│   ├── ultra_defender.json # Log ultra defender
│   └── performance.json # Log performa
└── session/             # Session WhatsApp
```

## 🔧 Kustomisasi

### Menambah Pattern Bug Baru

Edit `config.js` di bagian `bugPatterns`:

```javascript
bugPatterns: {
  customBug: [
    /pattern_regex_anda/gi,
    /pattern_lainnya/gi
  ]
}
```

### Mengubah Aksi Otomatis

```javascript
autoActions: {
  block: true,      // Auto block pengirim
  delete: true,     // Auto delete pesan
  log: true,        // Log aktivitas
  notify: false     // Notifikasi (disable untuk performa)
}
```

### Whitelist Nomor

```javascript
whitelist: [
  '6281234567890@s.whatsapp.net',  // Nomor individu
  '6281234567890-1234567890@g.us'  // Group ID
]
```

## 📊 Monitoring

### Performance Stats
- CPU Usage
- Memory Usage  
- Messages per Second
- Processing Rate
- Queue Size
- Uptime

### Defense Stats
- Total Messages Processed
- Bugs Detected
- Users Blocked
- Messages Deleted
- Detection Rate

## 🚨 Troubleshooting

### Bot Tidak Terkoneksi
1. Pastikan nomor WhatsApp aktif
2. Cek koneksi internet
3. Restart bot
4. Hapus folder `session` untuk reset

### Performa Lambat
1. Tingkatkan RAM (minimal 16GB)
2. Gunakan CPU dengan core lebih banyak
3. Tutup aplikasi lain
4. Set `maxConcurrentMessages` lebih rendah

### Error Dependencies
```bash
# Update dependencies
npm update

# Clear cache
npm cache clean --force

# Reinstall
rm -rf node_modules package-lock.json
npm install
```

## ⚠️ Peringatan

- **Gunakan dengan bijak** - Jangan spam atau abuse
- **Server requirement** - Butuh server dengan spek tinggi
- **Legal compliance** - Patuhi ToS WhatsApp
- **Testing** - Test di environment yang aman dulu

## 🛠️ Development

### Menambah Fitur Baru
1. Fork repository
2. Buat branch fitur
3. Implementasi fitur
4. Test thoroughly
5. Submit pull request

### Debug Mode
```bash
DEBUG=true node index.js
```

## 📞 Support

Jika ada masalah atau pertanyaan:
1. Check troubleshooting guide
2. Review configuration
3. Check logs untuk error details
4. Pastikan dependencies ter-update

## 📄 License

MIT License - Gunakan dengan tanggung jawab

## 🙏 Credits

- **Baileys** - WhatsApp Web API
- **WhiskeySockets** - Baileys maintainer
- **Community** - Bug patterns dan detection methods

---

**⚡ WhatsApp Defender Ultra - Maximum Protection, Unlimited Performance! ⚡**
