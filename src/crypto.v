module whatsapp

import crypto.rand
import crypto.sha256
import crypto.hmac
import crypto.aes
import encoding.base64

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