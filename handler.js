import WhatsAppDefender from './Defender.js'
import DefendUltra from './DefendUltra.js'
import PerformaMonitor from './Performa.js'
import { config } from './config.js'
import { getContentType } from '@whiskeysockets/baileys'
import moment from 'moment'
import chalk from 'chalk'

class MessageHandler {
  constructor(sock) {
    this.sock = sock
    this.defender = new WhatsAppDefender(sock)
    this.ultraDefender = new DefendUltra()
    this.performanceMonitor = new PerformaMonitor()
    
    this.messageQueue = []
    this.processing = false
    this.stats = {
      totalMessages: 0,
      processedMessages: 0,
      blockedMessages: 0,
      deletedMessages: 0,
      errorCount: 0,
      startTime: Date.now()
    }
    
    // Initialize systems
    this.initializeSystems()
  }

  // Initialize all defense systems
  async initializeSystems() {
    try {
      console.log(chalk.blue('🚀 Initializing Defense Systems...'))
      
      // Start performance monitoring
      await this.performanceMonitor.startMonitoring()
      console.log(chalk.green('✅ Performance Monitor started'))
      
      // Initialize Ultra Defender
      await this.ultraDefender.initializeCluster()
      console.log(chalk.green('✅ Ultra Defender initialized'))
      
      // Start message processing
      this.startMessageProcessing()
      console.log(chalk.green('✅ Message processing started'))
      
      // Start stats reporting
      this.startStatsReporting()
      console.log(chalk.green('✅ Stats reporting started'))
      
      console.log(chalk.green.bold('🛡️  All Defense Systems Online!'))
      
    } catch (error) {
      console.error(chalk.red('❌ Failed to initialize defense systems:'), error)
    }
  }

  // Handle incoming messages
  async handleMessage(message) {
    try {
      this.stats.totalMessages++
      
      // Add to processing queue
      this.messageQueue.push({
        message: message,
        timestamp: Date.now(),
        processed: false
      })
      
      // Process immediately if not busy
      if (!this.processing) {
        this.processMessageQueue()
      }
      
    } catch (error) {
      console.error(chalk.red('❌ Error handling message:'), error)
      this.stats.errorCount++
    }
  }

  // Process message queue
  async processMessageQueue() {
    if (this.processing || this.messageQueue.length === 0) return
    
    this.processing = true
    
    try {
      // Process messages in batches for maximum performance
      const batchSize = config.maxConcurrentMessages || 1000
      const batch = this.messageQueue.splice(0, batchSize)
      
      console.log(chalk.yellow(`⚡ Processing batch of ${batch.length} messages`))
      
      // Process all messages in parallel for unlimited performance
      const promises = batch.map(item => this.processMessage(item))
      await Promise.allSettled(promises)
      
      this.stats.processedMessages += batch.length
      
    } catch (error) {
      console.error(chalk.red('❌ Error processing message queue:'), error)
      this.stats.errorCount++
    } finally {
      this.processing = false
      
      // Continue processing if there are more messages
      if (this.messageQueue.length > 0) {
        setImmediate(() => this.processMessageQueue())
      }
    }
  }

  // Process individual message
  async processMessage(item) {
    const startTime = Date.now()
    
    try {
      const { message } = item
      
      // Skip if already processed
      if (item.processed) return
      
      // Basic validation
      if (!message || !message.key || !message.message) {
        return
      }
      
      // Get message info
      const messageId = message.key.id
      const sender = message.key.remoteJid
      const messageType = getContentType(message.message)
      
      // Skip own messages
      if (message.key.fromMe) return
      
      // Check whitelist
      if (config.whitelist.includes(sender)) {
        console.log(chalk.white(`⚪ Whitelisted sender: ${sender}`))
        return
      }
      
      // Log message received
      this.logMessageReceived(message, messageType)
      
      // Run all analysis systems in parallel
      const [basicAnalysis, ultraAnalysis] = await Promise.all([
        this.defender.analyzeMessage(message),
        this.runUltraAnalysis(message)
      ])
      
      // Process results
      await this.processAnalysisResults(basicAnalysis, ultraAnalysis, message)
      
      // Mark as processed
      item.processed = true
      
      // Log processing time
      const processingTime = Date.now() - startTime
      if (processingTime > 100) { // Log slow messages
        console.log(chalk.yellow(`⏱️  Slow message processing: ${processingTime}ms`))
      }
      
    } catch (error) {
      console.error(chalk.red('❌ Error processing individual message:'), error)
      this.stats.errorCount++
    }
  }

  // Run ultra analysis
  async runUltraAnalysis(message) {
    try {
      // Add message to ultra defender queue
      this.ultraDefender.addMessage(message)
      
      // Return placeholder (ultra analysis is async)
      return {
        processed: true,
        timestamp: Date.now()
      }
    } catch (error) {
      console.error(chalk.red('❌ Ultra analysis error:'), error)
      return null
    }
  }

  // Process analysis results
  async processAnalysisResults(basicAnalysis, ultraAnalysis, message) {
    try {
      // Process basic analysis
      if (basicAnalysis && basicAnalysis.isBug) {
        await this.defender.executeActions(basicAnalysis)
        this.stats.blockedMessages++
        
        if (config.autoActions.delete) {
          this.stats.deletedMessages++
        }
      }
      
      // Ultra analysis is processed separately in DefendUltra
      
    } catch (error) {
      console.error(chalk.red('❌ Error processing analysis results:'), error)
    }
  }

  // Log message received
  logMessageReceived(message, messageType) {
    try {
      const sender = message.key.remoteJid
      const isGroup = sender.endsWith('@g.us')
      const chatType = isGroup ? 'GROUP' : 'PRIVATE'
      const lid = sender.split('@')[0]
      const time = moment().format('HH:mm:ss')
      
      // Only log in debug mode to avoid spam
      if (process.env.DEBUG) {
        console.log(chalk.gray(`📨 ${time} | ${chatType} | ${lid} | ${messageType}`))
      }
      
    } catch (error) {
      console.error(chalk.red('❌ Error logging message:'), error)
    }
  }

  // Handle connection updates
  handleConnectionUpdate(update) {
    try {
      const { connection, lastDisconnect, qr } = update
      
      if (qr) {
        console.log(chalk.yellow('📱 QR Code received (but using pairing code)'))
      }
      
      if (connection === 'close') {
        const shouldReconnect = lastDisconnect?.error?.output?.statusCode !== 401
        
        console.log(chalk.red('🔴 Connection closed'))
        console.log(chalk.yellow('🔄 Should reconnect:'), shouldReconnect)
        
        if (shouldReconnect) {
          console.log(chalk.blue('🔄 Attempting to reconnect...'))
          return true // Signal to reconnect
        } else {
          console.log(chalk.red('🚫 Logged out, need to re-authenticate'))
          return false
        }
      }
      
      if (connection === 'open') {
        console.log(chalk.green.bold('🟢 Connected successfully!'))
        console.log(chalk.green(`📱 Connected as: ${this.sock.user.id.split(':')[0]}`))
        
        // Start defense systems
        this.onConnectionOpen()
      }
      
      if (connection === 'connecting') {
        console.log(chalk.yellow('🟡 Connecting to WhatsApp...'))
      }
      
    } catch (error) {
      console.error(chalk.red('❌ Connection update error:'), error)
    }
  }

  // Handle successful connection
  onConnectionOpen() {
    try {
      console.log(chalk.green.bold('\n🛡️  WHATSAPP DEFENDER ACTIVE 🛡️'))
      console.log(chalk.green('✅ All systems operational'))
      console.log(chalk.green('✅ Bug detection enabled'))
      console.log(chalk.green('✅ Auto-block enabled'))
      console.log(chalk.green('✅ Auto-delete enabled'))
      console.log(chalk.green('✅ Logging enabled'))
      console.log(chalk.blue('────────────────────────────────────\n'))
      
      // Send status to performance monitor
      this.performanceMonitor.printStats()
      
    } catch (error) {
      console.error(chalk.red('❌ Connection open handler error:'), error)
    }
  }

  // Handle presence updates
  handlePresenceUpdate(presence) {
    try {
      // Log presence updates in debug mode
      if (process.env.DEBUG) {
        console.log(chalk.gray(`👤 Presence update:`, presence))
      }
    } catch (error) {
      console.error(chalk.red('❌ Presence update error:'), error)
    }
  }

  // Handle group updates
  handleGroupUpdate(updates) {
    try {
      updates.forEach(update => {
        if (process.env.DEBUG) {
          console.log(chalk.gray(`👥 Group update:`, update))
        }
      })
    } catch (error) {
      console.error(chalk.red('❌ Group update error:'), error)
    }
  }

  // Handle contacts update
  handleContactsUpdate(contacts) {
    try {
      if (process.env.DEBUG) {
        console.log(chalk.gray(`📞 Contacts updated: ${Object.keys(contacts).length}`))
      }
    } catch (error) {
      console.error(chalk.red('❌ Contacts update error:'), error)
    }
  }

  // Handle chats update
  handleChatsUpdate(chats) {
    try {
      if (process.env.DEBUG) {
        console.log(chalk.gray(`💬 Chats updated: ${chats.length}`))
      }
    } catch (error) {
      console.error(chalk.red('❌ Chats update error:'), error)
    }
  }

  // Handle message updates (edits, deletions, etc.)
  handleMessageUpdate(updates) {
    try {
      updates.forEach(update => {
        const { key, update: messageUpdate } = update
        
        if (messageUpdate.pollUpdates) {
          // Handle poll updates
          this.handlePollUpdate(key, messageUpdate.pollUpdates)
        }
        
        if (messageUpdate.reaction) {
          // Handle reaction updates
          this.handleReactionUpdate(key, messageUpdate.reaction)
        }
      })
    } catch (error) {
      console.error(chalk.red('❌ Message update error:'), error)
    }
  }

  // Handle poll updates
  handlePollUpdate(key, pollUpdates) {
    try {
      if (process.env.DEBUG) {
        console.log(chalk.gray(`📊 Poll update for message ${key.id}`))
      }
    } catch (error) {
      console.error(chalk.red('❌ Poll update error:'), error)
    }
  }

  // Handle reaction updates
  handleReactionUpdate(key, reaction) {
    try {
      if (process.env.DEBUG) {
        console.log(chalk.gray(`😀 Reaction update for message ${key.id}: ${reaction.text}`))
      }
    } catch (error) {
      console.error(chalk.red('❌ Reaction update error:'), error)
    }
  }

  // Start message processing loop
  startMessageProcessing() {
    setInterval(() => {
      if (!this.processing && this.messageQueue.length > 0) {
        this.processMessageQueue()
      }
    }, 10) // Check every 10ms for maximum responsiveness
  }

  // Start stats reporting
  startStatsReporting() {
    setInterval(() => {
      this.reportStats()
    }, 60000) // Report every minute
  }

  // Report statistics
  reportStats() {
    try {
      const uptime = Date.now() - this.stats.startTime
      const messagesPerSecond = this.stats.processedMessages / (uptime / 1000)
      
      console.log(chalk.blue(`
📊 DEFENDER STATISTICS 📊
Total Messages: ${this.stats.totalMessages}
Processed: ${this.stats.processedMessages}
Blocked: ${this.stats.blockedMessages}
Deleted: ${this.stats.deletedMessages}
Errors: ${this.stats.errorCount}
Queue Size: ${this.messageQueue.length}
Processing Rate: ${messagesPerSecond.toFixed(2)} msg/sec
Uptime: ${moment.duration(uptime).humanize()}
────────────────────────────────────
`))
      
    } catch (error) {
      console.error(chalk.red('❌ Stats reporting error:'), error)
    }
  }

  // Get current statistics
  getStats() {
    const uptime = Date.now() - this.stats.startTime
    
    return {
      ...this.stats,
      uptime: uptime,
      queueSize: this.messageQueue.length,
      messagesPerSecond: this.stats.processedMessages / (uptime / 1000),
      defenderStats: this.defender.getStats(),
      performanceStats: this.performanceMonitor.getPerformanceReport()
    }
  }

  // Emergency stop
  emergencyStop() {
    try {
      console.log(chalk.red.bold('🚨 EMERGENCY STOP ACTIVATED 🚨'))
      
      this.processing = false
      this.messageQueue = []
      
      // Stop performance monitoring
      this.performanceMonitor.stopMonitoring()
      
      console.log(chalk.red('🛑 All systems stopped'))
      
    } catch (error) {
      console.error(chalk.red('❌ Emergency stop error:'), error)
    }
  }

  // Graceful shutdown
  async gracefulShutdown() {
    try {
      console.log(chalk.yellow('🔄 Initiating graceful shutdown...'))
      
      // Stop accepting new messages
      this.processing = false
      
      // Process remaining messages
      if (this.messageQueue.length > 0) {
        console.log(chalk.yellow(`⏳ Processing remaining ${this.messageQueue.length} messages...`))
        await this.processMessageQueue()
      }
      
      // Stop monitoring
      this.performanceMonitor.stopMonitoring()
      
      // Final stats
      this.reportStats()
      
      console.log(chalk.green('✅ Graceful shutdown completed'))
      
    } catch (error) {
      console.error(chalk.red('❌ Graceful shutdown error:'), error)
    }
  }
}

export default MessageHandler