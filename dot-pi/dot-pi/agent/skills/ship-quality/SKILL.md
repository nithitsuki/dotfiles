---
description: Run a quality workflow with user approval gates for every task, scaled by risk tier (XXS, XS, S, M, L). Use at the start of each session and for each task. Covers risk triage, spec approval, plan approval, implementation proof, independent review, ship approval, and lessons.
name: ship-quality
---

# ship-quality

## Purpose

This skill runs a quality workflow for every task. The workflow has a quality gate at every step. The user approves each gate. The goal is high-quality work in every session.

## When to use this skill

Load this skill at the start of each session. The system prompt requires it. Use it for every task. Do not skip a gate unless the user says to skip it. Exception: for XXS tasks, the skill does not apply. Make the edit directly, with no gates and no subagents.

## Roles

The agent is the coordinator. The user is the approver. Subagents do the work.

- The coordinator asks the questions and runs the gates.
- The coordinator does the planning and the coordination.
- The coordinator does not write code or do other execution work, except for XS and XXS tasks, where the coordinator does the work directly.
- A worker subagent writes the code and runs the checks.
- A reviewer subagent judges the work.
- Use `deepseek-v4-flash-free` for subagents whenever possible. Pass the model name when you spawn a subagent.

## The gates

- G0 — Intake and risk triage.
- G1 — Spec approval.
- G2 — Plan approval.
- G3 — Implementation with proof.
- G4 — Independent review.
- G5 — User ship gate.
- G6 — Lessons.

## Risk levels

At G0, ask the user to choose a risk level:

- XXS — The skill does not apply. Preferred for very trivial tasks.
- XS — a small change with a known shape. No multi-agent: the coordinator writes the code and runs the checks directly. No worker or reviewer subagents.
- S — trivial change, such as a basic single target goal
- M — a feature or a moderate change.
- L — architecture, security, or a breaking change.

Use these gate depths:

- For XXS, run no gates, not even G0. Make the edit directly and show the result.
- For XS, do G3-lite and G5 directly, without subagents. Skip G1, G2, and G4.
- For S, do G3-lite and G5. Skip G1, G2, and G4.
- For M, do all gates.
- For L, do all gates. Use a different model for the reviewer when possible. Add a rollback plan to the G5 report.

## G0 — Intake and risk triage

Ask the user these questions with `ask_user`:

- What is the goal?
- What does "done" look like?
- What is the risk level: XXS, XS, S, M, or L?
- What are the constraints and the architecture context?
- What are the future plans for this area?

Ask one question at a time. Do not start work before the user answers. Keep the user in the loop at all times.

For L work, also ask: who else must be in the loop? What can break?

## G1 — Spec approval

Write a mini-spec to a scratch file. The spec has:

- The goal.
- The scope.
- The non-goals.
- The acceptance criteria as runnable commands.
- The risks.

Keep the spec to 50 lines or fewer. Show it to the user. Ask the user to approve it with `ask_user`. Do not design or implement before approval.

## G2 — Plan approval

Write an implementation plan. The plan has:

- The files to change.
- The order of work.
- The test strategy.
- The risks.

Show the plan to the user. Ask the user to approve it with `ask_user`. If the plan changes during work, ask the user again.

## G3 — Implementation with proof

For XS work, the coordinator implements the plan directly. Otherwise, spawn a worker subagent to implement the plan. Give the subagent the spec, the plan, and the checks below. Use `deepseek-v4-flash-free` for the worker whenever possible. The worker implements the plan in small slices. The worker runs the checks after each slice:

- The type check.
- The linter.
- The tests.
- The build.
- The acceptance criteria commands from the spec.

For M and L work, the worker spot-checks the tests. The worker breaks the code on purpose. The worker confirms that the tests fail. This grades the tests, not just the code.

The worker reports the commands and their outputs. The coordinator records the proof in the scratch file. The proof is the commands and their outputs. Do not commit during work.

## G4 — Independent review

Spawn a reviewer subagent with fresh context. Use `deepseek-v4-flash-free` for the reviewer whenever possible. For L work, use a different model when possible. The reviewer judges the work. The author does not judge the work.

The reviewer checks the diff against:

- The spec and the acceptance criteria.
- The code quality and the repo conventions.
- The security and the edge cases.
- The documentation rules (use `asd-ste100` for docs).

The reviewer reports findings by severity:

- Critical.
- Major.
- Minor.
- Nit.

Fix all critical and major findings. The worker applies the fixes. The reviewer re-checks the work. The user can waive minor findings at G5. For L work, add a second review pass for security and architecture.

## G5 — User ship gate

Show the user a summary. The summary has:

- The files changed.
- The gate results and the proof.
- The review report.
- The risks that remain.
- The rollback plan for L work.
- The commands to view the changes, such as `git diff --staged`.
- The commands to test the changes, such as `bun test` and the acceptance criteria commands.

Ask the user to approve with `ask_user`. The options are:

- Approve and ship.
- Request changes.
- Stop.

Commit and push only after approval. Write a commit message that refers to the spec. If code signing needs the user, give the commit command to the user.

## G6 — Lessons

After you ship, append to the lessons log at `~/.agents/lessons.md` (make sure it is .gitignored).

- What went wrong.
- What the user corrected.
- Which gate caught which defect.
- How the agent fails.

Read the lessons log at the start of L work.

## Override protocol

The user can override any gate at any time. The user can say:

- "Skip the gates."
- "Skip the review."
- "Ship it."
- "Full speed."

Respect the override at once. Do not argue with the user. Note the override in the summary. An override applies to the current task only. Each new task starts with the full workflow.

## What not to do

For XXS tasks, none of these rules apply: the skill is ignored.

- Do not implement before G1 approval.
- Do not write code yourself. Spawn a worker subagent, except for XS and XXS tasks.
- Do not review your own work at G4.
- Do not commit before G5 approval.
- Do not claim that a gate passed without proof.
- Do not start work before the G0 answers.
