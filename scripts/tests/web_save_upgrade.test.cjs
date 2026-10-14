// Real old/new web exports, one browser origin and IndexedDB. All Firebase
// traffic is fulfilled in memory; no test accounts or scores reach production.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const crypto = require('node:crypto');
const { chromium } = require(path.join(process.env.USERPROFILE, '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright'));
const [oldRoot, newRoot, evidenceDir] = process.argv.slice(2).map(p => path.resolve(p));
assert(oldRoot && newRoot && evidenceDir, 'Pass old web root, new web root, evidence directory');
fs.mkdirSync(evidenceDir, {recursive:true});
const uid = 'uid-web-upgrade-fixture';
const name = 'WebKeeper';
const skillIds = ['fight', 'fishing', 'build', 'woodcutting', 'thieving'];
const now = () => Math.floor(Date.now()/1000);
const fixture = {
  save_schema_version:1, save_reset_generation:0,
  skills:Object.fromEntries(skillIds.map(id => [id,{xp:1000000,level:1}])),
  mastery:{'fishing:anchor-the-tiny-boat-dock':{xp:2468,level:1}},
  stamina:Object.fromEntries(skillIds.map(id => [id,17])),
  stamina_bank:Object.fromEntries(skillIds.map(id => [id,3])),
  mats:{softwood:321,hardwood:45}, selected_skill_id:'fight',
  running_skill_id:'',running_action_id:'',action_progress:0,
  manual_activity_unlocks:{'build:add-roof-to-something-roofless':true},
  built_modules:{'fight:duel-leaning-fence-post':true},
  onboarding_tutorial_complete:true,
  leaderboard_player_id:uid,leaderboard_display_name:name,leaderboard_name_key:'webkeeper',
  leaderboard_profile_claimed:true,leaderboard_name_claim_verified:true,
  leaderboard_auth_provider:'anonymous',leaderboard_auth_refresh_token:'fixture-refresh',
  leaderboard_auth_bound_uid:uid,saved_at:now(),
};
let buildRoot = oldRoot;
const mime = {'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
const server = http.createServer((req,res) => {
  const url = new URL(req.url,'http://127.0.0.1');
  const headers = {'Cache-Control':'no-store','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'};
  if(url.pathname==='/setup') {res.writeHead(200,{...headers,'Content-Type':'text/html'});res.end('<!doctype html><title>Save upgrade fixture</title>');return;}
  const file=path.resolve(buildRoot,'.'+(url.pathname==='/'?'/index.html':decodeURIComponent(url.pathname)));
  if(!file.startsWith(buildRoot+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()) {res.writeHead(404);res.end();return;}
  res.writeHead(200,{...headers,'Content-Type':mime[path.extname(file)]||'application/octet-stream'});
  fs.createReadStream(file).pipe(res);
});
let browser;
let activePage;
let saveKey = '/userfs/idle_elite_save.json';
const requests=[];
const errors=[];
let stage='old';
const database={leaderboards:{v1:{
  profiles_by_uid:{[uid]:{uid,display_name:name,name_key:'webkeeper',avatar_index:0,profile_claimed:true,name_claim_verified:true,auth_provider:'anonymous',updated_at_unix:now()}},
  name_claims:{webkeeper:{uid,name,name_key:'webkeeper',avatar_index:0}},
  scores:{total_level:{'fixture-other':{name:'Other',score:495,total_xp:40000000}}},
}}};
function getDb(parts){let value=database;for(const part of parts)value=value?.[part];return value??null;}
function setDb(parts,value){let target=database;for(const part of parts.slice(0,-1))target=target[part]??={};target[parts.at(-1)]=value;}
function serverValues(value){if(value&&typeof value==='object'){if(value['.sv']==='timestamp')return Date.now();return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,serverValues(v)]));}return value;}
async function routeFirebase(route){
  const request=route.request(), url=new URL(request.url()), method=request.method();
  const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'*','Access-Control-Allow-Methods':'GET,POST,PUT,PATCH,OPTIONS','Content-Type':'application/json','ETag':'"fixture"'};
  if(method==='OPTIONS')return route.fulfill({status:204,headers});
  let body=null;try{body=JSON.parse(request.postData()||'null');}catch{}
  requests.push({stage,host:url.hostname,path:url.pathname,method,body});
  if(url.hostname==='securetoken.googleapis.com')return route.fulfill({status:200,headers,json:{access_token:'fixture-id-token',id_token:'fixture-id-token',expires_in:'3600',refresh_token:'fixture-refresh',user_id:uid,project_id:'idle-elite',token_type:'Bearer'}});
  if(url.hostname==='identitytoolkit.googleapis.com')return route.fulfill({status:200,headers,json:{localId:uid,idToken:'fixture-id-token',refreshToken:'fixture-refresh',expiresIn:'3600'}});
  if(!url.hostname.endsWith('.firebaseio.com'))return route.abort();
  const parts=url.pathname.replace(/\.json$/,'').split('/').filter(Boolean);
  if(method==='PATCH')for(const [key,value]of Object.entries(body||{}))setDb(parts.concat(key.split('/')),serverValues(value));
  else if(method==='PUT')setDb(parts,serverValues(body));
  else assert.equal(method,'GET','Unexpected database mutation');
  return route.fulfill({status:200,headers,body:JSON.stringify(method==='GET'?getDb(parts):null)});
}
async function idb(page,action,text){return page.evaluate(async({action,text,saveKey})=>{
  const db=await new Promise((resolve,reject)=>{const request=indexedDB.open('/userfs',21);request.onupgradeneeded=()=>{const store=request.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp',{unique:false});};request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error);});
  try{return await new Promise((resolve,reject)=>{
    const tx=db.transaction('FILE_DATA',['read','keys'].includes(action)?'readonly':'readwrite'), store=tx.objectStore('FILE_DATA');let result=null;
    if(action==='keys') {const request=store.getAllKeys();request.onsuccess=()=>{result=request.result;};}
    else if(action==='read') {const request=store.get(saveKey);request.onsuccess=()=>{result=request.result?new TextDecoder().decode(request.result.contents):null;};}
    else {
      const put=()=>store.put({timestamp:new Date(),mode:33206,contents:new TextEncoder().encode(text)},saveKey);
      if(action==='seed') {const request=store.getAllKeys();request.onsuccess=()=>{for(const key of request.result)if(String(key).endsWith('.json'))store.delete(key);put();};}
      else put();
    }
    tx.oncomplete=()=>resolve(result);tx.onerror=()=>reject(tx.error);
  });}finally{db.close();}
},{action,text,saveKey});}
function decode(text){const raw=JSON.parse(text);if(raw.payload_json){assert.equal(crypto.createHash('sha256').update(raw.payload_json).digest('hex'),raw.checksum);return JSON.parse(raw.payload_json);}return raw;}
function encode(payload){const payload_json=JSON.stringify(payload);return JSON.stringify({...payload,save_envelope_version:1,payload_json,checksum:crypto.createHash('sha256').update(payload_json).digest('hex')});}
function preserved(payload){for(const id of skillIds)assert(payload.skills[id].xp>=1000000,`${stage}: lost ${id} XP`);assert(payload.mats.softwood>=321,`${stage}: lost materials`);assert(payload.built_modules['fight:duel-fence-post'],`${stage}: lost built module after legacy ID normalization`);assert.equal(payload.leaderboard_player_id,uid);assert.equal(payload.leaderboard_display_name,name);}
async function saved(page,condition){const until=Date.now()+100000;while(Date.now()<until){const text=await idb(page,'read');if(text){const payload=decode(text);if(condition(payload))return payload;}await new Promise(r=>setTimeout(r,500));}throw Error(stage+': persistent save did not reach expected state');}
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${server.address().port}`;
  browser=await chromium.launch({channel:'msedge',headless:true,args:['--mute-audio']});
  const context=await browser.newContext({viewport:{width:1080,height:1920}});
  await context.route('**/*',route=>new URL(route.request().url()).origin===origin?route.continue():routeFirebase(route));
  const page=await context.newPage();
  activePage=page;
  page.on('console',message=>{if(message.type()==='error')errors.push({stage,text:message.text()});});
  page.on('pageerror',error=>errors.push({stage,text:error.message}));
  // Discover the real export's user-data namespace before seeding the fixture.
  await page.goto(origin+'/');
  const discoveryDeadline=Date.now()+45000;
  while(Date.now()<discoveryDeadline){
    const keys=await idb(page,'keys');
    const found=keys.find(key=>String(key).endsWith('/idle_elite_save.json'));
    if(found){saveKey=found;break;}
    await new Promise(r=>setTimeout(r,500));
  }
  console.log('web-save-path '+saveKey);
  await page.goto(origin+'/setup');
  await idb(page,'seed',JSON.stringify(fixture));
  await page.goto(origin+'/');
  const oldSave=await saved(page,p=>p.save_schema_version>1&&p.save_revision>0);
  preserved(oldSave);
  console.log('old-web-save-preserved');
  await page.screenshot({path:path.join(evidenceDir,'old-browser-save.png')});
  // Leave the old game before adjusting only the fixture's cooldown and
  // acknowledged scores. Gameplay remains exactly what the old build saved.
  await page.goto(origin+'/setup');
  const returning=decode(await idb(page,'read'));
  returning.leaderboard_last_submit_unix=now()-1800;
  returning.leaderboard_repair_publish_version=2;
  returning.leaderboard_last_submitted_total_xp=skillIds.reduce((sum,id)=>sum+returning.skills[id].xp,0)+617;
  returning.leaderboard_last_submitted_score=returning.leaderboard_last_submitted_total_xp;
  returning.leaderboard_last_submitted_scores_by_category??={};
  returning.leaderboard_last_submitted_scores_by_category.total_level=skillIds.reduce((sum,id)=>sum+returning.skills[id].level,0);
  for(const id of skillIds)returning.leaderboard_last_submitted_scores_by_category['skill_xp:'+id]=returning.skills[id].xp;
  await idb(page,'write',encode(returning));
  buildRoot=newRoot;stage='new';
  await page.goto(origin+'/');
  const newSave=await saved(page,p=>p.save_revision>returning.save_revision&&p.leaderboard_last_submit_unix>returning.leaderboard_last_submit_unix);
  preserved(newSave);
  const published=database.leaderboards.v1.scores.total_level[uid];
  assert(published&&published.total_xp>=5000000,'Existing XP was not republished');
  assert(requests.some(r=>r.stage==='new'&&r.method==='PATCH'&&Object.keys(r.body||{}).some(k=>k==='scores/total_level/'+uid)),'New build did not submit unchanged returning score');
  await page.reload();stage='reopened';
  const reopened=await saved(page,p=>p.save_revision>newSave.save_revision);
  preserved(reopened);
  await page.screenshot({path:path.join(evidenceDir,'new-browser-save-reopened.png')});
  assert(!errors.some(e=>/SCRIPT ERROR|Parse Error|checksum|wasm.*abort/i.test(e.text)),JSON.stringify(errors));
  const summary={passed:true,oldSchema:oldSave.save_schema_version,newSchema:reopened.save_schema_version,skillXP:Object.fromEntries(skillIds.map(id=>[id,reopened.skills[id].xp])),materials:reopened.mats.softwood,publishedTotalXP:published.total_xp,productionWrites:0};
  fs.writeFileSync(path.join(evidenceDir,'browser-upgrade-result.json'),JSON.stringify(summary,null,2));
  console.log('web-save-upgrade-ok '+JSON.stringify(summary));
})().catch(async error=>{
  console.error(error.stack);process.exitCode=1;
  if(activePage){
    await activePage.screenshot({path:path.join(evidenceDir,'failure.png')}).catch(()=>{});
    fs.writeFileSync(path.join(evidenceDir,'failure-storage.json'),JSON.stringify({saveKey,keys:await idb(activePage,'keys'),raw:await idb(activePage,'read')},null,2));
  }
}).finally(async()=>{
  fs.writeFileSync(path.join(evidenceDir,'browser-errors.json'),JSON.stringify(errors,null,2));
  fs.writeFileSync(path.join(evidenceDir,'firebase-fixture-requests.json'),JSON.stringify(requests,null,2));
  if(browser)await browser.close();server.close();
});
