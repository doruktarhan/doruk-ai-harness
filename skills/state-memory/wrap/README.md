# /wrap

**What it does.** Closes out an agent's work session inside a multi-agent `.doruk/` feature
folder. It runs five consistency checks against the shared state, then makes the mechanical
end-of-session writes (folder README "Last updated", the agent's section in STATE.md, decision
and future-work appends) — only after showing you the diff and getting your OK.

**Why I built it.** I run several agents on one feature at a time, each owning its own folder
under `.doruk/features/<feature>/<agent>/`. State drifts fast in that setup: STATE.md says one
thing, the folder README says another, a "where to start" link points at a file someone already
archived, or one agent quietly edits a folder it doesn't own and the two stop agreeing. I was
catching these by hand at the end of every session and missing some. `/wrap` turns that ritual
into a checklist a model actually runs the same way every time — README↔STATE agreement,
stale-link scan, cross-folder write detection, HANDOFF.md trim, and the "date a decision when
it was decided, not when you wrote it down" convention. Then it does the boring updates for me.

**How to use it.**

1. Copy this `wrap/` folder into `~/.claude/skills/` (or your project's `.claude/skills/`).
2. Finish a focused work session in one agent-owned folder.
3. Say `/wrap` (or "wrap up" / "wrap the folder"). No arguments — it infers the folder from
   what you edited this session.
4. Review the recap and the proposed diff, then approve.
5. Run `/handoff` next if the session changed anything visible at the feature level. `/wrap`
   deliberately does **not** touch the cross-feature HANDOFF index itself; it composes with a
   separate handoff skill so the two concerns stay clean.

It pairs with a `.doruk/` state system — a `STATE.md` per feature plus per-agent folders. If
your features have a single owner rather than the multi-agent split, you don't need this; a
plain handoff skill is enough.
