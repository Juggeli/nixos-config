import assert from "node:assert/strict";
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import test from "node:test";
import ts from "typescript";

const compiled = mkdtempSync(join(process.cwd(), ".cmd-agent-test-"));
for (const name of [
  "cmd-agent",
  "registry",
  "activation",
  "config",
  "prompt-store",
  "tools-store",
  "types",
]) {
  const source = readFileSync(
    join(process.cwd(), "extensions", `${name}.ts`),
    "utf8",
  );
  const output = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2022,
    },
  }).outputText;
  writeFileSync(join(compiled, `${name}.js`), output);
}
const { activateAgent, registerAgentCommand } = await import(
  pathToFileURL(join(compiled, "cmd-agent.js")).href
);
rmSync(compiled, { recursive: true, force: true });

const webArchitect = `---
name: agent-architect-web
description: Web architect
tools: [web_search, fetch_content, get_search_content]
---

Design agents.
`;

test("configures a workspace default without changing the global default", async () => {
  const root = mkdtempSync(join(tmpdir(), "pi-agents-cmd-"));
  const previousHome = process.env.HOME;
  const previousDefaultAgent = process.env.PI_DEFAULT_AGENT;
  const notifications: Array<{ message: string; level: string }> = [];
  const commands = new Map<string, any>();
  process.env.HOME = join(root, "home");
  delete process.env.PI_DEFAULT_AGENT;
  mkdirSync(join(root, ".pi", "agents"), { recursive: true });
  writeFileSync(
    join(root, ".pi", "agents", "workspace-agent.md"),
    `---
name: workspace-agent
description: Workspace agent
---

Work locally.
`,
  );

  try {
    registerAgentCommand(
      {
        registerCommand(name: string, command: any) {
          commands.set(name, command);
        },
      } as any,
      () => null,
      () => undefined,
    );

    await commands.get("agent-default").handler("--workspace workspace-agent", {
      cwd: root,
      ui: {
        notify(message: string, level: string) {
          notifications.push({ message, level });
        },
      },
    });

    assert.deepEqual(
      JSON.parse(readFileSync(join(root, ".pi", "pi-agents.json"), "utf8")),
      { defaultAgent: "workspace-agent" },
    );
    assert.deepEqual(notifications, [
      {
        message:
          "Workspace default agent: workspace-agent — active at next pi start (or /agent workspace-agent to activate now)",
        level: "info",
      },
    ]);
  } finally {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;
    if (previousDefaultAgent === undefined) delete process.env.PI_DEFAULT_AGENT;
    else process.env.PI_DEFAULT_AGENT = previousDefaultAgent;
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses the web architect when pi-web-access is unavailable", async () => {
  const root = mkdtempSync(join(tmpdir(), "pi-agents-cmd-"));
  const previousDir = process.env.PI_CODING_AGENT_DIR;
  const notifications: Array<{ message: string; level: string }> = [];
  let stateChanges = 0;
  process.env.PI_CODING_AGENT_DIR = join(root, "agent-home");
  mkdirSync(join(process.env.PI_CODING_AGENT_DIR, "agents"), {
    recursive: true,
  });
  writeFileSync(
    join(process.env.PI_CODING_AGENT_DIR, "agents", "agent-architect-web.md"),
    webArchitect,
  );

  const pi = {
    getAllTools: () => [{ name: "read" }],
  };
  const ctx = {
    cwd: root,
    ui: {
      notify(message: string, level: string) {
        notifications.push({ message, level });
      },
    },
  };

  try {
    await activateAgent(
      pi as any,
      ctx as any,
      "agent-architect-web",
      () => null,
      () => {
        stateChanges++;
      },
    );

    assert.equal(stateChanges, 0);
    assert.deepEqual(notifications, [
      {
        message:
          'Agent "agent-architect-web" requires pi-web-access (missing: web_search, fetch_content, get_search_content). Install it with "pi install npm:pi-web-access", then run /reload; or use /agent agent-architect.',
        level: "error",
      },
    ]);
  } finally {
    if (previousDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previousDir;
    rmSync(root, { recursive: true, force: true });
  }
});
