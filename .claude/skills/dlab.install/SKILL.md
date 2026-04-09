---
name: dlab.install
description: Guided setup for Design Lab Docker environment
allowed-tools: Bash, Read, AskUserQuestion, Task
---

# Design Lab Install

Guided install for the Design Lab Docker dev environment. Walks the user through prerequisites, `.env` configuration, image build, host aliases, and first launch.

## Phase 0: Container Guard

Check if already running inside the container:

```bash
test -f /.dockerenv && echo "IN_CONTAINER" || echo "HOST"
```

If `IN_CONTAINER`: print "You're already inside the Design Lab container — this skill is for host-side setup. Nothing to do." and **stop immediately**.

## Phase 1: Gather Preferences

1. Run `ls .env` to check if `.env` exists. Do NOT read its contents — only check existence.

2. Use **one** `AskUserQuestion` call with up to 2 questions:

   **Question 1 — Aliases:**
   "Install host aliases (`dlab`, `dlab-build`, `dlab-down`) to ~/.bashrc?"
   Options: Yes / No

   **Question 2 — .env status (conditional wording):**
   - If `.env` exists: "Found existing `.env` file. Keep it or recreate from template?"
     Options: Keep / Recreate
   - If `.env` does NOT exist: "No `.env` file found. Create from template?"
     Options: Create now / Skip — I'll do it manually

## Phase 2: Prerequisites Check

Run these diagnostic commands (in parallel where possible):

```bash
docker --version
docker compose version
nvidia-smi
docker info 2>/dev/null | grep -i runtime
```

Check results:
- `docker` and `docker compose` must be present.
- `nvidia-smi` must succeed (parse driver version for reporting).
- Docker nvidia runtime should be listed.

If any prerequisite is missing, print a clear error explaining what's needed and **stop**. Do not attempt to install system dependencies.

## Phase 3: `.env` Setup (conditional)

Only if user chose **Create now** or **Recreate**:

1. Copy `.env.template` to `.env`:
   ```bash
   cp .env.template .env
   ```

2. **Auto-detect `ISAACLAB_HOST_PATH`** — compute from cwd. The skill runs from `source/design_lab`, so IsaacLab root is `../../`:
   ```bash
   ISAACLAB_HOST_PATH="$(cd ../../ && pwd)"
   ```
   Use `sed` to replace the placeholder in `.env`.

3. **Auto-detect `MODELS_HOST_PATH`** — check if `../../resources/models` exists relative to IsaacLab root (i.e. `../../../../resources/models` from cwd), or a sibling `models/` next to IsaacLab root. If found, populate. If not found, use `AskUserQuestion` to ask the user for the path.

4. **Detect CUDA version:**
   ```bash
   bash docker/detect_cuda.sh
   ```
   Append `CUDA_VERSION=<detected>` to `.env`.

5. Leave credential placeholders (OnShape, JFrog) as-is from the template — tell the user they can fill those in later.

If user chose **Keep** or **Skip**, move on without touching `.env`.

## Phase 4: Build

Spawn a **Bash sub-agent** (via the Task tool) to run the Docker build. This isolates the long-running build and its verbose output from the main context window.

```bash
docker compose build
```

If the build fails, report the error output to the user and suggest next steps. Don't try heroic fixes.

## Phase 5: Aliases (conditional)

Only if user opted in during Phase 1:

```bash
bash docker/dlab_host_aliases.sh
```

Tell the user to run `source ~/.bashrc` or open a new terminal to activate aliases.

## Phase 6: First Launch + Verify

```bash
docker compose up -d
docker exec design-lab-dev echo "Container ready!"
```

If launch succeeds, report success with quick-start info:
- How to enter the container: `dlab` (if aliases installed) or `docker exec -it design-lab-dev bash`
- Container aliases available inside: `workbench`, `mujoco`, `isaac`, `claude`

If launch fails, run `docker compose logs --tail=30` for diagnostics and report to the user.
