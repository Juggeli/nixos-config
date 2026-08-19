import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import test from "node:test";
import ts from "typescript";

const compiled = mkdtempSync(join(process.cwd(), ".activation-test-"));
for (const name of ["activation", "registry", "types"]) {
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
const { applyAgent } = await import(
  pathToFileURL(join(compiled, "activation.js")).href
);
rmSync(compiled, { recursive: true, force: true });

test("applyAgent applies thinkingLevel after setModel so it survives the model switch", async () => {
  // Simulates the bug: set_model re-applies the global default thinking level
  // ("high"). The agent's thinkingLevel ("medium") must be applied last.
  let orderedOps: string[] = [];
  let thinkingLevel = "high"; // global default

  const pi = {
    getActiveTools: () => ["read"],
    getThinkingLevel: () => thinkingLevel,
    setActiveTools: (_tools: string[]) => {},
    setThinkingLevel: (next: string) => {
      thinkingLevel = next;
      orderedOps.push(`thinking:${next}`);
    },
    setModel: async (_model: unknown) => {
      // Simulate set_model re-applying the global default
      thinkingLevel = "high";
      orderedOps.push("model");
      return true;
    },
  };

  const context = {
    modelRegistry: {
      find: (_provider: string, _id: string) => ({
        provider: "test",
        id: "some-model",
      }),
      getAll: () => [],
    },
    model: { provider: "test", id: "old-model" },
    ui: {
      notify: () => undefined,
    },
  };

  const agent = {
    name: "test-agent",
    description: "Test",
    thinkingLevel: "medium",
    model: "test/some-model",
    systemPrompt: "Test prompt",
    source: "user" as const,
    filePath: "/tmp/test.md",
  };

  // Use null prevState so the restore point is captured from current settings.
  const state = await applyAgent(pi as never, context as never, agent, null);

  // Assert: thinking applied AFTER model
  assert.deepEqual(orderedOps, ["model", "thinking:medium"]);
  // Assert: the restore point captured was "high" (the pre-agent level)
  assert.equal(state.savedThinkingLevel, "high");
  // Assert: final thinking level is the agent's, not the global default
  assert.equal(thinkingLevel, "medium");
});
