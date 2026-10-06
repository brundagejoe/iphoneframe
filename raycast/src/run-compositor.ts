import { execFile } from "node:child_process";
import { access } from "node:fs/promises";
import { constants } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join } from "node:path";
import { promisify } from "node:util";

const execute = promisify(execFile);

export async function frameClipboard(
  projectDirectory: string,
  fit: string,
): Promise<void> {
  const project =
    projectDirectory === "~"
      ? homedir()
      : projectDirectory.startsWith("~/")
        ? join(homedir(), projectDirectory.slice(2))
        : projectDirectory;
  if (!isAbsolute(project))
    throw new Error(
      "Choose an absolute iPhoneFrame project folder in extension settings.",
    );
  if (fit !== "contain" && fit !== "fill")
    throw new Error("Choose a valid screenshot fit in extension settings.");
  const executable = join(project, "bin", "iphoneframe");
  const configuration = join(project, "frame.json");
  try {
    await access(executable, constants.X_OK);
    await access(configuration, constants.R_OK);
  } catch {
    throw new Error(
      "Choose the iPhoneFrame project folder containing bin/iphoneframe and frame.json in extension settings.",
    );
  }
  try {
    // An argument array avoids shell quoting and works with spaces in the project path.
    // Swift handles the image clipboard directly; no temporary file or text copy is involved.
    await execute(executable, ["--config", configuration, "--fit", fit], {
      cwd: project,
      timeout: 30_000,
      maxBuffer: 256 * 1024,
    });
  } catch (error) {
    const failure = error as Error & { stderr?: string; killed?: boolean };
    if (failure.killed)
      throw new Error("Framing timed out. Try a smaller screenshot.");
    throw new Error(
      failure.stderr?.trim().replace(/^iphoneframe:\s*/, "") || failure.message,
    );
  }
}
