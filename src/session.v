module whatsapp

import time
import json
import os
import encoding.base64
import crypto.rand
import sync

// Session manager utama untuk WhatsApp
pub struct Session {
mut:
	ws_client       &WSClient
	state           ConnectionState
	config          SessionConfig
	client_id       string
	keypair         KeyPair
	encryption_keys ?EncryptionKeys
	connection_info ?ConnectionInfo
	auth_state      map[string]string
	chats           map[string]Chat
	contacts        map[string]ContactInfo
	message_store   MessageStore
	event_callbacks ?EventCallbacks
	mutex           &sync.Mutex
	session_file    string
	qr_attempts     int
	pairing_attempts int
	last_qr_scan    time.Time
	heartbeat_timer ?&time.Timer
	retry_count     int
}

// Message store untuk menyimpan pesan
struct MessageStore {
mut:
	messages map[string][]Message
	mutex    &sync.Mutex
}

// Buat session baru
pub fn new_session(config SessionConfig) !&Session {
	// Generate client ID dan keypair
	client_id := generate_client_id()!
	keypair := generate_keypair()!
	
	// Setup event callbacks
	mut callbacks := EventCallbacks{}
	
	// Create WebSocket client
	ws_client := new_ws_client(&callbacks)!
	
	mut session := &Session{
		ws_client: ws_client
		state: .disconnected
		config: config
		client_id: client_id
		keypair: keypair
		encryption_keys: none
		connection_info: none
		auth_state: map[string]string{}
		chats: map[string]Chat{}
		contacts: map[string]ContactInfo{}
		message_store: MessageStore{
			messages: map[string][]Message{}
			mutex: sync.new_mutex()
		}
		event_callbacks: none
		mutex: sync.new_mutex()
		session_file: os.join_path(config.session_path, 'session.json')
		qr_attempts: 0
		pairing_attempts: 0
		last_qr_scan: time.now()
		heartbeat_timer: none
		retry_count: 0
	}
	
	// Setup callbacks untuk WebSocket client
	callbacks.on_qr_code = fn [mut session] (qr_data string) {
		session.handle_qr_code(qr_data)
	}
	
	callbacks.on_pairing_code = fn [mut session] (code string) {
		session.handle_pairing_code(code)
	}
	
	callbacks.on_connection_update = fn [mut session] (state ConnectionState, data map[string]string) {
		session.handle_connection_update(state, data)
	}
	
	callbacks.on_auth_state_change = fn [mut session] (data map[string]string) {
		session.handle_auth_state_change(data)
	}
	
	callbacks.on_message = fn [mut session] (message Message) {
		session.handle_message(message)
	}
	
	callbacks.on_error = fn [mut session] (error string, data map[string]string) {
		session.handle_error(error, data)
	}
	
	session.event_callbacks = &callbacks
	session.ws_client.event_callbacks = &callbacks
	
	return session
}

// Start session dengan autentikasi
pub fn (mut session Session) start() ! {
	session.mutex.@lock()
	defer {
		session.mutex.unlock()
	}
	
	// Coba load session yang sudah ada
	if session.load_existing_session() {
		println('✅ Session tersimpan ditemukan, mencoba login otomatis...')
		session.connect_with_existing_session()!
	} else {
		println('🔄 Memulai session baru...')
		session.connect_new_session()!
	}
}

// Connect dengan session baru
fn (mut session Session) connect_new_session() ! {
	session.state = .connecting
	
	// Connect WebSocket
	session.ws_client.connect()!
	
	// Tunggu koneksi
	for !session.ws_client.is_connected() {
		time.sleep(100 * time.millisecond)
	}
	
	// Send init command
	session.ws_client.send_init(session.client_id)!
	
	// Wait untuk response init
	session.wait_for_init_response()!
}

// Connect dengan session yang sudah ada
fn (mut session Session) connect_with_existing_session() ! {
	session.state = .connecting
	
	// Connect WebSocket
	session.ws_client.connect()!
	
	// Tunggu koneksi
	for !session.ws_client.is_connected() {
		time.sleep(100 * time.millisecond)
	}
	
	// Coba login dengan tokens yang tersimpan
	if conn_info := session.connection_info {
		session.ws_client.send_login(conn_info.client_token, conn_info.server_token, session.client_id)!
	} else {
		// Fallback ke session baru
		session.connect_new_session()!
	}
}

// Wait untuk response init
fn (mut session Session) wait_for_init_response() ! {
	timeout := time.now().add(30 * time.second)
	
	for time.now().before(timeout) {
		if session.state == .authenticating {
			break
		}
		time.sleep(100 * time.millisecond)
	}
	
	if session.state != .authenticating {
		return error('Timeout waiting for init response')
	}
}

// Handle QR code generation
fn (mut session Session) handle_qr_code(qr_data string) {
	session.qr_attempts++
	session.last_qr_scan = time.now()
	
	if session.config.print_qr {
		println('\n📱 Scan QR Code ini dengan WhatsApp di ponsel kamu:')
		session.print_qr_code(qr_data)
		println('\n⏰ QR Code akan expired dalam 20 detik')
		println('🔄 Attempt ${session.qr_attempts}/5')
	}
	
	// Set timeout untuk regenerate QR
	spawn session.qr_timeout_handler()
}

// Handle pairing code generation
fn (mut session Session) handle_pairing_code(code string) {
	session.pairing_attempts++
	
	println('\n🔑 Pairing Code kamu: ${code}')
	println('📱 Masukkan code ini di WhatsApp ponsel kamu:')
	println('   1. Buka WhatsApp di ponsel')
	println('   2. Pergi ke Settings > Linked Devices')
	println('   3. Tap "Link a Device"')
	println('   4. Tap "Link with phone number instead"')
	println('   5. Masukkan code: ${code}')
	println('🔄 Attempt ${session.pairing_attempts}/3')
}

// Handle connection state changes
fn (mut session Session) handle_connection_update(state ConnectionState, data map[string]string) {
	session.state = state
	
	match state {
		.connected {
			println('🔗 Terhubung ke WhatsApp Web')
		}
		.authenticating {
			println('🔐 Memulai proses autentikasi...')
			session.start_authentication()!
		}
		.authenticated {
			println('✅ Autentikasi berhasil!')
			session.finalize_authentication()!
		}
		.ready {
			println('🚀 WhatsApp siap digunakan!')
			session.start_heartbeat()
			session.sync_initial_data()!
		}
		.disconnected {
			println('❌ Koneksi terputus')
			session.handle_disconnection()
		}
		.logged_out {
			println('🚪 Logged out dari WhatsApp')
			session.cleanup_session()
		}
		else {
			println('🔄 Status: ${state}')
		}
	}
}

// Handle auth state changes
fn (mut session Session) handle_auth_state_change(data map[string]string) {
	session.auth_state = data.clone()
	
	if 'type' in data {
		match data['type'] {
			'connection' {
				session.process_connection_data(data)!
			}
			'challenge' {
				session.process_challenge(data)!
			}
			'success' {
				session.state = .authenticated
			}
			else {}
		}
	}
}

// Start authentication process
fn (mut session Session) start_authentication() ! {
	match session.config.auth_method {
		.qr_code {
			session.generate_qr_code()!
		}
		.pairing_code {
			session.generate_pairing_code()!
		}
		.existing_session {
			// Already handled in connect_with_existing_session
		}
	}
}

// Generate QR code
fn (mut session Session) generate_qr_code() ! {
	// Generate QR code data
	public_key_b64 := base64.encode(session.keypair.public_key)
	
	if conn_info := session.connection_info {
		qr_data := '${conn_info.ref},${public_key_b64},${session.client_id}'
		session.handle_qr_code(qr_data)
	}
}

// Generate pairing code
fn (mut session Session) generate_pairing_code() ! {
	if session.config.phone_number.len == 0 {
		return error('Phone number diperlukan untuk pairing code')
	}
	
	// Generate pairing code (8 digit)
	code_bytes := rand.bytes(4)!
	mut code := ''
	for b in code_bytes {
		code += (b % 10).str()
	}
	
	session.handle_pairing_code(code)
}

// Process connection data dari server
fn (mut session Session) process_connection_data(data map[string]string) ! {
	if 'data' in data {
		conn_data := json.decode(map[string]json.Any, data['data'])!
		
		mut info := ConnectionInfo{
			battery: if 'battery' in conn_data { conn_data['battery'].int() } else { 100 }
			platform: if 'platform' in conn_data { conn_data['platform'].str() } else { 'unknown' }
			pushname: if 'pushname' in conn_data { conn_data['pushname'].str() } else { '' }
			secret: if 'secret' in conn_data { conn_data['secret'].str() } else { '' }
			server_token: if 'serverToken' in conn_data { conn_data['serverToken'].str() } else { '' }
			client_token: if 'clientToken' in conn_data { conn_data['clientToken'].str() } else { '' }
			browser_token: if 'browserToken' in conn_data { conn_data['browserToken'].str() } else { '' }
			wid: if 'wid' in conn_data { conn_data['wid'].str() } else { '' }
			ref: if 'ref' in conn_data { conn_data['ref'].str() } else { '' }
			ttl: if 'ttl' in conn_data { conn_data['ttl'].int() } else { 20000 }
			is_new: true
		}
		
		session.connection_info = info
		
		// Generate encryption keys
		if info.secret.len > 0 {
			session.generate_encryption_keys()!
		}
	}
}

// Generate encryption keys dari secret
fn (mut session Session) generate_encryption_keys() ! {
	if conn_info := session.connection_info {
		secret_bytes := base64.decode(conn_info.secret)!
		
		// Extract public key dari secret (first 32 bytes)
		server_public := secret_bytes[0..32]
		
		// Generate shared secret
		shared_secret := generate_shared_secret(session.keypair.private_key, server_public)!
		
		// Derive encryption keys
		keys := derive_wa_keys(shared_secret, []u8{})!
		session.encryption_keys = keys
		
		println('🔐 Encryption keys berhasil di-generate')
	}
}

// Process challenge dari server
fn (mut session Session) process_challenge(data map[string]string) ! {
	if 'challenge' in data {
		challenge_b64 := data['challenge']
		challenge_bytes := base64.decode(challenge_b64)!
		
		// Sign challenge dengan MAC key
		if keys := session.encryption_keys {
			mac := hmac_sha256(keys.mac_key, challenge_bytes)
			response := base64.encode(mac)
			
			if conn_info := session.connection_info {
				session.ws_client.send_challenge_response(response, conn_info.server_token, session.client_id)!
			}
		}
	}
}

// Finalize authentication
fn (mut session Session) finalize_authentication() ! {
	session.state = .ready
	session.save_session()!
	
	// Start periodic session save
	spawn session.periodic_session_save()
}

// Handle incoming messages
fn (mut session Session) handle_message(message Message) {
	// Store message
	session.store_message(message)
	
	// Update chat
	session.update_chat_with_message(message)
	
	// Trigger callbacks jika ada
	if callbacks := session.event_callbacks {
		if message_fn := callbacks.on_message {
			message_fn(message)
		}
	}
}

// Store message
fn (mut session Session) store_message(message Message) {
	session.message_store.mutex.@lock()
	defer {
		session.message_store.mutex.unlock()
	}
	
	if message.remote_jid !in session.message_store.messages {
		session.message_store.messages[message.remote_jid] = []Message{}
	}
	
	session.message_store.messages[message.remote_jid] << message
	
	// Keep only last 1000 messages per chat
	if session.message_store.messages[message.remote_jid].len > 1000 {
		session.message_store.messages[message.remote_jid] = session.message_store.messages[message.remote_jid][1..]
	}
}

// Update chat dengan message terbaru
fn (mut session Session) update_chat_with_message(message Message) {
	session.mutex.@lock()
	defer {
		session.mutex.unlock()
	}
	
	mut chat := session.chats[message.remote_jid] or {
		Chat{
			jid: message.remote_jid
			name: message.remote_jid
			chat_type: if message.remote_jid.contains('@g.us') { .group } else { .individual }
			timestamp: message.timestamp
			unread_count: 0
			last_message: none
			pinned: false
			archived: false
			muted_until: 0
			ephemeral_duration: 0
			description: ''
			group_metadata: none
			contact_info: none
			presence: none
		}
	}
	
	chat.last_message = &message
	chat.timestamp = message.timestamp
	
	if !message.from_me {
		chat.unread_count++
	}
	
	session.chats[message.remote_jid] = chat
}

// Handle errors
fn (mut session Session) handle_error(error string, data map[string]string) {
	println('❌ Error: ${error}')
	
	// Handle specific errors
	if 'code' in data {
		code := data['code'].int()
		match code {
			401 {
				println('🚪 Session expired, perlu login ulang')
				session.cleanup_session()
			}
			408 {
				println('⏰ Connection timeout, mencoba reconnect...')
				spawn session.reconnect()
			}
			515 {
				println('🔄 Restart required')
				session.restart()!
			}
			else {
				println('🔍 Error code: ${code}')
			}
		}
	}
}

// Handle disconnection
fn (mut session Session) handle_disconnection() {
	if session.heartbeat_timer != none {
		timer := session.heartbeat_timer or { return }
		timer.stop()
	}
	
	// Try to reconnect jika bukan logout manual
	if session.state != .logged_out {
		spawn session.reconnect()
	}
}

// Reconnect dengan backoff
fn (mut session Session) reconnect() {
	session.retry_count++
	
	if session.retry_count > whatsapp.max_reconnect_attempts {
		println('❌ Max reconnect attempts reached')
		return
	}
	
	// Exponential backoff
	delay := time.Duration(1000 * (1 << session.retry_count)) * time.millisecond
	if delay > 30 * time.second {
		delay = 30 * time.second
	}
	
	println('🔄 Reconnecting in ${delay}...')
	time.sleep(delay)
	
	session.start() or {
		println('❌ Reconnect failed: ${err}')
		spawn session.reconnect()
	}
}

// Restart session
fn (mut session Session) restart() ! {
	session.cleanup_session()
	session.start()!
}

// Start heartbeat
fn (mut session Session) start_heartbeat() {
	session.heartbeat_timer = time.new_timer()
	
	spawn fn [mut session] () {
		for {
			time.sleep(whatsapp.heartbeat_interval * time.millisecond)
			
			if session.state == .ready && session.ws_client.is_connected() {
				// Send heartbeat ping
				session.ws_client.ws.ping() or {
					session.handle_error('Heartbeat failed', {})
					break
				}
			} else {
				break
			}
		}
	}()
}

// Sync initial data setelah login
fn (mut session Session) sync_initial_data() ! {
	println('🔄 Syncing initial data...')
	
	// Request chats
	session.request_chats()!
	
	// Request contacts
	session.request_contacts()!
	
	// Request presence updates
	session.request_presence_updates()!
	
	println('✅ Initial sync completed')
}

// Request chats dari server
fn (mut session Session) request_chats() ! {
	// Implementation akan ditambahkan
}

// Request contacts dari server
fn (mut session Session) request_contacts() ! {
	// Implementation akan ditambahkan
}

// Request presence updates
fn (mut session Session) request_presence_updates() ! {
	// Implementation akan ditambahkan
}

// QR timeout handler
fn (mut session Session) qr_timeout_handler() {
	time.sleep(20 * time.second)
	
	if session.state == .authenticating && session.config.auth_method == .qr_code {
		if session.qr_attempts < 5 {
			println('⏰ QR Code expired, generating new one...')
			session.generate_qr_code() or {
				println('❌ Failed to generate new QR code: ${err}')
			}
		} else {
			println('❌ Max QR attempts reached')
		}
	}
}

// Print QR code ke terminal
fn (mut session Session) print_qr_code(data string) {
	// Simple ASCII QR code representation
	println('┌${'─'.repeat(50)}┐')
	for i in 0 .. 20 {
		mut line := '│'
		for j in 0 .. 48 {
			// Simple pattern based on data hash
			hash := (data.len + i + j) % 3
			if hash == 0 {
				line += '██'
			} else {
				line += '  '
			}
		}
		line += '│'
		println(line)
	}
	println('└${'─'.repeat(50)}┘')
	println('QR Data: ${data}')
}

// Save session ke file
fn (mut session Session) save_session() ! {
	// Create session directory jika belum ada
	session_dir := os.dir(session.session_file)
	if !os.exists(session_dir) {
		os.mkdir_all(session_dir)!
	}
	
	mut session_data := map[string]json.Any{}
	session_data['client_id'] = json.Any(session.client_id)
	session_data['private_key'] = json.Any(base64.encode(session.keypair.private_key))
	session_data['public_key'] = json.Any(base64.encode(session.keypair.public_key))
	
	if keys := session.encryption_keys {
		session_data['enc_key'] = json.Any(base64.encode(keys.enc_key))
		session_data['mac_key'] = json.Any(base64.encode(keys.mac_key))
	}
	
	if conn_info := session.connection_info {
		mut conn_data := map[string]json.Any{}
		conn_data['server_token'] = json.Any(conn_info.server_token)
		conn_data['client_token'] = json.Any(conn_info.client_token)
		conn_data['browser_token'] = json.Any(conn_info.browser_token)
		conn_data['secret'] = json.Any(conn_info.secret)
		conn_data['wid'] = json.Any(conn_info.wid)
		conn_data['pushname'] = json.Any(conn_info.pushname)
		session_data['connection'] = json.Any(conn_data)
	}
	
	session_data['timestamp'] = json.Any(time.now().unix_time())
	
	json_str := json.encode_pretty(session_data)
	os.write_file(session.session_file, json_str)!
	
	println('💾 Session saved to ${session.session_file}')
}

// Load existing session dari file
fn (mut session Session) load_existing_session() bool {
	if !os.exists(session.session_file) {
		return false
	}
	
	content := os.read_file(session.session_file) or { return false }
	session_data := json.decode(map[string]json.Any, content) or { return false }
	
	// Load client ID
	if 'client_id' in session_data {
		session.client_id = session_data['client_id'].str()
	}
	
	// Load keypair
	if 'private_key' in session_data && 'public_key' in session_data {
		private_key := base64.decode(session_data['private_key'].str()) or { return false }
		public_key := base64.decode(session_data['public_key'].str()) or { return false }
		
		session.keypair = KeyPair{
			private_key: private_key
			public_key: public_key
		}
	}
	
	// Load encryption keys
	if 'enc_key' in session_data && 'mac_key' in session_data {
		enc_key := base64.decode(session_data['enc_key'].str()) or { return false }
		mac_key := base64.decode(session_data['mac_key'].str()) or { return false }
		
		session.encryption_keys = EncryptionKeys{
			enc_key: enc_key
			mac_key: mac_key
		}
	}
	
	// Load connection info
	if 'connection' in session_data {
		conn_data := session_data['connection'].as_map()
		
		session.connection_info = ConnectionInfo{
			server_token: if 'server_token' in conn_data { conn_data['server_token'].str() } else { '' }
			client_token: if 'client_token' in conn_data { conn_data['client_token'].str() } else { '' }
			browser_token: if 'browser_token' in conn_data { conn_data['browser_token'].str() } else { '' }
			secret: if 'secret' in conn_data { conn_data['secret'].str() } else { '' }
			wid: if 'wid' in conn_data { conn_data['wid'].str() } else { '' }
			pushname: if 'pushname' in conn_data { conn_data['pushname'].str() } else { '' }
			battery: 100
			platform: 'V-WhatsApp'
			phone: map[string]string{}
			ref: ''
			ttl: 20000
			is_new: false
		}
	}
	
	println('📂 Existing session loaded')
	return true
}

// Cleanup session
fn (mut session Session) cleanup_session() {
	session.state = .logged_out
	
	// Remove session file
	if os.exists(session.session_file) {
		os.rm(session.session_file) or {}
	}
	
	// Clear data
	session.auth_state.clear()
	session.chats.clear()
	session.contacts.clear()
	session.connection_info = none
	session.encryption_keys = none
	
	println('🧹 Session cleaned up')
}

// Periodic session save
fn (mut session Session) periodic_session_save() {
	for {
		time.sleep(5 * time.minute)
		
		if session.state == .ready {
			session.save_session() or {
				println('❌ Failed to save session: ${err}')
			}
		} else {
			break
		}
	}
}

// Public API methods

// Send text message
pub fn (mut session Session) send_message(jid string, text string, options SendMessageOptions) !string {
	if session.state != .ready {
		return error('Session not ready')
	}
	
	// Implementation akan ditambahkan di message.v
	return 'message_id'
}

// Get chats
pub fn (session &Session) get_chats() map[string]Chat {
	return session.chats.clone()
}

// Get messages untuk chat tertentu
pub fn (session &Session) get_messages(jid string) []Message {
	session.message_store.mutex.@lock()
	defer {
		session.message_store.mutex.unlock()
	}
	
	return session.message_store.messages[jid] or { []Message{} }
}

// Get connection state
pub fn (session &Session) get_state() ConnectionState {
	return session.state
}

// Logout
pub fn (mut session Session) logout() ! {
	if session.ws_client.is_connected() {
		session.ws_client.send_logout()!
	}
	
	session.ws_client.close()!
	session.cleanup_session()
}