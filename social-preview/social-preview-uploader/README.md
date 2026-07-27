# social-preview-uploader

Minimal Playwright uploader for GitHub repository social preview images.
Vendored from [AnswerDotAI/gh-social-preview](https://github.com/AnswerDotAI/gh-social-preview)
(ISC license) with the README-screenshot logic stripped — accepts a
pre-rendered PNG via `--image`.

Used by the adjacent `social-preview.sh` to upload chassis-rendered cards.
GitHub does not expose a public API for this setting; Playwright UI
automation is the only path.

## One-time setup

```bash
cd swift-institute/Skills/social-preview/social-preview-uploader
npm install                 # installs playwright + downloads Chromium (~150 MB)
node upload.js init-auth    # opens browser; log in; session saved to disk
```

The session is saved at `$XDG_STATE_HOME/gh-social-preview/auth/github.json`
(falls back to `~/.local/state/gh-social-preview/auth/github.json`). Same
location as the upstream `gh-social-preview` tool, so the two share auth
state.

## Direct use

```bash
node upload.js --repo owner/name --image /path/to/social-preview.png
```

Headless (no visible browser). Prints `✅ <repo>: uploaded` on success.

## Indirect use (via wrapper)

```bash
swift-institute/Skills/social-preview/social-preview.sh --upload swift-primitives/swift-buffer-primitives
```

Renders + uploads in one step.

## Caveats

- The session cookie is password-equivalent. **Local-only** — must not be
  stored in CI secrets. See `Research/social-preview-cards-ecosystem-strategy.md`.
- Brittle to GitHub UI selector changes; if upload silently fails, check
  whether `#edit-social-preview-button`, `input#repo-image-file-input`, or
  `input.js-repository-image-id` were renamed.
- Re-run `node upload.js init-auth` if the saved session expires.
