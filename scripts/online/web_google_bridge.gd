extends RefCounted

# Google credentials are passed directly to Firebase by online_runtime. They are
# never stored in JavaScript storage, URLs, analytics, or cloud-save payloads.
const SOURCE := """
(() => {
  if (window.idleEliteGoogle) return;
  let notify, client, loading = false, busy = false;
  const emit = (event, value = '') => notify && notify(event, value);
  window.idleEliteGoogle = {
    init(callback, clientId) {
      notify = callback;
      if (client) { emit('ready'); return; }
      if (loading) return;
      loading = true;
      const script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.onerror = () => { loading = false; emit('error', 'Google sign-in could not load. Try again.'); };
      script.onload = () => {
        loading = false;
        client = google.accounts.oauth2.initTokenClient({
          client_id: clientId,
          scope: 'openid email profile',
          include_granted_scopes: false,
          callback: (result) => {
            busy = false;
            if (result.error || !result.access_token) { emit('error', 'Google sign-in was cancelled.'); return; }
            emit('credential', result.access_token);
          },
          error_callback: () => { busy = false; emit('error', 'Google sign-in was cancelled or blocked.'); }
        });
        emit('ready');
      };
      document.head.appendChild(script);
    },
    request() {
      if (!client || busy) return false;
      busy = true;
      try { client.requestAccessToken({prompt: 'select_account'}); return true; }
      catch (_) { busy = false; emit('error', 'Google sign-in could not open.'); return false; }
    }
  };
})();
"""

var bridge
var callback
var ready := false
var prepared := false
var online

static func enabled() -> bool:
	return OS.has_feature("web") and bool(ProjectSettings.get_setting("application/config/web_accounts", false))

func prepare(owner, retry := false) -> void:
	online = owner
	if ready or (prepared and not retry) or not enabled() or owner.google_auth_web_client_id.is_empty():
		return
	prepared = true
	if bridge == null:
		JavaScriptBridge.eval(SOURCE, true)
		bridge = JavaScriptBridge.get_interface("idleEliteGoogle")
		callback = JavaScriptBridge.create_callback(_event)
	bridge.init(callback, owner.google_auth_web_client_id)

func request() -> bool:
	return ready and bridge != null and bool(bridge.request())

func _event(args: Array) -> void:
	if args.is_empty() or not is_instance_valid(online):
		return
	match str(args[0]):
		"ready":
			ready = true
			online.app._profile_chat_overlay_surface().call_deferred("_rebuild_profile_overlay_if_visible")
		"credential":
			online.google_auth_credential_kind = "access_token"
			online._on_google_sign_in_succeeded(str(args[1]))
		"error":
			online._on_google_sign_in_failed(str(args[1]))
