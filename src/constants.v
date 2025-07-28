module whatsapp

// WhatsApp Web protocol constants
pub const (
	// WebSocket endpoints
	ws_url = 'wss://web.whatsapp.com/ws'
	web_origin = 'https://web.whatsapp.com'
	
	// Protocol version
	wa_version = [0, 4, 3298]
	
	// Binary node tags
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
	
	// WhatsApp tokens dictionary
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
		'unsubscribe', 'disable'
	]
	
	// Crypto constants
	client_id_length = 16
	secret_length = 144
	shared_secret_expanded_length = 80
	enc_key_length = 32
	mac_key_length = 32
	hmac_length = 32
	
	// Media constants
	media_key_length = 32
	media_key_expanded_length = 112
	media_mac_length = 10
)