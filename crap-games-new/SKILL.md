---
name: crap-games-new
description: Start a new Godot web game for crap.games, from naming through the crap-games Copier template, the template fixes it still needs, an optional Blender art pipeline, a design doc, and deployment to <slug>.crap.games with the game registered on all.crap.games. Use whenever the user wants to make, start, scaffold or deploy a new crap.games game, a new game "like snail sim / fuel / graffiti pets", or asks how crap.games games are set up, even if they don't say "crap.games".
---

# New crap.games game

crap.games hosts small Godot web games, one per subdomain, listed at all.crap.games.

Reference projects (local copies, also on GitHub under `mcfredrick/`):

| Project | Local path | Why look at it |
| --- | --- | --- |
| crap_games (registry + shared workflows) | `~/Crap Games/crap_games` | `games/registry.json`, `.github/workflows/deploy_godot_web.yml`, `update-registry.yml` |
| crap-games-template (Copier) | `~/Crap Games/crap-games-template` | What a new game starts from |
| Snail Simulator, Fuel | `~/Crap Games/snail-simulator`, `~/Crap Games/fuel` | Deployed games built from the template |
| Graffiti Pets | `~/Code/cloddy-game-crap` | Blender-generated art pipeline (parts kit, sockets, toon shaders) |
| Starship Tinkerer | `~/Code/starship-tinkerer` | Template + Blender pipeline + design doc together |

## 1. Shape the idea

Before building anything, settle these with the user (AskUserQuestion, recommended option first):

- **Name and subdomain.** The subdomain becomes the repo name too (`mcfredrick/<subdomain>`). If the
  game could start a series, put the specific word first (`starship-tinkerer`, later
  `clock-tinkerer`).
- **Art approach.** Real-time 3D from a Blender kit, Blender-rendered 2D sprites, or a mix. Web
  export means the Compatibility renderer, so keep shaders simple (cel bands and an inverted-hull
  outline work well).
- **Core verbs and anything optional.** Which activities are required, and which are side content.
- **First milestone.** Usually a design doc plus scaffold, then a vertical slice.

## 2. Scaffold from the template

```bash
mkdir -p ~/Code/<subdomain> && cd ~/Code/<subdomain>
copier copy --trust --defaults --vcs-ref HEAD \
  -d game_name="<Name>" -d subdomain="<subdomain>" -d description="<one or two sentences>" \
  -d category="<puzzle|action|strategy|simulation|arcade|casual|educational|other>" \
  -d tags="<comma list>" -d version="0.1.0" \
  gh:mcfredrick/crap-games-template .
```

Use the `gh:` source so `.copier-answers.yml` points somewhere `copier update --trust` works from
any machine. `author` defaults to `ttam` and `repo_url` to `mcfredrick/<subdomain>`.

The user owns the template, the registry and the shared workflows. When a template bug turns up, fix
it in `~/Crap Games/crap-games-template`, test it by rendering a throwaway game into the scratchpad
and running its `export_web.sh`, push, then `copier update --trust` the game. Patch a game by hand
only for changes specific to that game.

Verify with `godot --headless --path godot_web_game --import` and then `./export_web.sh`. The build
should contain `index.html`, `index.wasm`, `index.pck`, `index.icon.png` and `js/`.

## 3. Project docs

- `CLAUDE.md`: layout, commands, content conventions, how to verify visual changes, and a
  `## Workflow Standards` section that follows the machine's workflow rules.
- `README.md`: replace the template's generic one (it tells people to run copier) with a short
  description, the play URL and the dev commands.
- `docs/DESIGN.md` when the game has story, progression or an economy: pitch, pillars, core loop,
  systems, cast, art direction, technical plan, milestones and open questions. Follow the user's
  prose style rules (no em dashes, no "X, not Y", no colon setups).

## 4. Blender art pipeline (optional)

Follow Graffiti Pets (`~/Code/cloddy-game-crap/blender/`):

- Scripts run headless inside Blender's own Python:
  `/Applications/Blender.app/Contents/MacOS/Blender -b --python blender/<script>.py -- <args>`.
- A `kit.py` builds the parts with bmesh, and an export script writes one `.glb` with
  `export_materials="NONE"`. Godot assigns materials by the mesh-name suffix (material roles such as
  `_fur`, `_accent`), so recoloring needs no per-part code.
- Sockets are empties on base meshes. Parts are modeled in the socket's local frame so placement is
  just parenting.
- Prefix child names with their part (`<part>__<child>`) so names stay unique and Blender never adds
  `.001` suffixes.
- Make sure every mesh has a UV layer before `calc_uvs`, or the call silently does nothing.
- Commit generated assets so the game builds without Blender. Run `godot --headless --path
  godot_web_game --import` after regenerating them.
- Look at a rendered frame before calling any visual change done. Missing UVs, flipped normals and
  outline hulls blocking light only showed up in renders.
- For quick geometry checks, render with `BLENDER_WORKBENCH` and object colors set per material
  role (see Starship Tinkerer's `blender/preview_kit.py`). It takes seconds.
- 2D art such as character portraits and item icons can come from Blender too: build simple
  shapes, shade them with Shader to RGB into a constant ColorRamp emitted as color, add a solidify
  inverted-hull outline with a back-face-culled dark material, and render EEVEE with
  `film_transparent` and the Standard view transform (see `blender/portraits.py`). Expressions are
  just parameters for brows, eyes and mouth. EEVEE prints Metal shader errors in background mode
  on macOS but still renders correctly.
- Scripts that other scripts import must guard their entry point with
  `if __name__ == "__main__":`.

## 5. Godot patterns that worked

From Starship Tinkerer (`~/Code/starship-tinkerer/godot_web_game`):

- **Screenshot harness.** `scenes/Main.gd` reads `--fixture=`, `--screen=` and `--shot=` after `--`,
  sets up a known state, opens a screen, saves one frame and quits, using a throwaway save path.
  Run it without `--headless` (the headless renderer draws nothing). Check every screen this way.
- **Logic in pure `class_name` scripts** (stats, grading, dialogue parsing, race physics) so
  `godot --headless --script res://tests/run_tests.gd` can test them. Autoloads don't exist under
  `--script`, so a "compile every script" checker has to run as a scene.
- **Content as data.** JSON and `.txt` files aren't Godot resources and are left out of exports
  unless `include_filter` in `export_presets.cfg` names them (for example
  `data/*.json, data/dialogue/*.txt`). Confirm with `LC_ALL=C grep -a -c <string> index.pck`.
- **Themes.** Controls only inherit a theme from a Control or Window parent. If screens are plain
  Nodes or overlays live in CanvasLayers, set `theme` on each top-level control.
- **Gotchas:** run `godot --headless --import` after adding a `class_name` or a font; GDScript can't
  infer types from Dictionary values (`var x: float = d.v`); `TIME` isn't available inside helper
  functions of sky shaders, so pass it in; a hand-built ArrayMesh may need `cull_disabled` if its
  winding is backwards; `ease` is a built-in function name, so don't use it for variables.
- **Variable fonts** (Google Fonts, OFL) work through `FontVariation` with a `wght` variation.
  Download them with `gh api -H "Accept: application/vnd.github.raw" repos/google/fonts/contents/ofl/...`.
- **Web builds have no system fonts.** On desktop Godot quietly borrows missing glyphs (✓ ● ♥ ◀)
  from the OS, so they look fine in screenshots and draw as boxes in the browser. Bundle a symbols
  fallback from the start: subset Noto Sans Symbols 2 (OFL) with `uv run --with fonttools pyftsubset
  NotoSansSymbols2-Regular.ttf --unicodes="U+2190-21FF,U+25A0-25FF,U+2600-26FF,U+2700-27BF"`
  (about 110 KB) and set it in `fallbacks` on every `FontVariation`. Add a test that gathers every
  character from data, dialogue and script string literals and checks each has a glyph in the
  bundled fonts. Keep font setup in a pure `class_name` so the test can use it. Starship
  Tinkerer's `scripts/ui/fonts.gd` and `test_every_shown_character_has_a_glyph` are the reference.
- **Let the test runner discover tests.** Loop over `get_method_list()` and call every `test_`
  method instead of listing them by hand, or a new test can be written and never run.
- **Phones.** A 1280x720 canvas makes text tiny on a phone. Detect coarse-pointer, small screens
  through `JavaScriptBridge` and shrink `content_scale_size` (960x540 works), then fit centered
  overlays to the shorter screen. Touch buttons only see one pointer, so race-style controls that
  need two fingers at once must track `InputEventScreenTouch` indices themselves.
  Screenshot at phone size with `--resolution 1170x540` and a flag that forces phone mode.

## 6. Deploy for development

The user deploys early to the default GitHub Pages URL and waits on the crap.games domain until
release.

1. **Repo and Pages.** `git init -b main`, commit, then
   `gh repo create mcfredrick/<subdomain> --public --source . --push` and immediately
   `gh api -X POST repos/mcfredrick/<subdomain>/pages -f build_type=workflow`. The deploy uses
   `actions/deploy-pages`, which needs `build_type=workflow`. Enabling Pages right after the push is
   fine because the first run's deploy job starts after its build job finishes.
2. **Verify.** `gh run watch <id> -R mcfredrick/<subdomain> --exit-status`, then check that
   `https://mcfredrick.github.io/<subdomain>/` serves `index.html`, `index.wasm`, `index.pck` and
   `js/share-feature.js`. The user site has no custom domain, so project pages stay on github.io.
   Then make sure the game actually boots with headless Chrome:
   `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --use-angle=swiftshader --enable-unsafe-swiftshader --window-size=1280,720 --timeout=40000 --user-data-dir=<scratch dir> --screenshot=out.png <url>`.
   Use `--timeout`, because `--virtual-time-budget` screenshots before Godot draws a frame. Add
   `--enable-logging=stderr --v=0` and grep `CONSOLE` to read the console ("Game started
   successfully" means the engine booted).
3. **Shell buttons.** The template's share and music buttons sit in the top-left and top-right
   corners of the page, so keep in-game HUD elements inset about 84 px from both sides.

## 7. Release on crap.games

Not yet run end to end. Correct these steps the first time they're used.

1. **DNS.** crap.games DNS is at Namecheap and each game has its own CNAME record. The user adds
   `<subdomain>` pointing to `mcfredrick.github.io.`. Check it with
   `dig +short <subdomain>.crap.games CNAME`.
2. **Custom domain.** `gh api -X PUT repos/mcfredrick/<subdomain>/pages -f cname=<subdomain>.crap.games`,
   then `-F https_enforced=true` once the certificate is issued.
3. **Registry secret.** The register workflow needs `REGISTRY_UPDATE_TOKEN` (a PAT with `repo` and
   `workflow` scopes). The user sets it with
   `! gh secret set REGISTRY_UPDATE_TOKEN -R mcfredrick/<subdomain>`, which prompts for the value.
   Never handle the token yourself.
4. **Register.** Registration only runs by hand:
   `gh workflow run register_game.yml -R mcfredrick/<subdomain>`. Then pull
   `~/Crap Games/crap_games` and confirm the entry in `games/registry.json` and on all.crap.games.
