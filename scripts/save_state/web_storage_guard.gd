extends RefCounted

# Browser-only save protection. On the web, user:// is an IndexedDB mirror that
# every Godot game on the same origin shares, the browser may refuse or evict it,
# and each open tab syncs its whole in-memory copy back over the others. This
# guard makes those failure modes visible and stops a stale tab from writing.

const SAVE_OWNER_CHANNEL := "idle-elite-save-owner"
const BANNER_ELEMENT_ID := "idle-elite-save-banner"
const NOT_PERSISTENT_MESSAGE := "Your browser is not keeping Idle Elite saves (private window or blocked site storage). Progress will be lost when this tab closes. Use Settings > Export Save to keep a copy."
const OTHER_TAB_MESSAGE := "Idle Elite was opened in another tab. This tab stopped so it cannot overwrite your newer progress."

# Set once another tab owns the save. Any user:// write would make this tab sync
# its stale in-memory filesystem back over the newer tab's IndexedDB copy.
static var writes_disabled := false

var save_owner := true
var _on_hidden: Callable
var _on_owner_lost: Callable
var _on_visible: Callable
var _on_import_text: Callable
# JavaScript callbacks must stay referenced or the browser side loses them.
var _hidden_callback
var _visible_callback
var _owner_lost_callback
var _import_callback


static func is_web() -> bool:
	return OS.has_feature("web")


func setup(on_hidden: Callable, on_owner_lost: Callable, on_visible: Callable = Callable()) -> void:
	if not is_web():
		return
	_on_hidden = on_hidden
	_on_owner_lost = on_owner_lost
	_on_visible = on_visible
	if not OS.is_userfs_persistent():
		show_banner(NOT_PERSISTENT_MESSAGE)
	_hidden_callback = JavaScriptBridge.create_callback(_js_page_hidden)
	_visible_callback = JavaScriptBridge.create_callback(_js_page_visible)
	_owner_lost_callback = JavaScriptBridge.create_callback(_js_owner_lost)
	var window = JavaScriptBridge.get_interface("window")
	window.__idleEliteOnHidden = _hidden_callback
	window.__idleEliteOnVisible = _visible_callback
	window.__idleEliteOnOwnerLost = _owner_lost_callback
	JavaScriptBridge.eval("""
		(function () {
			try { if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); } } catch (e) {}
			var notifyHidden = function () { if (window.__idleEliteOnHidden) { window.__idleEliteOnHidden(); } };
			document.addEventListener('visibilitychange', function () {
				if (document.visibilityState === 'hidden') { notifyHidden(); }
				else if (window.__idleEliteOnVisible) { window.__idleEliteOnVisible(); }
			});
			window.addEventListener('pageshow', function () {
				if (document.visibilityState !== 'hidden' && window.__idleEliteOnVisible) { window.__idleEliteOnVisible(); }
			});
			window.addEventListener('pagehide', notifyHidden);
			if (typeof BroadcastChannel === 'undefined') { return; }
			var tabId = Math.random().toString(36).slice(2);
			var channel = new BroadcastChannel('%s');
			channel.onmessage = function (event) {
				var data = event.data || {};
				if (data.type === 'claim' && data.id !== tabId && window.__idleEliteOnOwnerLost) {
					window.__idleEliteOnOwnerLost();
				}
			};
			// The newest tab owns the save; every older tab stops writing.
			channel.postMessage({ type: 'claim', id: tabId });
			window.__idleEliteSaveChannel = channel;
		})();
	""" % SAVE_OWNER_CHANNEL, true)


func show_banner(message: String) -> void:
	if not is_web():
		return
	JavaScriptBridge.eval("""
		(function (text) {
			var banner = document.getElementById('%s');
			if (!banner) {
				banner = document.createElement('div');
				banner.id = '%s';
				banner.style.cssText = 'position:fixed;left:0;right:0;top:0;z-index:2147483647;padding:12px 16px;background:#b3261e;color:#fff;font:600 15px/1.35 system-ui,sans-serif;text-align:center;';
				document.body.appendChild(banner);
			}
			banner.textContent = text;
		})(%s);
	""" % [BANNER_ELEMENT_ID, BANNER_ELEMENT_ID, JSON.stringify(message)], true)


func download_text(file_name: String, text: String) -> void:
	if is_web():
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "application/json")


func request_import(on_import_text: Callable) -> void:
	if not is_web():
		return
	_on_import_text = on_import_text
	_import_callback = JavaScriptBridge.create_callback(_js_import_text)
	var window = JavaScriptBridge.get_interface("window")
	window.__idleEliteOnImportText = _import_callback
	JavaScriptBridge.eval("""
		(function () {
			var input = document.createElement('input');
			input.type = 'file';
			input.accept = '.json,application/json,text/plain';
			input.onchange = function () {
				var file = input.files && input.files[0];
				if (!file) { return; }
				var reader = new FileReader();
				reader.onload = function () { window.__idleEliteOnImportText(String(reader.result || '')); };
				reader.readAsText(file);
			};
			input.click();
		})();
	""", true)


func _js_page_hidden(_args: Array) -> void:
	if save_owner and _on_hidden.is_valid():
		_on_hidden.call()


func _js_page_visible(_args: Array) -> void:
	if save_owner and _on_visible.is_valid():
		_on_visible.call()


func _js_owner_lost(_args: Array) -> void:
	if not save_owner:
		return
	save_owner = false
	writes_disabled = true
	show_banner(OTHER_TAB_MESSAGE)
	if _on_owner_lost.is_valid():
		_on_owner_lost.call()


func _js_import_text(args: Array) -> void:
	if args.is_empty() or not _on_import_text.is_valid():
		return
	_on_import_text.call(str(args[0]))
