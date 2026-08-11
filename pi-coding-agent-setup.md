# Pi Coding Agent Setup

How the [pi coding agent](https://github.com/earendil-works/pi-coding-agent) is configured on this machine, and what this repo stows for it.

## Stowed package: `dot-pi`

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

## Deliberately NOT stowed

These live in `~/.pi/agent/` but stay local to the machine:

- `auth.json` — API keys / OAuth credentials (**secrets, never commit**)
- `trust.json` — per-project trust decisions (machine-specific paths)
- `npm/` — installed pi package cache
- `sessions/`, `missions/`, `run-history.jsonl`, `models-store.json` — runtime state

## Skills (user scope)

Skills are **not** stored in this repo. Two tools install them into `~/.pi/agent/skills/` (real directory, not stowed):

- The GitHub CLI (`gh skill install`)
- The skills CLI (`bunx skills add`)

### Via the GitHub CLI

Run these during pi setup:

```bash
gh skill install --agent pi --scope user brycewang-stanford/Auto-Empirical-Research-Skills latex-to-typst
gh skill install --agent pi --scope user brycewang-stanford/Auto-Empirical-Research-Skills typst-paper
gh skill install --agent pi --scope user --pin main jihe520/MathModelAgent typst-author
gh skill install nithitsuki/asd-ste100-skill asd-ste100 --agent pi --scope user
```

| Skill | Source repo |
| --- | --- |
| `latex-to-typst` | brycewang-stanford/Auto-Empirical-Research-Skills |
| `typst-paper` | brycewang-stanford/Auto-Empirical-Research-Skills |
| `typst-author` | jihe520/MathModelAgent |
| `asd-ste100` | nithitsuki/asd-ste100-skill |

### Via the skills CLI

The skills CLI is the package manager for the open agent skills ecosystem ([skills.sh](https://skills.sh)). It copies the skill into `~/.pi/agent/skills/`. Run this during pi setup:

```bash
bunx skills add https://github.com/anthropics/skills --skill skill-creator --agent pi --global --copy --yes
```

| Skill | Source repo |
| --- | --- |
| `skill-creator` | anthropics/skills |

The `skill-creator` skill creates new skills and improves existing skills. It runs evals and benchmarks to measure skill performance. Update it with `bunx skills update skill-creator --global`.

The `asd-ste100` skill is required: the agent rules in `APPEND_SYSTEM.md` (see below) tell pi to follow it for all documentation.

**`ship-quality`** is different — it ships inside this repo at `dot-pi/dot-pi/agent/skills/ship-quality/` and stows into `~/.pi/agent/skills/` alongside the gh-managed skills (it has no gh metadata, so `gh skill list` / `gh skill update` ignore it — update it via git). The `APPEND_SYSTEM.md` rules tell pi to load it at session start.

Notes:

- `--agent` is **case-sensitive**: use lowercase `pi` (the help shows "Pi (pi)").
- `typst-author` needs `--pin main`: the repo's only release tag `v0.0.1` predates its `skills/` directory, so the default install finds nothing.
- **Security:** gh warns that skills may contain prompt injections or malicious scripts. Review `SKILL.md` contents (and any scripts) after installing or updating.
- To update installed skills: `gh skill update --all`.
- User-scope skills install to `~/.pi/agent/skills/`, which is a real directory here — do not add it to the `dot-pi` stow package.

## Notes

- `lastChangelogVersion` is stripped from the tracked `settings.json` — it's ephemeral state that pi rewrites on startup, which would otherwise dirty the repo after every pi update.
- If the symlink is ever replaced by a real file (e.g. you run `pi` before stowing on a fresh machine), re-stow or diff the files: pi writes through the symlink, so edits in `~/.pi/agent/settings.json` are edits in this repo.

## Customizing the system prompt

Optional — pi ships a default system prompt. To override it:

- `~/.pi/agent/SYSTEM.md` — **replaces** the default system prompt (global)
- `~/.pi/agent/APPEND_SYSTEM.md` — **appends** to the default (global)
- `.pi/SYSTEM.md` / `.pi/APPEND_SYSTEM.md` — per-project variants

This repo ships `dot-pi/dot-pi/agent/APPEND_SYSTEM.md`, which stows to `~/.pi/agent/APPEND_SYSTEM.md`. It contains the global agent rules (bun-only JS tooling, no `uv` for Python, `asd-ste100` for documentation, aggressive `ask_user` / `web_search` use, subagent review before commit/push, and a quality-gate workflow). The rules are written in ASD-STE100 Simplified Technical English. Changes take effect on the next pi start.

The rules require loading the **`ship-quality`** skill at session start. It is a risk-scaled quality-gate workflow (spec approval → plan approval → implementation with proof → independent review → user ship approval → lessons) that keeps the developer in the loop on every task, with a user override at any point. See its `SKILL.md` for the full protocol.

## Fresh install checklist

```bash
# 1. install pi (see pi docs) then stow this package
cd ~/.dotfiles && stow -t ~ --dotfiles dot-pi

# 2. install the pinned packages listed in settings.json
pi update --all

# 3. log in to your provider (writes ~/.pi/agent/auth.json, not tracked)
pi /login

# 4. user-scope skills (see "Skills" section above)
gh skill install --agent pi --scope user brycewang-stanford/Auto-Empirical-Research-Skills latex-to-typst
gh skill install --agent pi --scope user brycewang-stanford/Auto-Empirical-Research-Skills typst-paper
gh skill install --agent pi --scope user --pin main jihe520/MathModelAgent typst-author
gh skill install nithitsuki/asd-ste100-skill asd-ste100 --agent pi --scope user
bunx skills add https://github.com/anthropics/skills --skill skill-creator --agent pi --global --copy --yes
```
