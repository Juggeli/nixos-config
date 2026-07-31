import { serve } from "@hono/node-server";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { Store } from "./db.ts";
import { createApp } from "./server.ts";

const dataFile = process.env.DATA_FILE ?? join(process.cwd(), "data", "data.json");
const port = Number(process.env.PORT ?? 3000);
const hostname = process.env.HOST ?? "127.0.0.1";
const publicDir = join(dirname(fileURLToPath(import.meta.url)), "..", "public");

const store = new Store(dataFile);
await store.init();

const app = createApp(store, publicDir);

serve({ fetch: app.fetch, port, hostname }, (info) => {
  console.log(`portion-calculator listening on http://${info.address}:${info.port}`);
  console.log(`data file: ${dataFile}`);
});
