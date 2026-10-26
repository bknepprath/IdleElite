extends RefCounted

# Enable only after this publisher, the hosting domain, H5 Games and the web
# consent message are approved/configured. AdMob approval does not cover H5.
const LIVE_ENABLED := false
const PUBLISHER_ID := "ca-pub-4125359195200512"

# Kept in a GDScript resource so every Web export includes the same bridge.
# Tests execute this exact source with a fake SDK, without serving live ads.
const SOURCE := """
(() => {
  if (window.idleEliteRewardedAds) return;
  let initialized = false, ready = false, failed = false, active = null;
  let notify = null;
  const emit = (request, event, detail = '') => {
    if (notify) notify(request.id, event, detail);
  };
  const finish = (request, status) => {
    if (active !== request) return;
    clearTimeout(request.timer);
    active = null;
    emit(request, 'done', status);
  };
  const place = (request) => {
    if (active !== request || request.placed || !ready) return;
    request.placed = true;
    try {
      window.adBreak({
        type: 'reward', name: 'idle_elite_bonus',
        beforeReward: (showAd) => {
          if (active === request) showAd(); // Explicit Watch ad click initiated this request.
        },
        beforeAd: () => {
          if (active !== request || request.showing) return;
          request.showing = true;
          clearTimeout(request.timer); // Never time out an ad the player is watching.
          emit(request, 'showing');
        },
        adViewed: () => {
          if (active !== request || !request.showing || request.rewarded) return;
          request.rewarded = true;
          emit(request, 'reward');
        },
        adDismissed: () => {
          if (active === request) emit(request, 'dismissed');
        },
        afterAd: () => {
          if (active === request) emit(request, 'resume');
        },
        adBreakDone: (info) => finish(request, info?.breakStatus || 'unavailable')
      });
    } catch (_) { finish(request, 'error'); }
  };
  window.idleEliteRewardedAds = {
    init(callback, publisher, liveEnabled, testMode) {
      notify = callback;
      if (initialized) return;
      initialized = true;
      if (!liveEnabled && !testMode) { failed = true; return; }
      window.adsbygoogle = window.adsbygoogle || [];
      window.adBreak = window.adConfig = (config) => window.adsbygoogle.push(config);
      const script = document.createElement('script');
      script.async = true;
      script.crossOrigin = 'anonymous';
      script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + encodeURIComponent(publisher);
      if (testMode) script.setAttribute('data-adbreak-test', 'on');
      script.onerror = () => {
        failed = true;
        if (active) finish(active, 'unavailable');
      };
      window.adConfig({preloadAdBreaks: 'on', sound: 'off', onReady: () => {
        ready = true;
        if (active) place(active);
      }});
      document.head.appendChild(script);
    },
    request(id, soundEnabled) {
      if (active) return false;
      const request = {id, placed: false, showing: false, rewarded: false};
      active = request;
      if (failed) { finish(request, 'unavailable'); return true; }
      request.timer = setTimeout(() => finish(request, 'timeout'), 15000);
      window.adConfig({sound: soundEnabled ? 'on' : 'off'});
      place(request);
      return true;
    }
  };
})();
"""
