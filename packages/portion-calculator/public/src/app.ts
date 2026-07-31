interface Vessel {
  id: string;
  name: string;
  weight: number;
  createdAt: string;
}

interface Calculation {
  id: string;
  vesselId: string;
  vesselName: string;
  vesselWeight: number;
  totalWeight: number;
  portions: number;
  portionWeight: number;
  netWeight: number;
  note?: string;
  createdAt: string;
  warning?: boolean;
}

type View = "calculator" | "vessels" | "history";

interface Prefill {
  vesselId?: string;
  totalWeight?: number;
  portions?: number;
  note?: string;
}

const state: { view: View; prefill: Prefill } = { view: "calculator", prefill: {} };

const view = document.getElementById("view") as HTMLElement;

// Pastel accents used for vessel avatars (Catppuccin Mocha).
const AVATAR_COLORS = ["#fab387", "#cba6f7", "#89b4fa", "#94e2d5", "#a6e3a1", "#f9e2af", "#f5c2e7", "#74c7ec"];

// --- API ---

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  const body = await res.json().catch(() => null);
  if (!res.ok) {
    throw new Error((body && body.error) || `Request failed (${res.status})`);
  }
  return body as T;
}

const getVessels = () => api<Vessel[]>("/api/vessels");
const getCalculations = () => api<Calculation[]>("/api/calculations");

// --- Helpers ---

function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  attrs: Record<string, string> = {},
  ...children: (Node | string)[]
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  for (const child of children) node.append(child);
  return node;
}

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function fmt(n: number): string {
  return `${round2(n)} g`;
}

function colorFor(name: string): string {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return AVATAR_COLORS[h % AVATAR_COLORS.length];
}

function avatar(name: string): HTMLElement {
  const a = el("span", { class: "avatar" }, name.trim().charAt(0) || "?");
  a.style.background = colorFor(name);
  return a;
}

function stagger(node: HTMLElement, i: number): void {
  node.style.setProperty("--i", String(i));
}

function dayLabel(iso: string): string {
  const d = new Date(iso);
  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(today.getDate() - 1);
  const sameDay = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  if (sameDay(d, today)) return "Today";
  if (sameDay(d, yesterday)) return "Yesterday";
  return d.toLocaleDateString(undefined, { weekday: "short", year: "numeric", month: "short", day: "numeric" });
}

// --- Navigation ---

function setView(next: View) {
  state.view = next;
  for (const btn of document.querySelectorAll<HTMLButtonElement>(".bottomnav button")) {
    btn.classList.toggle("active", btn.dataset.view === next);
  }
  void render();
}

for (const btn of document.querySelectorAll<HTMLButtonElement>(".bottomnav button")) {
  btn.addEventListener("click", () => setView(btn.dataset.view as View));
}

// --- Render dispatch ---

async function render(): Promise<void> {
  view.replaceChildren();
  try {
    if (state.view === "calculator") await renderCalculator();
    else if (state.view === "vessels") await renderVessels();
    else await renderHistory();
  } catch (err) {
    view.replaceChildren(el("div", { class: "card error" }, (err as Error).message));
  }
}

// --- Calculator view ---

async function renderCalculator(): Promise<void> {
  const vessels = await getVessels();

  if (vessels.length === 0) {
    view.append(
      el("div", { class: "empty" }, el("span", { class: "glyph" }, "🍲"), "No vessels yet. Add one to start calculating."),
      (() => {
        const b = el("button", { class: "btn" }, "Add a vessel");
        b.addEventListener("click", () => setView("vessels"));
        return b;
      })(),
    );
    return;
  }

  const prefill = state.prefill;
  state.prefill = {};

  // --- Live readout (the scale display) ---
  const bigNum = el("span", { class: "big" }, "—");
  const readoutNum = el("div", { class: "readout-num" }, bigNum, el("span", { class: "unit" }, "g"));
  const live = el("span", { class: "live" }, el("span", { class: "live-dot" }), "live");
  const netChip = el("b", {}, "—");
  const totalChip = el("b", {}, "—");
  const tareVal = el("b", {}, "—");
  const foodVal = el("b", {}, "—");
  const rVessel = el("span", { class: "r-vessel" });
  const rFood = el("span", { class: "r-food" });

  const readout = el(
    "div",
    { class: "readout" },
    el("div", { class: "readout-top" }, el("span", { class: "readout-label" }, "Per portion"), live),
    readoutNum,
    el(
      "div",
      { class: "readout-chips" },
      el("span", { class: "chip" }, netChip, " net"),
      el("span", { class: "chip" }, totalChip, " total"),
    ),
    el("div", { class: "ratio" }, rVessel, rFood),
    el(
      "div",
      { class: "ratio-legend" },
      el("span", {}, el("i", { class: "dot vessel" }), "tare ", tareVal),
      el("span", {}, el("i", { class: "dot food" }), "food ", foodVal),
    ),
  );

  // --- Inputs ---
  const vesselSelect = el("select", { id: "vessel" });
  for (const v of vessels) {
    const opt = el("option", { value: v.id }, `${v.name} (${v.weight} g)`);
    if (v.id === prefill.vesselId) opt.selected = true;
    vesselSelect.append(opt);
  }

  const totalInput = el("input", {
    id: "total",
    type: "number",
    inputmode: "decimal",
    min: "0",
    step: "any",
    placeholder: "0",
  });
  totalInput.value = prefill.totalWeight != null ? String(prefill.totalWeight) : "";
  const totalWrap = el("div", { class: "input-wrap" }, totalInput, el("span", { class: "suffix" }, "g"));

  const portionsInput = el("input", {
    id: "portions",
    type: "number",
    inputmode: "numeric",
    min: "1",
    step: "1",
    placeholder: "1",
  });
  portionsInput.value = prefill.portions != null ? String(prefill.portions) : "";

  const stepBy = (delta: number) => {
    const cur = parseInt(portionsInput.value, 10);
    const next = (Number.isInteger(cur) ? cur : 1) + delta;
    portionsInput.value = String(Math.max(1, next));
    updatePreview();
  };
  const minus = el("button", { type: "button", class: "step", "aria-label": "Fewer portions" }, "−");
  const plus = el("button", { type: "button", class: "step", "aria-label": "More portions" }, "+");
  minus.addEventListener("click", () => stepBy(-1));
  plus.addEventListener("click", () => stepBy(1));
  const stepper = el("div", { class: "stepper" }, minus, portionsInput, plus);

  const noteInput = el("input", { id: "note", type: "text", placeholder: "Optional note" });
  noteInput.value = prefill.note ?? "";

  const errorBox = el("div", { class: "error" });

  const card = el(
    "div",
    { class: "card" },
    el("label", { for: "vessel" }, "Vessel"),
    vesselSelect,
    el("label", { for: "total" }, "Total weight (food + vessel)"),
    totalWrap,
    el("label", { for: "portions" }, "Portions"),
    stepper,
    el("label", { for: "note" }, "Note"),
    noteInput,
    errorBox,
  );

  const saveBtn = el("button", { class: "btn" }, "Save to history");
  card.append(saveBtn);

  view.append(el("div", { class: "calc-grid" }, readout, card));

  const selectedVessel = () => vessels.find((v) => v.id === vesselSelect.value);

  function updatePreview() {
    const vessel = selectedVessel();
    const total = parseFloat(totalInput.value);
    const portions = parseInt(portionsInput.value, 10);
    const hasTotal = vessel != null && Number.isFinite(total) && total > 0;

    // Ratio bar + legend.
    if (hasTotal && vessel) {
      const net = total - vessel.weight;
      rVessel.style.width = `${Math.min(vessel.weight / total, 1) * 100}%`;
      rFood.style.width = `${(Math.max(net, 0) / total) * 100}%`;
      tareVal.textContent = fmt(vessel.weight);
      foodVal.textContent = fmt(Math.max(net, 0));
    } else {
      rVessel.style.width = "0";
      rFood.style.width = "0";
      tareVal.textContent = "—";
      foodVal.textContent = "—";
    }

    // Big number + chips.
    if (hasTotal && vessel && Number.isInteger(portions) && portions >= 1) {
      const net = round2(total - vessel.weight);
      const portion = round2(net / portions);
      const warning = vessel.weight >= total;

      bigNum.textContent = String(portion);
      netChip.textContent = fmt(net);
      totalChip.textContent = fmt(total);
      readout.classList.toggle("warn", warning);
      live.classList.add("on");

      readoutNum.classList.remove("pop");
      void readoutNum.offsetWidth;
      readoutNum.classList.add("pop");
    } else {
      bigNum.textContent = "—";
      netChip.textContent = "—";
      totalChip.textContent = "—";
      readout.classList.remove("warn");
      live.classList.remove("on");
    }
  }

  for (const input of [vesselSelect, totalInput, portionsInput]) {
    input.addEventListener("input", updatePreview);
  }
  updatePreview();

  saveBtn.addEventListener("click", async () => {
    errorBox.textContent = "";
    try {
      await api("/api/calculations", {
        method: "POST",
        body: JSON.stringify({
          vesselId: vesselSelect.value,
          totalWeight: parseFloat(totalInput.value),
          portions: parseInt(portionsInput.value, 10),
          note: noteInput.value.trim() || undefined,
        }),
      });
      saveBtn.classList.add("success");
      saveBtn.textContent = "Saved ✓";
      saveBtn.disabled = true;
      setTimeout(() => setView("history"), 550);
    } catch (err) {
      errorBox.textContent = (err as Error).message;
    }
  });
}

// --- Vessels view ---

async function renderVessels(): Promise<void> {
  const vessels = await getVessels();

  const nameInput = el("input", { id: "vname", type: "text", maxlength: "100", placeholder: "e.g. Dutch oven" });
  const weightInput = el("input", {
    id: "vweight",
    type: "number",
    inputmode: "decimal",
    min: "0",
    step: "any",
    placeholder: "0",
  });
  const weightWrap = el("div", { class: "input-wrap" }, weightInput, el("span", { class: "suffix" }, "g"));
  const formError = el("div", { class: "error" });
  const addBtn = el("button", { class: "btn" }, "Add vessel");

  const form = el(
    "div",
    { class: "card" },
    el("h2", {}, "New vessel"),
    el("label", { for: "vname" }, "Name"),
    nameInput,
    el("label", { for: "vweight" }, "Empty weight"),
    weightWrap,
    formError,
    addBtn,
  );
  view.append(form);

  addBtn.addEventListener("click", async () => {
    formError.textContent = "";
    try {
      await api("/api/vessels", {
        method: "POST",
        body: JSON.stringify({ name: nameInput.value, weight: parseFloat(weightInput.value) }),
      });
      await render();
    } catch (err) {
      formError.textContent = (err as Error).message;
    }
  });

  if (vessels.length === 0) {
    view.append(el("div", { class: "empty" }, el("span", { class: "glyph" }, "⚖️"), "No vessels yet."));
    return;
  }

  const list = el("ul", { class: "list" });
  vessels.forEach((v, i) => {
    const li = vesselRow(v);
    stagger(li, i);
    list.append(li);
  });
  view.append(list);
}

function vesselRow(v: Vessel): HTMLLIElement {
  const name = el("span", { class: "name" }, avatar(v.name), v.name);
  const meta = el("span", { class: "meta" }, el("b", {}, `${v.weight} g`));
  const row = el("div", { class: "row" }, name, meta);

  const editBtn = el("button", { class: "icon-btn accent" }, "Edit");
  const delBtn = el("button", { class: "icon-btn danger" }, "Delete");
  const actions = el("div", { class: "actions" }, editBtn, delBtn);

  editBtn.addEventListener("click", () => startEdit(li, v));
  delBtn.addEventListener("click", async () => {
    if (!confirm(`Delete vessel "${v.name}"?`)) return;
    await api(`/api/vessels/${v.id}`, { method: "DELETE" });
    await render();
  });

  const li = el("li", {}, row, actions);
  return li;
}

function startEdit(li: HTMLLIElement, v: Vessel) {
  const nameInput = el("input", { type: "text", maxlength: "100" });
  nameInput.value = v.name;
  const weightInput = el("input", { type: "number", inputmode: "decimal", min: "0", step: "any" });
  weightInput.value = String(v.weight);
  const weightWrap = el("div", { class: "input-wrap" }, weightInput, el("span", { class: "suffix" }, "g"));
  const errBox = el("div", { class: "error" });
  const saveBtn = el("button", { class: "icon-btn accent" }, "Save");
  const cancelBtn = el("button", { class: "icon-btn" }, "Cancel");

  saveBtn.addEventListener("click", async () => {
    errBox.textContent = "";
    try {
      await api(`/api/vessels/${v.id}`, {
        method: "PUT",
        body: JSON.stringify({ name: nameInput.value, weight: parseFloat(weightInput.value) }),
      });
      await render();
    } catch (err) {
      errBox.textContent = (err as Error).message;
    }
  });
  cancelBtn.addEventListener("click", () => render());

  li.replaceChildren(
    el("label", {}, "Name"),
    nameInput,
    el("label", {}, "Empty weight"),
    weightWrap,
    errBox,
    el("div", { class: "actions" }, saveBtn, cancelBtn),
  );
}

// --- History view ---

async function renderHistory(): Promise<void> {
  const calcs = await getCalculations();

  if (calcs.length === 0) {
    view.append(el("div", { class: "empty" }, el("span", { class: "glyph" }, "📖"), "No saved calculations yet."));
    return;
  }

  const groups = new Map<string, Calculation[]>();
  for (const c of calcs) {
    const label = dayLabel(c.createdAt);
    const arr = groups.get(label) ?? [];
    arr.push(c);
    groups.set(label, arr);
  }

  let i = 0;
  for (const [label, items] of groups) {
    view.append(el("div", { class: "date-group" }, label));
    const list = el("ul", { class: "list" });
    for (const c of items) {
      const li = calcRow(c);
      stagger(li, i++);
      list.append(li);
    }
    view.append(list);
  }
}

function calcRow(c: Calculation): HTMLLIElement {
  const portion = el(
    "span",
    { class: "calc-portion" },
    `${c.portionWeight} g `,
    el("span", { class: "x" }, `× ${c.portions}`),
  );
  const time = el("span", { class: "meta" }, new Date(c.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }));
  const head = el("div", { class: "row" }, portion, time);

  const details = el(
    "div",
    { class: "meta" },
    el("b", {}, c.vesselName),
    ` · net ${c.netWeight} g · total ${c.totalWeight} g`,
  );

  const children: (Node | string)[] = [head, details];
  if (c.note) children.push(el("span", { class: "note-chip" }, `“${c.note}”`));
  if (c.warning) children.push(el("div", { class: "warning" }, "Saved with a vessel-weight warning."));

  const recalc = el("button", { class: "icon-btn accent" }, "Recalculate");
  recalc.addEventListener("click", () => {
    state.prefill = { vesselId: c.vesselId, totalWeight: c.totalWeight, portions: c.portions, note: c.note };
    setView("calculator");
  });
  children.push(el("div", { class: "actions" }, recalc));

  return el("li", {}, ...children);
}

// --- Boot ---

void render();
