---
name: publish-plan
description: Publish an HTML plan, report, or interactive draft to plans.jugi.cc and return a shareable URL. Use when the user asks to publish or share an artifact through their self-hosted plans service.
---

Publish with `publish-plan`, available globally on the user's machines.

Create a self-contained UTF-8 HTML file with inline CSS and, when useful, inline
JavaScript. Maximum size: 5 MiB. Include a viewport meta tag for mobile viewing.
Scripts run in a sandbox: network requests, external scripts, forms, frames,
browser storage, and access to the parent origin are blocked. Embed fonts and
images as data URLs where possible; HTTPS images are also supported.

Publishing makes the content accessible to anyone with its unlisted link.
Publish the artifact the user requested; exclude credentials and unrelated
private files. A request to publish or share authorizes that upload.

```sh
publish-plan upload ./plan.html --title "Migration plan"
```

Return the resulting `url` as a clickable link. Keep the returned draft `id`
when revising the same artifact:

```sh
publish-plan upload ./plan.html --id DRAFT_ID --title "Migration plan"
publish-plan list
```

Updates preserve the shared URL and append an immutable version, available at
`versionUrl`. Previous versions remain accessible. `rawUrl` serves the HTML bytes
for other agents to read. `list` requires the publishing credential.

The global CLI automatically uses the shared agenix credential on every
configured NixOS and macOS machine. No login or environment setup is needed
after applying the machine's configuration. Never print or put the decrypted
credential in command arguments, HTML, or source control. If it is missing,
report that the machine's configuration needs to be applied; preserve the local
artifact. `PLANS_KEY_FILE` can override the credential path for testing, and
`PLANS_API_URL` overrides the default `https://plans.jugi.cc` endpoint.
