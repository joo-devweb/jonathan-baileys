import { config } from './config.js'
import fs from 'fs'
import path from 'path'
import moment from 'moment'
import { getContentType } from '@whiskeysockets/baileys'

class WhatsAppDefender {
  constructor(sock) {
    this.sock = sock
    this.stats = {
      messagesProcessed: 0,
      bugsDetected: 0,
      usersBlocked: 0,
      messagesDeleted: 0,
      startTime: Date.now()
    }
    this.cache = new Map()
    this.processing = new Set()
  }

  // Fungsi utama untuk menganalisis pesan
  async analyzeMessage(message) {
    try {
      const messageId = message.key.id
      
      // Hindari pemrosesan duplikat
      if (this.processing.has(messageId)) return null
      this.processing.add(messageId)

      const result = {
        isBug: false,
        bugType: null,
        messageType: null,
        severity: 'low',
        patterns: [],
        timestamp: Date.now(),
        sender: message.key.remoteJid,
        messageId: messageId
      }

      // Identifikasi tipe pesan
      const messageType = getContentType(message.message)
      result.messageType = messageType

      if (!config.messageTypes.includes(messageType)) {
        this.processing.delete(messageId)
        return null
      }

      // Analisis berdasarkan tipe pesan
      const analysisResult = await this.analyzeByType(message, messageType)
      
      if (analysisResult.isBug) {
        result.isBug = true
        result.bugType = analysisResult.bugType
        result.severity = analysisResult.severity
        result.patterns = analysisResult.patterns
        
        this.stats.bugsDetected++
      }

      this.stats.messagesProcessed++
      this.processing.delete(messageId)
      
      return result

    } catch (error) {
      console.error('❌ Error analyzing message:', error)
      this.processing.delete(message.key.id)
      return null
    }
  }

  // Analisis berdasarkan tipe pesan
  async analyzeByType(message, messageType) {
    const result = {
      isBug: false,
      bugType: null,
      severity: 'low',
      patterns: []
    }

    try {
      switch (messageType) {
        case 'conversation':
        case 'extendedTextMessage':
          return this.analyzeTextMessage(message)
          
        case 'imageMessage':
        case 'videoMessage':
        case 'audioMessage':
          return this.analyzeMediaMessage(message)
          
        case 'documentMessage':
          return this.analyzeDocumentMessage(message)
          
        case 'contactMessage':
          return this.analyzeContactMessage(message)
          
        case 'locationMessage':
        case 'liveLocationMessage':
          return this.analyzeLocationMessage(message)
          
        case 'stickerMessage':
          return this.analyzeStickerMessage(message)
          
        case 'buttonsMessage':
        case 'templateMessage':
        case 'listMessage':
        case 'interactiveMessage':
          return this.analyzeInteractiveMessage(message)
          
        case 'pollCreationMessage':
        case 'pollUpdateMessage':
          return this.analyzePollMessage(message)
          
        default:
          return result
      }
    } catch (error) {
      console.error(`❌ Error analyzing ${messageType}:`, error)
      return result
    }
  }

  // Analisis pesan teks
  analyzeTextMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    let text = ''
    if (message.message.conversation) {
      text = message.message.conversation
    } else if (message.message.extendedTextMessage?.text) {
      text = message.message.extendedTextMessage.text
    }

    if (!text) return result

    // Check LID vulnerability
    for (const pattern of config.bugPatterns.lid) {
      if (pattern.test(text)) {
        result.isBug = true
        result.bugType = 'LID_VULNERABILITY'
        result.severity = 'critical'
        result.patterns.push('LID')
        break
      }
    }

    // Check text bomb
    if (!result.isBug) {
      for (const pattern of config.bugPatterns.textBomb) {
        if (pattern.test(text)) {
          result.isBug = true
          result.bugType = 'TEXT_BOMB'
          result.severity = 'high'
          result.patterns.push('TEXT_BOMB')
          break
        }
      }
    }

    // Check emoji bomb
    if (!result.isBug) {
      for (const pattern of config.bugPatterns.emojiBomb) {
        if (pattern.test(text)) {
          result.isBug = true
          result.bugType = 'EMOJI_BOMB'
          result.severity = 'high'
          result.patterns.push('EMOJI_BOMB')
          break
        }
      }
    }

    // Check crash patterns
    if (!result.isBug) {
      for (const pattern of config.bugPatterns.crash) {
        if (pattern.test(text)) {
          result.isBug = true
          result.bugType = 'CRASH_BUG'
          result.severity = 'critical'
          result.patterns.push('CRASH')
          break
        }
      }
    }

    // Check lag patterns
    if (!result.isBug) {
      for (const pattern of config.bugPatterns.lag) {
        if (pattern.test(text)) {
          result.isBug = true
          result.bugType = 'LAG_BUG'
          result.severity = 'medium'
          result.patterns.push('LAG')
          break
        }
      }
    }

    return result
  }

  // Analisis pesan media
  analyzeMediaMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const messageType = getContentType(message.message)
    const mediaMessage = message.message[messageType]
    
    if (!mediaMessage) return result

    // Check filename
    if (mediaMessage.fileName) {
      for (const pattern of config.bugPatterns.mediaBug) {
        if (pattern.test(mediaMessage.fileName)) {
          result.isBug = true
          result.bugType = 'MEDIA_BUG'
          result.severity = 'high'
          result.patterns.push('MEDIA_FILENAME')
          break
        }
      }
    }

    // Check mimetype
    if (mediaMessage.mimetype) {
      for (const pattern of config.bugPatterns.fileSpoof) {
        if (pattern.test(mediaMessage.mimetype)) {
          result.isBug = true
          result.bugType = 'FILE_SPOOF'
          result.severity = 'critical'
          result.patterns.push('MIMETYPE_SPOOF')
          break
        }
      }
    }

    // Check caption
    if (mediaMessage.caption && !result.isBug) {
      const textAnalysis = this.analyzeTextMessage({
        message: { conversation: mediaMessage.caption }
      })
      if (textAnalysis.isBug) {
        result.isBug = true
        result.bugType = textAnalysis.bugType
        result.severity = textAnalysis.severity
        result.patterns = textAnalysis.patterns
      }
    }

    return result
  }

  // Analisis pesan dokumen
  analyzeDocumentMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const docMessage = message.message.documentMessage
    if (!docMessage) return result

    // Check CVE-2025-30401 - File spoofing
    if (docMessage.fileName) {
      for (const pattern of config.bugPatterns.fileSpoof) {
        if (pattern.test(docMessage.fileName)) {
          result.isBug = true
          result.bugType = 'CVE_2025_30401'
          result.severity = 'critical'
          result.patterns.push('FILE_SPOOFING')
          break
        }
      }
    }

    // Check PDF exploits (CVE-2025-30259)
    if (docMessage.mimetype === 'application/pdf' && !result.isBug) {
      // Jika ada cara untuk membaca konten PDF, check pattern PDF exploit
      result.isBug = true
      result.bugType = 'CVE_2025_30259'
      result.severity = 'critical'
      result.patterns.push('PDF_EXPLOIT')
    }

    return result
  }

  // Analisis pesan kontak
  analyzeContactMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const contactMessage = message.message.contactMessage
    if (!contactMessage?.vcard) return result

    for (const pattern of config.bugPatterns.contactBug) {
      if (pattern.test(contactMessage.vcard)) {
        result.isBug = true
        result.bugType = 'CONTACT_BUG'
        result.severity = 'high'
        result.patterns.push('CONTACT_EXPLOIT')
        break
      }
    }

    return result
  }

  // Analisis pesan lokasi
  analyzeLocationMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const messageType = getContentType(message.message)
    const locationMessage = message.message[messageType]
    
    if (!locationMessage) return result

    // Check koordinat yang tidak valid
    if (locationMessage.degreesLatitude || locationMessage.degreesLongitude) {
      const lat = locationMessage.degreesLatitude
      const lng = locationMessage.degreesLongitude
      
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        result.isBug = true
        result.bugType = 'LOCATION_BUG'
        result.severity = 'medium'
        result.patterns.push('INVALID_COORDINATES')
      }
    }

    return result
  }

  // Analisis sticker
  analyzeStickerMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const stickerMessage = message.message.stickerMessage
    if (!stickerMessage) return result

    // Check ukuran file yang tidak wajar
    if (stickerMessage.fileLength > 1024 * 1024 * 10) { // > 10MB
      result.isBug = true
      result.bugType = 'STICKER_BUG'
      result.severity = 'medium'
      result.patterns.push('OVERSIZED_STICKER')
    }

    return result
  }

  // Analisis pesan interaktif
  analyzeInteractiveMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    // Interactive messages bisa mengandung script berbahaya
    result.isBug = true
    result.bugType = 'INTERACTIVE_BUG'
    result.severity = 'medium'
    result.patterns.push('INTERACTIVE_MESSAGE')

    return result
  }

  // Analisis poll
  analyzePollMessage(message) {
    const result = { isBug: false, bugType: null, severity: 'low', patterns: [] }
    
    const messageType = getContentType(message.message)
    const pollMessage = message.message[messageType]
    
    if (!pollMessage) return result

    // Check poll dengan opsi terlalu banyak
    if (pollMessage.options && pollMessage.options.length > 100) {
      result.isBug = true
      result.bugType = 'POLL_BUG'
      result.severity = 'medium'
      result.patterns.push('POLL_SPAM')
    }

    return result
  }

  // Eksekusi aksi otomatis
  async executeActions(analysisResult) {
    if (!analysisResult.isBug) return

    const sender = analysisResult.sender
    const messageId = analysisResult.messageId

    try {
      // Check whitelist
      if (config.whitelist.includes(sender)) {
        console.log(`⚪ Sender ${sender} is whitelisted, skipping actions`)
        return
      }

      // Delete message
      if (config.autoActions.delete) {
        try {
          await this.sock.sendMessage(sender, { delete: { id: messageId, fromMe: false, remoteJid: sender } })
          this.stats.messagesDeleted++
          console.log(`🗑️ Deleted bug message from ${sender}`)
        } catch (error) {
          console.error('❌ Error deleting message:', error.message)
        }
      }

      // Block user
      if (config.autoActions.block) {
        try {
          await this.sock.updateBlockStatus(sender, 'block')
          this.stats.usersBlocked++
          console.log(`🚫 Blocked user ${sender}`)
        } catch (error) {
          console.error('❌ Error blocking user:', error.message)
        }
      }

      // Log to console
      this.logToConsole(analysisResult)

      // Log to file
      if (config.autoActions.log) {
        this.logToFile(analysisResult)
      }

    } catch (error) {
      console.error('❌ Error executing actions:', error)
    }
  }

  // Log ke console
  logToConsole(result) {
    const isGroup = result.sender.endsWith('@g.us')
    const chatType = isGroup ? 'GROUP' : 'PRIVATE'
    const lid = result.sender.split('@')[0]
    const time = moment().format('YYYY-MM-DD HH:mm:ss')

    console.log(`
🚨 BUG DETECTED 🚨
LID: ${lid}
GROUP/PRIVATE: ${chatType}
TIPE: ${result.bugType}
WAKTU: ${time}
SEVERITY: ${result.severity}
PATTERNS: ${result.patterns.join(', ')}
MESSAGE_TYPE: ${result.messageType}
────────────────────────────────────
`)
  }

  // Log ke file JSON
  logToFile(result) {
    try {
      const logEntry = {
        timestamp: moment().format(),
        lid: result.sender.split('@')[0],
        chatType: result.sender.endsWith('@g.us') ? 'GROUP' : 'PRIVATE',
        bugType: result.bugType,
        messageType: result.messageType,
        severity: result.severity,
        patterns: result.patterns,
        messageId: result.messageId,
        processed: true
      }

      const logFile = config.logging.logFile
      let logs = []

      // Read existing logs
      if (fs.existsSync(logFile)) {
        try {
          const data = fs.readFileSync(logFile, 'utf8')
          logs = JSON.parse(data)
        } catch (error) {
          console.error('❌ Error reading log file:', error.message)
          logs = []
        }
      }

      // Add new log
      logs.push(logEntry)

      // Keep only recent logs (based on config)
      const cutoffDate = moment().subtract(config.logging.keepLogs, 'days')
      logs = logs.filter(log => moment(log.timestamp).isAfter(cutoffDate))

      // Write logs
      fs.writeFileSync(logFile, JSON.stringify(logs, null, 2))

    } catch (error) {
      console.error('❌ Error logging to file:', error)
    }
  }

  // Get statistics
  getStats() {
    const uptime = Date.now() - this.stats.startTime
    return {
      ...this.stats,
      uptime: uptime,
      messagesPerSecond: this.stats.messagesProcessed / (uptime / 1000),
      detectionRate: (this.stats.bugsDetected / this.stats.messagesProcessed * 100).toFixed(2) + '%'
    }
  }

  // Reset statistics
  resetStats() {
    this.stats = {
      messagesProcessed: 0,
      bugsDetected: 0,
      usersBlocked: 0,
      messagesDeleted: 0,
      startTime: Date.now()
    }
  }
}

export default WhatsAppDefender