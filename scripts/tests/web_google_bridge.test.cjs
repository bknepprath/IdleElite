const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../online/web_google_bridge.gd'),'utf8').match(/const SOURCE := """([\s\S]*?)"""/)[1];
function fixture() {
  let options, requests=0;
  const scripts=[], events=[], window={};
  const context={window, document:{createElement(){return {};},head:{appendChild(s){scripts.push(s);}}},google:{accounts:{oauth2:{initTokenClient(o){options=o;return{requestAccessToken(){requests++;}};}}}}};
  vm.runInNewContext(source,context);
  const bridge=window.idleEliteGoogle;
  bridge.init((...a)=>events.push(a),'client');
  return {bridge,scripts,events,ready(){scripts[0].onload();},options(){return options;},requests(){return requests;}};
}
test('no popup before SDK readiness and only requested identity scopes',()=>{
  const f=fixture(); assert.equal(f.bridge.request(),false); f.ready();
  assert.equal(f.options().scope,'openid email profile'); assert.equal(f.options().include_granted_scopes,false);
  assert.equal(f.requests(),0); assert.equal(f.bridge.request(),true); assert.equal(f.requests(),1);
});
test('duplicate clicks cannot open multiple account choosers',()=>{
  const f=fixture(); f.ready(); f.bridge.request(); assert.equal(f.bridge.request(),false); assert.equal(f.requests(),1);
});
test('cancellation releases busy state without a credential',()=>{
  const f=fixture(); f.ready(); f.bridge.request(); f.options().error_callback({type:'popup_closed'});
  assert.equal(f.events.some(e=>e[0]==='credential'),false); assert.equal(f.bridge.request(),true);
});
test('access denied never authenticates',()=>{
  const f=fixture(); f.ready(); f.bridge.request(); f.options().callback({error:'access_denied'});
  assert.equal(f.events.some(e=>e[0]==='credential'),false);
});
test('credential travels only through the game callback',()=>{
  const f=fixture(); f.ready(); f.bridge.request(); f.options().callback({access_token:'fixture-token'});
  assert.deepEqual(f.events.at(-1),['credential','fixture-token']);
  assert.equal(f.scripts[0].src,'https://accounts.google.com/gsi/client');
});
test('SDK network failure can retry',()=>{
  const f=fixture(); f.scripts[0].onerror(); f.bridge.init(()=>{},'client'); assert.equal(f.scripts.length,2);
});
