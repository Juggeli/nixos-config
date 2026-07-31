import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { Data } from "./types.ts";

const EMPTY: Data = { vessels: [], calculations: [] };

/**
 * File-backed JSON store. All mutations go through `update`, which serializes
 * read-modify-write cycles and persists atomically (write temp file, rename).
 */
export class Store {
  private queue: Promise<unknown> = Promise.resolve();
  private readonly path: string;

  constructor(path: string) {
    this.path = path;
  }

  async init(): Promise<void> {
    await mkdir(dirname(this.path), { recursive: true });
    try {
      await readFile(this.path, "utf8");
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ENOENT") {
        await this.writeRaw(EMPTY);
      } else {
        throw err;
      }
    }
  }

  async read(): Promise<Data> {
    try {
      const raw = await readFile(this.path, "utf8");
      const parsed = JSON.parse(raw) as Partial<Data>;
      return {
        vessels: Array.isArray(parsed.vessels) ? parsed.vessels : [],
        calculations: Array.isArray(parsed.calculations) ? parsed.calculations : [],
      };
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ENOENT") {
        return { ...EMPTY };
      }
      throw err;
    }
  }

  /** Run `fn` against the current data and persist whatever it returns. */
  update<T>(fn: (data: Data) => T | Promise<T>): Promise<T> {
    const run = this.queue.then(async () => {
      const data = await this.read();
      const result = await fn(data);
      await this.writeRaw(data);
      return result;
    });
    // Keep the chain alive even if a step throws.
    this.queue = run.catch(() => undefined);
    return run;
  }

  private async writeRaw(data: Data): Promise<void> {
    const tmp = `${this.path}.tmp`;
    await writeFile(tmp, JSON.stringify(data, null, 2), "utf8");
    await rename(tmp, this.path);
  }
}
