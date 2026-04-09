---
name: commit
description: Create a well-formatted git commit
disable-model-invocation: true
---
Create a git commit for the current changes:
1. Run `git diff --staged` to see what's staged
2. If nothing is staged, stage the relevant files (never use `git add .`)
3. Write a conventional commit message (feat:, fix:, docs:, etc.)
4. Focus on WHY, not WHAT
5. Create the commit
