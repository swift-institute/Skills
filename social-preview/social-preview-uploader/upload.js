#!/usr/bin/env node
/**
 * upload.js — minimal Playwright uploader for GitHub repository social preview
 * images. Vendored from AnswerDotAI/gh-social-preview (ISC license) with the
 * README-screenshot logic stripped; accepts a pre-rendered PNG via --image.
 *
 * Why vendored: the upstream tool only screenshots the README; it has no
 * --image flag for our custom-rendered chassis cards.
 *
 * Commands:
 *   node upload.js init-auth                          # one-time browser login
 *   node upload.js --repo owner/name --image path.png # upload
 *
 * Provenance: Research/social-preview-cards-ecosystem-strategy.md
 */

const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright");

const BASE_URL = "https://github.com";

// ── Storage state path (matches gh-social-preview default for cookie reuse) ──
const xdgState = process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state");
const STATE_PATH = path.join(xdgState, "gh-social-preview/auth/github.json");

function parseArgs(argv) {
    const out = { _: [] };
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a.startsWith("--")) {
            const key = a.slice(2);
            const next = argv[i + 1];
            if (!next || next.startsWith("--")) {
                out[key] = true;
            } else {
                out[key] = next;
                i++;
            }
        } else {
            out._.push(a);
        }
    }
    return out;
}

async function initAuth() {
    fs.mkdirSync(path.dirname(STATE_PATH), { recursive: true });

    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();

    console.log(`Opening ${BASE_URL}/login …`);
    await page.goto(`${BASE_URL}/login`, { waitUntil: "domcontentloaded" });
    console.log("\nLog in (including 2FA). Session will be saved automatically.\n");

    page.setDefaultTimeout(0);
    page.setDefaultNavigationTimeout(0);
    await page.waitForFunction(() => {
        const meta = document.querySelector('meta[name="user-login"]')?.content?.trim();
        return !!meta;
    }, null, { polling: 500 });

    const username = await page.evaluate(() =>
        document.querySelector('meta[name="user-login"]')?.content?.trim() || ""
    );

    await context.storageState({ path: STATE_PATH });
    await browser.close();
    console.log(`✅ Saved session for @${username} to ${STATE_PATH}`);
}

async function upload(repo, imagePath, headed = false) {
    if (!fs.existsSync(STATE_PATH)) {
        throw new Error(
            `No saved session at ${STATE_PATH}. Run: node upload.js init-auth`
        );
    }
    if (!fs.existsSync(imagePath)) {
        throw new Error(`Image not found: ${imagePath}`);
    }

    const settingsUrl = `${BASE_URL}/${repo}/settings`;
    const browser = await chromium.launch({ headless: !headed, slowMo: headed ? 500 : 0 });
    const context = await browser.newContext({
        storageState: STATE_PATH,
        viewport: { width: 1280, height: 720 },
    });
    const page = await context.newPage();
    page.setDefaultTimeout(30_000);

    await page.goto(settingsUrl, { waitUntil: "domcontentloaded" });
    // A dead session doesn't always redirect to /login — GitHub serves repo
    // settings pages as a 404 to the now-anonymous user, so the /login check
    // alone misses expiry and the run later dies on a 60s selector timeout.
    // Assert the logged-in meta tag is present too.
    const loggedIn = await page.evaluate(
        () => !!document.querySelector('meta[name="user-login"]')?.content?.trim()
    );
    if (page.url().includes("/login") || !loggedIn) {
        await browser.close();
        throw new Error("Session expired — re-run: node upload.js init-auth");
    }

    const heading = page.locator("xpath=//h2[normalize-space()='Social preview']").first();
    const editButton = page.locator("#edit-social-preview-button");
    const fileInput = page.locator("input#repo-image-file-input");
    const uploadMenu = page.getByText(/upload an image/i).first();
    const imageIdInput = page.locator("input.js-repository-image-id");
    const imageContainer = page.locator(".js-repository-image-container");

    await heading.waitFor({ state: "attached", timeout: 60_000 });
    await heading.scrollIntoViewIfNeeded().catch(() => {});

    let prevId = "";
    if (await imageIdInput.count()) {
        prevId = (await imageIdInput.first().inputValue().catch(() => "")).trim();
    }

    if (await editButton.count()) {
        await editButton.first().click({ force: true }).catch(() => {});
    }

    await Promise.any([
        fileInput.first().waitFor({ state: "attached", timeout: 30_000 }),
        uploadMenu.waitFor({ state: "visible", timeout: 30_000 }),
    ]);

    const uploadResponse = page.waitForResponse(
        (resp) => {
            const u = resp.url();
            const ok = resp.status() >= 200 && resp.status() < 300;
            return ok && (u.includes("/upload/repository-images/") ||
                          u.includes("/upload/policies/repository-images"));
        },
        { timeout: 20_000 }
    ).catch(() => null);

    if (await fileInput.count()) {
        await fileInput.first().setInputFiles(imagePath);
    } else {
        const [chooser] = await Promise.all([
            page.waitForEvent("filechooser"),
            uploadMenu.click({ force: true }),
        ]);
        await chooser.setFiles(imagePath);
    }

    const networkOk = !!(await uploadResponse);

    // Network response only signals "image bytes received". GitHub commits the
    // image to the social_preview_id slot asynchronously; closing the browser
    // before that completes leaves a stale og:image pointing to nothing
    // (S3 AccessDenied). Wait for both confirmation signals per upstream.

    // 1. Wait for image-id input to change (or populate, if first upload).
    if (!networkOk) {
        await page.waitForFunction(
            ({ prev }) => {
                const el = document.querySelector("input.js-repository-image-id");
                if (!el) return false;
                const v = (el.value || "").trim();
                return !!v && v !== prev;
            },
            { prev: prevId },
            { timeout: 30_000 }
        ).catch(() => {});
    }

    // 2. Always wait for image-id to be non-empty (catches the "first upload"
    // case where prevId was empty and waitForResponse fired before id populated).
    await page.waitForFunction(
        () => {
            const el = document.querySelector("input.js-repository-image-id");
            return !!((el?.value || "").trim());
        },
        { timeout: 20_000 }
    ).catch(() => {});

    // 3. Wait for image container to be visible (commit-to-slot signal).
    if (await imageContainer.count()) {
        await page.waitForFunction(
            () => {
                const el = document.querySelector(".js-repository-image-container");
                return el && el.hidden === false;
            },
            { timeout: 30_000 }
        ).catch(() => {});
    }

    // 4. Wait for all pending network requests (S3 upload, attach POST) to
    // complete. The image-id can populate before the S3 upload finishes —
    // closing the browser early leaves a stale image_id on a non-existent
    // S3 object.
    await page.waitForLoadState("networkidle", { timeout: 30_000 }).catch(() => {});

    // 5. Final assertion: image-id is set.
    const newId = (await imageIdInput.first().inputValue().catch(() => "")).trim();
    if (!newId) {
        await browser.close();
        throw new Error(`${repo}: upload did not produce a social_preview image id`);
    }

    await browser.close();
    console.log(`✅ ${repo}: uploaded (id=${newId.slice(0, 8)}…)`);
}

async function main() {
    const args = parseArgs(process.argv.slice(2));
    if (args._[0] === "init-auth") {
        await initAuth();
        return;
    }
    if (!args.repo || !args.image) {
        console.error("Usage: node upload.js --repo owner/name --image path.png [--headed]");
        console.error("       node upload.js init-auth");
        process.exit(2);
    }
    await upload(args.repo, args.image, !!args.headed);
}

main().catch((err) => {
    console.error(`✗ ${err.message}`);
    process.exit(1);
});
