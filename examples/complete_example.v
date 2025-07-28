module main

import whatsapp
import time
import os

fn main() {
	println('🚀 WhatsApp V-Lang Library - Complete Example')
	println('===============================================')
	println('Author: Nathan.dev')
	println('Version: 1.0.0')
	println('')
	
	// Konfigurasi session
	config := whatsapp.SessionConfig{
		auth_method: .qr_code // Bisa juga .pairing_code
		browser_name: 'V-WhatsApp Bot'
		browser_version: '1.0.0'
		phone_number: '' // Diperlukan jika menggunakan pairing_code
		print_qr: true
		session_path: './session_data'
		log_level: 'info'
	}
	
	// Buat session baru
	mut session := whatsapp.new_session(config) or {
		eprintln('❌ Gagal membuat session: ${err}')
		return
	}
	
	// Setup event handlers
	setup_event_handlers(mut session)
	
	// Start session
	println('🔄 Memulai WhatsApp session...')
	session.start() or {
		eprintln('❌ Gagal memulai session: ${err}')
		return
	}
	
	// Wait sampai session ready
	for session.get_state() != .ready {
		time.sleep(1 * time.second)
		print('.')
	}
	
	println('\n✅ WhatsApp session siap!')
	
	// Demo fitur-fitur
	demo_features(mut session)
	
	// Keep alive
	println('\n⏰ Bot berjalan... Tekan Ctrl+C untuk keluar')
	for {
		time.sleep(1 * time.second)
		
		// Check jika session masih aktif
		if session.get_state() != .ready {
			println('❌ Session tidak aktif, mencoba restart...')
			session.start() or {
				eprintln('❌ Gagal restart session: ${err}')
				break
			}
		}
	}
	
	// Cleanup
	println('\n🧹 Membersihkan session...')
	session.logout() or {
		eprintln('❌ Gagal logout: ${err}')
	}
	
	println('👋 Selesai!')
}

// Setup event handlers untuk session
fn setup_event_handlers(mut session whatsapp.Session) {
	// Jika ada event callbacks yang perlu diset, lakukan di sini
	println('🔧 Event handlers telah dikonfigurasi')
}

// Demo berbagai fitur library
fn demo_features(mut session whatsapp.Session) {
	println('\n🎯 Demo Fitur Library:')
	
	// 1. Tampilkan info session
	display_session_info(session)
	
	// 2. Tampilkan daftar chat
	display_chats(session)
	
	// 3. Demo kirim pesan (commented untuk keamanan)
	// demo_send_message(mut session)
	
	// 4. Demo fitur lainnya
	demo_other_features(session)
}

// Tampilkan informasi session
fn display_session_info(session whatsapp.Session) {
	println('\n📊 Informasi Session:')
	println('   Status: ${session.get_state()}')
	
	chats := session.get_chats()
	println('   Total Chats: ${chats.len}')
	
	println('   Session Path: ./session_data')
}

// Tampilkan daftar chat
fn display_chats(session whatsapp.Session) {
	println('\n💬 Daftar Chat:')
	
	chats := session.get_chats()
	if chats.len == 0 {
		println('   Tidak ada chat ditemukan')
		return
	}
	
	mut count := 0
	for jid, chat in chats {
		if count >= 5 { // Tampilkan hanya 5 chat pertama
			println('   ... dan ${chats.len - 5} chat lainnya')
			break
		}
		
		chat_type := match chat.chat_type {
			.individual { '👤' }
			.group { '👥' }
			.broadcast { '📢' }
			else { '❓' }
		}
		
		unread_indicator := if chat.unread_count > 0 { ' (${chat.unread_count} unread)' } else { '' }
		
		println('   ${chat_type} ${chat.name}${unread_indicator}')
		println('      JID: ${jid}')
		
		if last_msg := chat.last_message {
			time_str := time.unix(i64(last_msg.timestamp)).format()
			println('      Last: ${last_msg.text} (${time_str})')
		}
		
		count++
	}
}

// Demo kirim pesan (untuk testing, uncomment jika diperlukan)
/*
fn demo_send_message(mut session whatsapp.Session) {
	println('\n📤 Demo Kirim Pesan:')
	
	// PERINGATAN: Ganti dengan JID yang valid untuk testing
	test_jid := '6281234567890@s.whatsapp.net' // Contoh format JID
	
	// Kirim pesan teks sederhana
	options := whatsapp.SendMessageOptions{}
	
	message_id := session.send_message(test_jid, 'Hello dari V-WhatsApp Library! 🚀', options) or {
		eprintln('❌ Gagal kirim pesan: ${err}')
		return
	}
	
	println('   ✅ Pesan terkirim dengan ID: ${message_id}')
	
	// Demo kirim pesan dengan quote
	quoted_options := whatsapp.SendMessageOptions{
		quoted_message_id: message_id
	}
	
	session.send_message(test_jid, 'Ini adalah reply pesan!', quoted_options) or {
		eprintln('❌ Gagal kirim reply: ${err}')
		return
	}
	
	println('   ✅ Reply pesan terkirim')
}
*/

// Demo fitur lainnya
fn demo_other_features(session whatsapp.Session) {
	println('\n🔧 Fitur Lainnya:')
	
	// Demo get messages dari chat tertentu
	chats := session.get_chats()
	if chats.len > 0 {
		// Ambil chat pertama sebagai contoh
		for jid, _ in chats {
			messages := session.get_messages(jid)
			println('   📥 Messages di ${jid}: ${messages.len} pesan')
			
			// Tampilkan 3 pesan terakhir
			if messages.len > 0 {
				start_idx := if messages.len > 3 { messages.len - 3 } else { 0 }
				for i in start_idx .. messages.len {
					msg := messages[i]
					sender := if msg.from_me { 'You' } else { 'Contact' }
					time_str := time.unix(i64(msg.timestamp)).format()
					println('      ${sender}: ${msg.text} (${time_str})')
				}
			}
			break // Hanya tampilkan dari chat pertama
		}
	}
	
	println('   ✅ Demo fitur selesai')
}

// Helper function untuk handle Ctrl+C
fn handle_interrupt() {
	println('\n🛑 Interrupt signal received')
	exit(0)
}