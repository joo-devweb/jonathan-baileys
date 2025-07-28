module main

import whatsapp

fn main() {
	println('WhatsApp V-Lang Library Example')
	println('================================')
	
	// Create new WhatsApp session
	mut session := whatsapp.new_session() or {
		eprintln('Failed to create session: ${err}')
		return
	}
	
	// Set up event handlers
	session.on_qr_code = fn (qr_data string) {
		println('\n🔗 QR Code Data: ${qr_data}')
		println('📱 Scan this QR code with your WhatsApp mobile app')
		
		// Generate and display QR code
		qr := whatsapp.generate_qr_code(qr_data)
		println('\n📋 QR Code:')
		println(qr.to_ascii())
		
		// Also create URL for online QR generation
		url := whatsapp.create_qr_url(qr_data, 300)
		println('🌐 Online QR Code: ${url}')
	}
	
	session.on_pairing = fn (code string) {
		println('🔑 Pairing Code: ${code}')
	}
	
	session.on_connected = fn () {
		println('✅ Successfully connected to WhatsApp!')
		println('🚀 Session is ready to send/receive messages')
	}
	
	session.on_message = fn (node whatsapp.BinaryNode) {
		println('📨 Received message: ${node.tag}')
		if node.tag == 'message' {
			// Handle incoming message
			handle_incoming_message(node)
		}
	}
	
	session.on_error = fn (err string) {
		eprintln('❌ Error: ${err}')
	}
	
	// Connect to WhatsApp
	println('🔄 Connecting to WhatsApp Web...')
	session.connect() or {
		eprintln('Failed to connect: ${err}')
		return
	}
	
	// Wait for authentication
	println('⏳ Waiting for authentication...')
	for !session.is_ready() {
		// Keep the program running
		// In a real application, you might want to handle this differently
		if session.get_state() == .disconnected {
			eprintln('❌ Connection lost')
			return
		}
	}
	
	println('🎉 WhatsApp session is ready!')
	
	// Example: Send a message (uncomment and modify as needed)
	/*
	session.send_text_message('1234567890@c.us', 'Hello from V-Lang WhatsApp Library!') or {
		eprintln('Failed to send message: ${err}')
	}
	*/
	
	// Keep the session alive
	println('📡 Session active. Press Ctrl+C to exit.')
	for session.is_ready() {
		// Keep running
		// In a real application, you might want to handle user input here
	}
	
	// Cleanup
	session.disconnect() or {
		eprintln('Error during disconnect: ${err}')
	}
	
	println('👋 Goodbye!')
}

fn handle_incoming_message(node whatsapp.BinaryNode) {
	// Extract message details
	mut from := ''
	mut message_type := ''
	mut message_id := ''
	
	if 'from' in node.attributes {
		from = node.attributes['from']
	}
	
	if 'type' in node.attributes {
		message_type = node.attributes['type']
	}
	
	if 'id' in node.attributes {
		message_id = node.attributes['id']
	}
	
	println('📧 Message Details:')
	println('   From: ${from}')
	println('   Type: ${message_type}')
	println('   ID: ${message_id}')
	
	// Handle content based on type
	if content := node.content {
		match content {
			string {
				println('   Text: ${content}')
			}
			[]whatsapp.BinaryNode {
				println('   Content nodes: ${content.len}')
				for child in content {
					if child.tag == 'body' {
						if text_content := child.content {
							if text_content is string {
								println('   Body: ${text_content}')
							}
						}
					}
				}
			}
			else {
				println('   Content: [binary data]')
			}
		}
	}
}