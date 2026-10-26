const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../save_state/web_storage_guard.gd'),'utf8').match(/JavaScriptBridge.eval\("""([\s\S]*?)"""/)[1].replace('%s','idle-elite-save-owner');
function environment(channels) {
  let lost=0, listeners=0;
  const window={__idleEliteOnOwnerLost:()=>lost++,addEventListener(){listeners++;}};
  const context={window,navigator:{},document:{addEventListener(){listeners++;}},BroadcastChannel:class {
    constructor(name){this.name=name;this.closed=false;channels.push(this);}
    postMessage(data){for(const c of channels)if(c!==this&&!c.closed&&c.name===this.name&&c.onmessage)c.onmessage({data});}
    close(){this.closed=true;}
  }};
  return {setup(){vm.runInNewContext(source,context);},lost:()=>lost,listeners:()=>listeners};
}
test('account scene reload keeps save ownership and installs lifecycle handlers once',()=>{
  const channels=[]; const tab=environment(channels); tab.setup();tab.setup();
  assert.equal(tab.lost(),0);assert.equal(tab.listeners(),3);assert.equal(channels.filter(c=>!c.closed).length,1);
});
test('another browser tab still revokes the old writer',()=>{
  const channels=[];const first=environment(channels),second=environment(channels);
  first.setup();second.setup();assert.equal(first.lost(),1);assert.equal(second.lost(),0);
});
