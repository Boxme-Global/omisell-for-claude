# Writing an Omisell skill

Every role skill follows this file. The design spec is internal to Omisell (catalogue, required behaviour, anti-goals, constraints); its rules are summarised in `plugins/omisell/shared/house-rules.md`.

## Branches

- `main` is what ships. The Claude plugin directory tracks it: every commit there becomes a new version that is scanned and reviewed. It holds only the shipping files: `.claude-plugin/marketplace.json`, `README.md`, `LICENSE`, `.gitignore`, and `plugins/omisell/` with `.claude-plugin/`, `.mcp.json` and `skills/`.
- `dev` is where work happens: the same files plus `plugins/omisell/evals/`, `plugins/omisell/shared/`, `scripts/`, this file and CI. Open PRs against `dev`.

## Layout

```
plugins/omisell/skills/<skill-name>/SKILL.md
plugins/omisell/evals/<skill-name>-<case>/prompt.md + graders/*.md
```

- `<skill-name>`: English kebab-case, equal to the frontmatter `name`. Invoked as `/omisell:<skill-name>`.
- Frontmatter keys: `name` and `description` only (claude.ai rejects most other keys). `description` is ONE line, ≤ 1024 chars, and holds trigger phrases in Vietnamese, Thai and English.
- Body in English. The answer follows the user's language.
- Do not hand-edit the house rules block. Edit `plugins/omisell/shared/house-rules.md`, then run `python3 scripts/skills.py sync`.

## Template

```markdown
---
name: <skill-name>
description: <What it answers in one clause>. Use when the user says "<vi phrase>", "<vi phrase>", "<th phrase>", "<en phrase>".
---

# Omisell: <title>

Goal: <the decision or action this helps with, in one sentence>.

## Steps

1. <first call: the most aggregate tool, with the arguments that matter>
2. <second call, only if the first shows something to drill into>
3. <fallback when a tool is refused or missing, e.g. aggregate_orders for staff>

## Answer

- Summary: <what the 1-2 sentences must say>
- Table: <columns, sort order, top N>
- Next: <actions + skills to suggest>

## Writes (only for ✍️ skills)

<which verb, which dry_run first, what the preview must show, what to report after get_action_status>

## Do not

- <skill-specific anti-goal>
```

`python3 scripts/skills.py sync` appends the house rules block under the body.

## Before you open a PR

1. `python3 scripts/skills.py sync && python3 scripts/skills.py check`
2. `claude plugin validate . --strict`
3. Run the skill on the Connectors Directory demo account (credentials with the Omisell team, never in this repo) and on one real shop, in Claude Code: `claude --plugin-dir plugins/omisell`, then `/mcp` to sign in.
4. Add at least one eval case per skill under `plugins/omisell/evals/` (see `start-first-run`).
5. Check the answer against §6: business picked, permission refusals in plain words, preview before any write, period next to every number, no customer phone/address/email, no internal ids or tool names.

## Running the evals

`claude plugin eval` runs in a sandbox with its own HOME, so a claude.ai connector does not reach it. Point a COPY of the plugin at the real server:

1. Get an MCP access token: `claude mcp add --transport http omisell-eval https://mcp.omisell.com/mcp`, then `/mcp`, sign in with the demo account and **tick ONE business**. The token lives 1 hour.
2. In a temporary copy of `plugins/omisell`, write `.mcp.json` with the header `"Authorization": "Bearer <token>"` (a `${VAR}` is NOT passed into the sandbox). Keep that file at mode 600 and delete it right after the run. Never commit it.
3. Run from the copy: `claude plugin eval . --allow-real-servers --allow-tools mcp__plugin_omisell_omisell__<tool> …` listing every tool except `confirm_action`, so no write executes.

Rules for the cases:
- Every case except `start-pick-business` assumes a **single-business** token: with several businesses the skills ask which one first (house rules), and a single-turn eval has nobody to answer. Run `start-pick-business` separately with a multi-business token.
- Token permission: `bulk-order-actions-read-only-token` needs a READ-ONLY token (write permission not ticked at sign-in); the write cases that confirm a change need a token WITH the write permission. Run them in separate batches.
- Never put a business id, account or customer data in a prompt: this repo is public.
- A case whose criteria need data (completed orders in the period, delivered COD, cost of goods, a staff account without a permission) only means something when the demo business has that data; otherwise the honest "no data" answer is correct and the case should not be scored as a failure.

## Publishing a release

1. On `dev`: bump `version` in `plugins/omisell/.claude-plugin/plugin.json`; `python3 scripts/skills.py sync && python3 scripts/skills.py check`; `claude plugin validate . --strict`.
2. Run `scripts/release.sh --dry-run <slug> "release: vX.Y.Z"`, then again without `--dry-run`. It builds `release/<slug>` from `main` with ONLY the shipping files of `origin/dev` (a file deleted on dev is deleted too), refuses anything outside that set or anything that looks like an internal host, id, staff email or token, runs the directory validator, makes ONE commit and opens the PR to `main`. Never merge `dev` into `main` (the GitHub compare `main...dev` conflicts by design whenever a dev-only file changes): `evals/`, `shared/`, `scripts/`, `CONTRIBUTING.md` and `.github/` would ship inside the plugin and be scanned as plugin content.
3. Keep `privacyPolicyUrl` in plugin.json: the directory asks for it ("No privacy policy URL"), and Claude Code 2.1.322 loads the plugin with it. Do not add `documentationUrl` / `supportUrl`: the directory flags both as "Unrecognized field in plugin.json"; docs and support come from the README.
4. Read the PR diff once more for anything the pattern cannot catch (a customer name, an order code from a real shop), then merge it. Each commit on `main` is a new directory version: the release branch carries one commit, so squash-merge it.
5. Tag `vX.Y.Z` and release with `omisell-plugin.zip` (zip of `.claude-plugin`, `.mcp.json`, `skills` from `plugins/omisell/`) plus the `python3 scripts/skills.py package` zips.
