param(
    [int]$Port = 8123,
    [double]$MaxFrameMs = 50.0,
    [double]$MaxRafMs = 50.0,
    [switch]$RequireAllMounted,
    [int]$MinScrollDelta = 1000,
    [int]$RepeatCount = 3,
    [string]$Ablation = "",
    [string]$NodePath = "",
    [string]$NodeModulesPath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$webRoot = Join-Path $projectRoot "builds\web"
$tmpDir = Join-Path $projectRoot ".codex-tmp"
$probeScript = Join-Path $tmpDir "fishing-web-touch-scroll-probe.mjs"

if ([string]::IsNullOrWhiteSpace($NodePath)) {
    $bundledNode = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
    if (Test-Path -LiteralPath $bundledNode) {
        $NodePath = $bundledNode
    } else {
        $NodePath = "node"
    }
}

if ([string]::IsNullOrWhiteSpace($NodeModulesPath)) {
    $bundledNodeModules = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules"
    if (Test-Path -LiteralPath $bundledNodeModules) {
        $NodeModulesPath = $bundledNodeModules
    }
}

Assert-True (Test-Path -LiteralPath $webRoot) "Missing builds\web. Run scripts\package-itch-web.ps1 first."
Assert-True (Test-Path -LiteralPath (Join-Path $webRoot "index.html")) "Missing builds\web\index.html. Run scripts\package-itch-web.ps1 first."
if (-not (Test-Path -LiteralPath $tmpDir)) {
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
}

$webRootForJs = $webRoot.Replace("\", "/")
$nodeModulesForJs = $NodeModulesPath.Replace("\", "/")

@"
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const projectRequire = createRequire(import.meta.url);
const webRoot = '$webRootForJs';
const nodeModulesPath = '$nodeModulesForJs';
const port = $Port;
const maxFrameMs = $MaxFrameMs;
const maxRafMs = $MaxRafMs;
const requireAllMounted = '$RequireAllMounted' === 'True';
const minScrollDelta = $MinScrollDelta;
const repeatCount = $RepeatCount;
const ablation = '$Ablation';
const query = '?codex_fishing_perf=1' + (ablation ? '&fishing_ablation=' + encodeURIComponent(ablation) : '');
const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon'
};

async function importPlaywright() {
  try {
    return await import('playwright-core');
  } catch (firstError) {
    try {
      return await import('playwright');
    } catch (_secondError) {
    }
    if (!nodeModulesPath) {
      throw firstError;
    }
    const packageCandidates = [
      path.join(nodeModulesPath, 'playwright-core'),
      path.join(nodeModulesPath, 'playwright'),
      path.join(nodeModulesPath, '.pnpm', 'node_modules', 'playwright-core'),
      path.join(nodeModulesPath, '.pnpm', 'node_modules', 'playwright')
    ];
    for (const packagePath of packageCandidates) {
      try {
        return projectRequire(packagePath);
      } catch (_error) {
      }
    }
    throw firstError;
  }
}

function serveFile(req, res) {
  try {
    const parsed = new URL(req.url || '/', 'http://127.0.0.1');
    let pathname = decodeURIComponent(parsed.pathname || '/');
    if (pathname === '/') {
      pathname = '/index.html';
    }
    const requested = path.normalize(path.join(webRoot, pathname));
    if (!requested.startsWith(path.normalize(webRoot))) {
      res.writeHead(403);
      res.end('forbidden');
      return;
    }
    fs.stat(requested, (err, stat) => {
      if (err || !stat.isFile()) {
        res.writeHead(404);
        res.end('not found');
        return;
      }
      res.writeHead(200, {
        'Content-Type': mime[path.extname(requested).toLowerCase()] || 'application/octet-stream',
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cache-Control': 'no-store'
      });
      fs.createReadStream(requested).pipe(res);
    });
  } catch (error) {
    res.writeHead(500);
    res.end(String(error && error.stack || error));
  }
}

const server = http.createServer(serveFile);
await new Promise(resolve => server.listen(port, '127.0.0.1', resolve));

let browser = null;
try {
  const { chromium } = await importPlaywright();
  const launchErrors = [];
  for (const options of [
    { channel: 'chrome', headless: true },
    { channel: 'msedge', headless: true },
    { executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true }
  ]) {
    try {
      browser = await chromium.launch(options);
      break;
    } catch (error) {
      launchErrors.push(String(error && error.message || error));
    }
  }
  if (!browser) {
    throw new Error('Unable to launch Chromium: ' + launchErrors.join('\n'));
  }

  async function startRafProbe(page) {
    await page.evaluate(() => {
    window.__rafProbe = { samples: [], last: performance.now(), active: true, phase: 'drag' };
    function tick(t) {
      const probe = window.__rafProbe;
      if (!probe || !probe.active) {
        return;
      }
      probe.samples.push({ dt: t - probe.last, phase: probe.phase || 'unknown' });
      probe.last = t;
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  });
  }

  async function markRafProbePhase(page, phase) {
    await page.evaluate(nextPhase => {
      if (window.__rafProbe) {
        window.__rafProbe.phase = nextPhase;
      }
    }, phase);
  }

  async function stopRafProbe(page) {
    return await page.evaluate(() => {
      const probe = window.__rafProbe;
      if (!probe) {
        return [];
      }
      probe.active = false;
      return probe.samples.slice();
    });
  }

  function summarizeRaf(samples, phase = '') {
    const values = samples
      .map((sample, index) => ({
        index,
        dt: Number(typeof sample === 'number' ? sample : sample.dt || 0),
        phase: String(typeof sample === 'number' ? 'unknown' : sample.phase || 'unknown')
      }))
      .filter(sample => !phase || sample.phase === phase);
    if (!values.length) {
      return { max: 0, over50: 0, index: -1, phase };
    }
    let worst = values[0];
    for (const sample of values) {
      if (sample.dt > worst.dt) {
        worst = sample;
      }
    }
    return {
      max: worst.dt,
      over50: values.filter(sample => sample.dt > 50).length,
      index: worst.index,
      phase: worst.phase
    };
  }

  async function runTouchProbe(page, client, box) {
    const x = box.x + box.width * 0.5;
    const y0 = box.y + box.height * 0.76;
    await client.send('Input.dispatchTouchEvent', {
      type: 'touchStart',
      touchPoints: [{ x, y: y0, radiusX: 8, radiusY: 8, id: 1 }]
    });
    for (let index = 1; index <= 260; index++) {
      const y = y0 - 980 * (index / 260);
      await client.send('Input.dispatchTouchEvent', {
        type: 'touchMove',
        touchPoints: [{ x, y, radiusX: 8, radiusY: 8, id: 1 }]
      });
      await page.waitForTimeout(2);
    }
    await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  }

  async function runMouseDragProbe(page, client, box) {
    const x = box.x + box.width * 0.5;
    const y0 = box.y + box.height * 0.76;
    await client.send('Input.dispatchMouseEvent', {
      type: 'mousePressed',
      x,
      y: y0,
      button: 'left',
      buttons: 1,
      clickCount: 1
    });
    for (let index = 1; index <= 260; index++) {
      const y = y0 - 980 * (index / 260);
      await client.send('Input.dispatchMouseEvent', {
        type: 'mouseMoved',
        x,
        y,
        button: 'left',
        buttons: 1
      });
      await page.waitForTimeout(2);
    }
    await client.send('Input.dispatchMouseEvent', {
      type: 'mouseReleased',
      x,
      y: y0 - 980,
      button: 'left',
      buttons: 0,
      clickCount: 1
    });
  }

  async function runScenario(label, contextOptions, dragKind, iteration) {
    const context = await browser.newContext(contextOptions);
    const page = await context.newPage();
    await page.goto('http://127.0.0.1:' + port + '/index.html' + query, {
      waitUntil: 'domcontentloaded',
      timeout: 60000
    });
    await page.waitForFunction(
      () => window.__idleEliteFishingPerf && window.__idleEliteFishingPerf.ready === true,
      null,
      { timeout: 90000 }
    );
    await page.waitForTimeout(2500);

    const before = await page.evaluate(() => ({ ...window.__idleEliteFishingPerf }));
    const beforeFrame = Number(before.frame || 0);
    const box = await page.locator('canvas').boundingBox();
    if (!box) {
      throw new Error('No canvas found for ' + label);
    }
    const client = await context.newCDPSession(page);
    await startRafProbe(page);
    if (dragKind === 'touch') {
      await runTouchProbe(page, client, box);
    } else {
      await runMouseDragProbe(page, client, box);
    }
    await markRafProbePhase(page, 'settle');
    await page.waitForFunction(
      ({ minScrollDelta, beforeFrame }) => {
        const perf = window.__idleEliteFishingPerf;
        if (!perf || !perf.scrollPerfLast) {
          return false;
        }
        const last = perf.scrollPerfLast;
        return (
          last.reason === 'settled'
          && Number(last.scrollDelta || 0) >= minScrollDelta
          && Number(perf.frame || 0) > beforeFrame
        );
      },
      { minScrollDelta, beforeFrame },
      { timeout: 10000 }
    );
    const raf = await stopRafProbe(page);
    const after = await page.evaluate(() => ({ ...window.__idleEliteFishingPerf }));
    await context.close();

    const scrollDelta = Number(after.scroll || 0) - Number(before.scroll || 0);
    const scrollPerf = after.scrollPerfLast || {};
    const rafSummary = summarizeRaf(raf);
    const rafDragSummary = summarizeRaf(raf, 'drag');
    const rafSettleSummary = summarizeRaf(raf, 'settle');
    const result = {
      label: label + '-' + iteration,
      scenario: label,
      iteration,
      ablation,
      status: 'ok',
      scrollDelta,
      mounted: Number(after.mounted || 0),
      plan: Number(after.plan || 0),
      visiblePlaceholders: Boolean(after.visiblePlaceholders),
      visibleCulled: Number(after.visibleCulled || 0),
      rendered: Number((after.renderCull && after.renderCull.rendered) || 0),
      culled: Number((after.renderCull && after.renderCull.culled) || 0),
      maxFrameMsec: Number(scrollPerf.maxFrameMsec || 0),
      over50: Number(scrollPerf.over50 || 0),
      godotScrollDelta: Number(scrollPerf.scrollDelta || 0),
      rafMaxMsec: rafSummary.max,
      rafOver50: rafSummary.over50,
      rafWorstIndex: rafSummary.index,
      rafWorstPhase: rafSummary.phase,
      rafDragMaxMsec: rafDragSummary.max,
      rafDragOver50: rafDragSummary.over50,
      rafSettleMaxMsec: rafSettleSummary.max,
      rafSettleOver50: rafSettleSummary.over50
    };

    if (result.plan <= 0 || result.mounted <= 0) {
      throw new Error(label + ': expected mounted fishing modules, got ' + result.mounted + '/' + result.plan);
    }
    if (requireAllMounted && result.mounted !== result.plan) {
      throw new Error(label + ': expected all fishing modules mounted for the full-page stress path, got ' + result.mounted + '/' + result.plan);
    }
    if (result.visiblePlaceholders) {
      throw new Error(label + ': fishing web probe saw visible placeholders');
    }
    if (result.visibleCulled !== 0) {
      throw new Error(label + ': fishing web probe saw ' + result.visibleCulled + ' culled modules overlapping the viewport');
    }
    if (result.scrollDelta < minScrollDelta || result.godotScrollDelta < minScrollDelta) {
      throw new Error(label + ': expected scroll delta >= ' + minScrollDelta + ', got browser=' + result.scrollDelta + ' godot=' + result.godotScrollDelta);
    }
    if (result.maxFrameMsec > maxFrameMs) {
      throw new Error(label + ': Godot max frame ' + result.maxFrameMsec + 'ms exceeded ' + maxFrameMs + 'ms. details=' + JSON.stringify(result));
    }
    if (result.over50 > 0) {
      throw new Error(label + ': Godot reported ' + result.over50 + ' frames over 50ms. details=' + JSON.stringify(result));
    }
    if (result.rafMaxMsec > maxRafMs) {
      throw new Error(label + ': browser RAF max frame ' + result.rafMaxMsec + 'ms exceeded ' + maxRafMs + 'ms. details=' + JSON.stringify(result));
    }
    if (result.rafOver50 > 0) {
      throw new Error(label + ': browser RAF reported ' + result.rafOver50 + ' frames over 50ms. details=' + JSON.stringify(result));
    }
    return result;
  }

  const results = [];
  for (let iteration = 1; iteration <= repeatCount; iteration++) {
    results.push(await runScenario('mobile-touch-drag', {
      viewport: { width: 627, height: 1115 },
      deviceScaleFactor: 2,
      isMobile: true,
      hasTouch: true
    }, 'touch', iteration));
    results.push(await runScenario('desktop-mouse-drag', {
      viewport: { width: 627, height: 1115 },
      deviceScaleFactor: 1,
      isMobile: false,
      hasTouch: false
    }, 'mouse', iteration));
  }
  const worstGodot = results.reduce((worst, result) => Math.max(worst, result.maxFrameMsec), 0);
  const worstRaf = results.reduce((worst, result) => Math.max(worst, result.rafMaxMsec), 0);

  console.log(JSON.stringify({
    status: 'ok',
    repeatCount,
    worstGodotFrameMsec: worstGodot,
    worstRafMsec: worstRaf,
    results
  }, null, 2));
} finally {
  if (browser) {
    await browser.close();
  }
  await new Promise(resolve => server.close(resolve));
}
"@ | Set-Content -LiteralPath $probeScript -Encoding UTF8

$env:NODE_PATH = $NodeModulesPath
& $NodePath $probeScript
if ($LASTEXITCODE -ne 0) {
    throw "Fishing web touch scroll probe failed with exit code $LASTEXITCODE."
}

Write-Host "fishing-web-touch-scroll-ok"
