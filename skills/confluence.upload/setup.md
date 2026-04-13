# Confluence Upload — First-Time Setup

Two tools are required: `mark` (markdown-to-Confluence CLI) and `google-chrome` (headless Chrome for mermaid diagram rendering).

---

## macOS

Package managers handle integrity verification automatically.

### mark CLI

```bash
brew install kovetskiy/mark/mark
mark --version
```

### Google Chrome

```bash
brew install --cask google-chrome
```

---

## Linux (Container)

These dependencies are ephemeral — re-run after a container rebuild.

### mark CLI

Download the release binary and verify it against the checksums file published alongside the release before installing:

```bash
MARK_VERSION="15.3.0"

curl -fsSL -o /tmp/mark.tar.gz \
  "https://github.com/kovetskiy/mark/releases/download/v${MARK_VERSION}/mark_Linux_x86_64.tar.gz"

# Download the release checksum manifest
curl -fsSL -o /tmp/mark_checksums.txt \
  "https://github.com/kovetskiy/mark/releases/download/v${MARK_VERSION}/checksums.txt"

# Verify — aborts loudly if the checksum doesn't match
grep "mark_Linux_x86_64.tar.gz" /tmp/mark_checksums.txt | sha256sum --check --status \
  || { echo "ERROR: Checksum verification failed. Do not proceed."; rm -f /tmp/mark.tar.gz /tmp/mark_checksums.txt; exit 1; }

tar -xzf /tmp/mark.tar.gz -C /tmp/
install -m 755 /tmp/mark /usr/local/bin/mark
rm -f /tmp/mark.tar.gz /tmp/mark /tmp/mark_checksums.txt
mark --version
```

> If `checksums.txt` is not found at that URL, check the [releases page](https://github.com/kovetskiy/mark/releases) for the actual checksum filename and update the `curl` line above.

### Google Chrome (GPG-verified apt repository)

Use the official Google apt repository with GPG signature verification instead of a direct `.deb` download:

```bash
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
  http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list

apt-get update -qq && apt-get install -y -qq google-chrome-stable
```

---

## Confluence API Token

Create a personal API token at: https://id.atlassian.com/manage-profile/security/api-tokens

Set these environment variables — never commit them to source control:

```bash
export MARK_USERNAME="your-email@example.com"
export MARK_PASSWORD="your-api-token"
export MARK_BASE_URL="https://your-company.atlassian.net/wiki"
export MARK_SPACE="YOURSPACE"
```

---

## Verification

```bash
mark --version       # mark is installed
which google-chrome  # Chrome is installed for mermaid rendering
```

---

## Upgrading mark

Change `MARK_VERSION` in the Linux script above and retrieve the new checksum from the [releases page](https://github.com/kovetskiy/mark/releases). Brew users just run `brew upgrade kovetskiy/mark/mark`.
