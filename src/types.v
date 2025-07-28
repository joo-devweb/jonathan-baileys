module whatsapp

import time
import net.websocket

// Enum untuk status koneksi
pub enum ConnectionState {
	disconnected
	connecting
	connected
	authenticating
	authenticated
	ready
	logged_out
	closed
}

// Enum untuk metode autentikasi
pub enum AuthMethod {
	qr_code
	pairing_code
	existing_session
}

// Enum untuk tipe pesan
pub enum MessageType {
	text
	image
	video
	audio
	document
	sticker
	location
	contact
	extended_text
	template
	interactive
	button_reply
	list_reply
	product
	order
	payment
	poll
	reaction
	edit
	revoke
}

// Enum untuk tipe chat
pub enum ChatType {
	individual
	group
	broadcast
	newsletter
}

// Enum untuk role participant grup
pub enum ParticipantRole {
	member
	admin
	superadmin
}

// Enum untuk status pesan
pub enum MessageStatus {
	pending
	sent
	delivered
	read
	played
	failed
}

// Enum untuk tipe presence
pub enum PresenceType {
	unavailable
	available
	composing
	recording
	paused
}

// Struktur untuk JID (Jabber ID)
pub struct JID {
pub mut:
	user   string
	server string
	device int
	agent  int
}

// Struktur untuk keypair Curve25519
pub struct KeyPair {
pub mut:
	private_key []u8
	public_key  []u8
}

// Struktur untuk kunci enkripsi
pub struct EncryptionKeys {
pub mut:
	enc_key []u8
	mac_key []u8
}

// Struktur untuk informasi koneksi
pub struct ConnectionInfo {
pub mut:
	battery       int
	platform      string
	pushname      string
	secret        string
	server_token  string
	client_token  string
	browser_token string
	wid           string
	phone         map[string]string
	ref           string
	ttl           int
	is_new        bool
}

// Struktur untuk konfigurasi sesi
pub struct SessionConfig {
pub mut:
	auth_method     AuthMethod = .qr_code
	browser_name    string = whatsapp.browser_name
	browser_version string = whatsapp.browser_version
	phone_number    string
	print_qr        bool = true
	session_path    string = './session'
	log_level       string = 'info'
}

// Struktur untuk media info
pub struct MediaInfo {
pub mut:
	mimetype      string
	file_sha256   []u8
	file_length   u64
	media_key     []u8
	media_key_timestamp u64
	direct_path   string
	url           string
	width         int
	height        int
	duration      int
	page_count    int
	file_name     string
	caption       string
	thumbnail     []u8
	gif_playback  bool
}

// Struktur untuk lokasi
pub struct LocationInfo {
pub mut:
	degrees_latitude  f64
	degrees_longitude f64
	name              string
	address           string
	url               string
	live_period_secs  int
	accuracy_in_meters int
}

// Struktur untuk kontak
pub struct ContactInfo {
pub mut:
	display_name string
	given_name   string
	middle_name  string
	family_name  string
	prefix       string
	suffix       string
	formatted_name string
	organization string
	birthday     string
	urls         []ContactUrl
	emails       []ContactEmail
	phones       []ContactPhone
	addresses    []ContactAddress
}

pub struct ContactUrl {
pub mut:
	url  string
	type string
}

pub struct ContactEmail {
pub mut:
	email string
	type  string
}

pub struct ContactPhone {
pub mut:
	phone string
	type  string
}

pub struct ContactAddress {
pub mut:
	street      string
	city        string
	state       string
	zip         string
	country     string
	country_code string
	type        string
}

// Struktur untuk pesan
pub struct Message {
pub mut:
	id                string
	remote_jid        string
	from_me           bool
	participant       string
	timestamp         u64
	status            MessageStatus
	message_type      MessageType
	text              string
	quoted_message    ?&Message
	context_info      ?ContextInfo
	media_info        ?MediaInfo
	location_info     ?LocationInfo
	contact_info      ?ContactInfo
	reaction          ?ReactionInfo
	edit_info         ?EditInfo
	revoke_info       ?RevokeInfo
	ephemeral_duration int
	view_once         bool
	forward_score     int
	is_forwarded      bool
	broadcast_list_info ?BroadcastListInfo
}

// Struktur untuk context info
pub struct ContextInfo {
pub mut:
	stanza_id           string
	participant         string
	quoted_message      ?&Message
	mentioned_jid       []string
	group_mentions      []GroupMention
	forwarded           bool
	frequently_forwarded bool
	ephemeral_setting_timestamp u64
	disappearing_mode   ?DisappearingMode
	external_ad_reply   ?ExternalAdReply
}

pub struct GroupMention {
pub mut:
	group_jid      string
	group_subject  string
}

pub struct DisappearingMode {
pub mut:
	initiator string
	trigger   string
}

pub struct ExternalAdReply {
pub mut:
	title         string
	body          string
	media_type    string
	thumbnail     []u8
	media_url     string
	source_url    string
	source_type   string
	source_id     string
}

// Struktur untuk reaksi
pub struct ReactionInfo {
pub mut:
	text      string
	key       MessageKey
	sender_timestamp u64
}

pub struct MessageKey {
pub mut:
	remote_jid  string
	from_me     bool
	id          string
	participant string
}

// Struktur untuk edit pesan
pub struct EditInfo {
pub mut:
	message           Message
	timestamp_ms      u64
	edit_count        int
}

// Struktur untuk revoke pesan
pub struct RevokeInfo {
pub mut:
	timestamp_ms u64
	revoke_type  string
}

// Struktur untuk broadcast list
pub struct BroadcastListInfo {
pub mut:
	name         string
	recipients   []string
}

// Struktur untuk chat
pub struct Chat {
pub mut:
	jid                 string
	name                string
	chat_type           ChatType
	timestamp           u64
	unread_count        int
	last_message        ?Message
	pinned              bool
	archived            bool
	muted_until         u64
	ephemeral_duration  int
	description         string
	group_metadata      ?GroupMetadata
	contact_info        ?ContactInfo
	presence            ?PresenceInfo
}

// Struktur untuk metadata grup
pub struct GroupMetadata {
pub mut:
	id            string
	subject       string
	subject_owner string
	subject_time  u64
	creation_time u64
	owner         string
	description   string
	desc_owner    string
	desc_id       string
	desc_time     u64
	restrict      bool
	announce      bool
	ephemeral_duration int
	invite_code   string
	participants  []GroupParticipant
	past_participants []PastParticipant
	pending_participants []PendingParticipant
	membership_approval_mode string
	parent_group  string
	default_sub_group bool
	display_name  string
	pn_jid        string
	share_own_pn  bool
	pn_enabled    bool
	incognito     bool
	linked_parent string
	is_parent     bool
}

pub struct GroupParticipant {
pub mut:
	jid   string
	role  ParticipantRole
	rank  string
}

pub struct PastParticipant {
pub mut:
	jid         string
	leave_ts    u64
	leave_reason string
}

pub struct PendingParticipant {
pub mut:
	jid     string
	add_ts  u64
}

// Struktur untuk presence info
pub struct PresenceInfo {
pub mut:
	jid           string
	presence_type PresenceType
	last_seen     u64
	last_known_presence PresenceType
}

// Struktur untuk receipt info
pub struct ReceiptInfo {
pub mut:
	message_id   string
	receipt_type string
	timestamp    u64
	participant  string
}

// Struktur untuk notifikasi
pub struct Notification {
pub mut:
	id        string
	type      string
	timestamp u64
	from      string
	to        string
	participant string
	data      map[string]string
}

// Struktur untuk callback events
pub struct EventCallbacks {
pub mut:
	on_qr_code           ?fn (string)
	on_pairing_code      ?fn (string)
	on_connection_update ?fn (ConnectionState, map[string]string)
	on_auth_state_change ?fn (map[string]string)
	on_message           ?fn (Message)
	on_message_update    ?fn (Message, map[string]string)
	on_message_receipt   ?fn (ReceiptInfo)
	on_presence_update   ?fn (PresenceInfo)
	on_chat_update       ?fn (Chat, map[string]string)
	on_group_update      ?fn (GroupMetadata, map[string]string)
	on_group_participants_update ?fn (string, []GroupParticipant, string)
	on_notification      ?fn (Notification)
	on_call              ?fn (map[string]string)
	on_error             ?fn (string, map[string]string)
}

// Struktur untuk konfigurasi pesan
pub struct SendMessageOptions {
pub mut:
	quoted_message_id string
	ephemeral_duration int
	disappearing_messages_in_chat bool
	context_info      ?ContextInfo
	media_upload_timeout_ms int = 300000
	media_type_override string
}

// Struktur untuk polling pesan
pub struct PollInfo {
pub mut:
	name         string
	options      []PollOption
	select_type  int
	message_secret []u8
}

pub struct PollOption {
pub mut:
	name string
}

// Struktur untuk template pesan
pub struct TemplateInfo {
pub mut:
	template_id     string
	header_type     string
	header_text     string
	body_text       string
	footer_text     string
	buttons         []TemplateButton
	language_code   string
}

pub struct TemplateButton {
pub mut:
	display_text string
	button_id    string
	button_type  string
}

// Struktur untuk interactive pesan
pub struct InteractiveInfo {
pub mut:
	header_type string
	header_text string
	body_text   string
	footer_text string
	interactive_type string
	action      InteractiveAction
}

pub struct InteractiveAction {
pub mut:
	buttons    []InteractiveButton
	sections   []InteractiveSection
}

pub struct InteractiveButton {
pub mut:
	button_id   string
	display_text string
	button_type string
}

pub struct InteractiveSection {
pub mut:
	title string
	rows  []InteractiveRow
}

pub struct InteractiveRow {
pub mut:
	row_id      string
	title       string
	description string
}

// Struktur untuk business info
pub struct BusinessInfo {
pub mut:
	business_id    string
	business_name  string
	category       string
	description    string
	website        string
	email          string
	address        string
	latitude       f64
	longitude      f64
	profile_options map[string]string
}

// Struktur untuk product info
pub struct ProductInfo {
pub mut:
	product_id      string
	title           string
	description     string
	currency_code   string
	price_amount_1000 i64
	retailer_id     string
	url             string
	product_image_count int
	first_image_id  string
	sale_price_amount_1000 i64
}

// Struktur untuk order info
pub struct OrderInfo {
pub mut:
	order_id       string
	thumbnail      []u8
	item_count     int
	status         string
	surface        string
	message        string
	order_title    string
	seller_jid     string
	token          string
	total_amount_1000 i64
	total_currency_code string
}

// Struktur untuk payment info
pub struct PaymentInfo {
pub mut:
	currency_deprecated string
	amount_1000         i64
	receiver_jid        string
	status              string
	transaction_timestamp u64
	request_message_key MessageKey
	expiry_timestamp    u64
	futureproofed       bool
	currency            string
	txn_status          string
	primary_amount      i64
	exchange_rate       f64
}

// Struktur untuk call info
pub struct CallInfo {
pub mut:
	call_id      string
	from         string
	timestamp    u64
	video        bool
	status       string // ringing, accepted, rejected, missed, ended
	duration     int
	participants []string
}

// Struktur untuk newsletter info
pub struct NewsletterInfo {
pub mut:
	id            string
	name          string
	description   string
	invite_code   string
	creation_time u64
	state         string
	subscribers_count int
	verification  string
	picture       []u8
	preview       string
	reaction_codes []string
	mute          bool
}

// Type aliases untuk kompatibilitas
pub type WAMessage = Message
pub type WAChat = Chat
pub type WAContact = ContactInfo
pub type WAGroupMetadata = GroupMetadata
pub type WAPresence = PresenceInfo
pub type WAMediaInfo = MediaInfo
pub type WALocationInfo = LocationInfo