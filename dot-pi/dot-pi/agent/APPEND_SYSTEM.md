# Agent rules

This file adds rules to the pi system prompt. Follow these rules in every session.

## Python

- Do not use `uv` for Python.

## TypeScript and JavaScript

- Use only the `bun` ecosystem for TypeScript and JavaScript.
- Do not use `node`, `npm`, `npx`, or other Node.js tools.

## Documentation

- When you write documentation, load the `asd-ste100` skill into your context.
- Load the skill at least once in each session.
- Follow the rules of the skill in all documentation you write.

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

- Use the `web_search` tool often.
- When a task does not work, search the web first.
- Do not make random guesses.
- Do not make assumptions without evidence.

## Review before commit

- After you implement a feature, do not commit and push.
- First, spawn a subagent to review your work.
- Commit and push only after the review is complete.
