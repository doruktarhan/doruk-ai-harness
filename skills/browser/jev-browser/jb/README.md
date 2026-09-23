# jb

Isolated Playwright Chromium driven by Jev. A coding agent (or you) runs a
narrowly scoped browser goal; Jev chooses in-page actions.

Requires **Node 22+**. The host skill is `../SKILL.md`.

## Install

```bash
cd jb
npm install
npx playwright install chromium
mkdir -p ~/.jb
cp config.example.json ~/.jb/config.json
ln -s "$PWD/bin/jb" ~/.local/bin/jb   # or any dir on PATH
```

Edit `~/.jb/config.json` (never commit keys):

- `provider`: `"gateway"` (default) or `"typesafe"`
- Gateway: `gateway.apiKey` or `AI_GATEWAY_API_KEY`
- TypeSafe: `typesafe.apiKey` or `TYPESAFE_API_KEY`
- Visible browser: `"headless": false`

`TYPE_TEXT` still uses Gateway + Gemini when `provider` is `"typesafe"`.

Config: `~/.jb/config.json`. Artifacts: `~/.jb/data`.

## Run

```bash
cd jb
./bin/jb --session example stop
./bin/jb --session example run \
  --url https://example.com \
  --headed \
  --max-steps 20 \
  --goal "Find the More information link and open it. Do not click or play any videos. Stop when that page's title and body are visible."
./bin/jb --session example stop
```

```
./bin/jb [--session ID] run --goal "…" [--url URL] [--max-steps N] [--headless] [--headed]
./bin/jb [--session ID] state
./bin/jb [--session ID] logs [--tail N]
./bin/jb [--session ID] stream
./bin/jb [--session ID] stop
```

The daemon auto-starts on `run`. `stop` closes the browser and the daemon.

## Test

```bash
cd jb
npm test
```
