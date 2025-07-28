import makeWASocket, { 
  DisconnectReason, 
  useMultiFileAuthState, 
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
  Browsers
} from '@whiskeysockets/baileys'
import pino from 'pino'
import readline from 'readline'
import chalk from 'chalk'
import fs from 'fs'
import MessageHandler from './handler.js'
import { config } from './config.js'

// ASCII Art Banner
const banner = `
██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗ █████╗ ██████╗ ██████╗ 
██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗
██║ █╗ ██║███████║███████║   ██║   ███████╗███████║██████╔╝██████╔╝
██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║██╔══██║██╔═══╝ ██╔═══╝ 
╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║██║  ██║██║     ██║     
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     
                                                                    
██████╗ ███████╗███████╗███████╗███╗   ██╗██████╗ ███████╗██████╗  
██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗ 
██║  ██║█████╗  █████╗  █████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝ 
██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗ 
██████╔╝███████╗██║     ███████╗██║ ╚████║██████╔╝███████╗██║  ██║ 
╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝ 
                                                                    
                    🛡️  ULTRA ANTI BUG SYSTEM 🛡️
`

class WhatsAppDefenderBot {
  constructor() {
    this.sock = null
    this.handler = null
    this.isConnected = false
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 10
    
    // Setup readline interface
    this.rl = readline.createInterface({ 
      input: process.stdin, 
      output: process.stdout 
    })
    
    // Setup graceful shutdown
    this.setupGracefulShutdown()
  }

  // Setup graceful shutdown handlers
  setupGracefulShutdown() {
    const gracefulShutdown = async (signal) => {
      console.log(chalk.yellow(`\n🔄 Received ${signal}, initiating graceful shutdown...`))
      
      try {
        if (this.handler) {
          await this.handler.gracefulShutdown()
        }
        
        if (this.sock) {
          this.sock.end()
        }
        
        this.rl.close()
        console.log(chalk.green('✅ Graceful shutdown completed'))
        process.exit(0)
      } catch (error) {
        console.error(chalk.red('❌ Error during shutdown:'), error)
        process.exit(1)
      }
    }

    process.on('SIGINT', () => gracefulShutdown('SIGINT'))
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
    process.on('SIGUSR1', () => gracefulShutdown('SIGUSR1'))
    process.on('SIGUSR2', () => gracefulShutdown('SIGUSR2'))
  }

  // Ask for phone number
  askNumber() {
    return new Promise(resolve => {
      this.rl.question(chalk.cyan('📱 Masukkan nomor (62xxx): '), 
        number => resolve(number.replace(/[^0-9]/g, ''))
      )
    })
  }

  // Display startup banner
  displayBanner() {
    console.clear()
    console.log(chalk.magentaBright.bold(banner))
    console.log(chalk.green.bold(`\n🚀 Menjalankan ${config.botName}…\n`))
    console.log(chalk.blue('📋 System Information:'))
    console.log(chalk.blue(`   • Node.js Version: ${process.version}`))
    console.log(chalk.blue(`   • Platform: ${process.platform}`))
    console.log(chalk.blue(`   • Architecture: ${process.arch}`))
    console.log(chalk.blue(`   • Memory: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`))
    console.log(chalk.blue(`   • Uptime: ${Math.round(process.uptime())}s`))
    console.log(chalk.blue('────────────────────────────────────\n'))
  }

  // Start the bot
  async startBot() {
    try {
      this.displayBanner()
      
      console.log(chalk.yellow('⚙️  Initializing authentication state...'))
      const { state, saveCreds } = await useMultiFileAuthState(config.sessionName)
      
      console.log(chalk.yellow('🔍 Fetching latest Baileys version...'))
      const { version } = await fetchLatestBaileysVersion()
      console.log(chalk.green(`✅ Using Baileys version: ${version.join('.')}`))
      
      console.log(chalk.yellow('🔌 Creating WhatsApp socket...'))
      this.sock = makeWASocket({
        version,
        logger: pino({ level: 'silent' }),
        browser: Browsers.ubuntu('Chrome'),
        printQRInTerminal: false,
        auth: {
          creds: state.creds,
          keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' }))
        },
        generateHighQualityLinkPreview: true,
        markOnlineOnConnect: false, // Untuk receive notifications
        syncFullHistory: true,
        defaultQueryTimeoutMs: 60000,
        keepAliveIntervalMs: 30000,
        connectTimeoutMs: 60000,
        maxMsgRetryCount: 5,
        msgRetryCounterCache: new Map(),
        shouldIgnoreJid: jid => false,
        shouldSyncHistoryMessage: msg => true
      })

      // Global socket reference for other modules
      global.sock = this.sock

      // Initialize message handler
      console.log(chalk.yellow('🛡️  Initializing defense systems...'))
      this.handler = new MessageHandler(this.sock)

      // Setup event listeners
      this.setupEventListeners(saveCreds)

      // Handle pairing for first time
      await this.handlePairing()

      console.log(chalk.green('✅ Bot initialization completed'))
      
    } catch (error) {
      console.error(chalk.red('❌ Failed to start bot:'), error)
      
      // Retry after delay
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        this.reconnectAttempts++
        console.log(chalk.yellow(`🔄 Retrying in 5 seconds... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`))
        setTimeout(() => this.startBot(), 5000)
      } else {
        console.log(chalk.red('❌ Max reconnection attempts reached. Exiting...'))
        process.exit(1)
      }
    }
  }

  // Setup event listeners
  setupEventListeners(saveCreds) {
    // Credentials update
    this.sock.ev.on('creds.update', saveCreds)

    // Connection updates
    this.sock.ev.on('connection.update', (update) => {
      const shouldReconnect = this.handler.handleConnectionUpdate(update)
      
      if (update.connection === 'open') {
        this.isConnected = true
        this.reconnectAttempts = 0
      }
      
      if (update.connection === 'close' && shouldReconnect) {
        this.reconnectWithDelay()
      }
    })

    // Messages
    this.sock.ev.on('messages.upsert', ({ messages }) => {
      messages.forEach(message => {
        if (!message.key.fromMe) {
          this.handler.handleMessage(message)
        }
      })
    })

    // Message updates (reactions, edits, etc.)
    this.sock.ev.on('messages.update', (updates) => {
      this.handler.handleMessageUpdate(updates)
    })

    // Presence updates
    this.sock.ev.on('presence.update', (presence) => {
      this.handler.handlePresenceUpdate(presence)
    })

    // Group updates
    this.sock.ev.on('groups.update', (updates) => {
      this.handler.handleGroupUpdate(updates)
    })

    // Contacts update
    this.sock.ev.on('contacts.update', (contacts) => {
      this.handler.handleContactsUpdate(contacts)
    })

    // Chats update
    this.sock.ev.on('chats.upsert', (chats) => {
      this.handler.handleChatsUpdate(chats)
    })

    // Call events
    this.sock.ev.on('call', async (calls) => {
      for (const call of calls) {
        if (call.status === 'offer') {
          console.log(chalk.yellow(`📞 Incoming call from ${call.from}, rejecting...`))
          await this.sock.rejectCall(call.id, call.from)
        }
      }
    })

    // Error handling
    this.sock.ev.on('error', (error) => {
      console.error(chalk.red('❌ Socket error:'), error)
    })
  }

  // Handle pairing process
  async handlePairing() {
    if (!this.sock.authState.creds.registered) {
      console.log(chalk.cyan('\n🔐 First time setup - Pairing required'))
      
      const number = await this.askNumber()
      console.log(chalk.yellow('⏳ Tunggu 3 detik…'))
      await new Promise(r => setTimeout(r, 3000))
      
      console.log(chalk.yellow('🔑 Meminta pairing code…'))
      const code = await this.sock.requestPairingCode(number)
      
      console.log(chalk.green.bold(`\n🔗 PAIRING CODE: ${code}\n`))
      console.log(chalk.cyan('📱 Langkah selanjutnya:'))
      console.log(chalk.cyan('   1. Buka WhatsApp di HP'))
      console.log(chalk.cyan('   2. Pergi ke Settings > Linked Devices'))
      console.log(chalk.cyan('   3. Tap "Link a Device"'))
      console.log(chalk.cyan('   4. Masukkan kode pairing di atas'))
      console.log(chalk.blue('────────────────────────────────────\n'))
    }
  }

  // Reconnect with exponential backoff
  reconnectWithDelay() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log(chalk.red('❌ Max reconnection attempts reached'))
      return
    }

    this.reconnectAttempts++
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000) // Max 30 seconds
    
    console.log(chalk.yellow(`🔄 Reconnecting in ${delay/1000}s... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`))
    
    setTimeout(() => {
      this.startBot()
    }, delay)
  }

  // Display system status
  displayStatus() {
    if (this.handler) {
      const stats = this.handler.getStats()
      
      console.log(chalk.blue(`
🛡️  WHATSAPP DEFENDER STATUS 🛡️
Connection: ${this.isConnected ? chalk.green('✅ Connected') : chalk.red('❌ Disconnected')}
Messages Processed: ${stats.processedMessages}
Threats Blocked: ${stats.blockedMessages}
Messages Deleted: ${stats.deletedMessages}
Processing Rate: ${stats.messagesPerSecond.toFixed(2)} msg/sec
Queue Size: ${stats.queueSize}
Uptime: ${(stats.uptime / 1000 / 60).toFixed(1)} minutes
Memory Usage: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB
────────────────────────────────────
`))
    }
  }

  // Start status monitoring
  startStatusMonitoring() {
    setInterval(() => {
      this.displayStatus()
    }, 300000) // Every 5 minutes
  }
}

// Main execution
async function main() {
  try {
    const bot = new WhatsAppDefenderBot()
    
    // Start the bot
    await bot.startBot()
    
    // Start status monitoring
    bot.startStatusMonitoring()
    
    // Keep the process alive
    process.stdin.resume()
    
  } catch (error) {
    console.error(chalk.red('❌ Fatal error:'), error)
    process.exit(1)
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('❌ Unhandled Promise Rejection:'), reason)
})

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error(chalk.red('❌ Uncaught Exception:'), error)
  process.exit(1)
})

// Start the application
main().catch(console.error)

export default WhatsAppDefenderBot