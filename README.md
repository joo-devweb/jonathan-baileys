# 📱 WhatsApp V-Lang Library

**Library WhatsApp Web API untuk V Programming Language** - Implementasi lengkap protokol WhatsApp Web dengan dukungan QR Code dan Pairing Code authentication.

[![V Version](https://img.shields.io/badge/V-0.4.11+-blue.svg)](https://vlang.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Author](https://img.shields.io/badge/Author-Nathan.dev-orange.svg)](https://github.com/nathan-dev)

---

## 🚀 Fitur Utama

### ✨ **Protokol WhatsApp Web Lengkap**
- 🔗 WebSocket connection dengan proper headers dan extensions
- 🔐 Binary node parsing dan encoding sesuai protokol WhatsApp
- 🛡️ AES-256-CBC encryption/decryption untuk semua komunikasi
- 🔑 HMAC-SHA256 message authentication
- 🔄 Curve25519 ECDH key exchange
- 📊 HKDF key derivation sesuai standar

### 🔐 **Metode Autentikasi**
- ✅ **QR Code Authentication** - Scan dengan aplikasi WhatsApp mobile
- ✅ **Pairing Code Authentication** - Input kode di aplikasi mobile  
- ✅ **Session Restoration** - Auto-login dengan session tersimpan
- 🔄 Auto-reconnect dengan exponential backoff
- 💾 Persistent session storage

### 💬 **Manajemen Pesan**
- 📤 Kirim/terima pesan teks dengan enkripsi penuh
- 🖼️ Dukungan media (gambar, video, audio, dokumen)
- 📝 Message parsing dan decryption real-time
- 🔔 Event-driven message handling
- 💾 Local message storage dan caching
- ✅ Read receipts dan delivery status

### 🛠️ **Utilitas & Tools**
- 🎨 Built-in ASCII QR code generator
- 📊 Comprehensive logging dan debugging
- 🔄 Automatic session management
- 🌐 Multi-platform support (Linux, Windows, macOS)
- 📚 Type-safe API dengan V's strong typing

---

## 📦 Instalasi

### Prasyarat
- V Programming Language v0.4.11 atau lebih baru
- Internet connection untuk koneksi WhatsApp Web

### Clone Repository
```bash
git clone https://github.com/nathan-dev/whatsapp-v-lang.git
cd whatsapp-v-lang
```

### Build Library
```bash
v build .
```

---

## 🎯 Quick Start

### 1. Basic Usage dengan QR Code

```v
import whatsapp

fn main() {
    // Konfigurasi session
    config := whatsapp.SessionConfig{
        auth_method: .qr_code
        browser_name: 'My V Bot'
        browser_version: '1.0.0'
        print_qr: true
        session_path: './session_data'
    }
    
    // Buat session baru
    mut session := whatsapp.new_session(config) or {
        panic('Failed to create session: ${err}')
    }
    
    // Start session
    session.start() or {
        panic('Failed to start session: ${err}')
    }
    
    // Wait sampai ready
    for session.get_state() != .ready {
        time.sleep(1 * time.second)
    }
    
    println('✅ WhatsApp connected!')
    
    // Kirim pesan
    options := whatsapp.SendMessageOptions{}
    session.send_message('6281234567890@s.whatsapp.net', 'Hello from V!', options) or {
        println('Failed to send message: ${err}')
    }
}
```

### 2. Menggunakan Pairing Code

```v
import whatsapp

fn main() {
    config := whatsapp.SessionConfig{
        auth_method: .pairing_code
        phone_number: '+6281234567890' // Nomor HP Anda
        browser_name: 'V WhatsApp Bot'
        session_path: './session_data'
    }
    
    mut session := whatsapp.new_session(config) or {
        panic('Failed to create session: ${err}')
    }
    
    session.start() or {
        panic('Failed to start: ${err}')
    }
    
    // Pairing code akan ditampilkan di console
    // Masukkan code tersebut di WhatsApp mobile app
}
```

### 3. Event Handling

```v
import whatsapp

fn main() {
    // Setup event callbacks
    mut callbacks := whatsapp.EventCallbacks{
        on_message: fn (message whatsapp.Message) {
            println('📩 New message from ${message.remote_jid}: ${message.text}')
        }
        
        on_connection_update: fn (state whatsapp.ConnectionState, data map[string]string) {
            println('🔄 Connection state: ${state}')
        }
        
        on_qr_code: fn (qr_data string) {
            println('📱 Scan this QR code with your phone')
            // QR akan otomatis ditampilkan jika print_qr: true
        }
    }
    
    config := whatsapp.SessionConfig{
        auth_method: .qr_code
        session_path: './session_data'
    }
    
    mut session := whatsapp.new_session(config) or { panic(err) }
    session.start() or { panic(err) }
    
    // Keep alive
    for {
        time.sleep(1 * time.second)
    }
}
```

---

## 📚 API Documentation

### 🏗️ **Core Types**

#### SessionConfig
```v
struct SessionConfig {
    auth_method     AuthMethod = .qr_code    // Metode autentikasi
    browser_name    string = 'V-WhatsApp'    // Nama browser
    browser_version string = '1.0.0'         // Versi browser
    phone_number    string                   // Nomor HP (untuk pairing code)
    print_qr        bool = true              // Print QR code ke console
    session_path    string = './session'     // Path penyimpanan session
    log_level       string = 'info'          // Level logging
}
```

#### Message
```v
struct Message {
    id                string              // ID pesan
    remote_jid        string              // JID pengirim/penerima
    from_me           bool                // Apakah dari kita
    participant       string              // Participant (untuk grup)
    timestamp         u64                 // Timestamp pesan
    status            MessageStatus       // Status pesan
    message_type      MessageType         // Tipe pesan
    text              string              // Isi pesan teks
    quoted_message    ?&Message           // Pesan yang di-quote
    media_info        ?MediaInfo          // Info media (jika ada)
    // ... dan banyak field lainnya
}
```

### 🔧 **Main Methods**

#### Session Management
```v
// Buat session baru
fn new_session(config SessionConfig) !&Session

// Start session dan autentikasi
fn (mut session Session) start() !

// Get status koneksi
fn (session &Session) get_state() ConnectionState

// Logout dan cleanup
fn (mut session Session) logout() !
```

#### Messaging
```v
// Kirim pesan teks
fn (mut session Session) send_message(jid string, text string, options SendMessageOptions) !string

// Get daftar chat
fn (session &Session) get_chats() map[string]Chat

// Get pesan dari chat tertentu
fn (session &Session) get_messages(jid string) []Message
```

---

## 🎨 Examples

### Bot Sederhana
```v
import whatsapp
import time

fn main() {
    config := whatsapp.SessionConfig{
        auth_method: .qr_code
        browser_name: 'V Echo Bot'
        session_path: './bot_session'
    }
    
    mut session := whatsapp.new_session(config) or { panic(err) }
    
    // Setup message handler
    session.event_callbacks.on_message = fn [mut session] (message whatsapp.Message) {
        if !message.from_me && message.text.starts_with('!echo ') {
            response := message.text[6..] // Remove "!echo "
            options := whatsapp.SendMessageOptions{
                quoted_message_id: message.id
            }
            
            session.send_message(message.remote_jid, 'Echo: ${response}', options) or {
                println('Failed to send echo: ${err}')
            }
        }
    }
    
    session.start() or { panic(err) }
    
    // Keep bot running
    for {
        time.sleep(1 * time.second)
    }
}
```

### Group Management
```v
import whatsapp

fn main() {
    // ... setup session ...
    
    // Get grup info
    chats := session.get_chats()
    for jid, chat in chats {
        if chat.chat_type == .group {
            println('📱 Group: ${chat.name}')
            println('   JID: ${jid}')
            println('   Members: ${chat.group_metadata?.participants.len or { 0 }}')
        }
    }
}
```

---

## 🔧 Advanced Configuration

### Custom Event Callbacks
```v
mut callbacks := whatsapp.EventCallbacks{
    on_qr_code: fn (qr_data string) {
        // Custom QR handling
        save_qr_to_file(qr_data)
    }
    
    on_pairing_code: fn (code string) {
        // Custom pairing code handling
        send_code_via_email(code)
    }
    
    on_message: fn (message whatsapp.Message) {
        // Custom message processing
        process_incoming_message(message)
    }
    
    on_message_receipt: fn (receipt whatsapp.ReceiptInfo) {
        // Handle read receipts
        println('Message ${receipt.message_id} was ${receipt.receipt_type}')
    }
    
    on_presence_update: fn (presence whatsapp.PresenceInfo) {
        // Handle presence updates
        println('${presence.jid} is ${presence.presence_type}')
    }
    
    on_error: fn (error string, data map[string]string) {
        // Custom error handling
        log_error(error, data)
    }
}
```

### Session Persistence
```v
// Session akan otomatis disimpan ke file
// dan di-restore saat startup berikutnya

config := whatsapp.SessionConfig{
    session_path: './my_bot_session'  // Folder penyimpanan
    // ... config lainnya
}

// Session file akan dibuat di:
// ./my_bot_session/session.json
```

---

## 🛡️ Security & Best Practices

### 🔐 **Keamanan**
- ✅ Semua komunikasi dienkripsi end-to-end
- ✅ Private keys disimpan aman di local storage
- ✅ Session tokens di-encrypt sebelum disimpan
- ✅ HMAC validation untuk semua pesan masuk
- ⚠️ Jangan share session files dengan orang lain

### 📋 **Best Practices**
- 🔄 Selalu handle error dengan proper error handling
- 💾 Backup session files secara berkala
- 🚫 Jangan spam pesan (WhatsApp punya rate limiting)
- 📱 Test dengan nomor sendiri dulu sebelum production
- 🔍 Enable logging untuk debugging

### ⚡ **Performance Tips**
- 🎯 Gunakan event callbacks untuk handling real-time
- 💾 Implement message caching untuk aplikasi besar
- 🔄 Batch multiple operations jika memungkinkan
- 📊 Monitor memory usage untuk long-running bots

---

## 🐛 Troubleshooting

### Masalah Umum

#### 1. QR Code tidak muncul
```bash
# Pastikan terminal mendukung Unicode
export LANG=en_US.UTF-8

# Atau disable QR printing
config.print_qr = false
```

#### 2. Session tidak tersimpan
```bash
# Pastikan folder session bisa ditulis
mkdir -p ./session_data
chmod 755 ./session_data
```

#### 3. Koneksi sering terputus
```v
// Increase timeout values
config := whatsapp.SessionConfig{
    // ... other config
    log_level: 'debug'  // Enable debug logging
}
```

#### 4. Error saat compile
```bash
# Update V ke versi terbaru
v self-update

# Clean build cache
v clean-cache
```

---

## 🤝 Contributing

Kontribusi sangat diterima! Berikut cara berkontribusi:

### 1. Fork Repository
```bash
git fork https://github.com/nathan-dev/whatsapp-v-lang.git
```

### 2. Create Feature Branch
```bash
git checkout -b feature/amazing-feature
```

### 3. Commit Changes
```bash
git commit -m 'Add amazing feature'
```

### 4. Push & Create PR
```bash
git push origin feature/amazing-feature
# Buat Pull Request di GitHub
```

### 📋 **Development Guidelines**
- 🧪 Tambahkan tests untuk fitur baru
- 📚 Update dokumentasi jika diperlukan
- 🎨 Follow V coding conventions
- 🔍 Pastikan tidak ada breaking changes

---

## 📄 License

Project ini dilisensikan dengan **MIT License** - lihat file [LICENSE](LICENSE) untuk detail.

```
MIT License

Copyright (c) 2025 Nathan.dev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

---

## 👨‍💻 Author

**Nathan.dev**
- 🌐 GitHub: [@nathan-dev](https://github.com/nathan-dev)
- 📧 Email: nathan@example.com
- 🐦 Twitter: [@nathandev](https://twitter.com/nathandev)

---

## 🙏 Acknowledgments

- 🎯 **WhiskeySocket Baileys** - Inspirasi utama untuk implementasi protokol
- 🚀 **V Language Team** - Bahasa pemrograman yang amazing
- 🌍 **WhatsApp** - Platform messaging terbaik
- 👥 **Open Source Community** - Support dan kontribusi

---

## ⭐ Star History

Jika project ini berguna, jangan lupa kasih ⭐ ya!

[![Star History Chart](https://api.star-history.com/svg?repos=nathan-dev/whatsapp-v-lang&type=Date)](https://star-history.com/#nathan-dev/whatsapp-v-lang&Date)

---

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/nathan-dev/whatsapp-v-lang?style=social)
![GitHub forks](https://img.shields.io/github/forks/nathan-dev/whatsapp-v-lang?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/nathan-dev/whatsapp-v-lang?style=social)

---

<div align="center">

**🚀 Built with ❤️ using V Programming Language**

[⬆ Back to Top](#-whatsapp-v-lang-library)

</div>
