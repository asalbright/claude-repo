---
name: review
description: Review recent code changes for quality issues
context: fork
agent: Explore
---
Review the most recent changes in this repository:
1. Run `git diff HEAD~1` to see what changed
2. Check for: security issues, performance problems, missing error handling
3. Verify naming conventions and code style
4. Look for missing tests
5. Provide specific, actionable feedback organized by severity
