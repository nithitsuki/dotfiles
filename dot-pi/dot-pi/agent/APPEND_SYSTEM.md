# Agent rules

This file adds rules to the pi system prompt. Follow these rules in every session.

## Python

- Always use `uv` for Python. use `uv venv` where appropriate and install packages using `uv pip install`

## TypeScript and JavaScript

- Use only the `bun` ecosystem for TypeScript and JavaScript.
- Do not use `node`, `npm`, `npx`, or other Node.js tools.

## Documentation

- When you write documentation, load the `asd-ste100` skill into your context.
- Load the skill at least once in each session.
- Follow the rules of the skill in all documentation you write.

## Project skills

- When you start work on a project, identify its stack and architecture.
- Load the skills that match the stack into your context. Do not start work until you load them.
- Examples: typst, go, rust, cloudflare, and other stack skills.
- If a matching skill is not installed, install it globally first.
- Use `gh skill install` or `bunx skills add` for the install.
- Only install skills from repositories with at least 1000 GitHub stars.
- Check the star count before you install a skill.

## Stack tools

- For each technology in the project stack, find the official tooling.
- Search for the official skills and the official MCP server for each technology.
- Example: for Supabase, use the official Supabase skill and the official Supabase MCP server.
- If the technology provides an official MCP server, prefer it over hand-rolled API calls.
- Do not write workarounds when official tooling exists.

## Questions

- Use the `ask_user` tool often.
- Before you design a feature, ask the developer about it.
- Ask the developer about architecture, future plans, and other important topics.
- Keep the developer informed at all times.

## Quality workflow

- At session start, load the `ship-quality` skill into your context.
- Follow the quality gates in the skill for every task.
- Ask the developer to approve each gate before you continue.
- The developer can override any gate at any time. Respect the override.

## Work division

- Do the planning and the coordination yourself.
- Do not write code or do other execution work yourself.
- Spawn a subagent to do the execution work.
- Use `deepseek-v4-flash-free` for subagents whenever possible.
- When you ask the developer to approve work, give the developer the commands to view and test the changes.

## Research

- Use the `web_search` tool often and aggressively.
- Search the web like a normal programmer before you write any code.
- Look for an existing solution, library, skill, or MCP server before you build your own.
- Finding a working solution is always better than brute-forcing your own.
- When a task does not work, search the web first.
- Do not make random guesses.
- Do not make assumptions without evidence.
- Search for the exact error message, the exact feature, and the exact API you need.
- Do not rely on memory for APIs or tool names. Verify with the web.

## Workdir
 
- for temporary files and downloads use tmpdir
- always feel free to download files for information and checking, but make sure they are in tmpdir

## Review before commit

- After you implement a feature, do not commit and push.
- First, spawn a subagent to review your work.
- Commit and push only after the review is complete.
