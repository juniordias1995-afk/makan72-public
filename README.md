# Makan72

**Your AI agents are powerful alone. Together, they're unstoppable.**

Makan72 is a multi-agent AI orchestration system that turns isolated AI coding tools into a coordinated engineering team — with shared memory, automatic inter-agent communication, dynamic roles, and built-in quality control.

One human. Multiple AI agents. One mission.

---

## The Problem

You have access to incredible AI coding agents — Claude, Gemini, Qwen, DeepSeek, Goose, and more. Each one is powerful. But using them one at a time, you're leaving most of their potential on the table.

**Without Makan72:**

- You copy-paste context between agents manually
- Each agent starts from zero — no memory of what the others did
- No one reviews the code before it reaches you
- When one agent makes a mistake, the others repeat it
- You're the bottleneck — coordinating everything yourself

**With Makan72:**

- Agents share memory automatically — what one learns, all know
- They communicate through a structured messaging system — zero copy-paste
- Each agent has a role (leader, builder, reviewer) assigned per session
- Mistakes are recorded once and never repeated by any agent
- You define the mission. They coordinate. You review the result.

---

## What Makes Makan72 Different

### Agents That Talk to Each Other

Makan72 agents don't work in silos. They have a built-in communication system:

- **Task delegation** — the leader agent assigns sub-tasks to specialists
- **Status updates** — every agent reports progress in real time
- **Alerts** — if an agent detects a critical problem, the entire team is notified instantly
- **Knowledge sharing** — when one agent solves a problem, the solution becomes available to all

No middleware. No external API. No cloud service. Just agents coordinating like a real engineering team.

### Persistent Memory Across Sessions

Every agent starts each session knowing:

- **Who they are** — identity, strengths, weaknesses, and today's assigned role
- **What the project needs** — architecture, tech stack, coding standards
- **What mistakes to avoid** — a shared registry of known errors ("vaccines") so no one repeats them
- **What solutions already exist** — a knowledge bank so no one reinvents the wheel

Close the terminal, come back tomorrow — nothing is lost. The team picks up exactly where it left off.

### Dynamic Roles — The Right Agent for the Right Job

Any agent can take any role. Roles are assigned per session, not hardcoded:

| Role | Responsibility | Example agents |
|------|---------------|----------------|
| **Leader** | Coordinates the session, validates results, makes architectural decisions | Claude, Gemini |
| **Builder** | Writes code fast, implements features, runs tests | Qwen, DeepSeek |
| **Reviewer** | Critical code review, finds bugs, validates architecture | Claude, Gemini |
| **Researcher** | Web search, documentation, competitive analysis | Gemini, Goose |
| **Debugger** | Deep problem analysis, root cause investigation | DeepSeek, Claude |
| **Auditor** | Security review, compliance checks, architecture validation | Claude |
| **Operator** | Quick tasks, file operations, maintenance | Any agent |

Today Claude leads and Qwen builds. Tomorrow Gemini leads and Claude reviews. You decide based on what the project needs.

### Quality Gates — No Bad Code Gets Through

Every piece of work passes through automated validation before reaching you:

1. **Scope check** — did the agent stay within its assigned task?
2. **Code quality** — linting, formatting, automated tests
3. **Security scan** — no hardcoded credentials, no dangerous patterns
4. **Integration check** — does everything still work together?

Only work that passes all gates gets delivered. Everything else goes back with a clear explanation of what needs fixing.

### Agent-Agnostic — No Vendor Lock-In

Makan72 works with **any CLI-based AI agent**:

| Agent | Provider | Status |
|-------|----------|--------|
| Claude Code | Anthropic | Fully supported |
| Gemini CLI | Google | Fully supported |
| Qwen Code | Alibaba Cloud | Fully supported |
| OpenCode | DeepSeek | Fully supported |
| Goose | Linux Foundation | Fully supported |

New AI CLI released tomorrow? Add it to Makan72 with one command. No code changes. No configuration files to rewrite. The system adapts to the agent, not the other way around.

### Runs Entirely on Your Machine

No SaaS platform. No monthly subscription. No data leaving your machine beyond what the AI CLIs themselves send to their providers.

All you need: **bash**, **jq**, **Python 3.10+**, **git**, and at least one AI CLI installed.

---

## What Can You Build With Makan72?

Anything a team of engineers can build — faster, cheaper, and around the clock:

| Use Case | How Makan72 helps |
|----------|-------------------|
| **Full-stack apps** | One agent builds the backend, another the frontend, a third reviews both |
| **Complex refactoring** | An auditor analyses the codebase, a builder implements, a reviewer validates |
| **Research-driven development** | A researcher finds best practices while a builder implements them |
| **Bug hunting** | Multiple agents attack the same bug from different angles simultaneously |
| **Documentation** | One agent writes docs while another keeps coding — in parallel |
| **Code migration** | Coordinated effort across agents to move between frameworks or languages |
| **CI/CD automation** | Agents create, test, and validate deployment pipelines |

---

## Architecture Overview

```
                        You (the human)
                              |
                    Define mission + roles
                              |
                              v
               ┌──────────────────────────────┐
               |     MAKAN72 ORCHESTRATOR     |
               |                              |
               |   Shared        Automatic    |
               |   Memory     Communication   |
               |                              |
               |   Quality       Dynamic      |
               |    Gates     Role Management |
               |                              |
               |   Session       Health       |
               |   Control     Monitoring     |
               └───┬──────┬──────┬──────┬────┘
                   |      |      |      |
                   v      v      v      v
               Agent 1  Agent 2  Agent 3  Agent N
               Leader   Builder  Reviewer  Researcher
                Tab 1    Tab 2    Tab 3     Tab 4
```

Each agent runs in its own terminal tab with full autonomy within its assigned role. The orchestrator handles memory injection, inter-agent messaging, task routing, and quality validation — transparently.

---

## Quick Start

```bash
# 1. Install
git clone <repository> ~/.Makan72
cd ~/.Makan72 && ./setup.sh

# 2. Add agents to your team
makan72 agent add CLAUDE claude
makan72 agent add GEMINI gemini
makan72 agent add QWEN qwen

# 3. Launch an agent with full context
makan72 start CLAUDE

# 4. Check system health
makan72 health
```

Fresh install comes empty — no pre-installed agents, no vendor assumptions. You build the team you want.

---

## Requirements

| Component | Minimum | Notes |
|-----------|---------|-------|
| **OS** | Linux / macOS | Terminal-native |
| **Shell** | Bash 4.0+ | Core runtime |
| **jq** | 1.6+ | Data processing |
| **Python** | 3.10+ | Scripting |
| **git** | 2.0+ | Version control |
| **AI CLIs** | At least 1 | The agents themselves |
| **Internet** | Required | For AI provider API calls |

---

## Roadmap

**Delivered:**

- [x] Multi-agent orchestration with shared memory
- [x] Dynamic role assignment per session
- [x] Automatic inter-agent communication
- [x] Quality gates with multi-layer validation
- [x] Support for 5+ AI CLI tools simultaneously
- [x] Health monitoring and system diagnostics
- [x] Session-based workflow management
- [x] Agent registry with one-command add/remove

**Coming next:**

- [ ] Web dashboard for visual orchestration
- [ ] Plugin system for custom workflows
- [ ] Multi-human collaboration (multiple operators + agents)
- [ ] Marketplace for shared agent configurations and roles

---

## Frequently Asked Questions

**Is this a wrapper around one specific AI?**
No. Makan72 is completely agent-agnostic. It orchestrates any CLI-based AI tool. You can run Claude, Gemini, Qwen, DeepSeek, and Goose in the same session, each with a different role.

**Do agents actually communicate with each other?**
Yes. Makan72 includes a built-in messaging and signaling system. Agents exchange tasks, status updates, alerts, and solutions — automatically, without human intervention.

**Does it work with just one agent?**
Yes, but you're missing the point. Makan72 shines when multiple agents collaborate, each bringing different strengths to the same project.

**Is my code sent to any third-party service?**
Makan72 itself sends nothing anywhere. Your code only goes to the AI providers you choose to use (Anthropic, Google, etc.) through their official CLI tools.

**Can I add a new AI agent that doesn't exist yet?**
If it has a CLI interface, yes. Makan72's agent registry is designed to support any command-line AI tool — present or future.

**What makes this different from just opening multiple terminal tabs?**
Context. Memory. Communication. Quality control. Without Makan72, each agent starts blind. With Makan72, every agent knows the project, the team, the rules, the past mistakes, and the existing solutions — before writing a single line of code.

---

## License

**Proprietary.** All rights reserved.

This software is not open source. Unauthorized copying, modification, distribution, or use is prohibited without explicit written permission from the author.

---

<p align="center"><b>Makan72 v1.0.0</b></p>
<p align="center"><i>Because one AI is good, but a team of AIs is better.</i></p>
