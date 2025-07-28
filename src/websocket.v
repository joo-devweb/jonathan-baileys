module whatsapp

import net.websocket
import net.http
import time
import json
import sync
import encoding.base64

// WebSocket client untuk WhatsApp Web
pub struct WSClient {
mut:
	ws              &websocket.Client
	connected       bool
	authenticated   bool
	message_chan    chan WSMessage
	error_chan      chan WSError
	close_chan      chan bool
	ping_ticker     &time.Ticker
	reconnect_count int
	last_ping       time.Time
	last_pong       time.Time
	message_id      u64
	pending_messages map[string]PendingMessage
	event_callbacks ?&EventCallbacks
	mutex           &sync.Mutex
}

// Struktur untuk pesan WebSocket
pub struct WSMessage {
pub:
	id      string
	data    []u8
	is_text bool
}

// Struktur untuk error WebSocket
pub struct WSError {
pub:
	code    int
	message string
	fatal   bool
}

// Struktur untuk pesan pending
struct PendingMessage {
	timestamp time.Time
	callback  ?fn ([]u8) !
	timeout   time.Duration
}

// Buat WebSocket client baru
pub fn new_ws_client(callbacks ?&EventCallbacks) !&WSClient {
	return &WSClient{
		ws: unsafe { nil }
		connected: false
		authenticated: false
		message_chan: chan WSMessage{cap: 1000}
		error_chan: chan WSError{cap: 100}
		close_chan: chan bool{cap: 1}
		ping_ticker: unsafe { nil }
		reconnect_count: 0
		last_ping: time.now()
		last_pong: time.now()
		message_id: 0
		pending_messages: map[string]PendingMessage{}
		event_callbacks: callbacks
		mutex: sync.new_mutex()
	}
}

// Koneksi ke WhatsApp WebSocket
pub fn (mut client WSClient) connect() ! {
	client.mutex.@lock()
	defer {
		client.mutex.unlock()
	}

	if client.connected {
		return error('Sudah terhubung')
	}

	// Setup WebSocket dengan headers yang benar
	mut ws := websocket.new_client(whatsapp.ws_url)!
	ws.header.add_custom('Origin', whatsapp.web_origin)!
	ws.header.add_custom('User-Agent', whatsapp.user_agent)!
	ws.header.add_custom('Sec-WebSocket-Protocol', 'chat')!
	ws.header.add_custom('Sec-WebSocket-Extensions', 'permessage-deflate; client_max_window_bits')!

	// Set callback handlers
	ws.on_open = fn [mut client] (mut ws websocket.Client) ! {
		client.on_open()!
	}

	ws.on_message = fn [mut client] (mut ws websocket.Client, msg &websocket.Message) ! {
		client.on_message(msg)!
	}

	ws.on_error = fn [mut client] (mut ws websocket.Client, err string) ! {
		client.on_error(err)
	}

	ws.on_close = fn [mut client] (mut ws websocket.Client, code int, reason string) ! {
		client.on_close(code, reason)
	}

	// Mulai koneksi
	ws.connect()!
	client.ws = &ws
	
	// Start message processing goroutine
	spawn client.process_messages()
	
	// Start heartbeat
	client.start_heartbeat()
}

// Handler untuk koneksi terbuka
fn (mut client WSClient) on_open() ! {
	client.connected = true
	client.reconnect_count = 0
	client.last_ping = time.now()
	client.last_pong = time.now()
	
	if client.event_callbacks != none {
		callbacks := client.event_callbacks or { return }
		if callbacks.on_connection_update != none {
			update_fn := callbacks.on_connection_update or { return }
			update_fn(.connected, {})
		}
	}
}

// Handler untuk pesan masuk
fn (mut client WSClient) on_message(msg &websocket.Message) ! {
	match msg.opcode {
		.text_frame {
			// Handle text message (JSON)
			client.handle_text_message(msg.payload)!
		}
		.binary_frame {
			// Handle binary message (encrypted)
			client.handle_binary_message(msg.payload)!
		}
		.pong {
			client.last_pong = time.now()
		}
		else {
			// Ignore other frame types
		}
	}
}

// Handler untuk text message (JSON)
fn (mut client WSClient) handle_text_message(payload []u8) ! {
	text := payload.bytestr()
	
	// Parse message tag dan JSON
	parts := text.split(',')
	if parts.len < 2 {
		return error('Format pesan tidak valid')
	}
	
	tag := parts[0]
	json_part := parts[1..].join(',')
	
	// Parse JSON
	parsed := json.decode([]json.Any, json_part)!
	
	// Handle berdasarkan tipe pesan
	if parsed.len > 0 {
		match parsed[0] {
			json.Any(string) {
				cmd := parsed[0].str()
				match cmd {
					'Conn' {
						client.handle_conn_message(parsed)!
					}
					'Stream' {
						client.handle_stream_message(parsed)!
					}
					'Props' {
						client.handle_props_message(parsed)!
					}
					'Cmd' {
						client.handle_cmd_message(parsed)!
					}
					else {
						// Handle pesan lainnya
						client.handle_generic_message(tag, parsed)!
					}
				}
			}
			else {}
		}
	}
	
	// Check untuk pending message response
	client.resolve_pending_message(tag, payload)
}

// Handler untuk binary message (encrypted)
fn (mut client WSClient) handle_binary_message(payload []u8) ! {
	// Extract tag dari awal pesan
	comma_idx := payload.index_u8(`,`) or {
		return error('Tag tidak ditemukan dalam binary message')
	}
	
	tag := payload[..comma_idx].bytestr()
	binary_data := payload[comma_idx + 1..]
	
	// Kirim ke channel untuk processing
	client.message_chan <- WSMessage{
		id: tag
		data: binary_data
		is_text: false
	}
	
	// Check untuk pending message response
	client.resolve_pending_message(tag, payload)
}

// Handler untuk error
fn (mut client WSClient) on_error(err string) {
	client.error_chan <- WSError{
		code: -1
		message: err
		fatal: false
	}
	
	if client.event_callbacks != none {
		callbacks := client.event_callbacks or { return }
		if callbacks.on_error != none {
			error_fn := callbacks.on_error or { return }
			error_fn(err, {})
		}
	}
}

// Handler untuk koneksi ditutup
fn (mut client WSClient) on_close(code int, reason string) {
	client.connected = false
	client.authenticated = false
	
	if client.ping_ticker != unsafe { nil } {
		client.ping_ticker.stop()
	}
	
	client.close_chan <- true
	
	if client.event_callbacks != none {
		callbacks := client.event_callbacks or { return }
		if callbacks.on_connection_update != none {
			update_fn := callbacks.on_connection_update or { return }
			update_fn(.disconnected, {'code': code.str(), 'reason': reason})
		}
	}
	
	// Auto reconnect jika bukan close manual
	if code != 1000 && client.reconnect_count < whatsapp.max_reconnect_attempts {
		spawn client.reconnect()
	}
}

// Reconnect otomatis
fn (mut client WSClient) reconnect() {
	client.reconnect_count++
	
	// Exponential backoff
	delay := time.Duration(1000 * (1 << client.reconnect_count)) * time.millisecond
	if delay > 30 * time.second {
		delay = 30 * time.second
	}
	
	time.sleep(delay)
	
	client.connect() or {
		if client.reconnect_count < whatsapp.max_reconnect_attempts {
			spawn client.reconnect()
		}
	}
}

// Kirim pesan text
pub fn (mut client WSClient) send_text(tag string, data []json.Any) ! {
	if !client.connected {
		return error('Tidak terhubung')
	}
	
	json_str := json.encode(data)
	message := '${tag},${json_str}'
	
	client.ws.write_string(message)!
}

// Kirim pesan binary
pub fn (mut client WSClient) send_binary(tag string, data []u8) ! {
	if !client.connected {
		return error('Tidak terhubung')
	}
	
	mut message := tag.bytes()
	message << u8(`,`)
	message << data
	
	client.ws.write(message, .binary_frame)!
}

// Kirim pesan dengan callback
pub fn (mut client WSClient) send_with_callback(tag string, data []json.Any, callback fn ([]u8) !, timeout time.Duration) ! {
	// Simpan callback untuk response
	client.pending_messages[tag] = PendingMessage{
		timestamp: time.now()
		callback: callback
		timeout: timeout
	}
	
	// Kirim pesan
	client.send_text(tag, data)!
	
	// Set timeout untuk cleanup
	spawn client.cleanup_pending_message(tag, timeout)
}

// Generate message ID unik
pub fn (mut client WSClient) generate_message_id() string {
	client.message_id++
	return time.now().unix_time().str() + '.' + client.message_id.str()
}

// Start heartbeat ping
fn (mut client WSClient) start_heartbeat() {
	client.ping_ticker = time.new_ticker(whatsapp.heartbeat_interval * time.millisecond)
	
	spawn fn [mut client] () {
		for {
			select {
				_ := <-client.ping_ticker.c {
					if client.connected {
						// Check jika pong tidak diterima dalam 10 detik
						if time.now().unix_time() - client.last_pong.unix_time() > 10 {
							client.on_error('Ping timeout')
							break
						}
						
						// Kirim ping
						client.ws.ping()!
						client.last_ping = time.now()
					}
				}
				_ := <-client.close_chan {
					break
				}
			}
		}
	}()
}

// Process messages dari channel
fn (mut client WSClient) process_messages() {
	for {
		select {
			msg := <-client.message_chan {
				// Process binary message
				client.process_binary_message(msg) or {
					client.on_error('Error processing binary message: ${err}')
				}
			}
			_ := <-client.close_chan {
				break
			}
		}
	}
}

// Process binary message yang sudah didekripsi
fn (mut client WSClient) process_binary_message(msg WSMessage) ! {
	// Implementasi akan ditambahkan di binary_node.v
	// Untuk sekarang, kirim ke callback jika ada
	if client.event_callbacks != none {
		callbacks := client.event_callbacks or { return }
		// Process berdasarkan tipe pesan
	}
}

// Resolve pending message dengan response
fn (mut client WSClient) resolve_pending_message(tag string, response []u8) {
	if tag in client.pending_messages {
		pending := client.pending_messages[tag]
		if callback := pending.callback {
			callback(response) or {
				client.on_error('Error in pending message callback: ${err}')
			}
		}
		client.pending_messages.delete(tag)
	}
}

// Cleanup pending message yang timeout
fn (mut client WSClient) cleanup_pending_message(tag string, timeout time.Duration) {
	time.sleep(timeout)
	if tag in client.pending_messages {
		client.pending_messages.delete(tag)
	}
}

// Handler untuk pesan Conn
fn (mut client WSClient) handle_conn_message(data []json.Any) ! {
	if data.len >= 2 {
		if conn_data := data[1] as json.Any {
			// Parse connection info
			if client.event_callbacks != none {
				callbacks := client.event_callbacks or { return }
				if callbacks.on_auth_state_change != none {
					auth_fn := callbacks.on_auth_state_change or { return }
					auth_fn({'type': 'connection', 'data': conn_data.str()})
				}
			}
		}
	}
}

// Handler untuk pesan Stream
fn (mut client WSClient) handle_stream_message(data []json.Any) ! {
	// Handle stream updates
}

// Handler untuk pesan Props
fn (mut client WSClient) handle_props_message(data []json.Any) ! {
	// Handle props updates
}

// Handler untuk pesan Cmd
fn (mut client WSClient) handle_cmd_message(data []json.Any) ! {
	if data.len >= 2 {
		if cmd_data := data[1] as json.Any {
			// Handle command messages (challenge, etc)
		}
	}
}

// Handler untuk pesan generic
fn (mut client WSClient) handle_generic_message(tag string, data []json.Any) ! {
	// Handle pesan lainnya
}

// Tutup koneksi
pub fn (mut client WSClient) close() ! {
	client.mutex.@lock()
	defer {
		client.mutex.unlock()
	}
	
	if !client.connected {
		return
	}
	
	if client.ping_ticker != unsafe { nil } {
		client.ping_ticker.stop()
	}
	
	client.ws.close(1000, 'Normal closure')!
	client.connected = false
	client.authenticated = false
}

// Check apakah terhubung
pub fn (client &WSClient) is_connected() bool {
	return client.connected
}

// Check apakah sudah authenticated
pub fn (client &WSClient) is_authenticated() bool {
	return client.authenticated
}

// Set authenticated status
pub fn (mut client WSClient) set_authenticated(status bool) {
	client.authenticated = status
}

// Get message channel untuk external processing
pub fn (client &WSClient) get_message_channel() chan WSMessage {
	return client.message_chan
}

// Get error channel untuk external handling
pub fn (client &WSClient) get_error_channel() chan WSError {
	return client.error_chan
}

// Send admin init command
pub fn (mut client WSClient) send_init(client_id string) ! {
	tag := client.generate_message_id()
	
	init_data := [
		json.Any('admin'),
		json.Any('init'),
		json.Any(whatsapp.wa_version),
		json.Any([whatsapp.browser_name, whatsapp.browser_version]),
		json.Any(client_id),
		json.Any(true)
	]
	
	client.send_text(tag, init_data)!
}

// Send admin login command
pub fn (mut client WSClient) send_login(client_token string, server_token string, client_id string) ! {
	tag := client.generate_message_id()
	
	login_data := [
		json.Any('admin'),
		json.Any('login'),
		json.Any(client_token),
		json.Any(server_token),
		json.Any(client_id),
		json.Any('takeover')
	]
	
	client.send_text(tag, login_data)!
}

// Send challenge response
pub fn (mut client WSClient) send_challenge_response(challenge_response string, server_token string, client_id string) ! {
	tag := client.generate_message_id()
	
	challenge_data := [
		json.Any('admin'),
		json.Any('challenge'),
		json.Any(challenge_response),
		json.Any(server_token),
		json.Any(client_id)
	]
	
	client.send_text(tag, challenge_data)!
}

// Send logout command
pub fn (mut client WSClient) send_logout() ! {
	tag := client.generate_message_id()
	
	logout_data := [
		json.Any('admin'),
		json.Any('Conn'),
		json.Any('disconnect')
	]
	
	client.send_text(tag, logout_data)!
}

// Send presence update
pub fn (mut client WSClient) send_presence(jid string, presence_type PresenceType) ! {
	tag := client.generate_message_id()
	
	presence_str := match presence_type {
		.available { 'available' }
		.unavailable { 'unavailable' }
		.composing { 'composing' }
		.recording { 'recording' }
		.paused { 'paused' }
	}
	
	presence_data := [
		json.Any('action'),
		json.Any('presence'),
		json.Any(presence_str),
		json.Any(jid)
	]
	
	client.send_text(tag, presence_data)!
}

// Send read receipt
pub fn (mut client WSClient) send_read_receipt(jid string, message_id string, participant string) ! {
	tag := client.generate_message_id()
	
	mut receipt_data := [
		json.Any('action'),
		json.Any('read'),
		json.Any(jid),
		json.Any(message_id)
	]
	
	if participant.len > 0 {
		receipt_data << json.Any(participant)
	}
	
	client.send_text(tag, receipt_data)!
}