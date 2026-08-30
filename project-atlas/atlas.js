(() => {
  const data = window.ATLAS_DATA;
  const fields = Object.fromEntries(data.field_guide.map((name, index) => [name, index]));
  const files = data.files;
  const el = (id) => document.getElementById(id);
  const formatNumber = (value) => new Intl.NumberFormat('en-US').format(value);
  const formatBytes = (bytes) => {
    if (!bytes) return '0 B';
    const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
    const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
    const value = bytes / Math.pow(1024, index);
    return `${value.toLocaleString('en-US', { maximumFractionDigits: index > 1 ? 1 : 0 })} ${units[index]}`;
  };
  const sumBytes = (items) => items.reduce((sum, file) => sum + file[fields.bytes], 0);
  const fileHref = (path) => encodeURI(`../${path}`).replaceAll('#', '%23').replaceAll('?', '%3F');
  const isPath = (file, prefix) => file[fields.path] === prefix || file[fields.path].startsWith(`${prefix}/`);
  const metrics = (items) => ({ files: items.length, bytes: sumBytes(items) });

  function storageKeyFromPath(path) {
    const matches = (prefix) => path === prefix || path.startsWith(`${prefix}/`);
    if (matches('builds')) return 'builds';
    if (matches('.codex-tmp')) return 'agent-temp';
    if (matches('.godot')) return 'godot-cache';
    if (matches('.codex-tools')) return 'local-tools';
    if (path.startsWith('android/build/')) return 'android-build';
    if (/^(tmp|output|outputs|test-results)\//.test(path)) return 'generated-work';
    if (matches('play-store')) return 'play-store';
    if (/^(assets|scripts|scenes|addons)\//.test(path) || ['project.godot', 'export_presets.cfg'].includes(path)) return 'authored-game';
    return 'other';
  }
  const storageKey = (file) => storageKeyFromPath(file[fields.path]);

  const storageDefinitions = [
    { id: 'builds', name: 'Release builds and exports', color: '#d94761', description: 'Saved Android bundles, test packages, web exports, ZIP archives, and extracted package contents. Many versions duplicate the same game data.' },
    { id: 'agent-temp', name: 'Temporary agent work', color: '#e47b23', description: 'Task worktrees, test copies, captures, audit folders, and logs inside .codex-tmp. This is working material rather than the shipped game.' },
    { id: 'godot-cache', name: 'Godot import cache', color: '#c99518', description: 'Godot-generated textures and editor indexes inside .godot. Godot can recreate these files from source assets.' },
    { id: 'local-tools', name: 'Downloaded tools and tool output', color: '#865bc5', description: 'Export templates, Android source copies, helper downloads, and screenshots inside .codex-tools.' },
    { id: 'android-build', name: 'Generated Android build folder', color: '#3979c9', description: 'Gradle build output inside android/build. It is produced by Android exports and is not authored game source.' },
    { id: 'generated-work', name: 'Generated art, tests, and review output', color: '#1e9f91', description: 'Image-generation batches, QA captures, presentation output, temporary validation files, and test results.' },
    { id: 'authored-game', name: 'Authored game source and assets', color: '#26955f', description: 'Godot scripts, scenes, add-ons, project settings, and the source assets used to build Idle Elite.' },
    { id: 'play-store', name: 'Play Store source material', color: '#64a83e', description: 'Store listing graphics, screenshots, and release documents in the dedicated play-store folder.' },
    { id: 'other', name: 'Other project support', color: '#75828a', description: 'Documentation, configuration, the atlas, root-level review images, Firebase files, and other support material.' }
  ];

  const storageGroups = storageDefinitions.map((definition) => {
    const groupFiles = files.filter((file) => storageKey(file) === definition.id);
    return { ...definition, items: groupFiles, ...metrics(groupFiles) };
  }).sort((a, b) => b.bytes - a.bytes);
  const totalBytes = sumBytes(files);
  const authoredGroup = storageGroups.find((group) => group.id === 'authored-game');
  const producedGroups = storageGroups.filter((group) => ['builds', 'agent-temp', 'godot-cache', 'local-tools', 'android-build', 'generated-work'].includes(group.id));
  const producedBytes = producedGroups.reduce((sum, group) => sum + group.bytes, 0);
  const producedFiles = producedGroups.reduce((sum, group) => sum + group.files, 0);
  const gameImages = files.filter((file) => file[fields.image_state] && file[fields.path].startsWith('assets/') && !file[fields.path].startsWith('assets/android/'));
  const playStoreFiles = files.filter((file) => file[fields.path].startsWith('play-store/'));

  function addSummaryCard(value, label, detail) {
    const fragment = el('summary-card-template').content.cloneNode(true);
    fragment.querySelector('.summary-value').textContent = value;
    fragment.querySelector('.summary-label').textContent = label;
    fragment.querySelector('.summary-detail').textContent = detail;
    el('summary').appendChild(fragment);
  }

  function renderSummary() {
    const storeImages = playStoreFiles.filter((file) => ['.png', '.jpg', '.jpeg'].includes(file[fields.extension]));
    addSummaryCard(formatBytes(totalBytes), 'Entire project folder', `${formatNumber(files.length)} files, including all produced and temporary copies`);
    addSummaryCard(formatBytes(authoredGroup.bytes), 'Authored game source', `${formatNumber(authoredGroup.files)} scripts, scenes, add-ons, settings, and source assets`);
    addSummaryCard(formatBytes(producedBytes), 'Builds, temporary work, and caches', `${formatNumber(producedFiles)} files outside the authored game source`);
    addSummaryCard(formatNumber(gameImages.length), 'Game source images', `${formatBytes(sumBytes(gameImages))}; the full folder contains ${formatNumber(data.images.all.count)} images after copies and temporary work`);
    addSummaryCard(formatNumber(playStoreFiles.length), 'Files in play-store', `${formatNumber(storeImages.length)} images and ${formatNumber(playStoreFiles.length - storeImages.length)} documents or support files`);
    el('scope-line').textContent = `Snapshot ${data.generated_at}. Everything inside the Idle Elite project folder except Git's internal database.`;
    el('storage-title').textContent = `Why this project folder is ${formatBytes(totalBytes)}`;
  }

  function renderStorage() {
    renderTreemap('');
    renderTreemapLegend();
  }

  let currentTreemapPath = '';
  let treemapResizeTimer;
  let lastTreemapWidth = 0;
  let lastTreemapHeight = 0;

  function getTreemapChildren(path) {
    const prefix = path ? `${path}/` : '';
    const groups = new Map();
    files.forEach((file) => {
      const filePath = file[fields.path];
      if (path && !filePath.startsWith(prefix)) return;
      const remainder = path ? filePath.slice(prefix.length) : filePath;
      if (!remainder) return;
      const slash = remainder.indexOf('/');
      const segment = slash >= 0 ? remainder.slice(0, slash) : remainder;
      const childPath = path ? `${path}/${segment}` : segment;
      const type = slash >= 0 ? 'folder' : 'file';
      if (!groups.has(childPath)) groups.set(childPath, { name: segment, path: childPath, type, bytes: 0, count: 0 });
      const node = groups.get(childPath);
      node.bytes += file[fields.bytes];
      node.count += 1;
      if (type === 'folder') node.type = 'folder';
      if (type === 'file') node.file = file;
    });
    let nodes = [...groups.values()].sort((a, b) => b.bytes - a.bytes);
    if (nodes.length > 150) {
      const folders = nodes.filter((node) => node.type === 'folder');
      const directFiles = nodes.filter((node) => node.type === 'file');
      const room = Math.max(0, 149 - folders.length);
      const visible = directFiles.slice(0, room);
      const hidden = directFiles.slice(room);
      if (hidden.length) {
        visible.push({ name: `${formatNumber(hidden.length)} smaller files`, path: path ? `${path}/[smaller files]` : '[smaller files]', type: 'aggregate', bytes: hidden.reduce((sum, node) => sum + node.bytes, 0), count: hidden.length });
      }
      nodes = [...folders, ...visible].sort((a, b) => b.bytes - a.bytes);
    }
    return nodes;
  }

  function worstTreemapRatio(row, side) {
    if (!row.length) return Infinity;
    const sum = row.reduce((total, item) => total + item.area, 0);
    const maximum = Math.max(...row.map((item) => item.area));
    const minimum = Math.max(Math.min(...row.map((item) => item.area)), 0.0001);
    const sideSquared = side * side;
    return Math.max((sideSquared * maximum) / (sum * sum), (sum * sum) / (sideSquared * minimum));
  }

  function layoutTreemapRow(row, rect, output) {
    const sum = row.reduce((total, item) => total + item.area, 0);
    if (rect.w >= rect.h) {
      const rowWidth = Math.min(rect.w, sum / Math.max(rect.h, 1));
      let y = rect.y;
      row.forEach((item, index) => {
        const height = index === row.length - 1 ? rect.y + rect.h - y : item.area / Math.max(rowWidth, 0.0001);
        output.push({ ...item.node, x: rect.x, y, w: Math.max(0, rowWidth), h: Math.max(0, height) });
        y += height;
      });
      rect.x += rowWidth;
      rect.w -= rowWidth;
    } else {
      const rowHeight = Math.min(rect.h, sum / Math.max(rect.w, 1));
      let x = rect.x;
      row.forEach((item, index) => {
        const width = index === row.length - 1 ? rect.x + rect.w - x : item.area / Math.max(rowHeight, 0.0001);
        output.push({ ...item.node, x, y: rect.y, w: Math.max(0, width), h: Math.max(0, rowHeight) });
        x += width;
      });
      rect.y += rowHeight;
      rect.h -= rowHeight;
    }
  }

  function squarifyTreemap(nodes, width, height) {
    const positiveTotal = nodes.reduce((sum, node) => sum + Math.max(node.bytes, 1), 0);
    const scale = (width * height) / Math.max(positiveTotal, 1);
    const items = nodes.map((node) => ({ node, area: Math.max(node.bytes, 1) * scale }));
    const output = [];
    const rect = { x: 0, y: 0, w: width, h: height };
    let row = [];
    while (items.length) {
      const next = items[0];
      const side = Math.max(1, Math.min(rect.w, rect.h));
      if (!row.length || worstTreemapRatio([...row, next], side) <= worstTreemapRatio(row, side)) {
        row.push(items.shift());
      } else {
        layoutTreemapRow(row, rect, output);
        row = [];
      }
    }
    if (row.length) layoutTreemapRow(row, rect, output);
    return output;
  }

  function mixTreemapColor(hex, amount) {
    const number = parseInt(hex.slice(1), 16);
    const red = (number >> 16) & 255;
    const green = (number >> 8) & 255;
    const blue = number & 255;
    const mix = (channel) => Math.round(channel + (255 - channel) * amount);
    return `rgb(${mix(red)}, ${mix(green)}, ${mix(blue)})`;
  }

  function colorForTreemapNode(node, index) {
    const definition = storageDefinitions.find((item) => item.id === storageKeyFromPath(node.path)) || storageDefinitions.at(-1);
    const variation = ((index * 37) % 5) * 0.055;
    return mixTreemapColor(definition.color, variation);
  }

  function positionTreemapTooltip(event) {
    const tooltip = el('treemap-tooltip');
    const gap = 14;
    const width = tooltip.offsetWidth || 240;
    const height = tooltip.offsetHeight || 100;
    let x = event.clientX + gap;
    let y = event.clientY + gap;
    if (x + width > window.innerWidth - 8) x = event.clientX - width - gap;
    if (y + height > window.innerHeight - 8) y = event.clientY - height - gap;
    tooltip.style.left = `${Math.max(8, x)}px`;
    tooltip.style.top = `${Math.max(8, y)}px`;
  }

  function showTreemapTooltip(node, event, viewBytes) {
    const tooltip = el('treemap-tooltip');
    tooltip.replaceChildren();
    const title = document.createElement('strong');
    const typeLabel = node.type === 'folder' ? 'Folder' : node.type === 'file' ? 'File' : 'Grouped files';
    title.textContent = `${typeLabel} · ${node.name}`;
    const path = document.createElement('span');
    path.textContent = node.path;
    const size = document.createElement('span');
    size.textContent = `${formatBytes(node.bytes)} · ${formatNumber(node.count)} ${node.count === 1 ? 'file' : 'files'}`;
    const share = document.createElement('span');
    share.textContent = `${((node.bytes / totalBytes) * 100).toFixed(2)}% of project · ${((node.bytes / Math.max(viewBytes, 1)) * 100).toFixed(1)}% of this view`;
    tooltip.append(title, path, size, share);
    tooltip.hidden = false;
    positionTreemapTooltip(event);
  }

  function hideTreemapTooltip() {
    el('treemap-tooltip').hidden = true;
  }

  function showTreemapDetail(node) {
    const detail = el('treemap-detail');
    detail.replaceChildren();
    if (node.type !== 'file' || !node.file) return;
    const name = document.createElement('strong');
    name.textContent = node.path || 'Idle Elite project';
    const text = document.createTextNode(`${formatBytes(node.bytes)} · ${formatNumber(node.count)} ${node.count === 1 ? 'file' : 'files'} · ${((node.bytes / totalBytes) * 100).toFixed(2)}% of the project`);
    detail.append(name, text);
    const link = document.createElement('a');
    link.href = fileHref(node.file[fields.path]);
    link.target = '_blank';
    link.textContent = 'Open file';
    detail.appendChild(link);
  }

  function renderTreemapBreadcrumbs(path) {
    const container = el('treemap-breadcrumbs');
    container.replaceChildren();
    const parts = path ? path.split('/') : [];
    const paths = ['', ...parts.map((_, index) => parts.slice(0, index + 1).join('/'))];
    const labels = ['Idle Elite', ...parts];
    paths.forEach((value, index) => {
      if (index) {
        const separator = document.createElement('span');
        separator.className = 'treemap-separator';
        separator.textContent = '/';
        container.appendChild(separator);
      }
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'treemap-crumb';
      button.textContent = labels[index];
      button.addEventListener('click', () => renderTreemap(value));
      container.appendChild(button);
    });
    el('treemap-back').disabled = !path;
  }

  function renderTreemap(path = currentTreemapPath) {
    currentTreemapPath = path;
    const container = el('treemap');
    container.replaceChildren();
    el('treemap-detail').replaceChildren();
    renderTreemapBreadcrumbs(path);
    const nodes = getTreemapChildren(path);
    const viewBytes = nodes.reduce((sum, node) => sum + node.bytes, 0);
    const width = Math.max(container.clientWidth, 320);
    const height = container.clientHeight;
    lastTreemapWidth = width;
    lastTreemapHeight = height;
    const layout = squarifyTreemap(nodes, width, height);
    layout.forEach((node, index) => {
      if (node.w < 1 || node.h < 1) return;
      const tile = document.createElement('button');
      tile.type = 'button';
      tile.className = `treemap-tile ${node.type}`;
      tile.style.left = `${node.x}px`;
      tile.style.top = `${node.y}px`;
      tile.style.width = `${node.w}px`;
      tile.style.height = `${node.h}px`;
      tile.style.backgroundColor = colorForTreemapNode(node, index);
      const typeLabel = node.type === 'folder' ? 'Folder' : node.type === 'file' ? 'File' : 'Grouped files';
      tile.setAttribute('aria-label', `${typeLabel} ${node.name}, ${formatBytes(node.bytes)}, ${formatNumber(node.count)} files`);
      if (node.w > 78 && node.h > 38) {
        const label = document.createElement('span');
        label.className = 'treemap-label';
        const type = document.createElement('span');
        type.className = 'tile-type';
        type.textContent = typeLabel;
        const name = document.createElement('strong');
        name.textContent = node.name;
        const size = document.createElement('span');
        size.textContent = formatBytes(node.bytes);
        label.append(type, name, size);
        tile.appendChild(label);
      }
      tile.addEventListener('mouseenter', (event) => showTreemapTooltip(node, event, viewBytes));
      tile.addEventListener('mousemove', positionTreemapTooltip);
      tile.addEventListener('mouseleave', hideTreemapTooltip);
      tile.addEventListener('focus', () => {
        if (node.type === 'file') showTreemapDetail(node);
      });
      tile.addEventListener('click', () => {
        if (node.type === 'folder') renderTreemap(node.path);
        else showTreemapDetail(node);
      });
      container.appendChild(tile);
    });
  }

  function renderTreemapLegend() {
    [
      { name: 'Folder', className: 'legend-folder' },
      { name: 'Direct file', className: 'legend-file' }
    ].forEach((definition) => {
      const item = document.createElement('span');
      item.className = 'legend-item';
      const swatch = document.createElement('span');
      swatch.className = definition.className;
      const label = document.createTextNode(definition.name);
      item.append(swatch, label);
      el('treemap-legend').appendChild(item);
    });
  }

  const imageCategoryDefinitions = [
    { id: 'monsters', name: 'Monsters and bosses', color: '#d94761', test: (path) => /assets\/content\/fight\/(enemies|boss)\//.test(path) },
    { id: 'fight-action', name: 'Fighting actions and effects', color: '#e47b23', test: (path) => /assets\/content\/fight\/(actions|effects|animations|prototype|base-models)\//.test(path) },
    { id: 'backgrounds', name: 'Backgrounds, terrain, and textures', color: '#c99518', test: (path) => /(backgrounds|terrain|textures?|\/mats\/)\b/.test(path) },
    { id: 'ui', name: 'Interface, icons, and navigation', color: '#865bc5', test: (path) => /assets\/content\/(ui|icons|logo|achievements)\//.test(path) },
    { id: 'fishing', name: 'Fishing', color: '#3979c9', test: (path) => /assets\/content\/(fishing|combo\/fishing)\//.test(path) },
    { id: 'thieving', name: 'Thieving', color: '#7e55b5', test: (path) => /assets\/content\/(thieving|combo\/thieving)\//.test(path) },
    { id: 'woodcutting', name: 'Woodcutting', color: '#26955f', test: (path) => /assets\/content\/(woodcutting|combo\/woodcutting)\//.test(path) },
    { id: 'building', name: 'Building', color: '#b0692d', test: (path) => /assets\/content\/build\//.test(path) },
    { id: 'loading', name: 'Loading screens', color: '#1e9f91', test: (path) => /assets\/loading\//.test(path) },
    { id: 'characters', name: 'Hub and characters', color: '#d34a92', test: (path) => /assets\/content\/(hub|characters)\//.test(path) },
    { id: 'other', name: 'Other game images', color: '#75828a', test: () => true }
  ];

  const imageCategories = imageCategoryDefinitions.map((definition) => ({ ...definition, files: [] }));
  gameImages.forEach((file) => {
    const path = file[fields.path];
    imageCategories.find((category) => category.test(path)).files.push(file);
  });

  function createImageTree() {
    const root = { name: 'assets', path: 'assets', children: new Map(), ownFiles: [] };
    gameImages.forEach((file) => {
      const parts = file[fields.path].split('/');
      let node = root;
      for (let index = 1; index < parts.length - 1; index += 1) {
        const name = parts[index];
        if (!node.children.has(name)) {
          node.children.set(name, { name, path: parts.slice(0, index + 1).join('/'), children: new Map(), ownFiles: [] });
        }
        node = node.children.get(name);
      }
      node.ownFiles.push(file);
    });
    return root;
  }

  function collectNodeFiles(node) {
    return [...node.ownFiles, ...[...node.children.values()].flatMap(collectNodeFiles)];
  }

  function immediateFolderGroups(items, basePath = '') {
    const groups = new Map();
    items.forEach((file) => {
      const path = file[fields.path];
      const remainder = basePath && path.startsWith(`${basePath}/`) ? path.slice(basePath.length + 1) : path.replace(/^assets\//, '');
      const parts = remainder.split('/');
      const label = parts.length > 1 ? parts[0] : 'Files in this folder';
      if (!groups.has(label)) groups.set(label, []);
      groups.get(label).push(file);
    });
    return [...groups.entries()].map(([name, groupFiles]) => ({ name, files: groupFiles, bytes: sumBytes(groupFiles) })).sort((a, b) => b.files.length - a.files.length);
  }

  function createFileRow(file) {
    const row = document.createElement('div');
    row.className = 'file-row';
    const link = document.createElement('a');
    link.className = 'file-path';
    link.href = fileHref(file[fields.path]);
    link.target = '_blank';
    link.textContent = file[fields.path];
    const size = document.createElement('span');
    size.className = 'file-size';
    size.textContent = formatBytes(file[fields.bytes]);
    row.append(link, size);
    return row;
  }

  function showImageSelection(title, selectedFiles, basePath = '') {
    document.querySelectorAll('.category-button').forEach((button) => button.classList.toggle('active', button.dataset.category === title));
    const panel = el('image-selection');
    panel.replaceChildren();
    const header = document.createElement('div');
    header.className = 'selection-header';
    const heading = document.createElement('div');
    heading.className = 'selection-title';
    heading.textContent = title;
    const metric = document.createElement('div');
    metric.className = 'selection-metrics';
    const direct = selectedFiles.filter((file) => file[fields.image_state] === 'Direct runtime reference').length;
    metric.textContent = `${formatNumber(selectedFiles.length)} images · ${formatBytes(sumBytes(selectedFiles))}`;
    header.append(heading, metric);
    panel.appendChild(header);

    const note = document.createElement('p');
    note.className = 'selection-notice';
    note.textContent = `${formatNumber(direct)} have an exact path in runtime source or game data. ${formatNumber(selectedFiles.length - direct)} do not have a detected direct path and may still be loaded dynamically.`;
    panel.appendChild(note);

    const groups = immediateFolderGroups(selectedFiles, basePath).slice(0, 12);
    if (groups.length > 1) {
      const bars = document.createElement('div');
      bars.className = 'mini-bars';
      const maximum = Math.max(...groups.map((group) => group.files.length), 1);
      groups.forEach((group) => {
        const row = document.createElement('div');
        row.className = 'mini-bar';
        const label = document.createElement('span');
        label.textContent = group.name;
        const track = document.createElement('div');
        track.className = 'bar-track';
        const fill = document.createElement('div');
        fill.className = 'bar-fill';
        fill.style.width = `${(group.files.length / maximum) * 100}%`;
        track.appendChild(fill);
        const value = document.createElement('span');
        value.className = 'mini-bar-value';
        value.textContent = `${formatNumber(group.files.length)} files`;
        row.append(label, track, value);
        bars.appendChild(row);
      });
      panel.appendChild(bars);
    }

    const list = document.createElement('div');
    list.className = 'file-list';
    selectedFiles.slice().sort((a, b) => b[fields.bytes] - a[fields.bytes]).slice(0, 60).forEach((file) => list.appendChild(createFileRow(file)));
    panel.appendChild(list);
    if (selectedFiles.length > 60) {
      const limit = document.createElement('p');
      limit.className = 'selection-notice';
      limit.textContent = `Showing the 60 largest files in this selection. Use Find to locate a specific name.`;
      panel.appendChild(limit);
    }
  }

  function renderTreeNode(node, depth = 0) {
    const details = document.createElement('details');
    details.className = 'tree-node';
    details.open = depth < 2;
    const summary = document.createElement('summary');
    const button = document.createElement('button');
    button.className = 'tree-select';
    button.type = 'button';
    button.textContent = node.name;
    const nodeFiles = collectNodeFiles(node);
    button.addEventListener('click', (event) => {
      event.stopPropagation();
      showImageSelection(node.path, nodeFiles, node.path);
    });
    const value = document.createElement('span');
    value.className = 'tree-metric';
    value.textContent = `${formatNumber(nodeFiles.length)} · ${formatBytes(sumBytes(nodeFiles))}`;
    summary.append(button, value);
    details.appendChild(summary);
    [...node.children.values()].sort((a, b) => a.name.localeCompare(b.name)).forEach((child) => details.appendChild(renderTreeNode(child, depth + 1)));
    return details;
  }

  function renderImages() {
    imageCategories.forEach((category) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'category-button';
      button.dataset.category = category.name;
      button.style.setProperty('--category-color', category.color);
      const name = document.createElement('strong');
      name.textContent = category.name;
      const value = document.createElement('span');
      value.textContent = `${formatNumber(category.files.length)} images · ${formatBytes(sumBytes(category.files))}`;
      button.append(name, value);
      button.addEventListener('click', () => showImageSelection(category.name, category.files));
      el('image-categories').appendChild(button);
    });
    const tree = createImageTree();
    el('image-tree').appendChild(renderTreeNode(tree));
    const largestCategory = imageCategories.slice().sort((a, b) => b.files.length - a.files.length)[0];
    showImageSelection(largestCategory.name, largestCategory.files);
  }

  function metricBox(value, label) {
    const box = document.createElement('div');
    box.className = 'metric-box';
    const strong = document.createElement('strong');
    strong.textContent = value;
    const span = document.createElement('span');
    span.textContent = label;
    box.append(strong, span);
    return box;
  }

  function renderBuilds() {
    const buildFiles = files.filter((file) => file[fields.path].startsWith('builds/'));
    const buildArtifacts = buildFiles.filter((file) => ['.aab', '.apks', '.apk', '.zip', '.pck'].includes(file[fields.extension]));
    const byExtension = [
      ['.aab', 'Android App Bundles for Play upload'],
      ['.apks', 'Installable Android package sets for testing'],
      ['.zip', 'Archived release and upload folders']
    ];
    el('build-summary').appendChild(metricBox(formatBytes(sumBytes(buildFiles)), `${formatNumber(buildFiles.length)} files in builds`));
    byExtension.forEach(([extension, label]) => {
      const group = buildFiles.filter((file) => file[fields.extension] === extension);
      el('build-summary').appendChild(metricBox(formatBytes(sumBytes(group)), `${formatNumber(group.length)} ${label}`));
    });

    const months = new Map();
    buildFiles.forEach((file) => {
      const date = file[fields.modified];
      const key = date < '2000-01-01' ? 'Extracted' : date.slice(0, 7);
      if (!months.has(key)) months.set(key, []);
      months.get(key).push(file);
    });
    const monthRows = [...months.entries()].map(([month, monthFiles]) => ({ month, files: monthFiles, bytes: sumBytes(monthFiles) })).sort((a, b) => b.month.localeCompare(a.month));
    const maximum = Math.max(...monthRows.map((row) => row.bytes), 1);
    monthRows.forEach((month) => {
      const row = document.createElement('div');
      row.className = 'bar-row';
      const label = document.createElement('span');
      label.textContent = month.month;
      const track = document.createElement('div');
      track.className = 'bar-track';
      const fill = document.createElement('div');
      fill.className = 'bar-fill';
      fill.style.width = `${(month.bytes / maximum) * 100}%`;
      track.appendChild(fill);
      const value = document.createElement('span');
      value.className = 'bar-value';
      value.textContent = `${formatBytes(month.bytes)} · ${formatNumber(month.files.length)}`;
      row.append(label, track, value);
      el('build-timeline').appendChild(row);
    });

    buildArtifacts.sort((a, b) => b[fields.bytes] - a[fields.bytes]).slice(0, 20).forEach((file) => el('largest-builds').appendChild(createFileRow(file)));
  }

  const cleanupDefinitions = [
    { id: 'builds', title: '1. Saved builds and release packages', paths: 'builds/', status: 'Review versions', statusClass: 'review', description: 'Keep the current release and any versions needed for rollback. Older Android bundles, test packages, web exports, ZIP archives, and extracted copies are the largest cleanup opportunity.', test: (file) => isPath(file, 'builds') },
    { id: 'agent-temp', title: '2. Temporary agent work', paths: '.codex-tmp/', status: 'Inspect worktrees first', statusClass: 'review', description: 'Contains task worktrees, screenshots, test projects, extracted packages, and logs. Confirm that no unfinished work is needed before removing a worktree or task folder.', test: (file) => isPath(file, '.codex-tmp') },
    { id: 'godot-cache', title: '3. Godot imported texture cache', paths: '.godot/imported/', status: 'Regenerable', statusClass: '', description: 'Godot recreates these imported textures from the source assets. Removing this folder saves space and causes a full asset reimport on the next project launch.', test: (file) => file[fields.path].startsWith('.godot/imported/') },
    { id: 'generated-media', title: '4. Temporary image-generation batches', paths: 'tmp/imagegen/ · output/imagegen/', status: 'Review generated art', statusClass: 'review', description: 'Generated source batches and review output can contain useful art alongside rejected or superseded versions. Review the images before removing a batch.', test: (file) => /^(tmp|output)\/imagegen\//.test(file[fields.path]) },
    { id: 'android-build', title: '5. Android generated build output', paths: 'android/build/', status: 'Regenerable', statusClass: '', description: 'Gradle produces this folder during Android export. It is not authored game source and the release process can rebuild it.', test: (file) => file[fields.path].startsWith('android/build/') }
  ].map((definition) => {
    const groupFiles = files.filter(definition.test);
    return { ...definition, items: groupFiles, ...metrics(groupFiles) };
  });

  const selectedCleanup = new Set(JSON.parse(localStorage.getItem('idle-elite-atlas-cleanup-review') || '[]'));

  function renderCleanup() {
    cleanupDefinitions.forEach((group) => {
      const row = document.createElement('label');
      row.className = 'cleanup-row';
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.checked = selectedCleanup.has(group.id);
      checkbox.setAttribute('aria-label', `Add ${group.title} to cleanup review`);
      checkbox.addEventListener('change', () => {
        if (checkbox.checked) selectedCleanup.add(group.id); else selectedCleanup.delete(group.id);
        localStorage.setItem('idle-elite-atlas-cleanup-review', JSON.stringify([...selectedCleanup]));
      });
      const body = document.createElement('div');
      const title = document.createElement('div');
      title.className = 'cleanup-title';
      title.textContent = group.title;
      const paths = document.createElement('div');
      paths.className = 'cleanup-paths';
      paths.textContent = group.paths;
      const description = document.createElement('p');
      description.className = 'cleanup-description';
      description.textContent = group.description;
      const status = document.createElement('span');
      status.className = `status ${group.statusClass}`.trim();
      status.textContent = group.status;
      body.append(title, paths, description, status);
      const value = document.createElement('div');
      value.className = 'cleanup-metric';
      const size = document.createElement('strong');
      size.textContent = formatBytes(group.bytes);
      const count = document.createElement('span');
      count.textContent = `${formatNumber(group.files)} files`;
      value.append(size, count);
      row.append(checkbox, body, value);
      el('cleanup-groups').appendChild(row);
    });
  }

  function exportCleanupReview() {
    const selected = cleanupDefinitions.filter((group) => selectedCleanup.has(group.id));
    const rows = [['group', 'paths', 'files', 'bytes', 'status'], ...selected.map((group) => [group.title, group.paths, group.files, group.bytes, group.status])];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\r\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'idle-elite-cleanup-review.csv';
    link.click();
    URL.revokeObjectURL(url);
  }

  const htmlFiles = files.filter((file) => ['.html', '.htm'].includes(file[fields.extension]));
  const planningGroups = [
    { id: 'current', label: 'Current docs', description: 'HTML pages stored directly in docs', color: '#26955f', test: (file) => file[fields.path].startsWith('docs/') },
    { id: 'temporary', label: 'Temporary copies', description: 'HTML pages inside .codex-tmp', color: '#e47b23', test: (file) => file[fields.path].startsWith('.codex-tmp/') },
    { id: 'support', label: 'Generated and support', description: 'Build exports, reports, public pages, and atlas files', color: '#3979c9', test: (file) => !file[fields.path].startsWith('docs/') && !file[fields.path].startsWith('.codex-tmp/') }
  ].map((group) => {
    const items = htmlFiles.filter(group.test);
    return { ...group, items, ...metrics(items) };
  });
  let activePlanningGroup = 'current';
  const planningReviewKey = 'idle-elite-planning-html-review';
  const planningReview = JSON.parse(localStorage.getItem(planningReviewKey) || '{}');

  function planningDisplayName(path) {
    const filename = path.split('/').pop().replace(/\.html?$/i, '');
    return filename.replace(/[-_]+/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
  }

  function renderPlanningSummary() {
    planningGroups.forEach((group) => {
      el('planning-summary').appendChild(metricBox(formatNumber(group.files), `${group.label} · ${formatBytes(group.bytes)}`));
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `planning-filter${group.id === activePlanningGroup ? ' active' : ''}`;
      button.dataset.group = group.id;
      button.textContent = `${group.label} (${formatNumber(group.files)})`;
      button.addEventListener('click', () => {
        activePlanningGroup = group.id;
        el('planning-filters').querySelectorAll('.planning-filter').forEach((filter) => filter.classList.toggle('active', filter.dataset.group === group.id));
        renderPlanningFiles();
      });
      el('planning-filters').appendChild(button);
    });
    const allButton = document.createElement('button');
    allButton.type = 'button';
    allButton.className = 'planning-filter';
    allButton.dataset.group = 'all';
    allButton.textContent = `All HTML (${formatNumber(htmlFiles.length)})`;
    allButton.addEventListener('click', () => {
      activePlanningGroup = 'all';
      el('planning-filters').querySelectorAll('.planning-filter').forEach((filter) => filter.classList.toggle('active', filter.dataset.group === 'all'));
      renderPlanningFiles();
    });
    el('planning-filters').appendChild(allButton);
  }

  function renderPlanningFiles() {
    const target = el('planning-files');
    target.replaceChildren();
    const query = el('planning-search').value.trim().toLowerCase();
    const group = planningGroups.find((item) => item.id === activePlanningGroup);
    const source = group ? group.items : htmlFiles;
    const visible = source.filter((file) => file[fields.path].toLowerCase().includes(query)).sort((a, b) => b[fields.modified].localeCompare(a[fields.modified]) || a[fields.path].localeCompare(b[fields.path]));
    el('planning-count').textContent = `${formatNumber(visible.length)} files shown. Opening a file does not change it.`;
    visible.forEach((file) => {
      const path = file[fields.path];
      const row = document.createElement('div');
      const statusValue = planningReview[path] || 'unreviewed';
      row.className = 'planning-row';
      row.dataset.status = statusValue;
      const body = document.createElement('div');
      const link = document.createElement('a');
      link.className = 'planning-name';
      link.href = fileHref(path);
      link.target = '_blank';
      link.rel = 'noopener';
      link.textContent = planningDisplayName(path);
      const pathLine = document.createElement('div');
      pathLine.className = 'planning-path';
      pathLine.textContent = path;
      const meta = document.createElement('div');
      meta.className = 'planning-meta';
      meta.textContent = `${file[fields.modified]} · ${formatBytes(file[fields.bytes])}`;
      body.append(link, pathLine, meta);
      const select = document.createElement('select');
      select.className = 'planning-status';
      select.setAttribute('aria-label', `Review status for ${path}`);
      [['unreviewed', 'Unreviewed'], ['keep', 'Keep'], ['archive', 'Archive'], ['delete', 'Delete candidate']].forEach(([value, label]) => {
        const option = document.createElement('option');
        option.value = value;
        option.textContent = label;
        select.appendChild(option);
      });
      select.value = statusValue;
      select.addEventListener('change', () => {
        if (select.value === 'unreviewed') delete planningReview[path]; else planningReview[path] = select.value;
        row.dataset.status = select.value;
        localStorage.setItem(planningReviewKey, JSON.stringify(planningReview));
      });
      row.append(body, select);
      target.appendChild(row);
    });
  }

  function exportPlanningReview() {
    const rows = [['path', 'review_status', 'modified', 'bytes'], ...htmlFiles.map((file) => [file[fields.path], planningReview[file[fields.path]] || 'unreviewed', file[fields.modified], file[fields.bytes]])];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\r\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'idle-elite-planning-html-review.csv';
    link.click();
    URL.revokeObjectURL(url);
  }

  function renderPlayStore() {
    const graphics = playStoreFiles.filter((file) => ['.png', '.jpg', '.jpeg'].includes(file[fields.extension]));
    const documents = playStoreFiles.filter((file) => file[fields.extension] === '.md');
    const support = playStoreFiles.filter((file) => !graphics.includes(file) && !documents.includes(file));
    el('play-store-explanation').textContent = `${formatNumber(playStoreFiles.length)} files means ${formatNumber(graphics.length)} listing images and screenshots, ${formatNumber(documents.length)} release or policy documents, and ${formatNumber(support.length)} support marker. The folder uses ${formatBytes(sumBytes(playStoreFiles))}.`;
    el('play-store-groups').append(
      metricBox(formatNumber(graphics.length), `${formatBytes(sumBytes(graphics))} listing graphics and screenshots`),
      metricBox(formatNumber(documents.length), `${formatBytes(sumBytes(documents))} release and policy documents`),
      metricBox(formatNumber(support.length), `${formatBytes(sumBytes(support))} support marker`),
      metricBox(formatBytes(sumBytes(playStoreFiles)), 'Total Play Store source material')
    );
    playStoreFiles.slice().sort((a, b) => a[fields.path].localeCompare(b[fields.path])).forEach((file) => el('play-store-files').appendChild(createFileRow(file)));
  }

  function renderSearch(query) {
    const target = el('search-results');
    target.replaceChildren();
    const normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      el('search-count').textContent = '';
      return;
    }
    const matches = files.filter((file) => file[fields.path].toLowerCase().includes(normalized));
    el('search-count').textContent = `${formatNumber(matches.length)} matching files. Showing up to 100.`;
    matches.slice().sort((a, b) => b[fields.bytes] - a[fields.bytes]).slice(0, 100).forEach((file) => target.appendChild(createFileRow(file)));
  }

  el('export-review').addEventListener('click', exportCleanupReview);
  el('export-planning-review').addEventListener('click', exportPlanningReview);
  el('planning-search').addEventListener('input', renderPlanningFiles);
  el('search').addEventListener('input', (event) => renderSearch(event.target.value));
  el('treemap-back').addEventListener('click', () => {
    const parts = currentTreemapPath.split('/').filter(Boolean);
    parts.pop();
    renderTreemap(parts.join('/'));
  });
  new ResizeObserver(() => {
    const map = el('treemap');
    const width = Math.max(map.clientWidth, 320);
    const height = map.clientHeight;
    if (Math.abs(width - lastTreemapWidth) < 1 && Math.abs(height - lastTreemapHeight) < 1) return;
    clearTimeout(treemapResizeTimer);
    treemapResizeTimer = setTimeout(() => renderTreemap(), 100);
  }).observe(el('treemap'));
  renderSummary();
  renderStorage();
  renderImages();
  renderPlanningSummary();
  renderPlanningFiles();
  renderBuilds();
  renderCleanup();
  renderPlayStore();
})();
