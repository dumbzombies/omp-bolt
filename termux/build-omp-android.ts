// Compile the Track A binary: stock Bun, bionic target, addon shipped beside it.
import * as path from "node:path";
import { pathToFileURL } from "node:url";

const src = process.env.OMP_SRC;
const out = process.env.OUT;
if (!src || !out) throw new Error("OMP_SRC and OUT must be set");

const { compileCodingAgent } = await import(
	pathToFileURL(path.join(src, "packages/coding-agent/scripts/compile-binary.ts")).href
);

// Upstream's build-binary.ts runs with this cwd; workspace imports
// (`@oh-my-pi/pi-ai/...`) only resolve from inside the package tree.
process.chdir(path.join(src, "packages/coding-agent"));

// The tiny-model worker pins its runtime install to the version that was
// actually installed, not the catalog range.
const transformersVersion = (
	await Bun.file(path.join(src, "node_modules/@huggingface/transformers/package.json")).json()
).version as string;

await compileCodingAgent({
	repoRoot: src,
	entrypoint: path.join(src, "packages/coding-agent/src/cli.ts"),
	outfile: path.join(out, "omp.bin"),
	transformersVersion,
	native: null,
	// Bun's own name for the Android target; not in the bundled TS types.
	target: "bun-linux-arm64-android" as Bun.Build.CompileTarget,
});
