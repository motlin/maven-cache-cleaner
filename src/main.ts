import * as core from "@actions/core";
import * as fs from "fs";
import * as path from "path";
async function run(): Promise<void> {
  try {
    const m2Path = core.getInput("m2-path");

    // Resolve the m2 path using HOME environment variable
    const resolvedM2Path = path.resolve(m2Path.replace(/^~/, process.env.HOME || ""));

    core.saveState("resolvedM2Path", resolvedM2Path);
    const cleanup = await shouldCleanup(resolvedM2Path);
    core.saveState("shouldCleanup", cleanup);

    // Save start time
    const startTime = Date.now();
    core.saveState("startTime", startTime);
  } catch (error) {
    if (error instanceof Error) core.setFailed(error.message);
  }
}

async function shouldCleanup(directory: string): Promise<boolean> {
  if (!fs.existsSync(directory)) {
    core.warning("No detected loaded maven local repository. Will skip cleanup.");
    return false;
  }
  const testDirectoryPath = fs.mkdtempSync(path.join(directory, ".atime-test-"));
  const testFilePath = path.join(testDirectoryPath, "probe");

  try {
    fs.writeFileSync(testFilePath, "test");

    // sleep for 50 ms
    await new Promise((r) => setTimeout(r, 50));

    // Access the file to update atime
    fs.readFileSync(testFilePath);

    // Get the stats of the file
    const stats = fs.statSync(testFilePath);
    if (stats.atimeMs !== stats.mtimeMs) {
      return true;
    } else {
      core.warning("The filesystem does not support atime. No cleanup will be performed.");
      return false;
    }
  } finally {
    fs.rmSync(testDirectoryPath, { recursive: true, force: true });
  }
}

void run();
