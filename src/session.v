module whatsapp

import time
import json
import encoding.base64
import crypto.rand

// Session state
pub enum SessionState {
	disconnected
	connecting
	connected
	authenticating
	authenticated
	ready
}

// Authentication method
pub enum AuthMethod {
	qr_code
	pairing_code
}

// Connection info from WhatsApp
pub struct ConnectionInfo {
pub mut:
	battery       int
	platform      string
	pushname      string
	secret        string
	server_token  string
	client_token  string
	browser_token string
	wid           string
	phone         map[string]string
}

// WhatsApp session
pub struct Session {
mut:
	ws_client     &WSClient
	state         SessionState
	client_id     string
	keypair       KeyPair
	enc_key       []u8
	mac_key       []u8
	conn_info     ?ConnectionInfo
	message_tag   int
	auth_method   AuthMethod
	pairing_code  string
pub mut:
	on_qr_code    fn(string)
	on_pairing    fn(string)
	on_connected  fn()
	on_message    fn(BinaryNode)
	on_error      fn(string)
}

// Create new WhatsApp session
pub fn new_session() !&Session {
	ws_client := new_ws_client()!
	keypair := generate_keypair()!
	client_id := generate_client_id()!
	
	return &Session{
		ws_client: ws_client
		state: .disconnected
		client_id: client_id
		keypair: keypair
		enc_key: []u8{}
		mac_key: []u8{}
		conn_info: none
		message_tag: int(time.now().unix_time())
		auth_method: .qr_code
		pairing_code: ''
		on_qr_code: fn(code string) { println('QR Code: ${code}') }
		on_pairing: fn(code string) { println('Pairing Code: ${code}') }
		on_connected: fn() { println('Connected to WhatsApp!') }
		on_message: fn(node BinaryNode) { println('Received message: ${node.tag}') }
		on_error: fn(err string) { println('Error: ${err}') }
	}
}

// Connect to WhatsApp Web
pub fn (mut session Session) connect() ! {
	session.state = .connecting
	session.ws_client.connect()!
	session.state = .connected
	
	// Start message handler
	go session.handle_messages()
	
	// Send init message
	session.send_init()!
}

// Send init message to start authentication
fn (mut session Session) send_init() ! {
	session.message_tag++
	tag := session.message_tag.str()
	
	init_data := [
		json.Any('admin'),
		json.Any('init'),
		json.Any(wa_version.map(json.Any(it))),
		json.Any(['WhatsApp V-Lang Client', 'V-WA']),
		json.Any(session.client_id),
		json.Any(true)
	]
	
	session.ws_client.send_json_with_tag(tag, init_data)!
}

// Handle incoming messages
fn (mut session Session) handle_messages() {
	for {
		if !session.ws_client.is_connected() {
			break
		}
		
		message := session.ws_client.receive() or {
			session.on_error(err.msg())
			continue
		}
		
		match message.typ {
			.text {
				session.handle_text_message(message.payload.bytestr()) or {
					session.on_error(err.msg())
				}
			}
			.binary {
				session.handle_binary_message(message.payload) or {
					session.on_error(err.msg())
				}
			}
		}
	}
}

// Handle text (JSON) messages
fn (mut session Session) handle_text_message(message string) ! {
	tag, data := parse_tagged_message(message)!
	
	if data is []json.Any {
		array_data := data as []json.Any
		if array_data.len > 0 {
			first := array_data[0]
			if first is string {
				command := first as string
				match command {
					'Conn' {
						session.handle_connection_message(array_data)!
					}
					'Stream' {
						session.handle_stream_message(array_data)!
					}
					'Props' {
						session.handle_props_message(array_data)!
					}
					else {
						// Handle init response or other messages
						if array_data.len > 1 && array_data[1] is map[string]json.Any {
							obj := array_data[1] as map[string]json.Any
							if 'status' in obj {
								session.handle_init_response(obj)!
							}
						}
					}
				}
			}
		}
	}
}

// Handle init response
fn (mut session Session) handle_init_response(response map[string]json.Any) ! {
	status := response['status'] or { return error('No status in response') }
	if status is int && status as int == 200 {
		ref := response['ref'] or { return error('No ref in response') }
		if ref is string {
			session.generate_qr_code(ref as string)!
		}
	}
}

// Generate QR code for authentication
fn (mut session Session) generate_qr_code(ref string) ! {
	public_key_b64 := base64.encode(session.keypair.public_key)
	qr_data := '${ref},${public_key_b64},${session.client_id}'
	session.on_qr_code(qr_data)
}

// Handle connection message (after QR scan)
fn (mut session Session) handle_connection_message(data []json.Any) ! {
	if data.len < 2 {
		return error('Invalid connection message')
	}
	
	if data[1] is map[string]json.Any {
		conn_data := data[1] as map[string]json.Any
		
		mut conn_info := ConnectionInfo{}
		
		if 'battery' in conn_data {
			if batt := conn_data['battery'] {
				if batt is int {
					conn_info.battery = batt as int
				}
			}
		}
		
		if 'platform' in conn_data {
			if plat := conn_data['platform'] {
				if plat is string {
					conn_info.platform = plat as string
				}
			}
		}
		
		if 'pushname' in conn_data {
			if name := conn_data['pushname'] {
				if name is string {
					conn_info.pushname = name as string
				}
			}
		}
		
		if 'secret' in conn_data {
			if secret := conn_data['secret'] {
				if secret is string {
					conn_info.secret = secret as string
					session.derive_keys(secret as string)!
				}
			}
		}
		
		if 'wid' in conn_data {
			if wid := conn_data['wid'] {
				if wid is string {
					conn_info.wid = wid as string
				}
			}
		}
		
		session.conn_info = conn_info
		session.state = .authenticated
		session.on_connected()
	}
}

// Handle stream message
fn (mut session Session) handle_stream_message(data []json.Any) ! {
	// Stream message handling
	println('Stream message received')
}

// Handle props message
fn (mut session Session) handle_props_message(data []json.Any) ! {
	// Props message handling
	println('Props message received')
}

// Derive encryption keys from shared secret
fn (mut session Session) derive_keys(secret_b64 string) ! {
	secret := base64.decode(secret_b64)
	if secret.len != secret_length {
		return error('Invalid secret length: ${secret.len}')
	}
	
	// Extract server public key (first 32 bytes)
	server_public_key := secret[..32]
	
	// Generate shared secret using ECDH
	shared_secret := generate_shared_secret(session.keypair.private_key, server_public_key)!
	
	// Expand shared secret using HKDF
	null_salt := []u8{len: 32}
	shared_secret_expanded := hkdf_derive(shared_secret, null_salt, []u8{}, shared_secret_expanded_length)!
	
	// Validate HMAC (optional but recommended)
	expected_hmac := secret[32..64]
	validation_data := []u8{}
	validation_data << secret[..32]
	validation_data << secret[64..]
	computed_hmac := hmac_sha256(shared_secret_expanded[32..64], validation_data)
	
	if !validate_hmac(shared_secret_expanded[32..64], validation_data, expected_hmac) {
		return error('HMAC validation failed')
	}
	
	// Prepare encrypted keys
	mut keys_encrypted := []u8{}
	keys_encrypted << shared_secret_expanded[64..]
	keys_encrypted << secret[64..]
	
	// Decrypt keys using AES
	aes_key := shared_secret_expanded[..32]
	keys_decrypted := aes_decrypt(aes_key, keys_encrypted)!
	
	// Extract final keys
	session.enc_key = keys_decrypted[..enc_key_length]
	session.mac_key = keys_decrypted[enc_key_length..enc_key_length + mac_key_length]
	
	session.state = .ready
}

// Handle binary messages
fn (mut session Session) handle_binary_message(data []u8) ! {
	if data.len < hmac_length {
		return error('Binary message too short')
	}
	
	// Extract HMAC and encrypted data
	received_hmac := data[..hmac_length]
	encrypted_data := data[hmac_length..]
	
	// Validate HMAC
	if !validate_hmac(session.mac_key, encrypted_data, received_hmac) {
		return error('Binary message HMAC validation failed')
	}
	
	// Decrypt message
	decrypted_data := aes_decrypt(session.enc_key, encrypted_data)!
	
	// Parse binary node
	node := parse_binary_node(decrypted_data)!
	session.on_message(node)
}

// Send binary message
pub fn (mut session Session) send_binary_node(node BinaryNode) ! {
	if session.state != .ready {
		return error('Session not ready')
	}
	
	// Encode node to binary
	node_data := encode_binary_node(node)
	
	// Encrypt data
	encrypted_data := aes_encrypt(session.enc_key, node_data)!
	
	// Generate HMAC
	hmac_data := hmac_sha256(session.mac_key, encrypted_data)
	
	// Combine HMAC and encrypted data
	mut message := []u8{}
	message << hmac_data
	message << encrypted_data
	
	session.ws_client.send_binary(message)!
}

// Send text message to contact
pub fn (mut session Session) send_text_message(jid string, text string) ! {
	session.message_tag++
	
	message_node := BinaryNode{
		tag: 'message'
		attributes: {
			'id': session.message_tag.str()
			'type': 'text'
			'to': jid
		}
		content: BinaryNode{
			tag: 'body'
			attributes: {}
			content: text
		}
	}
	
	session.send_binary_node(message_node)!
}

// Request pairing code
pub fn (mut session Session) request_pairing_code(phone_number string) ! {
	session.auth_method = .pairing_code
	session.message_tag++
	
	pairing_data := [
		json.Any('admin'),
		json.Any('pair-code'),
		json.Any(phone_number),
		json.Any(session.client_id)
	]
	
	session.ws_client.send_json_with_tag(session.message_tag.str(), pairing_data)!
}

// Get session state
pub fn (session &Session) get_state() SessionState {
	return session.state
}

// Check if session is ready
pub fn (session &Session) is_ready() bool {
	return session.state == .ready
}

// Disconnect session
pub fn (mut session Session) disconnect() ! {
	session.state = .disconnected
	session.ws_client.close()!
}