# Tech Nation Personal Statement

HybridOps.Studio is the backbone of my work: a production-grade **hybrid platform blueprint** that I design, operate and document end to end. Around it, I bring a strong academic foundation plus real-world experience in education and NHS volunteering.

My focus is building reliable hybrid platforms, automating disaster recovery with **cost as a first-class signal**, and turning complex infrastructure into clear documentation and teaching material that other engineers and teams can actually use.


## 1. Foundation: academic excellence and early innovation

In 2024 I completed a **first-class BSc in Computer Science at the University of East London**, received a **departmental award for outstanding engagement**, and saw my final-year project ranked in the **top 15 of 120** students. That project, *Network Automation and Abstraction*, moved from manual network configuration towards programmable, testable automation and laid the groundwork for how I now think about network baselines, source of truth and reliability.

Alongside this I have built a technical base in Microsoft Azure administration (AZ-104 preparation), Cisco networking, and IBM training in **Cybersecurity** and **Enterprise Security in Practice**, plus membership of the **British Computer Society (BCS)**. This foundation supports the hybrid platform work below.


## 2. HybridOps.Studio: a reusable hybrid platform blueprint

To prove what I can do beyond job titles, I designed and built **HybridOps.Studio**: a **hybrid platform blueprint and reference implementation** that I run to production standards as a platform/SRE product.

It combines:

- A dual-ISP, pfSense-based **hybrid network and WAN edge** with IPsec to cloud.  
- A **source of truth model** using NetBox and PostgreSQL, consumed by Terraform, Ansible and Nornir.  
- A **delivery platform** built on Packer templates, Jenkins pipelines, RKE2 Kubernetes and GitOps patterns.  
- A **DR and cost-aware automation loop** using Prometheus federation, Alertmanager, GitHub Actions and a Cost Decision Service.  
- A **documentation and Academy engine**, served via `docs.hybridops.studio` with showcases under `/showcase`, backed by ADRs, HOWTOs, runbooks and proof artefacts.

I run this environment as a platform product: changes are justified in ADRs, operational flows have runbooks and DR drills, and key behaviours (such as failover and cost guardrails) produce verifiable artefacts under `docs/proof/`. The same blueprint underpins **HybridOps Academy**, where public documentation and showcases form the free learning surface and deeper Moodle-based bootcamps provide structured training.


## 3. Real-world impact: Latymer and operational delivery

The same mindset appears in my work at The Latymer School, where I work as an IT Technician, collaborating with the Network Manager and the wider IT team on day-to-day operations.

A recurring issue was storage pressure and corrupted user profiles on shared machines, affecting lessons and staff productivity. Instead of treating each incident as a one-off fix, I analysed the pattern and proposed a scripted solution. I wrote a **PowerShell script** that scanned for stale user profiles (for example, older than ten days) and deleted them safely, recorded a short demo and sent a proposal email explaining the impact on storage, login reliability and device lifespan. The Network Manager replied that the approach “looks good” and was happy for it to be tested, with feedback focused on deployment details.

The script was moved to the school’s apps server, attached to a Group Policy for a lab OU and then rolled out more widely. Today it is used across the school’s **six computer labs, around 64 student laptops and roughly 100 staff laptops**, touching **around 1,500 staff and student profiles** over time. It has become a standard support tool for profile and storage maintenance, helping to keep devices usable for longer and reduce repeat tickets. I also began designing an **automated device de-boarding process** so that retired devices could be wiped, unassigned and removed from inventory in a consistent, low-risk way.


## 4. Documentation, teaching and public surface

A defining part of my trajectory is the decision to **open up and teach**, not just build systems privately.

I maintain public repositories for **HybridOps.Studio** and my final-year project, structured with top-level READMEs, ADRs for major decisions, HOWTOs for specific tasks, runbooks for incidents and CI docs for pipelines. The documentation portal at `docs.hybridops.studio` is written for distinct audiences – assessors, hiring managers, engineers, learners and Academy prospects – each with a “start here” path into the blueprint. For assessors who cross-reference in context, the portal mirrors the Tech Nation PDFs and links them to the underlying ADRs, HOWTOs and runbooks; it adds navigation only, not new evidence.

On top of that, I am building **HybridOps Academy**:

- Public **showcases** at `docs.hybridops.studio/showcase` that act as free labs and walkthroughs.  
- A flagship **“HybridOps Architect”** cohort-based programme and specialist labs, delivered via Moodle and using the same repo and evidence tree as the live teaching environment.  
- Selected roles published as **Ansible Galaxy collections** with Molecule-tested pipelines, so other teams can adopt and extend them.

This blend of open documentation, structured teaching and sustainable premium offerings is how I intend to contribute to the UK tech ecosystem beyond any single employer.


## 5. Future plans in the UK

I have built my early career in the UK through study at the University of East London, work in a London school environment and NHS volunteering. Attending **Data Centre World London** has reinforced how much demand there is here for engineers who can bridge on-prem and cloud and think about cost and resilience together.

If endorsed under Tech Nation’s Global Talent route, I plan to focus on three interconnected tracks:

1. **Platform / SRE roles** where I can bring the HybridOps.Studio mindset – hybrid baselines, source-of-truth automation, DR and cost guardrails, and strong documentation – into real teams.  
2. **HybridOps Academy**, offering bootcamps and workshops that help startups and scale-ups adopt reliable, auditable and cost-conscious infrastructure patterns early.  
3. **Open community contribution**, through public repos, documentation, Ansible collections and talks that distil lessons from HybridOps.Studio and my professional roles into reusable patterns.

My aim is to design and run robust hybrid platforms, keep them observable and cost-aware, and **document and teach them so other engineers and teams can build on that work**.
