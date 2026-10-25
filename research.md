---
description: Run a research task as spec → autonomous execution → reviewed debrief
argument-hint: <what you want done>
---

The task: $ARGUMENTS

Run this session in three phases. Do not skip or merge them.

## Phase 1: Spec (I am in the loop)

1. Spawn the `hive:retrieval` agent to find my preferences and past decisions relevant to this task: how I like this kind of work done, approaches that failed before, open issues it touches. If that agent isn't available, say so and continue.
2. Read whatever in the repo bears on the task.
3. Interview me **one question at a time** until you understand every implicit requirement: the goal behind the task, what "done" looks like, what to vary and what to hold fixed, how to judge success, the compute or time budget, and what must not be touched. Skip anything retrieval or the repo already answered, and say what you inferred so I can correct it.
4. Write the spec to `.research/<short-task-name>/spec.md`: goal, requirements, success criteria, plan, and the decisions I fixed. Show it to me.
5. Spawn `model-router:plan-reviewer` on that file, passing the goal and the decisions I fixed. Revise the plan for any finding you agree with, and list the ones you rejected and why. If model-router isn't available, spawn a fresh general-purpose subagent to critique the plan instead.
6. Ask me to confirm the spec. Remind me that this is the point to switch to auto mode and pick **ultracode** in the effort menu (xhigh effort, lets you launch workflows). **Do not start Phase 2 until I confirm.**

## Phase 2: Execute (I have walked away)

- Work autonomously. Time spent does not matter; only the quality of the result does. Do not stop to ask me questions. When something is ambiguous, take the reading most consistent with the spec, record it in `.research/<task>/decisions.md` with your reasoning, and carry on.
- Before anything expensive or hard to undo (long runs, GPU jobs, large refactors), write down what you are about to do and why, and if it changes the approved plan, get `model-router:plan-reviewer` to check the change first.
- Commit work in small, described steps so any of it can be reverted.
- For a range of experiments, prompt variants or eval iterations, create a workflow to run them in parallel rather than one by one. Each branch gets its own subagent; collect and compare their results yourself before drawing conclusions.
- Check your own results: rerun anything surprising, look for bugs that would produce the same numbers, and do not draw conclusions from one data point.
- When the code is done, run `model-router:adversarial-code-reviewer` on the changes (scope: everything since the commit where Phase 2 started). Fix what you agree with; record what you rejected in `decisions.md`.

## Phase 3: Review (I am back)

1. Run `/debrief:debrief` to publish the review page: what was done and why, the riskiest judgment calls, side effects, and how the work was verified. If the debrief plugin isn't available, write `.research/<task>/report.html` covering the same points, with the relevant code and results inline, and give me its path.
2. In chat, give me the link plus at most five lines: the outcome, and what you most need me to check.
3. When I leave comments on the debrief, act on the ones that ask for changes, then run another debrief round.
