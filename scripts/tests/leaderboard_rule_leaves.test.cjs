// Evaluate the generated numeric leaf rules with Firebase-style data snapshots.
// Full authorization remains covered by the rules contract checks and live rollout.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const rules = JSON.parse(fs.readFileSync(path.join(__dirname, '../../firebase-realtime-database.rules.json'), 'utf8')).rules;
const leaves = rules.leaderboards.v1.scores.$category.$playerId;
class Snapshot {
  constructor(value, parent = null) { this.value = value; this.owner = parent; }
  val() { return this.value ?? null; }
  exists() { return this.value !== undefined && this.value !== null; }
  isNumber() { return typeof this.value === 'number' && Number.isFinite(this.value); }
  parent() { return this.owner; }
  child(key) { return new Snapshot(this.value?.[key], this); }
}
function accepts(leaf, category, before, after) {
  const rule = new Function('data', 'newData', '$category', `return (${leaves[leaf]['.validate']});`);
  return rule(new Snapshot(before).child(leaf), new Snapshot(after).child(leaf), category);
}
assert.equal(accepts('score', 'total_level', {score: 2000000}, {score: 495, total_xp: 2000000}), true);
assert.equal(accepts('score', 'total_level', {score: 2000000}, {score: 495, total_xp: 100}), false);
assert.equal(accepts('score', 'total_level', {score: 495}, {score: 400, total_xp: 2000000}), false);
assert.equal(accepts('score', 'skill_xp__fight', {score: 2000000}, {score: 495, total_xp: 2000000}), false);
assert.equal(accepts('score', 'total_level', {}, {score: 2000000}), false);
assert.equal(accepts('score', 'skill_xp__fight', {score: 100}, {score: 101}), true);
assert.equal(accepts('total_xp', 'total_level', {total_xp: 2000000}, {total_xp: 100}), false);
assert.equal(accepts('total_xp', 'total_level', {total_xp: 2000000}, {total_xp: 2000000}), true);
console.log('leaderboard-rule-leaves-ok (8 cases)');
