// postinstall：按当前平台从 GitHub Releases 下载对应的 Native AOT 二进制
// 模式同 esbuild：npm 只负责分发，真正的可执行文件按平台按需下载
import { createWriteStream, createReadStream, existsSync, mkdirSync, chmodSync, rmSync } from "node:fs";
import { get } from "node:https";
import { createHash } from "node:crypto";
import { platform, arch } from "node:process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO = "jianliangshinsoft/cli-agent-sample"; // 发布后替换为实际 GitHub 仓库
const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

const platformMap = {
  "win32-x64": { rid: "win-x64", file: "filecli-win-x64.zip", exe: "filecli.exe" },
  "linux-x64": { rid: "linux-x64", file: "filecli-linux-x64.tar.gz", exe: "filecli" },
  "linux-arm64": { rid: "linux-arm64", file: "filecli-linux-arm64.tar.gz", exe: "filecli" },
  "darwin-arm64": { rid: "osx-arm64", file: "filecli-osx-arm64.tar.gz", exe: "filecli" },
  "darwin-x64": { rid: "osx-x64", file: "filecli-osx-x64.tar.gz", exe: "filecli" },
};

const key = `${platform}-${arch}`;
const target = platformMap[key];
if (!target) {
  console.error(`filecli: 不支持的平台 ${key}`);
  process.exit(0); // 不阻塞安装，运行时报错即可
}

const binDir = path.join(root, "bin");
const dest = path.join(binDir, target.exe);
if (existsSync(dest)) {
  console.log(`filecli: 已存在，跳过下载`);
  process.exit(0);
}
mkdirSync(binDir, { recursive: true });

const url = `https://github.com/${REPO}/releases/latest/download/${target.file}`;
const tmp = dest + ".download";
const tmpChecksum = dest + ".download.sha256";
console.log(`filecli: 下载 ${url}`);

function download(url, outPath, redirects = 5) {
  return new Promise((resolve, reject) => {
    get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && redirects > 0) {
        return resolve(download(res.headers.location, outPath, redirects - 1));
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      res.pipe(createWriteStream(outPath)).on("finish", resolve).on("error", reject);
    }).on("error", reject);
  });
}

function sha256(filePath) {
  return new Promise((resolve, reject) => {
    const hash = createHash("sha256");
    createReadStream(filePath)
      .on("data", (chunk) => hash.update(chunk))
      .on("end", () => resolve(hash.digest("hex")))
      .on("error", reject);
  });
}

try {
  await download(url, tmp);
  // SHA256 完整性校验（防下载损坏与被篡改的二进制）
  await download(`${url}.sha256`, tmpChecksum);
  const expected = (await import("node:fs")).readFileSync(tmpChecksum, "utf8").trim().split(/\s+/)[0].toLowerCase();
  const actual = await sha256(tmp);
  if (expected !== actual) {
    rmSync(dest, { force: true });
    throw new Error(`SHA256 校验失败！期望 ${expected}，实际 ${actual}，已中止安装`);
  }
  console.log(`filecli: SHA256 校验通过 ${actual}`);
  if (target.file.endsWith(".zip")) {
    // 最小 zip 提取（单文件条目），避免依赖第三方库
    const { execSync } = await import("node:child_process");
    if (platform === "win32") {
      execSync(`powershell -NoProfile -Command "Expand-Archive -Path '${tmp}' -DestinationPath '${binDir}' -Force"`);
    } else {
      execSync(`unzip -o ${tmp} -d ${binDir}`);
    }
  } else {
    const { execSync } = await import("node:child_process");
    execSync(`tar xzf ${tmp} -C ${binDir}`);
  }
  if (platform !== "win32") chmodSync(dest, 0o755);
  console.log(`filecli: 安装完成 -> ${dest}`);
} catch (e) {
  console.error(`filecli: 安装中断 (${e.message})，请改用安装脚本安装`);
  process.exit(1);
} finally {
  rmSync(tmp, { force: true });
  rmSync(tmpChecksum, { force: true });
}
