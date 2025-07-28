module whatsapp

import crypto.rand
import crypto.sha256
import crypto.hmac
import crypto.aes
import crypto.md5
import encoding.base64
import encoding.hex

// Curve25519 key pair structure
pub struct KeyPair {
pub mut:
	private_key []u8
	public_key  []u8
}

// Generate new Curve25519 key pair
pub fn generate_keypair() !KeyPair {
	private_key := rand.bytes(32)!
	public_key := curve25519_public_key(private_key)!
	
	return KeyPair{
		private_key: private_key
		public_key: public_key
	}
}

// Generate Curve25519 public key from private key
fn curve25519_public_key(private_key []u8) ![]u8 {
	if private_key.len != 32 {
		return error('Private key must be 32 bytes')
	}
	
	// Curve25519 base point
	base_point := [u8(9), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	
	return curve25519_scalar_mult(private_key, base_point)
}

// Curve25519 scalar multiplication (simplified implementation)
fn curve25519_scalar_mult(scalar []u8, point []u8) ![]u8 {
	if scalar.len != 32 || point.len != 32 {
		return error('Both scalar and point must be 32 bytes')
	}
	
	// This is a simplified placeholder - in production use proper curve25519 implementation
	mut result := []u8{len: 32}
	for i in 0 .. 32 {
		result[i] = scalar[i] ^ point[i] // Placeholder operation
	}
	return result
}

// Generate shared secret using ECDH
pub fn generate_shared_secret(private_key []u8, public_key []u8) ![]u8 {
	return curve25519_scalar_mult(private_key, public_key)
}

// HKDF Extract
fn hkdf_extract(salt []u8, ikm []u8) []u8 {
	return hmac.new(sha256.sum, salt, ikm)
}

// HKDF Expand
fn hkdf_expand(prk []u8, info []u8, length int) ![]u8 {
	hash_len := 32 // SHA256 output length
	n := (length + hash_len - 1) / hash_len
	
	if n > 255 {
		return error('HKDF expand length too large')
	}
	
	mut okm := []u8{}
	mut t := []u8{}
	
	for i := 1; i <= n; i++ {
		mut input := t.clone()
		input << info
		input << u8(i)
		t = hmac.new(sha256.sum, prk, input)
		okm << t
	}
	
	return okm[..length]
}

// HKDF key derivation
pub fn hkdf_derive(secret []u8, salt []u8, info []u8, length int) ![]u8 {
	prk := hkdf_extract(salt, secret)
	return hkdf_expand(prk, info, length)
}

// AES-256-CBC encryption
pub fn aes_encrypt(key []u8, data []u8) ![]u8 {
	if key.len != 32 {
		return error('AES key must be 32 bytes for AES-256')
	}
	
	// Generate random IV
	iv := rand.bytes(16)!
	
	// Pad data to AES block size (16 bytes)
	mut padded_data := data.clone()
	padding_len := 16 - (data.len % 16)
	for _ in 0 .. padding_len {
		padded_data << u8(padding_len)
	}
	
	encrypted := aes.new_cipher(key).encrypt_cbc(padded_data, iv)!
	
	// Prepend IV to encrypted data
	mut result := iv.clone()
	result << encrypted
	return result
}

// AES-256-CBC decryption
pub fn aes_decrypt(key []u8, data []u8) ![]u8 {
	if key.len != 32 {
		return error('AES key must be 32 bytes for AES-256')
	}
	
	if data.len < 16 {
		return error('Encrypted data too short')
	}
	
	iv := data[..16]
	encrypted := data[16..]
	
	decrypted := aes.new_cipher(key).decrypt_cbc(encrypted, iv)!
	
	// Remove PKCS7 padding
	if decrypted.len == 0 {
		return error('Decrypted data is empty')
	}
	
	padding_len := int(decrypted[decrypted.len - 1])
	if padding_len > 16 || padding_len > decrypted.len {
		return error('Invalid padding')
	}
	
	return decrypted[..decrypted.len - padding_len]
}

// HMAC-SHA256
pub fn hmac_sha256(key []u8, data []u8) []u8 {
	return hmac.new(sha256.sum, key, data)
}

// Generate random client ID
pub fn generate_client_id() !string {
	random_bytes := rand.bytes(client_id_length)!
	return base64.encode(random_bytes)
}

// Validate HMAC
pub fn validate_hmac(key []u8, data []u8, expected_hmac []u8) bool {
	computed_hmac := hmac_sha256(key, data)
	if computed_hmac.len != expected_hmac.len {
		return false
	}
	
	for i in 0 .. computed_hmac.len {
		if computed_hmac[i] != expected_hmac[i] {
			return false
		}
	}
	return true
}

// Generate keypair Curve25519 baru
pub fn generate_keypair() !KeyPair {
	private_key := rand.bytes(32)!
	public_key := curve25519_public_key(private_key)!
	
	return KeyPair{
		private_key: private_key
		public_key: public_key
	}
}

// Generate public key dari private key menggunakan Curve25519
pub fn curve25519_public_key(private_key []u8) ![]u8 {
	if private_key.len != 32 {
		return error('Private key harus 32 bytes')
	}
	
	// Implementasi Curve25519 - menggunakan base point
	mut clamped_private := private_key.clone()
	clamped_private[0] &= 248
	clamped_private[31] &= 127
	clamped_private[31] |= 64
	
	// Base point untuk Curve25519
	base_point := [u8(9), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	
	return curve25519_scalar_mult(clamped_private, base_point)!
}

// Scalar multiplication untuk Curve25519
fn curve25519_scalar_mult(scalar []u8, point []u8) ![]u8 {
	if scalar.len != 32 || point.len != 32 {
		return error('Scalar dan point harus 32 bytes')
	}
	
	// Implementasi Montgomery ladder untuk Curve25519
	mut x1 := point.clone()
	mut x2 := [u8(1)].repeat(32)
	mut z2 := [u8(0)].repeat(32)
	mut x3 := point.clone()
	mut z3 := [u8(1)].repeat(32)
	
	swap := u8(0)
	
	for i := 254; i >= 0; i-- {
		bit := (scalar[i >> 3] >> (i & 7)) & 1
		swap ^= bit
		cswap(swap, mut x2, mut x3)
		cswap(swap, mut z2, mut z3)
		swap = bit
		
		// Montgomery ladder step
		mut a := fe_add(x2, z2)
		mut aa := fe_sq(a)
		mut b := fe_sub(x2, z2)
		mut bb := fe_sq(b)
		mut e := fe_sub(aa, bb)
		mut c := fe_add(x3, z3)
		mut d := fe_sub(x3, z3)
		mut da := fe_mul(d, a)
		mut cb := fe_mul(c, b)
		
		x3 = fe_sq(fe_add(da, cb))
		z3 = fe_mul(x1, fe_sq(fe_sub(da, cb)))
		x2 = fe_mul(aa, bb)
		z2 = fe_mul(e, fe_add(aa, fe_mul_121666(e)))
	}
	
	cswap(swap, mut x2, mut x3)
	cswap(swap, mut z2, mut z3)
	
	return fe_mul(x2, fe_invert(z2))
}

// Generate shared secret menggunakan ECDH
pub fn generate_shared_secret(private_key []u8, public_key []u8) ![]u8 {
	if private_key.len != 32 || public_key.len != 32 {
		return error('Keys harus 32 bytes')
	}
	
	return curve25519_scalar_mult(private_key, public_key)!
}

// HKDF (HMAC-based Key Derivation Function)
pub fn hkdf_expand(prk []u8, info []u8, length int) ![]u8 {
	if prk.len < 32 {
		return error('PRK terlalu pendek')
	}
	
	mut okm := []u8{}
	mut t := []u8{}
	counter := u8(1)
	
	for okm.len < length {
		mut input := t.clone()
		input << info
		input << counter
		
		t = hmac.new(prk, input, sha256.sum, sha256.block_size)
		okm << t
		
		if counter == 255 {
			break
		}
		counter++
	}
	
	return okm[..length]
}

// HKDF extract
pub fn hkdf_extract(salt []u8, ikm []u8) []u8 {
	mut actual_salt := salt.clone()
	if actual_salt.len == 0 {
		actual_salt = [u8(0)].repeat(32)
	}
	
	return hmac.new(actual_salt, ikm, sha256.sum, sha256.block_size)
}

// Full HKDF implementation
pub fn hkdf(ikm []u8, salt []u8, info []u8, length int) ![]u8 {
	prk := hkdf_extract(salt, ikm)
	return hkdf_expand(prk, info, length)!
}

// AES-256-CBC encryption
pub fn aes_encrypt(key []u8, iv []u8, plaintext []u8) ![]u8 {
	if key.len != 32 {
		return error('Key harus 32 bytes untuk AES-256')
	}
	if iv.len != 16 {
		return error('IV harus 16 bytes')
	}
	
	// Padding PKCS7
	mut padded_data := plaintext.clone()
	padding_length := 16 - (plaintext.len % 16)
	for _ in 0 .. padding_length {
		padded_data << u8(padding_length)
	}
	
	mut encrypted := []u8{}
	mut prev_block := iv.clone()
	
	for i := 0; i < padded_data.len; i += 16 {
		mut block := padded_data[i..i + 16].clone()
		
		// XOR dengan previous ciphertext (CBC mode)
		for j in 0 .. 16 {
			block[j] ^= prev_block[j]
		}
		
		// Encrypt block
		cipher_block := aes.new_cipher(key)!
		mut encrypted_block := [u8(0)].repeat(16)
		cipher_block.encrypt(mut encrypted_block, block)
		
		encrypted << encrypted_block
		prev_block = encrypted_block
	}
	
	return encrypted
}

// AES-256-CBC decryption
pub fn aes_decrypt(key []u8, iv []u8, ciphertext []u8) ![]u8 {
	if key.len != 32 {
		return error('Key harus 32 bytes untuk AES-256')
	}
	if iv.len != 16 {
		return error('IV harus 16 bytes')
	}
	if ciphertext.len % 16 != 0 {
		return error('Ciphertext length harus kelipatan 16')
	}
	
	mut decrypted := []u8{}
	mut prev_block := iv.clone()
	
	cipher_block := aes.new_cipher(key)!
	
	for i := 0; i < ciphertext.len; i += 16 {
		current_block := ciphertext[i..i + 16]
		mut decrypted_block := [u8(0)].repeat(16)
		
		// Decrypt block
		cipher_block.decrypt(mut decrypted_block, current_block)
		
		// XOR dengan previous ciphertext (CBC mode)
		for j in 0 .. 16 {
			decrypted_block[j] ^= prev_block[j]
		}
		
		decrypted << decrypted_block
		prev_block = current_block.clone()
	}
	
	// Remove PKCS7 padding
	if decrypted.len > 0 {
		padding_length := int(decrypted[decrypted.len - 1])
		if padding_length > 0 && padding_length <= 16 {
			return decrypted[..decrypted.len - padding_length]
		}
	}
	
	return decrypted
}

// HMAC-SHA256
pub fn hmac_sha256(key []u8, message []u8) []u8 {
	return hmac.new(key, message, sha256.sum, sha256.block_size)
}

// Generate random bytes
pub fn random_bytes(length int) ![]u8 {
	return rand.bytes(length)!
}

// Generate client ID (16 bytes base64)
pub fn generate_client_id() !string {
	bytes := rand.bytes(16)!
	return base64.encode(bytes)
}

// MD5 hash
pub fn md5_hash(data []u8) []u8 {
	return md5.sum(data)
}

// SHA256 hash
pub fn sha256_hash(data []u8) []u8 {
	return sha256.sum(data)
}

// Validate MAC
pub fn validate_mac(mac_key []u8, message []u8, expected_mac []u8) bool {
	computed_mac := hmac_sha256(mac_key, message)
	if computed_mac.len != expected_mac.len {
		return false
	}
	
	mut result := u8(0)
	for i in 0 .. computed_mac.len {
		result |= computed_mac[i] ^ expected_mac[i]
	}
	
	return result == 0
}

// Encrypt media (untuk gambar, video, dll)
pub fn encrypt_media(media_key []u8, data []u8) !MediaEncryptionResult {
	if media_key.len != 32 {
		return error('Media key harus 32 bytes')
	}
	
	// Expand media key menggunakan HKDF
	expanded_key := hkdf(media_key, []u8{}, 'WhatsApp Media Keys'.bytes(), 112)!
	
	iv := expanded_key[0..16]
	cipher_key := expanded_key[16..48]
	mac_key := expanded_key[48..80]
	
	// Encrypt data
	encrypted_data := aes_encrypt(cipher_key, iv, data)!
	
	// Calculate MAC
	mac_input := iv.clone()
	mac_input << encrypted_data
	mac := hmac_sha256(mac_key, mac_input)
	
	return MediaEncryptionResult{
		encrypted_data: encrypted_data
		mac: mac[0..10] // Truncated to 10 bytes
		iv: iv
	}
}

// Decrypt media
pub fn decrypt_media(media_key []u8, encrypted_data []u8, mac []u8, iv []u8) ![]u8 {
	if media_key.len != 32 {
		return error('Media key harus 32 bytes')
	}
	
	// Expand media key
	expanded_key := hkdf(media_key, []u8{}, 'WhatsApp Media Keys'.bytes(), 112)!
	
	cipher_key := expanded_key[16..48]
	mac_key := expanded_key[48..80]
	
	// Validate MAC
	mac_input := iv.clone()
	mac_input << encrypted_data
	computed_mac := hmac_sha256(mac_key, mac_input)
	
	if !validate_mac(mac_key, mac_input, mac) {
		return error('MAC validation failed')
	}
	
	// Decrypt data
	return aes_decrypt(cipher_key, iv, encrypted_data)!
}

// Helper structures
pub struct MediaEncryptionResult {
pub:
	encrypted_data []u8
	mac           []u8
	iv            []u8
}

// Helper functions untuk field arithmetic (Curve25519)
fn fe_add(a []u8, b []u8) []u8 {
	mut result := [u8(0)].repeat(32)
	mut carry := u32(0)
	
	for i in 0 .. 32 {
		sum := u32(a[i]) + u32(b[i]) + carry
		result[i] = u8(sum & 0xFF)
		carry = sum >> 8
	}
	
	return result
}

fn fe_sub(a []u8, b []u8) []u8 {
	mut result := [u8(0)].repeat(32)
	mut borrow := u32(0)
	
	for i in 0 .. 32 {
		diff := u32(a[i]) - u32(b[i]) - borrow
		result[i] = u8(diff & 0xFF)
		borrow = (diff >> 31) & 1
	}
	
	return result
}

fn fe_mul(a []u8, b []u8) []u8 {
	// Simplified multiplication - dalam implementasi nyata butuh optimasi
	mut result := [u8(0)].repeat(32)
	// Implementation would be complex, simplified for demo
	return result
}

fn fe_sq(a []u8) []u8 {
	return fe_mul(a, a)
}

fn fe_mul_121666(a []u8) []u8 {
	// Multiply by 121666 (constant for Curve25519)
	mut result := [u8(0)].repeat(32)
	// Simplified implementation
	return result
}

fn fe_invert(a []u8) []u8 {
	// Field inversion using Fermat's little theorem
	mut result := [u8(0)].repeat(32)
	// Complex implementation, simplified for demo
	result[0] = 1
	return result
}

fn cswap(swap u8, mut a []u8, mut b []u8) {
	if swap != 0 {
		for i in 0 .. a.len {
			temp := a[i]
			a[i] = b[i]
			b[i] = temp
		}
	}
}

// Utility functions
pub fn bytes_to_hex(data []u8) string {
	return hex.encode(data)
}

pub fn hex_to_bytes(hex_str string) ![]u8 {
	return hex.decode(hex_str)!
}

pub fn bytes_to_base64(data []u8) string {
	return base64.encode(data)
}

pub fn base64_to_bytes(b64_str string) ![]u8 {
	return base64.decode(b64_str)!
}

// Key derivation untuk WhatsApp
pub fn derive_wa_keys(shared_secret []u8, salt []u8) !EncryptionKeys {
	// Expand shared secret menjadi 80 bytes
	expanded := hkdf(shared_secret, salt, []u8{}, 80)!
	
	return EncryptionKeys{
		enc_key: expanded[0..32]
		mac_key: expanded[32..64]
	}
}

// Generate noise keypair untuk handshake
pub fn generate_noise_keypair() !KeyPair {
	return generate_keypair()!
}

// Noise protocol handshake (simplified)
pub fn noise_handshake(local_private []u8, remote_public []u8, payload []u8) ![]u8 {
	shared_secret := generate_shared_secret(local_private, remote_public)!
	
	// Derive keys untuk handshake
	keys := derive_wa_keys(shared_secret, []u8{})!
	
	// Encrypt payload
	iv := random_bytes(16)!
	encrypted := aes_encrypt(keys.enc_key, iv, payload)!
	
	// Calculate MAC
	mac := hmac_sha256(keys.mac_key, encrypted)
	
	mut result := iv.clone()
	result << encrypted
	result << mac
	
	return result
}

// Decrypt noise handshake response
pub fn decrypt_noise_response(shared_secret []u8, response []u8) ![]u8 {
	if response.len < 48 { // 16 (IV) + 32 (MAC) minimum
		return error('Response terlalu pendek')
	}
	
	iv := response[0..16]
	encrypted_data := response[16..response.len - 32]
	mac := response[response.len - 32..]
	
	// Derive keys
	keys := derive_wa_keys(shared_secret, []u8{})!
	
	// Validate MAC
	if !validate_mac(keys.mac_key, encrypted_data, mac) {
		return error('MAC validation failed')
	}
	
	// Decrypt
	return aes_decrypt(keys.enc_key, iv, encrypted_data)!
}