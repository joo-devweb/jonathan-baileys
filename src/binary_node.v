module whatsapp

import encoding.binary

// Binary node structure
pub struct BinaryNode {
pub mut:
	tag        string
	attributes map[string]string
	content    ?NodeContent
}

// Node content can be string, bytes, or list of nodes
pub type NodeContent = string | []u8 | []BinaryNode

// Binary reader for parsing WhatsApp binary messages
struct BinaryReader {
mut:
	data []u8
	pos  int
}

// Create new binary reader
fn new_binary_reader(data []u8) BinaryReader {
	return BinaryReader{
		data: data
		pos: 0
	}
}

// Read single byte
fn (mut r BinaryReader) read_byte() !u8 {
	if r.pos >= r.data.len {
		return error('End of data reached')
	}
	byte_val := r.data[r.pos]
	r.pos++
	return byte_val
}

// Read multiple bytes
fn (mut r BinaryReader) read_bytes(count int) ![]u8 {
	if r.pos + count > r.data.len {
		return error('Not enough data to read ${count} bytes')
	}
	result := r.data[r.pos..r.pos + count]
	r.pos += count
	return result
}

// Read int16 (big endian)
fn (mut r BinaryReader) read_int16() !u16 {
	bytes := r.read_bytes(2)!
	return binary.big_endian_u16(bytes)
}

// Read int20 (3 bytes, big endian)
fn (mut r BinaryReader) read_int20() !u32 {
	bytes := r.read_bytes(3)!
	return (u32(bytes[0] & 0x0F) << 16) | (u32(bytes[1]) << 8) | u32(bytes[2])
}

// Read int32 (big endian)
fn (mut r BinaryReader) read_int32() !u32 {
	bytes := r.read_bytes(4)!
	return binary.big_endian_u32(bytes)
}

// Unpack nibble to character
fn unpack_nibble(nibble u8) string {
	match nibble {
		0...9 { return (nibble + 48).ascii_str() } // '0'-'9'
		10 { return '-' }
		11 { return '.' }
		15 { return '\0' }
		else { return '' }
	}
}

// Unpack hex to character
fn unpack_hex(hex u8) string {
	match hex {
		0...9 { return (hex + 48).ascii_str() } // '0'-'9'
		10...15 { return (hex - 10 + 65).ascii_str() } // 'A'-'F'
		else { return '' }
	}
}

// Read packed string (nibble or hex)
fn (mut r BinaryReader) read_packed(tag u8) !string {
	n := r.read_byte()!
	count := int(n & 0x7F)
	
	mut result := ''
	for i in 0 .. count {
		byte_val := r.read_byte()!
		if tag == nibble_8 {
			result += unpack_nibble((byte_val >> 4) & 0x0F)
			result += unpack_nibble(byte_val & 0x0F)
		} else if tag == hex_8 {
			result += unpack_hex((byte_val >> 4) & 0x0F)
			result += unpack_hex(byte_val & 0x0F)
		}
	}
	
	if (n & 0x80) != 0 && result.len > 0 {
		result = result[..result.len - 1]
	}
	
	return result
}

// Read string based on tag
fn (mut r BinaryReader) read_string(tag u8) !string {
	match tag {
		list_empty { return '' }
		3...235 {
			token := wa_tokens[tag] or { return error('Invalid token index: ${tag}') }
			return if token == 's.whatsapp.net' { 'c.us' } else { token }
		}
		dictionary_0...dictionary_3 {
			index := tag - dictionary_0
			second_byte := r.read_byte()!
			token_index := int(index) * 256 + int(second_byte)
			if token_index >= wa_tokens.len {
				return error('Token index out of range: ${token_index}')
			}
			return wa_tokens[token_index]
		}
		binary_8 {
			length := r.read_byte()!
			return r.read_bytes(int(length))!.bytestr()
		}
		binary_20 {
			length := r.read_int20()!
			return r.read_bytes(int(length))!.bytestr()
		}
		binary_32 {
			length := r.read_int32()!
			return r.read_bytes(int(length))!.bytestr()
		}
		jid_pair {
			first_tag := r.read_byte()!
			first_part := r.read_string(first_tag)!
			second_tag := r.read_byte()!
			second_part := r.read_string(second_tag)!
			return '${first_part}@${second_part}'
		}
		nibble_8, hex_8 {
			return r.read_packed(tag)
		}
		else {
			return error('Unknown string tag: ${tag}')
		}
	}
}

// Check if tag is a list tag
fn is_list_tag(tag u8) bool {
	return tag == list_empty || tag == list_8 || tag == list_16
}

// Read list size based on tag
fn (mut r BinaryReader) read_list_size(tag u8) !int {
	match tag {
		list_empty { return 0 }
		list_8 { return int(r.read_byte()!) }
		list_16 { return int(r.read_int16()!) }
		else { return error('Invalid list tag: ${tag}') }
	}
}

// Read attributes
fn (mut r BinaryReader) read_attributes(count int) !map[string]string {
	mut attributes := map[string]string{}
	
	for _ in 0 .. count {
		key_tag := r.read_byte()!
		key := r.read_string(key_tag)!
		
		value_tag := r.read_byte()!
		value := r.read_string(value_tag)!
		
		attributes[key] = value
	}
	
	return attributes
}

// Read binary node
fn (mut r BinaryReader) read_node() !BinaryNode {
	list_tag := r.read_byte()!
	list_size := r.read_list_size(list_tag)!
	
	if list_size == 0 {
		return error('Invalid list size: 0')
	}
	
	// Read tag
	tag_byte := r.read_byte()!
	if tag_byte == stream_8 {
		return error('Invalid tag: STREAM_8')
	}
	tag := r.read_string(tag_byte)!
	
	// Read attributes
	attr_count := (list_size - 2 + list_size % 2) >> 1
	attributes := r.read_attributes(attr_count)!
	
	// Read content if present
	mut content := ?NodeContent(none)
	if list_size % 2 == 0 {
		content_tag := r.read_byte()!
		
		if is_list_tag(content_tag) {
			// Content is a list of nodes
			child_count := r.read_list_size(content_tag)!
			mut children := []BinaryNode{}
			for _ in 0 .. child_count {
				children << r.read_node()!
			}
			content = children
		} else if content_tag == binary_8 {
			length := r.read_byte()!
			content = r.read_bytes(int(length))!
		} else if content_tag == binary_20 {
			length := r.read_int20()!
			content = r.read_bytes(int(length))!
		} else if content_tag == binary_32 {
			length := r.read_int32()!
			content = r.read_bytes(int(length))!
		} else {
			content = r.read_string(content_tag)!
		}
	}
	
	return BinaryNode{
		tag: tag
		attributes: attributes
		content: content
	}
}

// Parse binary message to node
pub fn parse_binary_node(data []u8) !BinaryNode {
	mut reader := new_binary_reader(data)
	return reader.read_node()
}

// Binary writer for encoding nodes
struct BinaryWriter {
mut:
	data []u8
}

// Create new binary writer
fn new_binary_writer() BinaryWriter {
	return BinaryWriter{
		data: []u8{}
	}
}

// Write byte
fn (mut w BinaryWriter) write_byte(b u8) {
	w.data << b
}

// Write bytes
fn (mut w BinaryWriter) write_bytes(bytes []u8) {
	w.data << bytes
}

// Write int16 (big endian)
fn (mut w BinaryWriter) write_int16(val u16) {
	w.data << u8(val >> 8)
	w.data << u8(val & 0xFF)
}

// Write int20 (3 bytes, big endian)
fn (mut w BinaryWriter) write_int20(val u32) {
	w.data << u8((val >> 16) & 0x0F)
	w.data << u8((val >> 8) & 0xFF)
	w.data << u8(val & 0xFF)
}

// Write int32 (big endian)
fn (mut w BinaryWriter) write_int32(val u32) {
	w.data << u8(val >> 24)
	w.data << u8((val >> 16) & 0xFF)
	w.data << u8((val >> 8) & 0xFF)
	w.data << u8(val & 0xFF)
}

// Find token index
fn find_token_index(token string) ?int {
	for i, t in wa_tokens {
		if t == token {
			return i
		}
	}
	return none
}

// Write string with appropriate tag
fn (mut w BinaryWriter) write_string(s string) {
	if s.len == 0 {
		w.write_byte(list_empty)
		return
	}
	
	// Try to find in tokens
	if token_index := find_token_index(s) {
		if token_index <= 235 {
			w.write_byte(u8(token_index))
			return
		}
	}
	
	// Write as binary
	if s.len <= 255 {
		w.write_byte(binary_8)
		w.write_byte(u8(s.len))
		w.write_bytes(s.bytes())
	} else if s.len <= 1048575 { // 2^20 - 1
		w.write_byte(binary_20)
		w.write_int20(u32(s.len))
		w.write_bytes(s.bytes())
	} else {
		w.write_byte(binary_32)
		w.write_int32(u32(s.len))
		w.write_bytes(s.bytes())
	}
}

// Write attributes
fn (mut w BinaryWriter) write_attributes(attributes map[string]string) {
	for key, value in attributes {
		w.write_string(key)
		w.write_string(value)
	}
}

// Write node content
fn (mut w BinaryWriter) write_content(content NodeContent) {
	match content {
		string {
			w.write_string(content)
		}
		[]u8 {
			if content.len <= 255 {
				w.write_byte(binary_8)
				w.write_byte(u8(content.len))
				w.write_bytes(content)
			} else if content.len <= 1048575 {
				w.write_byte(binary_20)
				w.write_int20(u32(content.len))
				w.write_bytes(content)
			} else {
				w.write_byte(binary_32)
				w.write_int32(u32(content.len))
				w.write_bytes(content)
			}
		}
		[]BinaryNode {
			if content.len <= 255 {
				w.write_byte(list_8)
				w.write_byte(u8(content.len))
			} else {
				w.write_byte(list_16)
				w.write_int16(u16(content.len))
			}
			for node in content {
				w.write_node(node)
			}
		}
	}
}

// Write binary node
fn (mut w BinaryWriter) write_node(node BinaryNode) {
	attr_count := node.attributes.len
	list_size := 2 + attr_count * 2
	has_content := node.content != none
	
	if has_content {
		list_size++
	}
	
	// Write list size
	if list_size <= 255 {
		w.write_byte(list_8)
		w.write_byte(u8(list_size))
	} else {
		w.write_byte(list_16)
		w.write_int16(u16(list_size))
	}
	
	// Write tag
	w.write_string(node.tag)
	
	// Write attributes
	w.write_attributes(node.attributes)
	
	// Write content
	if has_content {
		if content := node.content {
			w.write_content(content)
		}
	}
}

// Encode binary node to bytes
pub fn encode_binary_node(node BinaryNode) []u8 {
	mut writer := new_binary_writer()
	writer.write_node(node)
	return writer.data
}