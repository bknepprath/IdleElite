"""Audit production resource reachability and early combo rewards, without saves."""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.codex-tmp/audit-2026-10-14'
data = json.loads((ROOT / 'docs/activity-database.json').read_text(encoding='utf-8-sig'))
actions = {
    f'{skill["id"]}:{action["id"]}': (skill['id'], action)
    for skill in data['skills'] for action in skill['actions']
    if 'seasonal_event' not in action
}
sources = {}
for key, (_, action) in actions.items():
    drop = action.get('unlock_drop', {})
    if drop:
        sources.setdefault(drop['id'], []).append(key)

def reachable_at(level):
    candidates = {
        key for key, (_, action) in actions.items()
        if action['unlock'] <= level
        and all(requirement.get('level', 1) <= level for requirement in action.get('requirements', []))
    }
    reached = {key for key in candidates if not actions[key][1].get('unlock_project')}
    while True:
        next_reached = reached | {
            key for key in candidates
            if all(any(source in reached for source in sources.get(step['resource'], []))
                   for step in actions[key][1].get('unlock_project', {}).get('steps', []))
        }
        if next_reached == reached:
            return sorted(reached), sorted(candidates - reached)
        reached = next_reached

reachability = {}
for level in [5, 10, 20, 50, 99]:
    reached, blocked = reachable_at(level)
    reachability[level] = {'reachable_count': len(reached), 'resource_blocked': blocked}

combos = []
for key, support in [('fight:wrestle-stuck-gate-latch', 'build'),
                     ('build:saw-planks', 'woodcutting'),
                     ('woodcutting:split-firewood', 'fishing')]:
    owner, action = actions[key]
    reward = action['xp_rewards']
    assert reward[owner] == 4 and reward[support] == 2, (key, reward)
    combos.append({'action': key, 'support': support, 'primary_xp': reward[owner],
                   'support_xp': reward[support], 'seconds': action['seconds'],
                   'expected_support_xp_per_minute_full_speed': round(60 * action['success'] / 100 * reward[support] / action['seconds'], 2),
                   'requirements': action.get('requirements', [])})

barriers = []
for material in ['iron', 'bronze', 'silver', 'gold', 'titanium', 'platinum', 'obsidian']:
    for stage in range(4):
        path = ROOT / f'assets/content/ui/project-damage-{material}-{stage}.png'
        with path.open('rb') as source:
            header = source.read(24)
        assert header[:8] == b'\x89PNG\r\n\x1a\n', path
        width, height = struct.unpack('>II', header[16:24])
        barriers.append({'path': path.relative_to(ROOT).as_posix(), 'width': width, 'height': height,
                         'portrait_draw_width': 1062, 'horizontal_upscale': round(1062 / width, 2)})

result = {'scope': 'Nonseasonal production data. Reachability assumes required skill levels; it is not a pacing simulation.',
          'reachability': reachability, 'early_combos': combos, 'barrier_resolution': barriers,
          'rate_limitations': 'Full-speed expected rates exclude stamina depletion, player input time, critical hits, streaks and mastery.'}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'progression-and-resolution.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
assert not reachability[99]['resource_blocked'], reachability[99]
print(json.dumps({'resource_projects_reachable': True, 'actions': len(actions),
                  'early_combos': len(combos), 'low_resolution_barrier_frames': sum(r['horizontal_upscale'] > 2 for r in barriers)}))
