// Compile the Track B image: Pi-Bolt patched Bun runtime, AOT + static heap.
// Run under the pi-bolt runtime; the AOT env vars are set by the workflow.
import * as path from "node:path";
import { pathToFileURL } from "node:url";

const src = process.env.OMP_SRC;
const out = process.env.OUT;
if (!src || !out) throw new Error("OMP_SRC and OUT must be set");

const extra = (process.env.OMP_ENTRYPOINTS ?? "").split("\n").filter(Boolean);
const { compileCodingAgent } = await import(
	pathToFileURL(path.join(src, "packages/coding-agent/scripts/compile-binary.ts")).href
);
const agentDir = path.join(src, "packages/coding-agent");
const entry = path.join(agentDir, "src/cli.ts");

// Upstream's build-binary.ts runs with this cwd; workspace imports
// (`@oh-my-pi/pi-ai/...`) only resolve from inside the package tree.
process.chdir(agentDir);

const transformersVersion = (
	await Bun.file(path.join(src, "node_modules/@huggingface/transformers/package.json")).json()
).version as string;

// Pi-Bolt emits no AOT image without a bytecode order file; pass 1 of the
// workflow records one with BUN_BYTECODE_ORDER_OUT and pass 2 consumes it.
const order = process.env.OMP_BYTECODE_ORDER;

await compileCodingAgent({
	repoRoot: src,
	entrypoint: entry,
	entrypoints: extra.length ? [entry, ...extra] : undefined,
	outfile: out,
	transformersVersion,
	native: null,
	executablePath: process.env.PIBOLT_BUN,
	...(order ? { bytecodeOrder: order } : {}),
});
