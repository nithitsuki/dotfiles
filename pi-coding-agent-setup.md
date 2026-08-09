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

Skills are **not** stored in this repo — they're installed directly with the GitHub CLI (`gh skill install`) into `~/.pi/agent/skills/` (real directory, gh-managed). Run these during pi setup:

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

The `asd-ste100` skill is required: the agent rules in `APPEND_SYSTEM.md` (see below) tell pi to follow it for all documentation.

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

This repo ships `dot-pi/dot-pi/agent/APPEND_SYSTEM.md`, which stows to `~/.pi/agent/APPEND_SYSTEM.md`. It contains the global agent rules (bun-only JS tooling, no `uv` for Python, `asd-ste100` for documentation, aggressive `ask_user` / `web_search` use, and subagent review before commit/push). The rules are written in ASD-STE100 Simplified Technical English. Changes take effect on the next pi start.

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
```
