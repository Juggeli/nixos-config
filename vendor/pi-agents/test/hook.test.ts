import assert from "node:assert/strict";
import {
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import test from "node:test";
import ts from "typescript";

const compiled = mkdtempSync(join(process.cwd(), ".hook-test-"));
compileDirectory(join(process.cwd(), "extensions"), compiled);
const { registerHooks } = await import(
  pathToFileURL(join(compiled, "hook.js")).href
);
const { environmentSnippet, toolGuidelinesSnippet } = await import(
  pathToFileURL(join(compiled, "prompt-build.js")).href
);
rmSync(compiled, { recursive: true, force: true });

interface ActiveAgentState {
  name: string;
  savedTools: string[];
  savedModelId?: string;
  savedThinkingLevel?: string;
}

function compileDirectory(
  sourceDirectory: string,
  targetDirectory: string,
): void {
  mkdirSync(targetDirectory, { recursive: true });
  for (const entry of readdirSync(sourceDirectory, { withFileTypes: true })) {
    const sourcePath = join(sourceDirectory, entry.name);
    if (entry.isDirectory()) {
      compileDirectory(sourcePath, join(targetDirectory, entry.name));
      continue;
    }
    if (!entry.isFile() || !entry.name.endsWith(".ts")) continue;
    const output = ts.transpileModule(readFileSync(sourcePath, "utf8"), {
      compilerOptions: {
        module: ts.ModuleKind.ESNext,
        target: ts.ScriptTarget.ES2022,
      },
    }).outputText;
    writeFileSync(
      join(targetDirectory, entry.name.replace(/\.ts$/, ".js")),
      output,
    );
  }
}

test("renders active tool guidelines without duplicating the tool list", () => {
  const pi = {
    getAllTools: () => [
      { name: "read", promptGuidelines: ["Use read to inspect files."] },
      { name: "bash", promptGuidelines: ["Use bash only when needed."] },
      { name: "hidden", promptGuidelines: ["Do not expose this."] },
    ],
  };

  assert.equal(
    toolGuidelinesSnippet(pi as never, ["read", "bash"]),
    "\n\n<tool_guidelines>\n" +
      "  - read: Use read to inspect files.\n" +
      "  - bash: Use bash only when needed.\n" +
      "</tool_guidelines>",
  );
  assert.doesNotMatch(
    environmentSnippet("/tmp", "test-model"),
    /Available tools/,
  );
});

test("activates the default agent when a new session starts", async () => {
  const cwd = mkdtempSync(join(tmpdir(), "pi-agents-hook-"));
  const agentDirectory = join(cwd, ".pi", "agents");
  mkdirSync(agentDirectory, { recursive: true });
  writeFileSync(
    join(agentDirectory, "default-agent.md"),
    `---
name: default-agent
description: Default test agent
tools:
  - read
thinkingLevel: high
---

Default prompt.
`,
  );
  writeFileSync(
    join(cwd, ".pi", "pi-agents.json"),
    JSON.stringify({ defaultAgent: "default-agent" }),
  );

  const previousAgentDirectory = process.env.PI_CODING_AGENT_DIR;
  const previousDefaultAgent = process.env.PI_DEFAULT_AGENT;
  process.env.PI_CODING_AGENT_DIR = join(cwd, "missing-global-agents");
  delete process.env.PI_DEFAULT_AGENT;

  let activeAgent: ActiveAgentState | null = null;
  let tools = ["read", "bash"];
  let thinkingLevel = "medium";
  let sessionStart:
    ((event: { reason: string }, context: any) => Promise<void>) | undefined;
  const statuses: string[] = [];
  const pi = {
    getActiveTools: () => tools,
    getThinkingLevel: () => thinkingLevel,
    on(event: string, handler: typeof sessionStart) {
      if (event === "session_start") sessionStart = handler;
    },
    setActiveTools: (next: string[]) => {
      tools = next;
    },
    setThinkingLevel: (next: string) => {
      thinkingLevel = next;
    },
  };
  const context = {
    cwd,
    modelRegistry: { find: () => undefined, getAll: () => [] },
    ui: {
      notify: () => undefined,
      setStatus: (_key: string, value: string) => statuses.push(value),
      theme: { fg: (_tone: string, value: string) => value },
    },
  };

  try {
    registerHooks(pi as never, () => activeAgent?.name ?? null, {
      setActiveAgentState: (state) => {
        activeAgent = state;
      },
    });

    await sessionStart?.({ reason: "new" }, context);

    assert.equal(activeAgent?.name, "default-agent");
    assert.deepEqual(tools, ["read"]);
    assert.equal(thinkingLevel, "high");
    assert.deepEqual(statuses, ["Agent: default-agent"]);
  } finally {
    if (previousAgentDirectory === undefined)
      delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previousAgentDirectory;
    if (previousDefaultAgent === undefined) delete process.env.PI_DEFAULT_AGENT;
    else process.env.PI_DEFAULT_AGENT = previousDefaultAgent;
    rmSync(cwd, { recursive: true, force: true });
  }
});
