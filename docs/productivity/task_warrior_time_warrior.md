---
id: task-warrior-time-warrior
title: Mastering Taskwarrior and Timewarrior
sidebar_label: Taskwarrior & Timewarrior
sidebar_position: 3
description: "Comprehensive tutorial for using Taskwarrior and Timewarrior for task and time management"
---

# Mastering Taskwarrior: A Comprehensive Tutorial for FAANG Product Managers

**Author: Grok (Built by xAI)**  
**Date: January 3, 2026**  
**Audience: Product Managers at FAANG-level companies (e.g., Facebook/Meta, Apple, Amazon, Netflix, Google/Alphabet) looking to optimize task and time management in high-stakes, fast-paced environments.**

---


## Introduction

As a Product Manager (PM) in a FAANG company, your days are a whirlwind of prioritizing features, coordinating with engineering teams, aligning with stakeholders, and juggling personal growth amid tight deadlines. Tools like Jira or Asana are great for team collaboration, but for personal task management—especially when you need offline access, flexibility, and zero-cost setup—Taskwarrior shines. This open-source, command-line task manager is lightweight, extensible, and excels at handling time-sensitive tasks, making it ideal for PMs who thrive on efficiency.

In this tutorial, we'll cover everything from basics to advanced usage, with real-world scenarios tailored to FAANG PM workflows. You'll learn how Taskwarrior manages time effectively (e.g., due times at 13:00 or timeboxing sessions) and how to integrate it with Timewarrior for tracking. By the end, you'll have a saveable reference to boost your productivity. All examples assume a Unix-like system (macOS/Linux; Windows users can use WSL).

Why Taskwarrior for FAANG PMs?
- **Speed and Focus**: CLI interface means no distractions from GUIs.
- **Offline-First**: Sync via Git or Dropbox for remote work.
- **Customization**: Tags, priorities, and urgency scoring align with OKRs and roadmaps.
- **Time Mastery**: Precise due times and time tracking prevent burnout in 24/7 cultures.

Let's dive in.

---

## Installation and Basic Setup

### Step 1: Installation
Install Taskwarrior via your package manager:
- **macOS (Homebrew)**: `brew install task`
- **Ubuntu/Debian**: `sudo apt install taskwarrior`
- **Fedora**: `sudo dnf install task`
- **Arch**: `sudo pacman -S task`

For Timewarrior (companion for time tracking):
- `brew install timewarrior` (or equivalent).

Verify: `task --version` should show something like 3.0.0+ (as of 2026).

### Step 2: Configuration
Taskwarrior uses `~/.taskrc` for settings. Create or edit it:
```
nano ~/.taskrc
```

Add basics:
```
# Theme for better readability
color=on
color.theme=dark-256

# Default date format with time
dateformat=Y-M-D H:N

# Urgency coefficients (customize for PM priorities)
urgency.user.project.coefficient=3.0  # Boost project-tagged tasks
urgency.due.coefficient=5.0          # Heavily weight due dates
urgency.priority.coefficient=2.0     # H/M/L priorities

# Recurrence (for repeating tasks like weekly reviews)
recurrence=on
```

For Timewarrior integration, install the hook:
- Download from Timewarrior's site or use: `timew :ids` to test.
- Add to `.taskrc`: `uda.timewarrior=1` and ensure hooks are enabled.

Sync tasks across devices: Use Git. Initialize a repo in `~/.task` and push to a private GitHub repo.

### Step 3: First Task
Add a simple task: `task add "Review Q1 OKRs" project:Product due:2026-01-10 priority:H`

List tasks: `task list`

This sets the foundation. Now, onto core features.

---

## Core Features: Building Your Task System

Taskwarrior uses attributes like `project`, `tags`, `priority`, `due`, and `scheduled`. Commands are intuitive: `add`, `modify`, `done`, `delete`.

### Adding and Organizing Tasks
- **Basic Add**: `task add "Prioritize feature backlog"`
- **With Attributes**:
  - Project: Groups tasks (e.g., `project:SearchAds` for a Google PM).
  - Tags: Flexible labels (e.g., `+engineering +design +urgent`).
  - Priority: H (high), M (medium), L (low).
  - Dependencies: `task add "Wireframe UI" depends:42` (links to task ID 42).

Example: `task add "Align on MVP scope with eng lead" project:PrimeVideo tags:+netflix +mvp due:2026-01-15T14:00 priority:M`

### Viewing and Filtering
- `task next`: Shows urgent tasks (based on due, priority, etc.).
- `task list project:Product`: Filter by project.
- `task +urgent`: Show tagged tasks.
- Custom Reports: Edit `.taskrc` to add `report.mypm.description=PM Dashboard` with columns like ID, Project, Due, Description.

### Editing and Completing
- Modify: `task 5 modify due:2026-01-20T13:00` (sets due at 1 PM).
- Start/Stop: `task 5 start` (marks as active); integrates with Timewarrior.
- Done: `task 5 done` (archives it).

Pro Tip: Use aliases in `.taskrc` like `alias.rm=delete` for shortcuts.

---

## Time Management Mastery

Taskwarrior excels at time-specific management, addressing your query on due times (e.g., 13:00) and timeboxing.

### Setting Due Dates with Precise Times
By default, dates are YYYY-MM-DD, but include time with `T HH:MM` (ISO format).
- Command: `task add "Stakeholder demo" due:2026-02-05T13:00`
- Override Format: If needed, `task add ... rc.dateformat=Y-M-DTH:N`
- Behavior: Tasks become overdue post-time; urgency spikes as time approaches.
- Scheduled Attribute: `scheduled:2026-02-05T10:00` hides tasks until then.

### Timeboxing with Timewarrior
Timeboxing allocates fixed blocks (e.g., 2 hours for backlog grooming). Taskwarrior + Timewarrior = perfect combo.
- Setup Hook: In `.taskrc`, add `hooks.on-add=/usr/share/task/hooks/on-add-timewarrior` (adjust path).
- Workflow:
  1. Add: `task add "Groom backlog" scheduled:2026-01-04T09:00 due:2026-01-04T11:00 tags:+timebox`
  2. Start: `task <ID> start` → Timewarrior tracks interval.
  3. Stop: `task <ID> stop` or `done`.
- Review: `timew summary :ids` shows time spent.
- Reports: `timew report` for charts (export to CSV for visualization).

For Pomodoro: Script a hook to auto-stop after 25 minutes.

Advanced: Use `wait` attribute for deferred visibility: `wait:2026-01-10`.

---

## Real-World Scenarios for FAANG PMs

Here, we apply Taskwarrior to typical FAANG PM challenges. Assume you're a PM at Amazon working on AWS features.

### Scenario 1: Managing Product Roadmap
**Context**: You have quarterly OKRs, feature prioritization, and cross-team dependencies in a high-velocity environment.

- **Setup**: Create projects like `project:AWSConsole` and tags `+p0 +p1` (priority levels).
- **Tasks**:
  - `task add "Define Q1 key results" project:AWSConsole due:2026-01-10T17:00 priority:H`
  - `task add "Prioritize bug fixes" depends:1 tags:+p1` (depends on OKRs).
  - Recurring: `task add "Weekly roadmap review" recur:weekly due:sat`
- **Workflow**: `task next` for daily focus. Use `task burndown.daily` for progress charts.
- **Time Management**: Timebox reviews: `task add "Roadmap sync with eng" scheduled:2026-01-05T14:00 due:2026-01-05T15:00` → Start/stop to track.
- **Outcome**: Prevents scope creep; urgency scoring highlights slipping items.

### Scenario 2: Sprint Planning and Execution
**Context**: Bi-weekly sprints with Jira integration, but personal tracking needed for your todos.

- **Setup**: Sync with Jira via scripts (e.g., export Jira issues to Taskwarrior JSON).
- **Tasks**:
  - `task add "Refine user stories" project:Sprint23 due:2026-01-07T10:00 tags:+planning`
  - `task add "Demo prep" depends:previous due:2026-01-14T13:00 priority:M`
- **Workflow**: `task active` for in-progress. Annotate: `task 3 annotate "Feedback from design: add dark mode"`.
- **Time Management**: Timebox planning: 2-hour block. Use Timewarrior for retrospective: `timew summary :week` to analyze time on planning vs. execution.
- **Outcome**: Complements Jira; personal overdue alerts keep you ahead in standups.

### Scenario 3: Stakeholder Alignment and Meetings
**Context**: Frequent exec reviews, like Amazon's "Working Backwards" docs or Google's data-driven pitches.

- **Setup**: Tags like `+stakeholder +exec`.
- **Tasks**:
  - `task add "Draft PRFAQ doc" project:Launch due:2026-01-20T09:00`
  - `task add "Schedule demo with VP" depends:previous scheduled:2026-01-21T11:00 due:2026-01-21T12:00`
- **Workflow**: `task calendar` for monthly overview. Export to iCal: Use `task export` and scripts.
- **Time Management**: Set precise due times for prep (e.g., 13:00 deadline). Timebox feedback loops: Track revision time to avoid over-polishing.
- **Outcome**: Ensures timely alignment; reduces last-minute scrambles in high-stakes meetings.

### Scenario 4: Personal Development and Work-Life Balance
**Context**: FAANG demands growth (e.g., promo packets) amid burnout risks.

- **Setup**: Project `project:Personal`.
- **Tasks**:
  - `task add "Read 'Inspired' book" due:2026-02-01 tags:+learning recur:monthly`
  - `task add "Mentor session prep" scheduled:2026-01-10T08:00 due:2026-01-10T09:00`
- **Workflow**: `task +learning list` for focus. Use priorities for balance (low for personal if work is H).
- **Time Management**: Timebox learning: 1-hour daily slots. Review with `timew chart` for weekly balance.
- **Outcome**: Tracks growth without neglecting core PM duties; prevents overload.

### Scenario 5: Crisis Management (e.g., Launch Delays)
**Context**: Sudden bugs or pivots, common in Netflix's A/B testing or Apple's hardware cycles.

- **Tasks**:
  - `task add "Triage production issue" priority:H due:now tags:+crisis`
  - `task add "Post-mortem analysis" depends:previous due:2026-01-06T16:00`
- **Workflow**: `task urgent` custom report for crises. Dependencies auto-sequence.
- **Time Management**: Immediate start/stop for tracking response time; use for metrics in reviews.
- **Outcome**: Structured chaos; data for future prevention.

---

## Advanced Tips and Integrations

- **Custom Hooks/Scripts**: Auto-sync with Google Calendar via Python scripts using `task export`.
- **Vit (Visual Interactive Taskwarrior)**: GUI wrapper: `brew install vit`.
- **Integrations**:
  - Email: Hook to parse emails into tasks.
  - GitHub: Sync issues with Taskwarrior via `bugwarrior`.
  - Mobile: Apps like "Taskwarrior for Android" for on-the-go.
- **Data Analysis**: Export to JSON/CSV: `task export > tasks.json`. Use Python/pandas for insights (e.g., time spent per project).
- **Backup/Sync**: Git repo for `.task` directory; add cron job for auto-commit.
- **Common Pitfalls**: Avoid over-tagging; review archived tasks quarterly with `task +COMPLETED list`.

For scaling: In teams, share Taskwarrior via shared repos, but stick to personal use for privacy.

---

## Conclusion

Taskwarrior transforms chaotic PM workflows into structured mastery, especially with its time-handling prowess. From setting a due at 13:00 to timeboxing sprints, it's a FAANG PM's secret weapon for efficiency. Start small—add your next 5 tasks—and iterate. For updates, check taskwarrior.org or community forums.

Save this as `taskwarrior-pm-tutorial.md` for reference. Questions? Experiment and adapt!

**Resources**:
- Official Docs: taskwarrior.org
- Timewarrior: timewarrior.net
- Community: Reddit r/taskwarrior

Happy tasking! 🚀