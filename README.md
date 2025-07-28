# WhatsApp V-Lang Library 📱

A comprehensive WhatsApp Web API library for the V programming language, supporting both QR Code and Pairing Code authentication methods.

## 🚀 Features

- **Full WhatsApp Web Protocol Implementation**
  - WebSocket connection with proper headers
  - Binary node parsing and encoding
  - AES-256-CBC encryption/decryption
  - HMAC-SHA256 message authentication
  - Curve25519 key exchange (ECDH)
  - HKDF key derivation

- **Authentication Methods**
  - ✅ QR Code authentication (scan with mobile app)
  - ✅ Pairing Code authentication (enter code in mobile app)
  - Session restoration (planned)

- **Message Handling**
  - Send/receive text messages
  - Binary message parsing
  - Message encryption/decryption
  - Real-time message events

- **Utilities**
  - Built-in QR code generator
  - ASCII QR code display
  - Online QR code URL generation
  - Comprehensive error handling

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/whatsapp-v-lib.git
cd whatsapp-v-lib

# Or install as a V module
v install https://github.com/yourusername/whatsapp-v-lib
```

## 🔧 Dependencies

This library uses V's built-in modules:
- `net.websocket` - WebSocket client
- `crypto.*` - Cryptographic functions
- `encoding.base64` - Base64 encoding/decoding
- `json` - JSON parsing
- `time` - Time utilities

## 📖 Quick Start

### Basic QR Code Authentication

```v
import whatsapp

fn main() {
    // Create a new WhatsApp session
    mut session := whatsapp.new_session()!
    
    // Set up QR code handler
    session.on_qr_code = fn (qr_data string) {
        println('Scan this QR code with WhatsApp:')
        qr := whatsapp.generate_qr_code(qr_data)
        println(qr.to_ascii())
    }
    
    // Set up connection handler
    session.on_connected = fn () {
        println('Connected to WhatsApp!')
    }
    
    // Set up message handler
    session.on_message = fn (node whatsapp.BinaryNode) {
        if node.tag == 'message' {
            println('Received message: ${node}')
        }
    }
    
    // Connect to WhatsApp
    session.connect()!
    
    // Wait for ready state
    for !session.is_ready() {
        // Keep running
    }
    
    // Send a message
    session.send_text_message('1234567890@c.us', 'Hello from V!')!
}
```

### Pairing Code Authentication

```v
import whatsapp

fn main() {
    mut session := whatsapp.new_session()!
    
    // Set up pairing code handler
    session.on_pairing = fn (code string) {
        println('Enter this code in WhatsApp: ${code}')
    }
    
    session.connect()!
    
    // Request pairing code for your phone number
    session.request_pairing_code('+1234567890')!
    
    // Wait for authentication...
}
```

## 📚 API Reference

### Session Management

#### `new_session() !&Session`
Creates a new WhatsApp session with default configuration.

#### `Session.connect() !`
Connects to WhatsApp Web servers and initiates the authentication process.

#### `Session.disconnect() !`
Closes the WebSocket connection and cleans up resources.

#### `Session.is_ready() bool`
Returns `true` if the session is authenticated and ready to send/receive messages.

### Authentication

#### `Session.request_pairing_code(phone_number string) !`
Requests a pairing code for the specified phone number.

### Messaging

#### `Session.send_text_message(jid string, text string) !`
Sends a text message to the specified JID (WhatsApp ID).

#### `Session.send_binary_node(node BinaryNode) !`
Sends a binary node message (for advanced use cases).

### Event Handlers

Set these function properties on your session to handle events:

```v
session.on_qr_code = fn (qr_data string) { /* Handle QR code */ }
session.on_pairing = fn (code string) { /* Handle pairing code */ }
session.on_connected = fn () { /* Handle successful connection */ }
session.on_message = fn (node BinaryNode) { /* Handle incoming messages */ }
session.on_error = fn (err string) { /* Handle errors */ }
```

### QR Code Utilities

#### `generate_qr_code(data string) QRCode`
Generates a QR code from the given data.

#### `QRCode.to_ascii() string`
Converts the QR code to ASCII art for terminal display.

#### `QRCode.save_to_file(filename string) !`
Saves the QR code as a text file.

#### `create_qr_url(data string, size int) string`
Creates a URL for online QR code generation.

## 🔒 Security Features

- **End-to-End Encryption**: All messages are encrypted using AES-256-CBC
- **Message Authentication**: HMAC-SHA256 ensures message integrity
- **Key Exchange**: Curve25519 ECDH for secure key agreement
- **Key Derivation**: HKDF for proper key expansion
- **Session Security**: Secure WebSocket connection with proper headers

## 📱 WhatsApp JID Format

WhatsApp uses JIDs (Jabber IDs) to identify users and groups:

- **Individual chats**: `[country_code][phone_number]@c.us`
  - Example: `1234567890@c.us`
- **Group chats**: `[creator_phone]-[timestamp]@g.us`
  - Example: `1234567890-1609459200@g.us`
- **Broadcast lists**: `[timestamp]@broadcast`
  - Example: `1609459200@broadcast`

## 🎯 Examples

Check out the `examples/` directory for complete working examples:

- `basic_example.v` - Basic QR code authentication and messaging
- `pairing_code_example.v` - Pairing code authentication with interactive chat

## 🛠️ Development

### Building the Library

```bash
# Compile the library
v -shared src/

# Run tests
v test src/

# Run examples
v run examples/basic_example.v
v run examples/pairing_code_example.v
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## ⚠️ Important Notes

- This library is for educational and research purposes
- Respect WhatsApp's Terms of Service
- Use responsibly and don't spam users
- The library implements the WhatsApp Web protocol, not the mobile API
- Some features may break if WhatsApp updates their protocol

## 🐛 Known Limitations

- Media messages (images, videos, documents) are not yet implemented
- Group management features are limited
- Voice messages are not supported
- Status updates are not implemented
- The Curve25519 implementation is simplified (use a proper crypto library in production)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- WhatsApp Web reverse engineering community
- [Baileys](https://github.com/WhiskeySockets/Baileys) - JavaScript WhatsApp library
- [whatsapp-web-reveng](https://github.com/sigalor/whatsapp-web-reveng) - Protocol documentation
- V language community

## ⚡ Performance

The library is designed to be lightweight and efficient:
- Minimal memory footprint
- Fast binary message parsing
- Efficient WebSocket handling
- Concurrent message processing

## 🔮 Roadmap

- [ ] Media message support (images, videos, documents)
- [ ] Voice message support
- [ ] Group management (create, join, leave, admin actions)
- [ ] Status updates
- [ ] Contact management
- [ ] Session persistence
- [ ] Multi-device support
- [ ] Better error handling and recovery
- [ ] Performance optimizations
- [ ] Comprehensive test suite

---

**Disclaimer**: This library is not affiliated with WhatsApp Inc. Use at your own risk and ensure compliance with WhatsApp's Terms of Service.
