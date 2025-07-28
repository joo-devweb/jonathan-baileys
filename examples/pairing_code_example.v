module main

import whatsapp
import os

fn main() {
	println('WhatsApp V-Lang Library - Pairing Code Example')
	println('==============================================')
	
	// Get phone number from user
	print('📱 Enter your phone number (with country code, e.g., +1234567890): ')
	phone_number := os.input('').trim_space()
	
	if phone_number.len == 0 {
		eprintln('❌ Phone number is required')
		return
	}
	
	// Create new WhatsApp session
	mut session := whatsapp.new_session() or {
		eprintln('Failed to create session: ${err}')
		return
	}
	
	// Set up event handlers
	session.on_pairing = fn (code string) {
		println('\n🔑 Your Pairing Code: ${code}')
		println('📱 Enter this code in your WhatsApp mobile app:')
		println('   1. Open WhatsApp on your phone')
		println('   2. Go to Settings > Linked Devices')
		println('   3. Tap "Link a Device"')
		println('   4. Enter the pairing code: ${code}')
	}
	
	session.on_connected = fn () {
		println('✅ Successfully connected to WhatsApp!')
		println('🚀 Session is ready to send/receive messages')
	}
	
	session.on_message = fn (node whatsapp.BinaryNode) {
		println('📨 Received message: ${node.tag}')
		handle_message(node)
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
	
	// Request pairing code
	println('📞 Requesting pairing code for ${phone_number}...')
	session.request_pairing_code(phone_number) or {
		eprintln('Failed to request pairing code: ${err}')
		return
	}
	
	// Wait for authentication
	println('⏳ Waiting for pairing code authentication...')
	for !session.is_ready() && session.get_state() != .disconnected {
		// Keep the program running
	}
	
	if session.get_state() == .disconnected {
		eprintln('❌ Connection lost')
		return
	}
	
	println('🎉 WhatsApp session is ready!')
	
	// Interactive chat mode
	println('\n💬 Interactive Chat Mode')
	println('========================')
	println('Commands:')
	println('  /send <number> <message> - Send a message')
	println('  /quit - Exit the program')
	println('')
	
	for session.is_ready() {
		print('> ')
		input := os.input('').trim_space()
		
		if input.starts_with('/quit') {
			break
		} else if input.starts_with('/send ') {
			parts := input[6..].split_nth(' ', 2)
			if parts.len >= 2 {
				jid := format_jid(parts[0])
				message := parts[1]
				
				println('📤 Sending message to ${jid}: ${message}')
				session.send_text_message(jid, message) or {
					eprintln('Failed to send message: ${err}')
				}
			} else {
				println('❌ Usage: /send <number> <message>')
			}
		} else if input.len > 0 {
			println('❌ Unknown command. Use /send <number> <message> or /quit')
		}
	}
	
	// Cleanup
	session.disconnect() or {
		eprintln('Error during disconnect: ${err}')
	}
	
	println('👋 Goodbye!')
}

fn handle_message(node whatsapp.BinaryNode) {
	if node.tag == 'message' {
		mut from := ''
		mut message_type := ''
		
		if 'from' in node.attributes {
			from = node.attributes['from']
		}
		
		if 'type' in node.attributes {
			message_type = node.attributes['type']
		}
		
		if message_type == 'text' {
			if content := node.content {
				if content is []whatsapp.BinaryNode {
					for child in content {
						if child.tag == 'body' {
							if text_content := child.content {
								if text_content is string {
									println('📨 Message from ${from}: ${text_content}')
								}
							}
						}
					}
				}
			}
		}
	}
}

fn format_jid(number string) string {
	// Remove any non-numeric characters except +
	mut clean_number := ''
	for char in number {
		if char.is_digit() || char == `+` {
			clean_number += char.ascii_str()
		}
	}
	
	// Remove leading + if present
	if clean_number.starts_with('+') {
		clean_number = clean_number[1..]
	}
	
	// Add @c.us suffix for individual chats
	return '${clean_number}@c.us'
}