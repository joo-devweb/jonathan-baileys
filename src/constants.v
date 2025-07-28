module whatsapp

// Konstanta endpoint dan konfigurasi WhatsApp Web
pub const (
	// WebSocket endpoints WhatsApp
	ws_url = 'wss://web.whatsapp.com/ws/chat'
	web_origin = 'https://web.whatsapp.com'
	user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
	
	// Versi protokol WhatsApp Web terbaru
	wa_version = [0, 4, 3298]
	wa_version_str = '2.2412.54'
	
	// Browser info untuk autentikasi
	browser_name = 'V-WhatsApp'
	browser_version = '1.0.0'
	
	// Timeout dan limit
	default_timeout = 30000 // 30 detik
	max_message_size = 1024 * 1024 * 10 // 10MB
	max_reconnect_attempts = 5
	heartbeat_interval = 30000 // 30 detik
	
	// Binary node tags untuk parsing pesan
	list_empty = 0
	stream_8 = 2
	dictionary_0 = 236
	dictionary_1 = 237
	dictionary_2 = 238
	dictionary_3 = 239
	list_8 = 248
	list_16 = 249
	jid_pair = 250
	hex_8 = 251
	binary_8 = 252
	binary_20 = 253
	binary_32 = 254
	nibble_8 = 255
	
	// Token dictionary WhatsApp - Diperbarui sesuai versi terbaru
	wa_tokens = [
		'', '', '', '200', '400', '404', '500', '501', '502', 'action', 'add',
		'after', 'archive', 'author', 'available', 'battery', 'before', 'body',
		'broadcast', 'chat', 'clear', 'code', 'composing', 'contacts', 'count',
		'create', 'debug', 'delete', 'demote', 'duplicate', 'encoding', 'error',
		'false', 'filehash', 'from', 'g.us', 'group', 'groups_v2', 'height', 'id',
		'image', 'in', 'index', 'invis', 'item', 'jid', 'kind', 'last', 'leave',
		'live', 'log', 'media', 'message', 'mimetype', 'missing', 'modify', 'name',
		'notification', 'notify', 'out', 'owner', 'participant', 'paused',
		'picture', 'played', 'presence', 'preview', 'promote', 'query', 'raw',
		'read', 'receipt', 'received', 'recipient', 'recording', 'relay',
		'remove', 'response', 'resume', 'retry', 's.whatsapp.net', 'seconds',
		'set', 'size', 'status', 'subject', 'subscribe', 't', 'text', 'to', 'true',
		'type', 'unarchive', 'unavailable', 'url', 'user', 'value', 'web', 'width',
		'mute', 'read_only', 'admin', 'creator', 'short', 'update', 'powersave',
		'checksum', 'epoch', 'block', 'previous', '409', 'replaced', 'reason',
		'spam', 'modify_tag', 'message_info', 'delivery', 'emoji', 'title',
		'description', 'canonical-url', 'matched-text', 'star', 'unstar',
		'media_key', 'filename', 'identity', 'unread', 'page', 'page_count',
		'search', 'media_message', 'security', 'call_log', 'profile', 'ciphertext',
		'invite', 'gif', 'vcard', 'frequent', 'privacy', 'blacklist', 'whitelist',
		'verify', 'location', 'document', 'elapsed', 'revoke_invite', 'expiration',
		'unsubscribe', 'disable', 'vname', 'old_jid', 'new_jid', 'announcement',
		'locked', 'prop', 'label', 'color', 'call', 'offer', 'call-id',
		'quick_reply', 'sticker', 'pay', 'accept', 'reject', 'stanza-id',
		'replace', 'participant-hash', 'miss', 'audio', 'video', 'recent'
	]
	
	// Media types yang didukung
	supported_image_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
	supported_video_types = ['video/mp4', 'video/3gpp', 'video/quicktime', 'video/x-ms-asf']
	supported_audio_types = ['audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/amr', 'audio/ogg']
	supported_document_types = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
	
	// Encryption constants
	aes_key_size = 32
	hmac_key_size = 32
	curve25519_key_size = 32
	hkdf_salt_size = 32
	
	// Message types
	msg_text = 'conversation'
	msg_image = 'imageMessage'
	msg_video = 'videoMessage'
	msg_audio = 'audioMessage'
	msg_document = 'documentMessage'
	msg_sticker = 'stickerMessage'
	msg_location = 'locationMessage'
	msg_contact = 'contactMessage'
	msg_extended_text = 'extendedTextMessage'
	
	// Presence types
	presence_available = 'available'
	presence_unavailable = 'unavailable'
	presence_composing = 'composing'
	presence_recording = 'recording'
	presence_paused = 'paused'
	
	// Chat types
	chat_individual = 'individual'
	chat_group = 'group'
	chat_broadcast = 'broadcast'
	
	// Group participant roles
	role_admin = 'admin'
	role_member = 'member'
	role_superadmin = 'superadmin'
	
	// Receipt types
	receipt_read = 'read'
	receipt_read_self = 'read-self'
	receipt_delivered = ''
	receipt_sender = 'sender'
	receipt_inactive = 'inactive'
	receipt_played = 'played'
	
	// Connection states
	conn_close = 'close'
	conn_open = 'open'
	conn_connecting = 'connecting'
	conn_logged_out = 'logged_out'
	
	// Error codes
	err_logged_out = 401
	err_restart_required = 515
	err_connection_lost = 408
	err_bad_mac = 400
	err_stream_end = 'stream:end'
	
	// Default limits
	default_history_sync_msg_count = 100
	default_max_msg_retry_count = 5
	default_msg_retry_interval_ms = [1000, 2000, 4000, 8000, 16000]
)