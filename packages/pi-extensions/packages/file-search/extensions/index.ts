/**
 * File Search Extension for pi
 *
 * Provides fd (find files) and rg (search content) tools using the system
 * binaries. Patterns are always passed after `--` so user input can never be
 * parsed as a flag.
 */

import { spawn } from "node:child_process";
import { mkdtemp, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

/** Constants */
const FD_DEFAULT_LIMIT = 1000;
const FD_MAX_LIMIT = 10_000;
const FD_MAX_DEPTH = 64;
const RG_DEFAULT_MAX_COUNT = 100;
const RG_MAX_COUNT = 1000;
const RG_MAX_CONTEXT = 20;
const EXEC_TIMEOUT_MS = 60_000;
const MAX_OUTPUT_LINES = 2000;
const MAX_OUTPUT_BYTES = 50_000;
const MAX_CAPTURE_BYTES = 10_000_000;
const PREVIEW_LINES = 20;

/** fd tool parameters */
interface FdParams {
	pattern?: string;
	path?: string;
	type?: "file" | "directory" | "symlink";
	extension?: string;
	glob?: boolean;
	hidden?: boolean;
	max_depth?: number;
	limit?: number;
}

/** rg tool parameters */
interface RgParams {
	pattern: string;
	path?: string;
	glob?: string;
	file_type?: string;
	case_sensitive?: boolean;
	fixed_strings?: boolean;
	hidden?: boolean;
	context?: number;
	limit?: number;
}

/** Unified details type for both tools */
interface SearchDetails {
	error?: string;
	lineCount?: number;
	truncated?: boolean;
	fullOutputPath?: string;
}

function clamp(value: number, minimum: number, maximum: number): number {
	return Math.min(maximum, Math.max(minimum, Math.floor(value)));
}

/** Some models prefix path arguments with @; built-in tools strip it, so do we. */
function normalizeSearchPath(raw: string): string | undefined {
	let path = raw.trim();
	if (path.startsWith("@")) path = path.slice(1);
	if (path === "~") return homedir();
	if (path.startsWith("~/")) return join(homedir(), path.slice(2));
	return path === "" ? undefined : path;
}

const FD_TYPE_FLAGS = { file: "f", directory: "d", symlink: "l" } as const;

export function buildFdArgs(params: FdParams): string[] {
	const args = ["--color=never"];
	if (params.hidden) args.push("--hidden");
	if (params.glob) args.push("--glob");
	if (params.type) args.push("--type", FD_TYPE_FLAGS[params.type]);
	if (params.extension) args.push("--extension", params.extension.replace(/^\.+/, ""));
	if (params.max_depth !== undefined) {
		args.push("--max-depth", String(clamp(params.max_depth, 1, FD_MAX_DEPTH)));
	}
	args.push("--max-results", String(clamp(params.limit ?? FD_DEFAULT_LIMIT, 1, FD_MAX_LIMIT)));
	// An empty pattern matches everything, which keeps `path` usable without a pattern.
	args.push("--", params.pattern ?? "");
	const path = params.path === undefined ? undefined : normalizeSearchPath(params.path);
	if (path) args.push(path);
	return args;
}

export function buildRgArgs(params: RgParams): string[] {
	const args = ["--line-number", "--color=never", "--no-heading", "--with-filename"];
	if (params.case_sensitive === true) args.push("--case-sensitive");
	else if (params.case_sensitive === false) args.push("--ignore-case");
	else args.push("--smart-case");
	if (params.fixed_strings) args.push("--fixed-strings");
	if (params.hidden) args.push("--hidden");
	if (params.context !== undefined) {
		args.push("--context", String(clamp(params.context, 0, RG_MAX_CONTEXT)));
	}
	if (params.glob) args.push("--glob", params.glob);
	if (params.file_type) args.push("--type", params.file_type);
	args.push("--max-count", String(clamp(params.limit ?? RG_DEFAULT_MAX_COUNT, 1, RG_MAX_COUNT)));
	args.push("--", params.pattern);
	const path = params.path === undefined ? undefined : normalizeSearchPath(params.path);
	if (path) args.push(path);
	return args;
}

interface RunResult {
	code: number | null;
	stdout: string;
	stderr: string;
	capped: boolean;
}

/** Run a search binary, capturing stdout up to a hard byte cap. */
function runProcess(command: string, args: string[], cwd: string, signal?: AbortSignal): Promise<RunResult> {
	return new Promise((resolve, reject) => {
		const child = spawn(command, args, { cwd, stdio: ["ignore", "pipe", "pipe"] });

		const stdout: Buffer[] = [];
		const stderr: Buffer[] = [];
		let stdoutBytes = 0;
		let capped = false;
		let settled = false;

		const timeoutId = setTimeout(() => {
			finish(new Error(`${command} timed out after ${EXEC_TIMEOUT_MS / 1000}s`));
			child.kill("SIGKILL");
		}, EXEC_TIMEOUT_MS);

		const onAbort = () => {
			finish(new Error("Search was cancelled"));
			child.kill("SIGKILL");
		};
		if (signal) {
			if (signal.aborted) {
				onAbort();
				return;
			}
			signal.addEventListener("abort", onAbort, { once: true });
		}

		function finish(error?: Error, result?: RunResult) {
			if (settled) return;
			settled = true;
			clearTimeout(timeoutId);
			signal?.removeEventListener("abort", onAbort);
			if (error) reject(error);
			else if (result) resolve(result);
		}

		child.stdout.on("data", (chunk: Buffer) => {
			if (stdoutBytes >= MAX_CAPTURE_BYTES) {
				if (!capped) {
					capped = true;
					child.kill("SIGKILL");
				}
				return;
			}
			stdout.push(chunk);
			stdoutBytes += chunk.length;
		});
		child.stderr.on("data", (chunk: Buffer) => {
			stderr.push(chunk);
		});

		child.on("error", (error) => {
			const message =
				(error as NodeJS.ErrnoException).code === "ENOENT" ? `${command} not found on PATH` : error.message;
			finish(new Error(message));
		});
		child.on("close", (code) => {
			finish(undefined, {
				code: capped ? 0 : code,
				stdout: Buffer.concat(stdout).toString("utf8"),
				stderr: Buffer.concat(stderr).toString("utf8"),
				capped,
			});
		});
	});
}

interface FormattedOutput {
	text: string;
	lineCount: number;
	truncated: boolean;
	fullOutputPath?: string;
}

/** Truncate output for the model, saving the full output to a temp file. */
async function formatOutput(tool: string, raw: string): Promise<FormattedOutput> {
	const trimmed = raw.replace(/\n$/, "");
	const lines = trimmed.split("\n");
	const lineCount = lines.length;

	if (lineCount <= MAX_OUTPUT_LINES && Buffer.byteLength(trimmed, "utf8") <= MAX_OUTPUT_BYTES) {
		return { text: trimmed, lineCount, truncated: false };
	}

	let kept = lines.slice(0, MAX_OUTPUT_LINES);
	let text = kept.join("\n");
	while (kept.length > 1 && Buffer.byteLength(text, "utf8") > MAX_OUTPUT_BYTES) {
		kept = kept.slice(0, Math.ceil(kept.length / 2));
		text = kept.join("\n");
	}

	let fullOutputPath: string | undefined;
	try {
		const dir = await mkdtemp(join(tmpdir(), `pi-${tool}-`));
		fullOutputPath = join(dir, "output.txt");
		await writeFile(fullOutputPath, raw, "utf8");
		text += `\n... ${lineCount - kept.length} more lines. Full output: ${fullOutputPath}`;
	} catch {
		text += `\n... ${lineCount - kept.length} more lines (truncated)`;
	}

	return { text, lineCount, truncated: true, fullOutputPath };
}

interface SearchToolResult {
	content: Array<{ type: "text"; text: string }>;
	details: SearchDetails;
}

async function executeSearch(
	tool: "fd" | "rg",
	args: string[],
	cwd: string,
	signal: AbortSignal | undefined,
	noMatchText: string,
): Promise<SearchToolResult> {
	try {
		const result = await runProcess(tool, args, cwd, signal);

		// ripgrep exits 1 for "no matches"; fd exits 0 even with no results.
		const noMatches = result.stdout === "" && (result.code === 0 || (tool === "rg" && result.code === 1));
		if (noMatches) {
			return {
				content: [{ type: "text" as const, text: noMatchText }],
				details: { lineCount: 0, truncated: false },
			};
		}
		if (result.code !== 0 && result.stdout === "") {
			const detail = result.stderr.trim() || `exit code ${result.code}`;
			return {
				content: [{ type: "text" as const, text: `Error: ${tool} failed: ${detail}` }],
				details: { error: detail },
			};
		}

		const formatted = await formatOutput(tool, result.stdout);
		return {
			content: [{ type: "text" as const, text: formatted.text }],
			details: {
				lineCount: formatted.lineCount,
				truncated: formatted.truncated || result.capped,
				fullOutputPath: formatted.fullOutputPath,
			},
		};
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		return {
			content: [{ type: "text" as const, text: `Error: ${message}` }],
			details: { error: message },
		};
	}
}

interface Theme {
	bold(text: string): string;
	fg(color: string, text: string): string;
}

function renderSearchResult(
	result: { content: Array<{ type: string; text?: string }>; details?: unknown },
	options: { expanded?: boolean; isPartial?: boolean },
	theme: Theme,
	noMatchText: string,
	unit: [singular: string, plural: string],
): Text {
	if (options.isPartial) return new Text(theme.fg("warning", "Searching..."), 0, 0);
	const details = result.details as SearchDetails | undefined;
	if (details?.error) {
		return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0);
	}
	if (!details?.lineCount) {
		return new Text(theme.fg("dim", noMatchText), 0, 0);
	}

	let text = theme.fg("success", `${details.lineCount} ${details.lineCount === 1 ? unit[0] : unit[1]}`);
	if (details.truncated) text += theme.fg("warning", " (truncated)");
	if (options.expanded) {
		const content = result.content[0];
		if (content?.type === "text" && content.text) {
			const lines = content.text.split("\n");
			for (const line of lines.slice(0, PREVIEW_LINES)) {
				text += `\n${theme.fg("dim", line)}`;
			}
			if (lines.length > PREVIEW_LINES) {
				text += `\n${theme.fg("muted", `... ${lines.length - PREVIEW_LINES} more lines`)}`;
			}
		}
	}
	return new Text(text, 0, 0);
}

/** Main extension entry point */
export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "fd",
		label: "Find Files",
		description: `Find files and directories by name with fd. Respects .gitignore by default.

Parameters:
- pattern: Regex matched against file names (or a glob when glob is true); omit to list everything
- path: Directory to search (default: current working directory)
- type: file, directory, or symlink
- extension: Only files with this extension, e.g. 'ts'
- glob: Treat pattern as a glob instead of a regex
- hidden: Include hidden files
- max_depth: Maximum directory depth (1-${FD_MAX_DEPTH})
- limit: Maximum results (default: ${FD_DEFAULT_LIMIT}, max: ${FD_MAX_LIMIT})`,
		promptSnippet: "Find files and directories by name with fd (fast, gitignore-aware)",
		promptGuidelines: [
			"Use fd as the primary tool for discovering files and directories by name, extension, or glob instead of bash with find or ls -R",
			"Use rg instead of fd when searching file contents rather than file names",
			"Keep using bash for complex multi-step workflows that pipe or post-process file listings",
		],

		parameters: Type.Object({
			pattern: Type.Optional(
				Type.String({
					description: "Regex matched against file names (or a glob when glob is true)",
				}),
			),
			path: Type.Optional(Type.String({ description: "Directory to search" })),
			type: Type.Optional(
				StringEnum(["file", "directory", "symlink"] as const, {
					description: "Only return entries of this type",
				}),
			),
			extension: Type.Optional(Type.String({ description: "Only files with this extension" })),
			glob: Type.Optional(Type.Boolean({ description: "Treat pattern as a glob" })),
			hidden: Type.Optional(Type.Boolean({ description: "Include hidden files" })),
			max_depth: Type.Optional(
				Type.Integer({ description: "Maximum directory depth", minimum: 1, maximum: FD_MAX_DEPTH }),
			),
			limit: Type.Optional(Type.Integer({ description: "Maximum results", minimum: 1, maximum: FD_MAX_LIMIT })),
		}),

		async execute(
			_toolCallId: string,
			params: FdParams,
			signal: AbortSignal | undefined,
			_onUpdate: unknown,
			ctx: { cwd?: string } | undefined,
		) {
			return executeSearch("fd", buildFdArgs(params), ctx?.cwd ?? process.cwd(), signal, "No files found");
		},

		renderCall(args, theme) {
			const params = args as unknown as FdParams;
			let text = theme.bold("fd ");
			text += params.pattern ? `"${params.pattern}"` : "(all)";
			if (params.path) text += theme.fg("muted", ` in ${params.path}`);
			const flags = [
				params.type && `type=${params.type}`,
				params.extension && `ext=${params.extension}`,
				params.glob && "glob",
				params.hidden && "hidden",
				params.max_depth !== undefined && `depth≤${params.max_depth}`,
			].filter((flag): flag is string => typeof flag === "string");
			if (flags.length > 0) text += ` ${theme.fg("dim", flags.join(" "))}`;
			return new Text(text, 0, 0);
		},

		renderResult(result, options, theme) {
			return renderSearchResult(result, options, theme, "No files found", ["entry", "entries"]);
		},
	});

	pi.registerTool({
		name: "rg",
		label: "Search Content",
		description: `Search file contents with ripgrep. Uses smart-case matching and respects .gitignore by default.

Parameters:
- pattern: Regex to search for (literal text when fixed_strings is true)
- path: File or directory to search (default: current working directory)
- glob: Only search files matching this glob, e.g. '*.ts'
- file_type: Only search files of this ripgrep type, e.g. 'ts', 'py', 'rust'
- case_sensitive: true forces case-sensitive, false forces case-insensitive (default: smart-case)
- fixed_strings: Treat pattern as a literal string
- hidden: Search hidden files
- context: Lines of context around each match (0-${RG_MAX_CONTEXT})
- limit: Maximum matches per file (default: ${RG_DEFAULT_MAX_COUNT}, max: ${RG_MAX_COUNT})`,
		promptSnippet: "Search file contents with ripgrep (fast regex content search)",
		promptGuidelines: [
			"Use rg as the primary tool for searching file contents instead of bash with grep",
			"Use fd instead of rg when looking for files by name rather than content",
			"Set fixed_strings on rg when searching for literal code snippets containing regex metacharacters",
			"Keep using bash for complex multi-step workflows that combine searching with other commands",
		],

		parameters: Type.Object({
			pattern: Type.String({ description: "Regex to search for" }),
			path: Type.Optional(Type.String({ description: "File or directory to search" })),
			glob: Type.Optional(Type.String({ description: "Only search files matching this glob" })),
			file_type: Type.Optional(Type.String({ description: "Only search files of this ripgrep type" })),
			case_sensitive: Type.Optional(
				Type.Boolean({ description: "Force case-sensitive (true) or case-insensitive (false)" }),
			),
			fixed_strings: Type.Optional(Type.Boolean({ description: "Treat pattern as a literal string" })),
			hidden: Type.Optional(Type.Boolean({ description: "Search hidden files" })),
			context: Type.Optional(
				Type.Integer({
					description: "Lines of context around each match",
					minimum: 0,
					maximum: RG_MAX_CONTEXT,
				}),
			),
			limit: Type.Optional(
				Type.Integer({ description: "Maximum matches per file", minimum: 1, maximum: RG_MAX_COUNT }),
			),
		}),

		async execute(
			_toolCallId: string,
			params: RgParams,
			signal: AbortSignal | undefined,
			_onUpdate: unknown,
			ctx: { cwd?: string } | undefined,
		) {
			return executeSearch("rg", buildRgArgs(params), ctx?.cwd ?? process.cwd(), signal, "No matches found");
		},

		renderCall(args, theme) {
			const params = args as unknown as RgParams;
			let text = theme.bold("rg ");
			text += `"${params.pattern}"`;
			if (params.path) text += theme.fg("muted", ` in ${params.path}`);
			const flags = [
				params.glob && `glob=${params.glob}`,
				params.file_type && `type=${params.file_type}`,
				params.fixed_strings && "literal",
				params.hidden && "hidden",
				params.context !== undefined && `ctx=${params.context}`,
			].filter((flag): flag is string => typeof flag === "string");
			if (flags.length > 0) text += ` ${theme.fg("dim", flags.join(" "))}`;
			return new Text(text, 0, 0);
		},

		renderResult(result, options, theme) {
			return renderSearchResult(result, options, theme, "No matches found", ["line", "lines"]);
		},
	});
}
