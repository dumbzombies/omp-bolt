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
const entry = path.join(src, "packages/coding-agent/src/cli.ts");

await compileCodingAgent({
	repoRoot: src,
	entrypoint: entry,
	entrypoints: extra.length ? [entry, ...extra] : undefined,
	outfile: out,
	transformersVersion: "4.2.0",
	native: null,
	executablePath: process.env.PIBOLT_BUN,
});
