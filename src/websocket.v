module whatsapp

import net.websocket
import net.http
import time
import json
import sync

// WebSocket message types
pub enum MessageType {
	text
	binary
}

// WebSocket message
pub struct WSMessage {
pub:
	typ     MessageType
	payload []u8
}

// WebSocket client for WhatsApp
pub struct WSClient {
mut:
	ws           &websocket.Client
	connected    bool
	message_chan chan WSMessage
	error_chan   chan string
	close_chan   chan bool
}

// Create new WebSocket client
pub fn new_ws_client() !&WSClient {
	mut client := &WSClient{
		ws: unsafe { nil }
		connected: false
		message_chan: chan WSMessage{cap: 100}
		error_chan: chan string{cap: 10}
		close_chan: chan bool{cap: 1}
	}
	
	return client
}

// Connect to WhatsApp Web WebSocket
pub fn (mut client WSClient) connect() ! {
	mut ws := websocket.new_client(ws_url)!
	
	// Set headers
	ws.header.add_custom('Origin', web_origin)!
	ws.header.add_custom('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')!
	
	// Set event handlers
	ws.on_open(fn [mut client] (mut ws websocket.Client) ! {
		client.connected = true
		println('WebSocket connected')
	})
	
	ws.on_message(fn [mut client] (mut ws websocket.Client, msg &websocket.Message) ! {
		match msg.opcode {
			.text_frame {
				client.message_chan <- WSMessage{
					typ: .text
					payload: msg.payload
				}
			}
			.binary_frame {
				client.message_chan <- WSMessage{
					typ: .binary
					payload: msg.payload
				}
			}
			else {}
		}
	})
	
	ws.on_error(fn [mut client] (mut ws websocket.Client, err string) ! {
		client.error_chan <- err
	})
	
	ws.on_close(fn [mut client] (mut ws websocket.Client, code int, reason string) ! {
		client.connected = false
		client.close_chan <- true
		println('WebSocket closed: ${code} - ${reason}')
	})
	
	client.ws = ws
	
	// Connect
	client.ws.connect()!
	
	// Wait for connection
	for !client.connected {
		time.sleep(10 * time.millisecond)
	}
}

// Send text message
pub fn (mut client WSClient) send_text(message string) ! {
	if !client.connected {
		return error('WebSocket not connected')
	}
	client.ws.write_string(message)!
}

// Send binary message
pub fn (mut client WSClient) send_binary(data []u8) ! {
	if !client.connected {
		return error('WebSocket not connected')
	}
	client.ws.write(data, .binary_frame)!
}

// Send JSON message with tag
pub fn (mut client WSClient) send_json_with_tag(tag string, data []json.Any) ! {
	json_str := json.encode(data)
	message := '${tag},${json_str}'
	client.send_text(message)!
}

// Receive message (blocking)
pub fn (mut client WSClient) receive() !WSMessage {
	select {
		msg := <-client.message_chan {
			return msg
		}
		err := <-client.error_chan {
			return error(err)
		}
		_ := <-client.close_chan {
			return error('WebSocket closed')
		}
	}
}

// Receive message with timeout
pub fn (mut client WSClient) receive_timeout(timeout time.Duration) !WSMessage {
	select {
		msg := <-client.message_chan {
			return msg
		}
		err := <-client.error_chan {
			return error(err)
		}
		_ := <-client.close_chan {
			return error('WebSocket closed')
		}
		timeout {
			return error('Timeout waiting for message')
		}
	}
}

// Check if connected
pub fn (client &WSClient) is_connected() bool {
	return client.connected
}

// Close connection
pub fn (mut client WSClient) close() ! {
	if client.connected {
		client.ws.close(1000, 'Normal closure')!
		client.connected = false
	}
}

// Parse tagged message (format: "tag,json_data")
pub fn parse_tagged_message(message string) !(string, json.Any) {
	comma_index := message.index(',') or {
		return error('Invalid message format: no comma found')
	}
	
	tag := message[..comma_index]
	json_part := message[comma_index + 1..]
	
	data := json.decode(json_part)!
	return tag, data
}

// Format tagged message
pub fn format_tagged_message(tag string, data json.Any) string {
	json_str := json.encode(data)
	return '${tag},${json_str}'
}