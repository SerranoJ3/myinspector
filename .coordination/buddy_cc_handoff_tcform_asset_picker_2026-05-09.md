# CC Handoff — Tapcard Form Asset Picker Polish

**Author:** Buddy
**Cut:** 2026-05-09 ~19:55 EDT
**Audience:** CC (Claude Code on Asus)
**Context:** Jorge wants the tapcard form modal pitch-worthy by tonight. Buddy is blitzing the diagram scaffolding (MAIN/CL/PL/compass/house). CC, you take the asset picker.

---

## ⚠ COORDINATION GATE

**Buddy is actively writing to `index.html` — diagram editor scope (lines ~7000-7400 plus a small zone in `diagramRender()`).** Your scope below is far enough away (line ~1718-1722 HTML + line ~7140-ish JS) that we won't physically collide.

**Sequencing rules:**
1. Run `git fetch origin demo-banner && git pull --rebase origin demo-banner` BEFORE you start. Buddy may have already pushed Sprint A1 by the time you read this.
2. Before each edit, run `git diff HEAD -- index.html` to check for uncommitted Buddy state. If there's uncommitted state, halt and ping Jorge in chat.
3. Commit + push as soon as your scope is done. Don't sit on a branch — Jorge wants this fast.
4. Branch: `demo-banner` (active demo branch). Fast-forward to `mi-demo-seed` after demo-banner is green.

---

## SCOPE — 2 deliverables, both small

### Deliverable 1: Rename "Valve" → "MP" in asset picker

**File:** `index.html`

**Find/replace 1 — picker button HTML (~line 1719):**
```html
<button type="button" onclick="diagramArmAsset('valve')">Valve</button>
```
→
```html
<button type="button" onclick="diagramArmAsset('meterpit')">MP</button>
```

**Find/replace 2 — `diagramArmAsset` labels object (~line 7140):**
```js
const labels = { watermain_tap:'WM Tap', valve:'Valve', hydrant:'Hydrant', other:'Other' };
```
→
```js
const labels = { watermain_tap:'WM Tap', meterpit:'MP', hydrant:'Hydrant', pole:'P#', other:'Other' };
```
(Note: also adds the `pole` label here in advance for Deliverable 2; don't re-touch this line.)

**Find/replace 3 — `assetColors` map in `diagramRender` (~line 7320):**
```js
const assetColors = { watermain_tap:'#16a34a', valve:'#dc2626', hydrant:'#eab308', other:'#94a3b8' };
```
→
```js
const assetColors = { watermain_tap:'#16a34a', meterpit:'#dc2626', hydrant:'#eab308', pole:'#a78bfa', other:'#94a3b8' };
```

**Find/replace 4 — `assetLetter` map in `diagramRender` (~line 7321):**
```js
const assetLetter = { watermain_tap:'T', valve:'V', hydrant:'H', other:'?' };
```
→
```js
const assetLetter = { watermain_tap:'T', meterpit:'M', hydrant:'H', pole:'P', other:'?' };
```

**Find/replace 5 — `diagramReadOnlyEmbed` `assetColors` (~line 7405):**
```js
const assetColors = { watermain_tap:'#16a34a', valve:'#dc2626', hydrant:'#eab308', other:'#94a3b8' };
```
→
```js
const assetColors = { watermain_tap:'#16a34a', meterpit:'#dc2626', hydrant:'#eab308', pole:'#a78bfa', other:'#94a3b8' };
```

**Find/replace 6 — `diagramReadOnlyEmbed` `assetLetter` (~line 7406):**
```js
const assetLetter = { watermain_tap:'T', valve:'V', hydrant:'H', other:'?' };
```
→
```js
const assetLetter = { watermain_tap:'T', meterpit:'M', hydrant:'H', pole:'P', other:'?' };
```

**Backward compat note:** old saved diagrams may have `type:'valve'` in jsonb. Those will render as `?` in grey (the `other` fallback) post-rename. Acceptable — only 1 demo property has a saved tapcard right now and it has no diagram yet (per pre-flight today).

---

### Deliverable 2: Add `P#` (telephone pole) asset type

The `pole` type is already declared in the labels/colors/letter maps via Deliverable 1. You just need:

**Find/replace 7 — picker button HTML (right after the renamed MP button at ~line 1719):**

Find:
```html
<button type="button" onclick="diagramArmAsset('meterpit')">MP</button>
              <button type="button" onclick="diagramArmAsset('hydrant')">Hydrant</button>
```
→
```html
<button type="button" onclick="diagramArmAsset('meterpit')">MP</button>
              <button type="button" onclick="diagramArmAsset('pole')">P#</button>
              <button type="button" onclick="diagramArmAsset('hydrant')">Hydrant</button>
```

**Find/replace 8 — pole-specific number prompt in `_diagramPointerDown`** (~line 7185, inside the `if(diagramArmedAssetType){` block):

Find:
```js
    if(diagramArmedAssetType){
    diagramSnapshot();
    const x = _diagramSnap(pt.x), y = _diagramSnap(pt.y);
    const id = `asset-${Date.now()}-${diagramState.assets.length}`;
    const labels = { watermain_tap:'WM Tap', valve:'Valve', hydrant:'Hydrant', other:'Asset' };
    const sameTypeCount = diagramState.assets.filter(a => a.type === diagramArmedAssetType).length + 1;
    diagramState.assets.push({ id, type: diagramArmedAssetType, x, y, label: `${labels[diagramArmedAssetType] || 'Asset'} ${sameTypeCount}` });
    diagramSelectedId = id;
    diagramSetStatus(`Placed ${labels[diagramArmedAssetType]} ${sameTypeCount}`);
    diagramArmedAssetType = null;
    diagramRender();
    return;
  }
```

Replace with:
```js
    if(diagramArmedAssetType){
    diagramSnapshot();
    const x = _diagramSnap(pt.x), y = _diagramSnap(pt.y);
    const id = `asset-${Date.now()}-${diagramState.assets.length}`;
    const labels = { watermain_tap:'WM Tap', meterpit:'MP', hydrant:'Hydrant', pole:'P#', other:'Asset' };
    const sameTypeCount = diagramState.assets.filter(a => a.type === diagramArmedAssetType).length + 1;
    let label;
    if(diagramArmedAssetType === 'pole'){
      // Inspector reads the pole number off the actual pole when placing
      const poleNum = prompt('Pole number? (read off the pole tag)');
      if(poleNum === null){ // user cancelled
        diagramArmedAssetType = null;
        diagramSetStatus('Pole placement cancelled');
        return;
      }
      label = `P${(poleNum || '').trim() || '?'}`;
    } else {
      label = `${labels[diagramArmedAssetType] || 'Asset'} ${sameTypeCount}`;
    }
    diagramState.assets.push({ id, type: diagramArmedAssetType, x, y, label });
    diagramSelectedId = id;
    diagramSetStatus(`Placed ${label}`);
    diagramArmedAssetType = null;
    diagramRender();
    return;
  }
```

---

## Acceptance criteria

After your commit, on Vercel preview:
1. Open tapcard form on a demo property → click `+ Asset` → picker shows: WM Tap, **MP** (was Valve), **P#** (new), Hydrant, Other
2. Click MP → tap canvas → marker appears with red square + "M" inside, label "MP 1" above
3. Click P# → tap canvas → prompt asks "Pole number?" → type "47" → marker appears purple square + "P" inside, label "P47"
4. Read-only embed of saved diagrams (in property detail submissions list) renders MP/P# correctly

## Commit message template

```
feat(MI-101-tcform-asset-picker): rename Valve→MP + add P# (Pole) asset type

- Asset picker renames "Valve" to "MP" (meterpit) per Jorge field-naming convention
- New "P#" (telephone pole) asset type with number prompt on placement
- Inspector reads pole number off the pole tag when placing
- Pole asset color: #a78bfa (purple), letter: 'P', label: 'P{number}'
- assetColors / assetLetter / labels maps updated in both diagramRender + diagramReadOnlyEmbed (+1 valve→meterpit migration concern: old saved diagrams render as '?' grey fallback)

Per Jorge directive 5/9/26 ~19:50 EDT: "valve should read meterpit or mp",
"why isnt P# a choice in the dropscreen meaning telephone pole #". Coordinated
with Buddy diagram-scaffolding sprint via .coordination/buddy_cc_handoff_tcform_asset_picker_2026-05-09.md.
```

## Estimated time

15-25 minutes for an experienced session. Halt if numstat exceeds ~30/-15 — that's a sign you're touching code outside this scope.

---

🐈
