---
name: confluence.upload
description: Upload markdown files to Confluence Cloud via mark CLI
argument-hint: <path-to-markdown-file-or-glob>
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Glob
---

# Upload to Confluence

Upload one or more markdown files to Confluence Cloud using the `mark` CLI. Handles metadata headers, mermaid diagram rendering, and post-upload cleanup.

## Phase 0: Dependency Check

Verify mark and Chrome are installed:

```bash
mark --version 2>/dev/null && echo "MARK_OK" || echo "MARK_MISSING"
which google-chrome 2>/dev/null && echo "CHROME_OK" || echo "CHROME_MISSING"
```

If either is missing, tell the user: "First-time setup required. See `.claude/skills/confluence.upload/setup.md` for install instructions." Then read that file, run the install commands, and continue.

## Phase 1: Credential Check

Check if credentials are set:

```bash
[ -n "$MARK_USERNAME" ] && [ -n "$MARK_PASSWORD" ] && [ -n "$MARK_BASE_URL" ] && echo "CREDS_OK" || echo "CREDS_MISSING"
```

If `CREDS_MISSING`, use **AskUserQuestion** to ask for any that are unset:
- Confluence email (username) → `MARK_USERNAME`
- API token (password) → `MARK_PASSWORD` — direct the user to https://id.atlassian.com/manage-profile/security/api-tokens if needed
- Confluence base URL → `MARK_BASE_URL` — e.g., `https://your-org.atlassian.net/wiki`

Also check for the default space:

```bash
[ -n "$MARK_SPACE" ] && echo "SPACE_OK" || echo "SPACE_MISSING"
```

If `SPACE_MISSING`, ask: "What is your Confluence space key? (e.g., `ENG`, `DOCS`, `TEC`)" and set `MARK_SPACE`.

Then set env vars for this session:

```bash
export MARK_USERNAME="<email>"
export MARK_PASSWORD="<token>"
export MARK_BASE_URL="<base-url>"
export MARK_SPACE="<space-key>"
```

## Phase 2: Resolve Input Files

The user provides a path argument — could be a single file, a glob, or a directory.

- If a single `.md` file: use it directly
- If a glob pattern: expand it
- If a directory: find all `*.md` files in it
- If no argument: use **AskUserQuestion** to ask which file(s) to upload

Read each file and check whether it already has `<!-- Space: -->` metadata headers.

## Phase 3: Add Metadata Headers (if missing)

If a file lacks `<!-- Space: -->` and `<!-- Parent: -->` headers, they must be added before upload.

### Default location

Use **AskUserQuestion** to ask where the page should live:

"Where should this page live on Confluence? Provide the parent page title (or a chain like `Docs > API Reference > Services`)."

The space comes from `MARK_SPACE`. The parent chain is what the user provides.

### Header format

Prepend these headers before the first line of content:

```markdown
<!-- Space: <MARK_SPACE> -->
<!-- Parent: <parent-page-title> -->
<!-- Parent: <child-parent-if-needed> -->
```

For the user's provided parent chain (e.g., `Docs > API > Services`), each `>` segment becomes a separate `<!-- Parent: -->` line.

For child pages that should nest under another page being uploaded in the same batch, add an additional `<!-- Parent: -->` line with the hub page title.

### Title handling

Use `--title-from-h1` so mark reads the page title from the `# H1` heading. No `<!-- Title: -->` header is needed. Use `--drop-h1` so the H1 doesn't duplicate as body content.

## Phase 3.5: Cross-Page Link Syntax

Mark supports linking to other Confluence pages using the `ac:` protocol prefix. When the target page title contains spaces, the URL **must** be wrapped in angle brackets or the link will render as broken text.

```markdown
# WRONG — breaks on Confluence
[Gantry - CLI](ac:Gantry - CLI)

# CORRECT — angle brackets required for titles with spaces
[Gantry - CLI](<ac:Gantry - CLI>)
```

Before uploading, scan each file for `](ac:` links and verify any multi-word titles use the `(<ac:...>)` form. Fix them if not.

## Phase 4: Upload

Upload files using mark. If uploading multiple files with parent-child relationships, upload parents first.

```bash
mark --title-from-h1 --drop-h1 --minor-edit --mermaid-scale 3 --features mermaid -f '<file.md>'
```

Capture the output. Mark prints the page URL on success.

## Phase 5: Post-Upload Cleanup

Mark renders mermaid diagrams as PNG attachments but sets a SHA256 hash as the image `ac:title`, which displays as unwanted caption text on Confluence.

After each successful upload, fix this via the Confluence REST API:

1. Extract the page ID from the URL mark printed
2. GET the page body via REST API
3. Remove hash captions: replace `ac:title="<64-char-hex>"` with `ac:title=""`
4. PUT the cleaned body back

```python
import json, re, urllib.request, base64

def cleanup_page(page_id, username, password, base_url):
    auth = base64.b64encode(f"{username}:{password}".encode()).decode()
    headers = {"Authorization": f"Basic {auth}", "Accept": "application/json"}

    # GET
    req = urllib.request.Request(
        f"{base_url}/rest/api/content/{page_id}?expand=body.storage,version",
        headers=headers
    )
    with urllib.request.urlopen(req) as resp:
        data = json.load(resp)

    body = data["body"]["storage"]["value"]
    version = data["version"]["number"]

    # Check if cleanup needed
    if not re.search(r'ac:title="[a-f0-9]{64}"', body):
        return  # No hash captions to clean

    # Clean hash captions
    body = re.sub(r'ac:title="[a-f0-9]{64}"', 'ac:title=""', body)

    # PUT
    payload = json.dumps({
        "version": {"number": version + 1},
        "title": data["title"],
        "type": "page",
        "body": {"storage": {"value": body, "representation": "storage"}}
    }).encode()
    req = urllib.request.Request(
        f"{base_url}/rest/api/content/{page_id}",
        data=payload, method="PUT",
        headers={**headers, "Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        json.load(resp)
```

Only run cleanup on pages that contain mermaid diagrams (check the source file for ` ```mermaid ` blocks before deciding).

## Phase 6: Report

Print a summary:

```
## Upload Complete

| File | Page Title | URL |
|------|-----------|-----|
| file.md | Page Title | https://your-org.atlassian.net/wiki/... |

Mermaid cleanup: applied to N pages
```

If any file failed, report the error and continue with remaining files.
