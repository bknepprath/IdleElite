const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const catalog = fs.readFileSync(path.join(root, 'scripts/ui/profile_portrait_catalog.gd'), 'utf8');
const count = Number(catalog.match(/const COUNT := (\d+)/)[1]);
const rules = JSON.parse(fs.readFileSync(path.join(root, 'firebase-realtime-database.rules.json'), 'utf8'));
const avatarRules = [];
function visit(value) {
  if (!value || typeof value !== 'object') return;
  for (const [key, child] of Object.entries(value)) {
    if (key === 'avatar_index') avatarRules.push(child['.validate']);
    visit(child);
  }
}
visit(rules);
assert.equal(avatarRules.length, 4, 'profiles, claims, chat and scores must agree');
for (const rule of avatarRules) {
  const accepts = new Function('newData', `return (${rule});`);
  for (let index = 0; index < count; index++) {
    assert(accepts({isNumber: () => true, val: () => index}), `Avatar ${index} is rejected`);
  }
  for (const index of [-1, count, 1000]) {
    assert.equal(accepts({isNumber: () => true, val: () => index}), false);
  }
}
const paths = [...catalog.matchAll(/"res:\/\/([^"\n]+\.png)"/g)].map(match => match[1]);
assert.equal(paths.length, 5);
for (const asset of paths) {
  const png = fs.readFileSync(path.join(root, asset));
  assert.equal(png.readUInt32BE(16), 256, asset);
  assert.equal(png.readUInt32BE(20), 256, asset);
  assert.equal(png[25], 6, 'RGBA PNG');
}
assert.match(catalog, /0: "res:\/\/assets\/content\/ui\/profile-portraits\/shark-bucket.png"/);
assert.match(catalog, /18: "res:\/\/assets\/content\/ui\/profile-portraits\/brick-helmet-builder.png"/);
console.log(`profile-portraits-ok: ${count} IDs, four online rule branches, five RGBA assets`);
