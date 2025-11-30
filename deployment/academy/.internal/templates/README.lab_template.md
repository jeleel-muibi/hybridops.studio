---
lab_id: "HOS-SH-XXX"
slug: "<slug>"
title: "<Showcase Name> — Academy Lab"
category: "academy-lab"
difficulty: "Intermediate"
estimated_time: "60–90 minutes"

audience: ["learners"]
access: "academy"

depends_on:
  - "Base platform bootstrap completed"
  - "Connectivity to lab environment available"
---

# <Showcase Name> — Academy Lab

## 1. Scenario

Briefly describe the scenario this lab implements and how it relates to the main showcase:

- What problem is being simulated.
- Where it sits in the HybridOps.Studio architecture.
- What the learner should be able to explain afterwards.

Link to the public showcase page:

- Showcase: `docs/showcases/<slug>/README.md`

---

## 2. Learning outcomes

By the end of this lab, the learner should be able to:

1. …
2. …
3. …

Use outcome verbs such as _deploy_, _diagnose_, _rollback_, _interpret logs_, _adjust capacity_, etc.

---

## 3. Prerequisites

State what must already be in place:

- Platform state (for example: base environment provisioned, cluster online).
- Access (for example: VPN, SSH key, portal URL).
- Tools (for example: `kubectl`, `ansible`, `terraform`, `gh`, `az`).

If specific environments or overlays are required, reference them:

- `deployment/environments/<env>/…`
- `deployment/academy/showcases/<slug>/overlays/…`

---

## 4. Topology and architecture

Give the learner a concrete view of what they are operating on.

- Insert or reference a diagram from the main docs if helpful.
- Keep diagrams in `diagrams/` under this lab package if they are lab-specific.

Example:

```markdown
![Lab topology](./diagrams/lab-topology.png)
```

Summarise:

- Key components and how they are connected.
- Which parts of the platform are “in scope” for the lab.

---

## 5. Lab tasks

Break the lab into numbered tasks. Each task should have:

- A short title.
- A clear objective.
- Step-by-step instructions.
- A verification step.

Example structure:

### Task 1 – Inspect the current state

**Objective:** Understand the starting point of the environment.

Steps:

1. Run …
2. Inspect …
3. Answer …

**Verify:**

- You can see …
- You have noted …

### Task 2 – Apply the change

**Objective:** Use the platform automation to make a controlled change.

Steps:

1. …

**Verify:**

- …

Repeat for as many tasks as needed (usually 3–6).

If tasks are large or you want machine-readable lab specs, you can move detailed steps into `tasks/` and keep this file as a high-level narrative.

---

## 6. Evidence to collect

Specify what artefacts learners should produce:

- Command output snapshots.
- Screenshots of dashboards or status pages.
- References to logs or traces.

Link to how evidence fits into the wider platform:

- Evidence Map: `docs/evidence_map.md`
- Proof archive locations if relevant: `docs/proof/<path>/`

Keep this section concrete and minimal. The goal is to make it easy to assess whether the lab was completed correctly.

---

## 7. Cleanup

Describe how to return the environment to a safe baseline:

- Commands to revert changes or destroy lab-specific resources.
- Any state that must be reset before the lab can be run again.

If cleanup is optional (for example in a disposable environment), state that explicitly.

---

## 8. Extensions (optional)

Suggest follow-up experiments:

- Hard-mode variations of the same scenario.
- “What if” changes that explore failure modes or trade-offs.
- Extra observability or cost-optimisation tasks.

These are optional and should not be required for the core lab completion.

---

**Notes for authors**

- Do not re-implement roles, playbooks or pipelines in this folder.
- Use overlays and configuration only; all automation should be reused from `deployment/`, `core/`, `control/` and `ci/`.
- Keep language direct and operational. Avoid marketing language.
