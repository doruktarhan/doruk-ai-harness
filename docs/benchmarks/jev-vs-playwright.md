# Benchmark: `jev-browser` (jb + Jev) vs Playwright MCP

**Date:** 2026-09-21 · **Runs:** one per task, per tool · **Machine:** macOS, headed Chromium

A small, honest field test, not a leaderboard. The question was practical: for "go find this
thing on a website" tasks, should a coding agent drive the browser itself through Playwright MCP,
or hand the whole goal to `jb` and let Jev pick the clicks?

## TL;DR

- **When Jev finishes, it's faster.** Verified successes took 9.6–12.9 s of wall time versus
  14.4–29.2 s for Playwright MCP on the same tasks.
- **It costs the calling agent almost nothing.** One `jb run` call returns a ~1 KB JSON summary.
  Playwright MCP took 3–9 tool calls per task, and one `browser_find` returned ~1,600 element refs
  (~22k tokens) into the agent's context.
- **The goal wording matters a lot.** The same docs task failed three times as a scroll hunt and
  passed in 5 steps once the goal said "use the site's search box". That lesson now lives in the
  skill.
- **Safety barriers work.** PyPI served a Fastly CAPTCHA; Jev stopped rather than trying to solve it.
  Once it returned `REVIEW` and once `BLOCKED`, so the barrier status isn't consistent yet.
- **Playwright MCP is still the fallback.** It has escape hatches Jev doesn't: `evaluate`, direct URL
  jumps, assertions, and network/console inspection. That's why the routing rule is "Jev first,
  Playwright MCP when Jev returns BLOCKED or step_limit".

## Tasks

| ID | Site | Goal |
|---|---|---|
| docs-lookup | playwright.dev | Open the API reference, then the `Page` class, then reach the `waitForSelector` section |
| article-hunt | blog.rust-lang.org | Find and open *Announcing Rust 1.84.0* in the archive list |
| search-filter | pypi.org | Search "http client", filter to Python 3.13, then open the first result |
| search-filter (HN) | hn.algolia.com | Search, change the date filter, then open a result (a stand-in once PyPI started serving CAPTCHAs) |

## Results

Wall time runs from the tool call to the result, including browser start for `jb`. Every
`done_unverified` result below was checked against its final screenshot.

### `jb` + Jev

| Run | Task | Status | Steps | Wall | Verified |
|---|---|---|---|---|---|
| 1a | docs-lookup | `interrupted` (typing helper failed) | 2 | 5.6 s | — |
| 1b | docs-lookup | `blocked` | 1 | 3.3 s | — |
| 1c | docs-lookup (scroll-hunt goal) | `step_limit` (30 scrolls) | 30 | 23.5 s | — |
| 1d | article-hunt | `done` | 19 | 12.7 s | ✅ post open |
| **2a** | **docs-lookup (search-box goal)** | **`done`** | **5** | **9.6 s** | ✅ `waitForSelector` heading visible |
| 2b | article-hunt | `done` | 19 | 12.9 s | ✅ post title + body |
| 2c | search-filter (PyPI) | `needs_review`: Fastly CAPTCHA | 2 | 5.0 s | ✅ correct stop |
| 2d | search-filter (PyPI) | `blocked`: CAPTCHA on load | 0 | 2.7 s | ✅ didn't solve it |
| 2e | search-filter (HN) | `done` | 4 | 10.3 s | ✅ story page open |

Round 1 found the problems and round 2 ran after the fixes (a working text helper and search-first
goals).

### Playwright MCP (driven by Claude)

| Task | Wall | Tool calls | Notes |
|---|---|---|---|
| docs-lookup | 22.9 s | 6 | Used one direct-URL jump, a shortcut Jev doesn't have |
| article-hunt | 14.4 s | 3 | Clicks only, but one `browser_find` returned ~1,600 refs (~22k tokens) |
| search-filter (PyPI) | 29.2 s | 9 | Needed a `browser_evaluate` escape hatch; one `find` returned ~90 checkboxes |
| search-filter (HN) | 28.9 s | 9 | One `select_option` failed; needed a `browser_evaluate` escape hatch |

## Head-to-head (successful runs)

| Task | jb + Jev | Playwright MCP |
|---|---|---|
| docs-lookup | **9.6 s**, 1 agent call | 22.9 s, 6 calls |
| article-hunt | **12.9 s**, 1 agent call | 14.4 s, 3 calls |
| search-filter (HN) | **10.3 s**, 1 agent call | 28.9 s, 9 calls |

## What changed in the skill because of this

- **Search box beats scrolling.** Jev scrolls one viewport at a time and can't jump to an anchor or
  use in-page find. Run 1c burned 30 steps, while run 2a finished in 5.
- **Treat `done_unverified` as a claim.** `jb` reports DONE whatever Jev's confidence is, so the skill
  makes the agent read the final screenshot before reporting success.
- **Routing:** Jev handles "find / open / navigate / fill a form". Playwright MCP handles testing,
  assertions, network/console, tabs, storage, and any Jev `BLOCKED` or `step_limit`.

## Caveats

- There's one run per cell, so this is n=1 with no variance. Read the numbers as a direction, not a
  statistic.
- Playwright MCP wall time includes the driving model's turns between tool calls, which is the real
  cost an agent pays. `jb` wall time includes daemon and browser start.
- Round 1 failures were partly setup (the typing helper), not only the model.
- The raw JSON summaries, jsonl traces, and screenshots are local (`~/.jb/data/bench`) and aren't in
  this repo.
