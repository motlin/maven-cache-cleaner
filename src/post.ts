import * as core from "@actions/core";
import * as fs from "fs";
import * as path from "path";

async function cleanup(): Promise<void> {
  try {
    const shouldCleanup = core.getState("shouldCleanup") === "true";
    if (!shouldCleanup) {
      core.warning("Not cleaning up m2 files. See main step logs for more information.");
      return;
    }
    const startTime = parseInt(core.getState("startTime"), 10);
    const duration = (Date.now() - startTime) / 60000; // Convert ms to minutes

    const resolvedM2Path = core.getState("resolvedM2Path");
    // Get all .pom files recursively
    const filesToRemove = findPomFiles(resolvedM2Path, duration);
    // Remove the parent directories of the found .pom files
    for (const file of filesToRemove) {
      const parentDir = path.dirname(file);
      if (fs.existsSync(parentDir)) {
        core.info(`Removing ${parentDir}`);
        fs.rmSync(parentDir, { recursive: true });
      }
    }
  } catch (error) {
    core.error((error as Error).message);
  }
}

function findPomFiles(dir: string, duration: number): string[] {
  const filesToRemove: string[] = [];

  function search(directory: string): void {
    const files = fs.readdirSync(directory, { withFileTypes: true });

    for (const file of files) {
      const fullPath = path.join(directory, file.name);

      if (file.isDirectory()) {
        search(fullPath);
      } else if (file.isFile() && file.name.endsWith(".pom")) {
        const stats = fs.statSync(fullPath);
        const lastAccessedMinutesAgo = (Date.now() - stats.atimeMs) / 60000;

        if (lastAccessedMinutesAgo > duration) {
          filesToRemove.push(fullPath);
        }
      }
    }
  }

  search(dir);
  return filesToRemove;
}

void cleanup();
