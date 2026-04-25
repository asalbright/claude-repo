#!/usr/bin/env python3
"""PreToolUse hook: block `git push` to protected branches across all remotes.

Compatible with Python 3.9+ (macOS system python).

Protected names (exact): main, master, develop
Protected prefixes: release (incl. release/*), production (incl. production/*)

Handles every push syntax I could think of: bare `git push`, explicit refspecs,
src:dst form, leading `+` for force, `--force`/`--force-with-lease`/`-f`,
`--delete`/`-d`, `:branch` deletion syntax, `HEAD` source, `refs/heads/<name>`,
env-var prefixes, chained commands (`&&`, `||`, `;`, `|`, `&`).
Unconditionally blocks `--all` and `--mirror` — they push every branch.
"""

import json
import re
import shlex
import subprocess
import sys

PROTECTED_EXACT = {"main", "master", "develop"}
PROTECTED_PREFIX = {"release", "production"}

BRANCH_HINT = (
    "Create a descriptive branch instead — feature/<short-name>, "
    "bug/<short-name>, chore/<short-name>, docs/<short-name>, or "
    "refactor/<short-name> — push that and open a PR."
)


def is_protected(branch):
    branch = branch.removeprefix("refs/heads/")
    if branch in PROTECTED_EXACT:
        return True
    for prefix in PROTECTED_PREFIX:
        if branch == prefix or branch.startswith(prefix + "/"):
            return True
    return False


def current_branch():
    try:
        r = subprocess.run(
            ["git", "symbolic-ref", "--short", "HEAD"],
            capture_output=True, text=True, timeout=2,
        )
        return r.stdout.strip() if r.returncode == 0 else None
    except Exception:
        return None


def targets_from_push_args(args):
    """Return destination branch names from a tokenized `git push ...` call.

    Returns ["<ALL>"] as a sentinel for --all/--mirror (every local branch).
    """
    for a in args:
        if a in ("--all", "--mirror"):
            return ["<ALL>"]

    # Strip flag tokens. We don't try to consume flag values — git push flags
    # that take values use `=` form or don't name branches positionally.
    positional = [a for a in args if not a.startswith("-")]

    # positional[0] = remote (may be absent), rest = refspecs
    refspecs = positional[1:]
    targets = []

    for spec in refspecs:
        if spec.startswith("+"):
            spec = spec[1:]
        if not spec:
            continue
        if ":" in spec:
            src, dst = spec.split(":", 1)
            # `src:` deletes src; `:dst` deletes dst — both target the non-empty side
            targets.append(dst if dst else src)
        elif spec == "HEAD":
            cb = current_branch()
            if cb:
                targets.append(cb)
        else:
            targets.append(spec)

    if not refspecs:
        # Bare `git push` or `git push <remote>` pushes the current branch
        cb = current_branch()
        if cb:
            targets.append(cb)

    return targets


def find_git_push_calls(command: str):
    """Yield tokenized args for each `git push ...` invocation in a shell string."""
    segments = re.split(r"(?:&&|\|\||;|\||&)", command)
    for seg in segments:
        seg = seg.strip()
        # Allow leading `VAR=val ` env assignments before `git push`
        m = re.match(r"^(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*git\s+push\b(.*)$", seg)
        if not m:
            continue
        tail = m.group(1)
        try:
            yield shlex.split(tail)
        except ValueError:
            yield tail.split()


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return  # Can't parse input; let the tool call through
    if data.get("tool_name") != "Bash":
        return
    command = data.get("tool_input", {}).get("command", "")
    if "git push" not in command:
        return

    for args in find_git_push_calls(command):
        targets = targets_from_push_args(args)
        if "<ALL>" in targets:
            deny(
                "Blocked: `git push --all` / `--mirror` pushes every local branch, "
                "including protected ones (main, master, develop, release*, "
                f"production*). Push specific branches by name. {BRANCH_HINT}"
            )
        for t in targets:
            if is_protected(t):
                deny(
                    f"Blocked: push target '{t}' is a protected branch "
                    "(main, master, develop, release*, production*). "
                    f"{BRANCH_HINT}"
                )


if __name__ == "__main__":
    main()
