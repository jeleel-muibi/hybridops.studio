# Evidence Slot 9 – Real-World Contributions in Employed Roles (Latymer)

> **Criteria:** Mandatory Criterion (MC) – real-world impact and potential.  
> **Also relevant to:** OC3 (significant technical contributions in employment).  
> **Note (working copy only):** `[IMG-XX]` placeholders will be replaced with final screenshots before submission.

## 1. Context – Role and Environment

The Latymer School is a high-performing selective secondary school in North London, with around **1,400 students** and a busy mix of teaching spaces, IT labs and staff devices. The IT environment supports:

- **Six dedicated computer labs**, used intensively during the school day.  
- Around **96 student laptops**, used for flexible teaching and interventions.  
- Roughly **100 staff laptops**, alongside staff desktops and shared machines.  

I worked as an **IT Technician with system administration responsibilities**, reporting to the **Network Manager** and working as part of the small IT team. My day-to-day work included:

- Handling support tickets from staff and students end-to-end.  
- Assisting with the **Windows 10 → 11** rollout and imaging process.  
- Working with **Active Directory, Group Policy and scripts** to apply changes safely.  
- Supporting classroom technology and ensuring labs were ready for lessons.

This evidence focuses on one concrete contribution: a **PowerShell-based user profile cleanup solution** that moved a recurring, disruptive problem from ad-hoc firefighting to a **repeatable, automated control** used across the school.

[IMG-01 – Redacted snippet from job description or reference email confirming IT Technician role reporting to Network Manager – ~6 lines]

---

## 2. Problem – Storage and Profile Issues at Scale

Before the script was introduced, the team faced recurring issues with **corrupted or bloated user profiles** on shared machines, particularly in computer labs and on shared student devices. Symptoms included:

- “Unable to load user profile” or temporary profile warnings.  
- Very slow logins when profiles became large or fragmented.  
- Local disks filling up on lab PCs, causing instability and failed logins.

This had real impact:

- Lessons could be disrupted while profiles were fixed or machines rebooted.  
- Staff had a poor experience on shared workstations, especially in busy periods.  
- Devices needed more frequent manual intervention or, in the worst case, rebuilds.

The pattern was clear: over time, **stale profiles** from users who had not logged in for months accumulated across **six labs, ~64 student laptops and ~100 staff laptops**, touching **thousands of profiles**. Without a systematic control, the team relied on manual cleanup or full re-images when disks became critically full.

[IMG-02 – Screenshot of a representative incident/ticket or a simple diagram showing labs and laptop fleets affected by profile issues – ~6 lines]

---

## 3. Solution – PowerShell Profile Cleanup Script

### 3.1 Proposal and design

Rather than treating each ticket as an isolated issue, I analysed the pattern of incidents and proposed a **scripted profile cleanup mechanism**. The goal was to:

- Identify **stale profiles** that had not been used for a configurable number of days (for example, 10+ days).  
- Safely delete those profiles without touching active users.  
- Reduce disk pressure and profile-related errors across the estate.  
- Make the behaviour predictable and repeatable, rather than ad-hoc.

I implemented a **PowerShell script** that:

- Enumerates local user profiles on a given machine.  
- Compares last-used timestamps against a defined threshold.  
- Skips system profiles and service accounts.  
- Removes only those profiles that are clearly stale.  
- Can be run under a scheduled task via **Group Policy**, so it does not rely on manual execution.

To make the proposal clear and accessible, I:

- Recorded a short **demo video** showing the script in action on a test machine.  
- Wrote an email to the **Network Manager** explaining:
  - The underlying problem and operational impact.  
  - The behaviour of the script and safety considerations.  
  - How it could be deployed (apps server + GPO).  

[IMG-03 – Screenshot of proposal email (redacted) showing demo video link and high-level explanation of the script – ~6 lines]
IMG-03: “Proposal email with demo link for PowerShell cleanup script.”

### 3.2 Network Manager approval

The Network Manager reviewed the demo and the proposal and replied positively, confirming that:

- The approach “**looks good**” and that he was “**happy for this to be tested**”.  
- The main considerations were **deployment hygiene**:
  - Using Intune vs legacy GPO where appropriate.  
  - Hosting the script on an internal server rather than ad-hoc copies.  
  - Using a standardised naming convention such as `LAT-DeleteUserProfile`.

This response shows that the solution was treated as a **legitimate operational control**, not just a one-off script. It also shows that I was trusted to work on changes that affect a broad set of devices, provided that rollout and governance were appropriate.

[IMG-04 – Screenshot of Network Manager reply, redacted to show approval wording and deployment considerations – ~6 lines]
IMG-04: “Network Manager approval and feedback on deployment standards.”

### 3.3 Deployment and operationalisation

Following approval, we moved into deployment:

- The script was placed on the school’s **apps server** under a standard scripts path, for example:  
  `\\lat-apps01\Applications\Scripts\LAT-DeleteUserProfile.ps1`.
- A **blank Group Policy Object (GPO)** was created and linked to the **C21 lab OU** as a safe starting point.  
- Within the GPO, a **Scheduled Task** was created to run the script under appropriate credentials at defined intervals (e.g. daily or weekly).

I was given permission to test the behaviour using my engineering account and to monitor the results on lab machines. Once we were satisfied that it behaved as intended and did not impact active users, the same pattern was applied across:

- The remaining labs.  
- The student laptop fleet.  
- Relevant staff laptops where profile bloat was a known issue.

At this point, the script had moved from a personal idea to a **standardised operational tool**, integrated into the school’s existing management stack.

[IMG-05 – Screenshot of email confirming script location and GPO deployment, or GPMC screenshot showing the GPO attached to the lab OU – ~6 lines]
IMG-05: “Confirmation of script location and GPO integration.”

---

## 4. Impact – How It Changed Operations

Over time, the profile cleanup mechanism became part of the **normal hygiene** of the environment. Its impact can be summarised as:

- **Coverage:**  
  - **6 labs**, **~96 student laptops** and **~100 staff laptops**, together handling **around 1,500 staff and student profiles** over time.  
- **Stability:**  
  - Fewer incidents related to “unable to load user profile” on shared machines.  
  - Reduced frequency of emergency profile cleanup or full device rebuilds.  
- **Performance and user experience:**  
  - Faster logins and fewer surprises at the start of lessons.  
  - Staff encountering fewer “mystery” profile errors on shared machines.  
- **Operational repeatability:**  
  - Profile cleanup became a **documented, automated control**, not a manual, one-off fix.  
  - The script could be adjusted (e.g. changing the age threshold) without rewriting the solution.

Even without formal incident metrics, the qualitative feedback from the IT team and the Network Manager was that the environment became **easier to manage** and less prone to profile-related disruption. Devices remained usable for longer, which also has a cost benefit in terms of delaying replacements or rebuild cycles.

[IMG-06 – Optional: before/after incident trend sketch, or a simple diagram showing “manual per-PC fixes” vs “scheduled, estate-wide cleanup” – ~6 lines]

---

## 5. Forward Thinking – Device De-boarding Automation

Beyond the immediate script, I also began to think about **device lifecycle** more holistically. In particular, I started outlining an **automated device de-boarding process** to handle machines that were being retired or repurposed.

The aim was to define a flow where:

1. A device is flagged for retirement.  
2. A standard **wipe and reset** process is triggered.  
3. The device is **unassigned** from users and removed from active groups or OUs.  
4. Inventory records are updated so that retired devices are clearly separated from active ones.

This work was in its early stages, but it demonstrates that I was thinking beyond individual scripts and towards **repeatable lifecycle automation**. The same mindset that drives HybridOps.Studio – lifecycle, reliability, and guardrails – was being applied inside a real school environment, under the constraints of existing tools and policies.

[IMG-07 – Simple flow diagram of proposed device de-boarding process: “Flag → Wipe → Unassign → Update inventory” – ~6 lines]

---

## 6. How This Supports the Criteria

This evidence supports the **Mandatory Criterion (MC)** by showing that:

- I can **identify a recurring operational problem** in a real organisation and quantify its impact.  
- I can design, propose and implement an **automated solution** that is safe enough to be adopted at scale.  
- I can work effectively with a **Network Manager** to move from idea → approval → GPO deployment.  
- The result is a control that improves reliability and user experience for **hundreds of users** and **dozens of devices**.

If needed, it can also contribute to **OC3 (significant technical contributions in employment)**, as it demonstrates:

- A meaningful impact on operational reliability.  
- A reduction in manual effort and firefighting.  
- Early thinking about **lifecycle and de-boarding**, not just one-off fixes.

---

**Context & navigation**

For easier cross-referencing, this PDF is mirrored on the [HybridOps.Studio documentation portal](https://docs.hybridops.studio) and linked from the [Tech Nation assessors’ guide](https://docs.hybridops.studio/briefings/gtv/how-to-review/). The docs site adds navigation only, not new evidence.
