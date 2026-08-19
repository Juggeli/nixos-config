import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  getDefaultAgentName,
  getWorkspaceDefaultAgentName,
  setWorkspaceDefaultAgentName,
} from "../extensions/config.ts";

test("resolves and persists a workspace default", () => {
  const root = mkdtempSync(join(tmpdir(), "pi-agents-config-"));
  const cwd = join(root, "workspace");
  const previousHome = process.env.HOME;
  const previousDefaultAgent = process.env.PI_DEFAULT_AGENT;
  mkdirSync(join(root, "home"), { recursive: true });
  process.env.HOME = join(root, "home");
  delete process.env.PI_DEFAULT_AGENT;

  try {
    setWorkspaceDefaultAgentName(cwd, "planner");

    assert.equal(getWorkspaceDefaultAgentName(cwd), "planner");
    assert.equal(getDefaultAgentName(cwd), "planner");
    assert.deepEqual(
      JSON.parse(readFileSync(join(cwd, ".pi", "pi-agents.json"), "utf8")),
      { defaultAgent: "planner" },
    );

    setWorkspaceDefaultAgentName(cwd, null);
    assert.equal(getWorkspaceDefaultAgentName(cwd), null);
    assert.equal(getDefaultAgentName(cwd), undefined);

    setWorkspaceDefaultAgentName(cwd, undefined);
    assert.equal(getWorkspaceDefaultAgentName(cwd), undefined);
  } finally {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;
    if (previousDefaultAgent === undefined) delete process.env.PI_DEFAULT_AGENT;
    else process.env.PI_DEFAULT_AGENT = previousDefaultAgent;
    rmSync(root, { recursive: true, force: true });
  }
});
