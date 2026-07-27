#!/bin/zsh
# social-preview.sh — render and upload a repo's social preview card.
#
# Usage:
#   ./Scripts/social-preview.sh <owner>/<name>            # render + upload (default)
#   ./Scripts/social-preview.sh <owner>/<name> --no-upload # render only; auto-open Finder + Settings
#   ./Scripts/social-preview.sh --backfill <owner>         # render + upload all public repos in org
#
# Reads the org-level brand from <org>/.github/metadata.yaml (socialPreview
# block: accent + caption), derives the namespace from the package name
# (kebab → CamelCase, strip layer suffix), renders the PNG via the universal
# renderer at swift-institute/.github/social-preview/, and uploads via the
# vendored Playwright uploader at Scripts/social-preview-uploader/.
#
# Why local-only?
# GitHub does not expose a public API for setting the social preview image
# (verified 2026-05). The only path is browser session-cookie automation,
# which CANNOT live in CI (cookie is password-equivalent). Run locally; the
# vendored uploader uses your existing browser session — same privilege as
# manually clicking "Edit" in the UI.
#
# First-time setup:
#   cd Scripts/social-preview-uploader && npm install
#   node upload.js init-auth                       # one browser login, persisted
#
# Dependencies on PATH:
#   gh, python3, node, npm, rsvg-convert (or resvg), yq

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORG_ROOT="$(dirname "$SCRIPT_DIR")"          # swift-institute/
DEVELOPER_DIR="$(dirname "$ORG_ROOT")"        # ~/Developer/

RENDERER="$ORG_ROOT/.github/social-preview/render.py"
CHASSIS="$ORG_ROOT/.github/social-preview/chassis.svg.tmpl"
UPLOADER_DIR="$SCRIPT_DIR/social-preview-uploader"
UPLOADER="$UPLOADER_DIR/upload.js"

# ── Argument parsing ─────────────────────────────────────────────────────────
NO_UPLOAD=false
BACKFILL=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-upload)
            NO_UPLOAD=true
            shift
            ;;
        --backfill)
            BACKFILL=true
            shift
            ;;
        -h|--help)
            sed -n '/^# Usage:/,/^# Dependencies/p' "$0" | sed 's/^# //;s/^#//'
            exit 0
            ;;
        -*)
            echo "Error: unknown flag '$1'" >&2
            exit 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: missing target. Usage: $0 <owner>/<name> [--no-upload]" >&2
    echo "                       $0 --backfill <owner>" >&2
    exit 2
fi

# ── Dependency probe ─────────────────────────────────────────────────────────
require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' not on PATH. $2" >&2
        exit 1
    fi
}

require_cmd gh "Install via 'brew install gh'."
require_cmd python3 "Bundled with macOS; check 'xcode-select --install'."
require_cmd yq "Install via 'brew install yq'."

if command -v rsvg-convert >/dev/null 2>&1; then
    SVG_RENDERER="rsvg-convert"
elif command -v resvg >/dev/null 2>&1; then
    SVG_RENDERER="resvg"
else
    echo "Error: neither rsvg-convert nor resvg on PATH. Install via 'brew install librsvg'." >&2
    exit 1
fi

if [[ "$NO_UPLOAD" == "false" ]]; then
    require_cmd node "Install via 'brew install node'."
    if [[ ! -d "$UPLOADER_DIR/node_modules" ]]; then
        echo "Error: uploader dependencies not installed." >&2
        echo "  cd $UPLOADER_DIR && npm install" >&2
        echo "  Then:  node upload.js init-auth   # one-time browser login" >&2
        exit 1
    fi
fi

# ── Render and (optionally) upload one card ──────────────────────────────────
render_one() {
    local target="$1"
    local owner="${target%%/*}"
    local name="${target##*/}"

    # Brand defaults from <org>/.github/metadata.yaml
    local org_metadata="$DEVELOPER_DIR/$owner/.github/metadata.yaml"
    if [[ ! -f "$org_metadata" ]]; then
        echo "Error: $org_metadata not found. The org's brand declaration is required." >&2
        return 1
    fi

    local accent_from accent_to accent_text caption
    accent_from=$(yq '.socialPreview.accent.from' "$org_metadata")
    accent_to=$(yq '.socialPreview.accent.to' "$org_metadata")
    accent_text=$(yq '.socialPreview.accent.text' "$org_metadata")
    caption=$(yq '.socialPreview.caption' "$org_metadata")

    if [[ "$accent_from" == "null" || -z "$accent_from" ]]; then
        echo "Error: $org_metadata has no .socialPreview.accent.from" >&2
        return 1
    fi

    # Namespace: prefer per-repo override in target's metadata.yaml, else derive.
    local namespace=""
    local target_metadata="$DEVELOPER_DIR/$owner/$name/.github/metadata.yaml"
    if [[ -f "$target_metadata" ]]; then
        local override
        override=$(yq '.socialPreview.displayName // ""' "$target_metadata")
        if [[ -n "$override" && "$override" != "null" ]]; then
            namespace="$override"
        fi
    fi
    if [[ -z "$namespace" ]]; then
        # Strip swift- prefix and trailing layer/standard suffix, then
        # convert kebab to display form. Authority codes (rfc, iso, ieee,
        # iec, w3c, whatwg, ecma, incits, bcp) are uppercased and
        # space-separated. Common acronyms (uri, pdf, css, html, json,
        # etc.) are uppercased. Numeric "standard-year" pairs (e.g.
        # incits-4-1986) join with hyphen.
        local stripped
        stripped=$(echo "$name" | sed -E 's/^swift-//; s/-(primitives|standards|foundations|standard)$//')
        namespace=$(echo "$stripped" | awk -F'-' '
            BEGIN {
                authority = " rfc iso ieee iec w3c whatwg ecma incits bcp "
                acronym = " uri url uuid pdf css html xml json rss svg png http https dns tcp udp ip io smtp imap pop3 sql sha md5 utf ascii iana ietf cpu epub "
                # Mixed-case overrides for tokens that need specific casing.
                special["ipv4"] = "IPv4"
                special["ipv6"] = "IPv6"
                special["github"] = "GitHub"
                special["urlrequest"] = "URLRequest"
                special["x86"] = "x86"
                special["leb128"] = "LEB128"
            }
            function format_token(t,    lower, stem) {
                lower = tolower(t)
                if (lower in special) return special[lower]
                if (index(acronym, " " lower " ") > 0) return toupper(t)
                # Pluralised acronym (uuids -> UUIDs). Checked only after the
                # exact-acronym match so https stays HTTPS, not HTTPs.
                if (lower ~ /s$/) {
                    stem = substr(lower, 1, length(lower) - 1)
                    if (index(acronym, " " stem " ") > 0) return toupper(stem) "s"
                }
                return toupper(substr(t, 1, 1)) tolower(substr(t, 2))
            }
            {
                out = ""
                authority_mode = 0
                for (i = 1; i <= NF; i++) {
                    token = $i
                    lower = tolower(token)
                    if (i == 1 && index(authority, " " lower " ") > 0) {
                        out = toupper(token)
                        authority_mode = 1
                    } else if (authority_mode) {
                        # Join consecutive numeric tokens with hyphen
                        # (standard-year pattern), else space-separate.
                        if (token ~ /^[0-9]+$/ && i > 2 && $(i-1) ~ /^[0-9]+$/) {
                            out = out "-" token
                        } else if (token ~ /^[0-9]+$/) {
                            out = out " " token
                        } else {
                            out = out " " format_token(token)
                        }
                    } else {
                        # Non-authority: space-separate for readability.
                        if (i == 1) out = format_token(token)
                        else out = out " " format_token(token)
                    }
                }
                print out
            }
        ')
    fi
    if [[ -z "$namespace" ]]; then
        echo "Error: could not derive namespace for $target" >&2
        return 1
    fi

    # Render
    local svg="/tmp/social-preview-$name.svg"
    local png="/tmp/social-preview-$name.png"
    python3 "$RENDERER" \
        --template "$CHASSIS" \
        --namespace "$namespace" \
        --package-name "$name" \
        --accent-from "$accent_from" \
        --accent-to "$accent_to" \
        --accent-text "$accent_text" \
        --caption "$caption" \
        --output "$svg"

    if [[ "$SVG_RENDERER" == "rsvg-convert" ]]; then
        rsvg-convert -w 1280 -h 640 "$svg" -o "$png"
    else
        resvg --width 1280 --height 640 "$svg" "$png"
    fi

    local size
    size=$(stat -f%z "$png")
    if [[ $size -gt 1048576 ]]; then
        echo "Error: rendered PNG exceeds 1 MB cap ($size bytes)" >&2
        return 1
    fi

    echo "  $target → $namespace ($caption, $size bytes)"

    if [[ "$NO_UPLOAD" == "true" ]]; then
        echo "    rendered: $png"
        # Auto-open Finder + Settings for manual drag-drop (single-target only;
        # in backfill mode this would spawn ~N Finder windows + browser tabs).
        if [[ "$BACKFILL" == "false" ]]; then
            open -R "$png" 2>/dev/null || true
            open "https://github.com/$target/settings#social-preview" 2>/dev/null || true
        fi
        return 0
    fi

    # Upload via vendored Playwright wrapper
    node "$UPLOADER" --repo "$target" --image "$png"
}

# ── Backfill across an org ───────────────────────────────────────────────────
if [[ "$BACKFILL" == "true" ]]; then
    org="$TARGET"
    echo "Enumerating public swift-* repos in $org…"
    repos=$(gh repo list "$org" --limit 2000 --no-archived --json name,isPrivate \
        --jq '[.[] | select(.isPrivate == false) | select(.name | startswith("swift-")) | select(.name | endswith(".org") | not) | .name] | .[]')
    n=$(echo "$repos" | wc -l | tr -d ' ')
    echo "Targets: $n"
    i=0
    echo "$repos" | while read -r name; do
        i=$((i+1))
        printf "[%d/%d] " "$i" "$n"
        render_one "$org/$name" || echo "    ERROR (continuing)"
    done
    exit 0
fi

# Single-target
render_one "$TARGET"
