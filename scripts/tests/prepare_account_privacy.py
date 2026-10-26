from pathlib import Path

site = Path(r'H:\Codex\Projects\Brian-Website-release')
game = Path(__file__).resolve().parents[2]
page = site / 'projects/idle-elite/index.html'
text = page.read_text(encoding='utf-8')
link = '        <a href="privacy.html" class="idle-elite-footer__privacy-link">Privacy policy</a>\n'
if 'idle-elite-footer__privacy-link' not in text:
    assert text.count('    </footer>') == 1
    text = text.replace('    </footer>', link + '    </footer>')
    page.write_text(text, encoding='utf-8')
style = site / 'projects/idle-elite/styles.css'
css = style.read_text(encoding='utf-8')
if '.idle-elite-footer__privacy-link' not in css:
    css += '\n.idle-elite-footer { align-items: center; gap: 1.5rem; flex-wrap: wrap; }\n.idle-elite-footer__privacy-link { color: var(--idle-elite-ink); font-size: 1rem; }\n'
    style.write_text(css, encoding='utf-8')
privacy = (game / 'public/privacy.html').read_text(encoding='utf-8')
privacy = privacy.replace('href="/delete-account.html"', 'href="https://idle-elite.web.app/delete-account.html"')
(site / 'projects/idle-elite/privacy.html').write_text(privacy, encoding='utf-8')
print('Prepared homepage privacy link and same-policy local-domain copy')
