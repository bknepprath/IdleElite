class_name FirebaseRuntime

const URL_SCHEME := "https://"
const US_HOST_SUFFIX := ".firebaseio.com"
const REGIONAL_HOST_SUFFIX := ".firebasedatabase.app"
const HOST_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789-"
const PLACEHOLDER_DATABASE_URL := "https://YOUR-PROJECT-default-rtdb.firebaseio.com"
const PLACEHOLDER_WEB_API_KEY := "YOUR_FIREBASE_WEB_API_KEY"


static func parse_json_silent(raw_text: String) -> Variant:
	var json := JSON.new()
	if json.parse(raw_text) != OK:
		return null
	return json.data


static func sanitized_database_url(config_url: String, default_url: String) -> String:
	var url := config_url if not config_url.is_empty() else default_url.strip_edges()
	while url.ends_with("/"):
		url = url.substr(0, url.length() - 1)
	if url == PLACEHOLDER_DATABASE_URL:
		return ""
	if not database_url_allowed(url):
		return ""
	return url


static func sanitized_api_key(config_key: String, default_key: String) -> String:
	var key := config_key if not config_key.is_empty() else default_key.strip_edges()
	if key == PLACEHOLDER_WEB_API_KEY:
		return ""
	if key.length() < 20 or key.find(" ") >= 0 or key.find("\t") >= 0 or key.find("\n") >= 0 or key.find("\r") >= 0:
		return ""
	return key


static func database_url_allowed(url: String) -> bool:
	if url.is_empty() or not url.begins_with(URL_SCHEME):
		return false
	var host := url.substr(URL_SCHEME.length()).to_lower()
	if host.is_empty() or host.find("/") >= 0 or host.find(":") >= 0:
		return false
	if host.find("your-project") >= 0 or host.find("your_project") >= 0:
		return false
	if host.ends_with(US_HOST_SUFFIX):
		var database_name := host.substr(0, host.length() - US_HOST_SUFFIX.length())
		return host_label_allowed(database_name)
	if host.ends_with(REGIONAL_HOST_SUFFIX):
		var database_and_region := host.substr(0, host.length() - REGIONAL_HOST_SUFFIX.length())
		var separator := database_and_region.find(".")
		if separator <= 0 or separator >= database_and_region.length() - 1:
			return false
		return (
			host_label_allowed(database_and_region.substr(0, separator))
			and host_label_allowed(database_and_region.substr(separator + 1))
		)
	return false


static func host_label_allowed(value: String) -> bool:
	if value.is_empty() or value.begins_with("-") or value.ends_with("-"):
		return false
	for i in range(value.length()):
		if HOST_CHARS.find(value.substr(i, 1)) < 0:
			return false
	return true


static func database_url(base_url: String, root_path: String, path := "", query := "") -> String:
	var root := root_path.strip_edges()
	while root.begins_with("/"):
		root = root.substr(1)
	while root.ends_with("/"):
		root = root.substr(0, root.length() - 1)
	var clean_path := path.strip_edges()
	while clean_path.begins_with("/"):
		clean_path = clean_path.substr(1)
	var url := "%s/%s" % [base_url, root]
	if not clean_path.is_empty():
		url = "%s/%s" % [url, clean_path]
	url = "%s.json" % url
	if not query.is_empty():
		url = "%s?%s" % [url, query]
	return url


static func server_timestamp() -> Dictionary:
	return {".sv": "timestamp"}


static func error_detail(body: PackedByteArray) -> String:
	var raw := body.get_string_from_utf8().strip_edges()
	if raw.is_empty():
		return ""
	var parsed = parse_json_silent(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return raw.substr(0, 120)
	var error = (parsed as Dictionary).get("error", {})
	if typeof(error) == TYPE_DICTIONARY:
		var message := str((error as Dictionary).get("message", "")).strip_edges()
		if not message.is_empty():
			return message
	var data_message := str((parsed as Dictionary).get("message", "")).strip_edges()
	if not data_message.is_empty():
		return data_message
	return raw.substr(0, 120)


static func stream_target(url: String) -> Dictionary:
	if not url.begins_with(URL_SCHEME):
		return {}
	var rest := url.substr(URL_SCHEME.length())
	var slash_index := rest.find("/")
	if slash_index <= 0:
		return {}
	var host := rest.substr(0, slash_index)
	var path := rest.substr(slash_index)
	return {
		"host": host,
		"path": path
	}
