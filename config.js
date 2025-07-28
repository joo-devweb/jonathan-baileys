import fs from 'fs'
import path from 'path'

// Konfigurasi utama
export const config = {
  // Bot settings
  botName: 'WhatsApp Defender Ultra',
  sessionName: './session',
  
  // Performance settings - Unlimited untuk performa maksimal
  maxConcurrentMessages: 100000,
  messageProcessingDelay: 0,
  blockDelay: 0,
  deleteDelay: 0,
  
  // Bug detection patterns
  bugPatterns: {
    // LID (Link ID) vulnerability patterns
    lid: [
      /[\u200B-\u200F\uFEFF]/g, // Zero-width characters
      /\u202E/g, // Right-to-left override
      /\u202D/g, // Left-to-right override
      /[\u2060-\u206F]/g, // Word joiner and invisible characters
      /\u00AD/g, // Soft hyphen
    ],
    
    // CVE-2025-30401 file attachment spoofing
    fileSpoof: [
      /\.(exe|scr|bat|cmd|com|pif|vbs|js|jar|zip)$/i,
      /data:application\/octet-stream/i,
      /javascript:/i,
      /vbscript:/i,
    ],
    
    // PDF exploit patterns (CVE-2025-30259)
    pdfExploit: [
      /\/JavaScript/i,
      /\/JS/i,
      /\/OpenAction/i,
      /\/AA/i,
      /\/Launch/i,
      /\/EmbeddedFile/i,
    ],
    
    // Text bomb patterns
    textBomb: [
      /(.)\1{1000,}/g, // Repeated characters
      /.{10000,}/g, // Very long messages
      /[\u0300-\u036F]{50,}/g, // Combining diacritical marks
      /[\u1AB0-\u1AFF]{50,}/g, // Combining diacritical marks extended
    ],
    
    // Emoji bomb patterns  
    emojiBomb: [
      /([\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]){100,}/gu,
      /[\u{FE00}-\u{FE0F}]{50,}/gu, // Variation selectors
    ],
    
    // Location bug patterns
    locationBug: [
      /degreesLatitude.*[^\d\-\.]/i,
      /degreesLongitude.*[^\d\-\.]/i,
      /location.*script/i,
    ],
    
    // Contact bug patterns
    contactBug: [
      /BEGIN:VCARD.*<script/is,
      /FN:.*[<>]/i,
      /TEL:.*[<>]/i,
    ],
    
    // Media bug patterns
    mediaBug: [
      /\.jse?g\.exe$/i,
      /\.mp4\.exe$/i,
      /\.pdf\.exe$/i,
      /data:text\/html/i,
    ],
    
    // Crash patterns
    crash: [
      /\u0001[\s\S]*\u0001/g, // Control characters
      /[\u{E0000}-\u{E007F}]{10,}/gu, // Tags
      /[\u{1D100}-\u{1D1FF}]{50,}/gu, // Musical symbols
    ],
    
    // Lag patterns
    lag: [
      /[\u{1F1E6}-\u{1F1FF}]{20,}/gu, // Flag emojis spam
      /[\u{1F9B0}-\u{1F9FF}]{50,}/gu, // Extended pictographs
    ]
  },
  
  // Message types to check
  messageTypes: [
    'conversation',
    'extendedTextMessage', 
    'imageMessage',
    'videoMessage',
    'audioMessage',
    'documentMessage',
    'contactMessage',
    'locationMessage',
    'liveLocationMessage',
    'stickerMessage',
    'buttonsMessage',
    'templateMessage',
    'listMessage',
    'interactiveMessage',
    'pollCreationMessage',
    'pollUpdateMessage'
  ],
  
  // Auto actions
  autoActions: {
    block: true,
    delete: true,
    log: true,
    notify: false // Set false untuk menghindari spam notifikasi
  },
  
  // Logging settings
  logging: {
    enabled: true,
    logFile: './logs/defender.json',
    maxLogSize: 100 * 1024 * 1024, // 100MB
    keepLogs: 30 // days
  },
  
  // Whitelist - nomor yang tidak akan diblock
  whitelist: [
    // Tambahkan nomor yang ingin di-whitelist
    // '6281234567890@s.whatsapp.net'
  ],
  
  // Performance monitoring
  performance: {
    enabled: true,
    logInterval: 60000, // 1 minute
    memoryThreshold: 80, // percent
    cpuThreshold: 90 // percent
  }
}

// Fungsi untuk load konfigurasi custom
export function loadCustomConfig(configPath) {
  try {
    if (fs.existsSync(configPath)) {
      const customConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'))
      Object.assign(config, customConfig)
      console.log('✅ Custom config loaded from:', configPath)
    }
  } catch (error) {
    console.error('❌ Error loading custom config:', error.message)
  }
}

// Fungsi untuk save konfigurasi
export function saveConfig(configPath = './config.json') {
  try {
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2))
    console.log('✅ Config saved to:', configPath)
  } catch (error) {
    console.error('❌ Error saving config:', error.message)
  }
}

// Fungsi untuk membuat direktori yang diperlukan
export function createDirectories() {
  const dirs = [
    './logs',
    './session', 
    './temp',
    './backup'
  ]
  
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true })
    }
  })
}

// Inisialisasi
createDirectories()

export default config