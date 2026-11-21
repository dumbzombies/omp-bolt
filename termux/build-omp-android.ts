// Compile the Track A binary: stock Bun, bionic target, addon shipped beside it.
import * as path from "node:path";
import { pathToFileURL } from "node:url";

const src = process.env.OMP_SRC;
const out = process.env.OUT;
if (!src || !out) throw new Error("OMP_SRC and OUT must be set");

const { compileCodingAgent } = await import(
	pathToFileURL(path.join(src, "packages/coding-agent/scripts/compile-binary.ts")).href
);

await compileCodingAgent({
	repoRoot: src,
	entrypoint: path.join(src, "packages/coding-agent/src/cli.ts"),
	outfile: path.join(out, "omp.bin"),
	transformersVersion: "4.2.0",
	native: null,
	// Bun's own name for the Android target; not in the bundled TS types.
	target: "bun-linux-arm64-android" as Bun.Build.CompileTarget,
});
