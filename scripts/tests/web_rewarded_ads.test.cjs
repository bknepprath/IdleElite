const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../monetization/web_rewarded_bridge.gd'), 'utf8').split('const SOURCE := """')[1].split('"""')[0];
function harness({live = false, testing = true} = {}) {
  const events = [], scripts = [], timers = new Map();
  let nextTimer = 0, placement;
  const window = {};
  const context = {window, encodeURIComponent,
    setTimeout(fn) { timers.set(++nextTimer, fn); return nextTimer; },
    clearTimeout(id) { timers.delete(id); },
    document: {createElement() { return {attributes: {}, setAttribute(k,v) {this.attributes[k]=v;}}; }, head: {appendChild(s) {scripts.push(s);}}}
  };
  vm.runInNewContext(source, context);
  const bridge = window.idleEliteRewardedAds;
  bridge.init((...args) => events.push(args), 'ca-pub-4125359195200512', live, testing);
  return {window, bridge, events, scripts, timers,
    ready() {
      window.adBreak = config => {placement = config;};
      window.adsbygoogle.find(c => c.onReady).onReady();
    },
    placement: () => placement,
    expire() { for (const fn of [...timers.values()]) fn(); },
    count(e) { return events.filter(a => a[1] === e).length; }
  };
}
test('release fails closed while H5/domain approval is missing', () => {
  const h = harness({testing:false});
  h.bridge.request(1,false);
  assert.equal(h.scripts.length,0);
  assert.equal(h.count('reward'),0);
  assert.equal(h.events[0][2],'unavailable');
});
test('debug requests use Google test ads and the current publisher', () => {
  const h = harness();
  assert.equal(h.scripts[0].attributes['data-adbreak-test'],'on');
  assert.match(h.scripts[0].src,/ca-pub-4125359195200512$/);
});
test('approved live configuration does not include the test flag', () => {
  const h=harness({live:true,testing:false});
  assert.equal(h.scripts[0].attributes['data-adbreak-test'],undefined);
});
test('SDK load alone never starts an ad; one explicit request grants once', () => {
  const h = harness(); h.ready();
  assert.equal(h.placement(),undefined);
  assert.equal(h.bridge.request(1,true),true);
  assert.equal(h.bridge.request(2,true),false);
  const p=h.placement(); let shows=0;
  p.beforeReward(()=>shows++); assert.equal(shows,1);
  p.beforeAd(); p.adViewed(); p.adViewed(); p.afterAd(); p.adBreakDone({breakStatus:'viewed'});
  assert.equal(h.count('reward'),1);
  assert.equal(h.count('resume'),1);
  assert.equal(h.count('done'),1);
  assert.equal(h.timers.size,0);
});
test('dismissal never grants, and releases the request for retry', () => {
  const h=harness(); h.ready(); h.bridge.request(1,false);
  const p=h.placement(); p.beforeAd(); p.adDismissed(); p.afterAd(); p.adBreakDone({breakStatus:'dismissed'});
  assert.equal(h.count('reward'),0);
  assert.equal(h.bridge.request(2,false),true);
});
test('no inventory completes without granting', () => {
  const h=harness(); h.ready(); h.bridge.request(1,false);
  h.placement().adBreakDone({breakStatus:'noAdPreloaded'});
  assert.equal(h.count('reward'),0); assert.equal(h.count('done'),1);
});
test('script failure and timeout unlock the button with no reward', () => {
  for(const fail of ['error','timeout']) {
    const h=harness(); h.bridge.request(1,false);
    if(fail==='error') h.scripts[0].onerror(); else h.expire();
    h.ready(); assert.equal(h.placement(),undefined);
    assert.equal(h.count('reward'),0); assert.equal(h.count('done'),1);
  }
});
test('late callbacks cannot open or reward an expired request or affect a new one', () => {
  const h=harness(); h.ready(); h.bridge.request(1,false);
  const old=h.placement(); h.expire(); h.bridge.request(2,false);
  old.beforeReward(()=>assert.fail('late ad opened')); old.beforeAd(); old.adViewed(); old.adBreakDone({breakStatus:'viewed'});
  assert.equal(h.count('reward'),0); assert.equal(h.count('showing'),0);
  const current=h.placement(); current.beforeAd(); current.adViewed(); current.adBreakDone({breakStatus:'viewed'});
  assert.equal(h.count('reward'),1); assert.equal(h.events.find(e=>e[1]==='reward')[0],2);
});
test('loading deadline does not interrupt an ad being watched', () => {
  const h=harness(); h.ready(); h.bridge.request(1,false);
  h.placement().beforeAd(); h.expire();
  assert.equal(h.count('done'),0);
  h.placement().adViewed(); assert.equal(h.count('reward'),1);
});
test('an SDK exception and reward callback without showing cannot grant', () => {
  const h=harness(); h.ready(); h.bridge.request(1,false);
  h.placement().adViewed(); assert.equal(h.count('reward'),0);
  h.placement().adBreakDone({breakStatus:'error'});
  h.window.adBreak=()=>{throw Error('SDK unavailable');};
  h.bridge.request(2,false); assert.equal(h.count('done'),2);
});
