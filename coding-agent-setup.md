# Coding Agent Setup

How the coding agents on this machine are configured, and what this repo stows for them.

This setup targets two harnesses:

- [pi](https://github.com/earendil-works/pi-coding-agent) — configured via the `dot-pi` stow package
- [opencode](https://opencode.ai) — configured via `~/.config/opencode/` (not stowed)

The skill tooling (`gh skill install` and `bunx skills add`) is harness-agnostic: both accept an `--agent` flag, so the same commands work for pi, opencode, or any other supported harness. Where an agent has its own system-prompt rules file (pi's `APPEND_SYSTEM.md`, opencode's `instructions/`), the rules in this doc are meant to be replicated there.

## pi: stowed package `dot-pi`

The `dot-pi/` package stows pi's **user settings file** to `~/.pi/agent/settings.json`:

```bash
cd ~/.dotfiles
stow -t ~ --dotfiles dot-pi
```

(`--dotfiles` is required: inside the package, `dot-pi/` maps to the hidden `.pi/` directory in your home.)

### What's in `settings.json`

- `defaultProvider` / `defaultModel` / `defaultThinkingLevel` / `theme` — pi's interactive defaults
- `packages` — pi package dependencies

### Dependencies

The repo pins the **pi-subagents** extension package (delegation + scripted multi-agent workflows):

| Package | Spec in settings.json | pi.dev page |
| --- | --- | --- |
| pi-subagents | `npm:pi-subagents` | <https://pi.dev/packages/pi-subagents> |

Install/update pi packages with:

```bash
pi install npm:pi-subagents   # adds to settings.json
pi update --all               # update pi + packages
pi list                       # show installed packages
```

Installed packages live in `~/.pi/agent/npm/` (real directory, *not* stowed).

### pi system prompt

pi ships a default system prompt that you can override:

- `~/.pi/agent/SYSTEM.md` — **replaces** the default system prompt (global)
- `~/.pi/agent/APPEND_SYSTEM.md` — **appends** to the default (global)
- `.pi/SYSTEM.md` / `.pi/APPEND_SYSTEM.md` — per-project variants

This repo ships `dot-pi/dot-pi/agent/APPEND_SYSTEM.md`, which stows to `~/.pi/agent/APPEND_SYSTEM.md`. It contains the global agent rules (bun-only JS tooling, no `uv` for Python, `asd-ste100` for documentation, aggressive `ask_user` / `web_search` use, subagent review before commit/push, a quality-gate workflow, the project-skills loading rule, and the stack-tools rule to find official skills and MCP servers for each technology — e.g. Supabase). The rules are written in ASD-STE100 Simplified Technical English. Changes take effect on the next pi start.

The same rules apply to opencode via `~/.config/opencode/instructions/agent-rules.md` (registered in `opencode.jsonc` under `instructions`), adapted to opencode's tools (`ask`, `webfetch`, `/tmp/opencode`, `general` subagents). Keep the two rule files in sync.

## opencode: `~/.config/opencode/`

opencode's config lives in `~/.config/opencode/` and is **not** stowed by this repo (it is machine-local). Key files:

- `opencode.jsonc` — `instructions` (which instruction files load every session) and MCP servers
- `instructions/` — always-on guidance, e.g. `rust-skills.md`, `agent-rules.md`
- `skills/` — skills loaded into opencode sessions

> [!WARNING]
> `~/.config/opencode/` is **not** safe to stow or commit wholesale. It holds secrets:
> `cli.json` and `service.json` contain credentials/tokens, and `node_modules/` /
> `package-lock.json` are local tooling. Never add this directory to a stow package or
> git repo. Only individual files that are known to be safe (e.g. `opencode.jsonc`,
> `instructions/`, `skills/`) should ever be versioned, and even then only if they contain
> no secrets — audit them first.

When you add an always-on rule for opencode, put it in an `instructions/*.md` file and register it in `opencode.jsonc` under `instructions` (see the `rust-skills.md` entry for the pattern).

### Per-stack MCP servers

Per the agent rules, use the **official** MCP server for each technology in the stack instead of hand-rolled API calls. Add each one to the `mcp` block of `opencode.jsonc` (and the pi config if pi supports it). The `mcp` block in this machine's `opencode.jsonc` already includes Cloudflare (`https://mcp.cloudflare.com/mcp`) and Supabase (`https://mcp.supabase.com/mcp`).

To find the official server for a new technology, search the web for `<technology> official MCP server` and read the project's docs — do not guess the URL. Prefer `remote` servers with `oauth` auth when the provider supports it. Servers that require a secret stay out of the committed/stowed config.

## Deliberately NOT stowed

These live under `~/.pi/agent/` and `~/.config/opencode/` but stay local to the machine:

- `auth.json` (pi) / `cli.json` / `service.json` (opencode) — API keys / OAuth credentials (**secrets, never commit**)
- `trust.json` — per-project trust decisions (machine-specific paths)
- `npm/` — installed pi package cache
- `node_modules/`, `package-lock.json` — opencode local tooling (machine-local)
- `sessions/`, `missions/`, `run-history.jsonl`, `models-store.json` — runtime state

## Skills (user scope)

Skills are **not** stored in this repo. Two harness-agnostic tools install them into each agent's global skills directory (e.g. `~/.pi/agent/skills/` for pi, `~/.agents/skills/` for opencode — real directories, not stowed):

- The GitHub CLI (`gh skill install`)
- The skills CLI (`bunx skills add`)

Both take an `--agent` flag; `bunx skills add` accepts it repeatably (pass it once per target harness).

### Via the GitHub CLI

Run these during setup:

```bash
gh skill install --agent pi --agent opencode --scope user brycewang-stanford/Auto-Empirical-Research-Skills latex-to-typst
gh skill install --agent pi --agent opencode --scope user brycewang-stanford/Auto-Empirical-Research-Skills typst-paper
gh skill install --agent pi --agent opencode --scope user --pin main jihe520/MathModelAgent typst-author
gh skill install --agent pi --agent opencode --scope user nithitsuki/asd-ste100-skill asd-ste100
```

| Skill | Source repo |
| --- | --- |
| `latex-to-typst` | brycewang-stanford/Auto-Empirical-Research-Skills |
| `typst-paper` | brycewang-stanford/Auto-Empirical-Research-Skills |
| `typst-author` | jihe520/MathModelAgent |
| `asd-ste100` | nithitsuki/asd-ste100-skill |

### Via the skills CLI

The skills CLI is the package manager for the open agent skills ecosystem ([skills.sh](https://skills.sh)). It copies each skill into the target agent's global skills directory. Run this during setup:

```bash
bunx skills add https://github.com/anthropics/skills --skill skill-creator --agent opencode --agent pi --global --copy --yes
bunx skills add https://github.com/mattpocock/skills --skill '*' --agent opencode --agent pi --global --copy --yes
```

The `--agent` flag is repeatable: pass it once per target agent.

| Skill | Source repo | Purpose |
| --- | --- | --- |
| `skill-creator` | anthropics/skills | Creates new skills, improves existing skills, runs evals |

Update `skill-creator` with `bunx skills update skill-creator --global`.

#### Matt Pocock's skills (mattpocock/skills)

The second command installs all 35 skills from [mattpocock/skills](https://github.com/mattpocock/skills). It copies them into `~/.agents/skills/` (opencode) and `~/.pi/agent/skills/` (pi). `--copy` copies the files. It does not create symlinks into caches. The CLI registers the skills for all supported agents in `~/.agents/.skill-lock.json`, but only the agents passed with `--agent` receive the files.

**Engineering skills** — these read and write the repo's issue tracker and domain docs. Run `setup-matt-pocock-skills` in each repo before you use them:

| Skill | Purpose |
| --- | --- |
| `setup-matt-pocock-skills` | Configures the issue tracker, triage labels, and domain doc layout for a repo |
| `triage` | Moves issues and external PRs through the triage roles |
| `to-spec` | Turns the conversation into a spec on the issue tracker |
| `to-tickets` | Breaks a plan or spec into tracer-bullet tickets |
| `wayfinder` | Plans huge work as a map of decision tickets |
| `implement` | Implements work from a spec or tickets |
| `tdd` | Test-driven development (red-green-refactor) |
| `code-review` | Reviews changes against the repo's standards and spec |
| `codebase-design` | Shared vocabulary for deep-module design |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and regressions |
| `research` | Investigates questions against primary sources |
| `prototype` | Builds a throwaway prototype to answer a design question |
| `improve-codebase-architecture` | Scans for deepening opportunities, presents an HTML report |
| `domain-modeling` | Builds the domain model (CONTEXT.md, ADRs) |
| `resolving-merge-conflicts` | Resolves in-progress merge and rebase conflicts |
| `migrate-to-shoehorn` | Migrates `as` assertions to @total-typescript/shoehorn |
| `setup-ts-deep-modules` | Wires dependency-cruiser for deep-module TypeScript packages |
| `setup-pre-commit` | Sets up Husky and lint-staged pre-commit hooks |
| `scaffold-exercises` | Creates exercise directory structures |

**Interview and thinking skills:**

| Skill | Purpose |
| --- | --- |
| `grill-me` / `grilling` / `grill-with-docs` | Relentless interviews to sharpen plans and designs |
| `loop-me` | Grills specs for workflows in the workspace |
| `wait-what` | Re-pitches a message that did not land |
| `to-questionnaire` | Turns a decision into a questionnaire |
| `teach` | Teaches the user a skill or concept |
| `ask-matt` | Routes to the right skill or flow |
| `handoff` / `claude-handoff` | Hands the conversation to a fresh agent |
| `wizard` | Generates an interactive bash wizard for human-only steps |

**Writing and git-safety skills:**

| Skill | Purpose |
| --- | --- |
| `writing-for-agents` | Writes documents for agents (skills, AGENTS.md, CLAUDE.md) |
| `writing-beats` / `writing-fragments` / `writing-shape` | Writing workflow: fragments, then shape, then beats |
| `git-guardrails-claude-code` | Blocks destructive git commands with Claude Code hooks |

Update all mattpocock skills with `bunx skills update --global`.

The `asd-ste100` skill is required: the agent rules in `APPEND_SYSTEM.md` (see above) tell pi to follow it for all documentation.

**`ship-quality`** is different — it ships inside this repo at `dot-pi/dot-pi/agent/skills/ship-quality/` and stows into `~/.pi/agent/skills/` alongside the gh-managed skills (it has no gh metadata, so `gh skill list` / `gh skill update` ignore it — update it via git). The `APPEND_SYSTEM.md` rules tell pi to load it at session start.

Notes:

- `--agent` is **case-sensitive**: use lowercase `pi` (the help shows "Pi (pi)").
- `typst-author` needs `--pin main`: the repo's only release tag `v0.0.1` predates its `skills/` directory, so the default install finds nothing.
- **Security:** gh warns that skills may contain prompt injections or malicious scripts. Review `SKILL.md` contents (and any scripts) after installing or updating.
- To update installed skills: `gh skill update --all`.
- User-scope skills install to each agent's real skills directory here — do not add them to the `dot-pi` stow package.

## Project skills loading

Rule for **every** agent and **every** project session:

> 1. **Identify the stack.** Before touching code, look at the codebase and its architecture (language, framework, tooling — typst, go, rust, cloudflare, etc.) and determine which skills apply.
> 2. **Load the matching skills.** Load every relevant installed skill into context before working. Do not work in a project whose stack skills you have not loaded.
> 3. **If a matching skill is missing, install it globally first.** Do not continue until the install succeeds:
>
>    ```bash
>    # via the GitHub CLI (install for every harness you use)
>    gh skill install --agent pi --agent opencode --scope user <owner>/<repo> <skill>
>
>    # via the skills CLI
>    bunx skills add <https://github.com/owner/repo> --skill <skill> --agent opencode --agent pi --global --copy --yes
>    ```
> 4. **Star threshold.** Only install skills from repositories with **at least 1,000 GitHub stars**. Check the star count first with `gh repo view <owner>/<repo> --json stargazerCount` and skip the repo if it does not meet the threshold. (Exception: this repo's own in-house skills, which ship via `dot-pi`.)
> 5. **Prefer this repo's pinned skills** (`typst-author`, `latex-to-typst`, `typst-paper`, `asd-ste100`, the mattpocock engineering skills, and the rust-skills family) when they cover the stack — do not install duplicates.

Rationale: loading the right domain skills up front measurably improves output quality on every task, and the global install makes the skill available to every future session in that stack without re-installing per project.

## Notes

- `lastChangelogVersion` is stripped from the tracked `settings.json` — it's ephemeral state that pi rewrites on startup, which would otherwise dirty the repo after every pi update.
- If the symlink is ever replaced by a real file (e.g. you run `pi` before stowing on a fresh machine), re-stow or diff the files: pi writes through the symlink, so edits in `~/.pi/agent/settings.json` are edits in this repo.
- The rules in `APPEND_SYSTEM.md` require loading the **`ship-quality`** skill at session start. It is a risk-scaled quality-gate workflow (spec approval → plan approval → implementation with proof → independent review → user ship approval → lessons) that keeps the developer in the loop on every task, with a user override at any point. See its `SKILL.md` for the full protocol.

## Fresh install checklist

```bash
# 1. install pi + opencode (see their docs), then stow the pi package
cd ~/.dotfiles && stow -t ~ --dotfiles dot-pi

# 2. install the pinned packages listed in settings.json
pi update --all

# 3. log in to your provider (writes ~/.pi/agent/auth.json, not tracked)
pi /login

# 4. user-scope skills (see "Skills" section above)
gh skill install --agent pi --agent opencode --scope user brycewang-stanford/Auto-Empirical-Research-Skills latex-to-typst
gh skill install --agent pi --agent opencode --scope user brycewang-stanford/Auto-Empirical-Research-Skills typst-paper
gh skill install --agent pi --agent opencode --scope user --pin main jihe520/MathModelAgent typst-author
gh skill install --agent pi --agent opencode --scope user nithitsuki/asd-ste100-skill asd-ste100
bunx skills add https://github.com/anthropics/skills --skill skill-creator --agent opencode --agent pi --global --copy --yes
bunx skills add https://github.com/mattpocock/skills --skill '*' --agent opencode --agent pi --global --copy --yes
```