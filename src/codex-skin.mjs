#!/usr/bin/env node
/** Dabin One-click Codex Skin: self-contained loopback-CDP controller. */
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { basename, dirname, extname, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const root = resolve(dirname(scriptPath), '..');
const runtime = resolve(root, 'runtime');
const statePath = resolve(runtime, 'state.json');
const pidPath = resolve(runtime, 'controller.pid');
const port = Number(process.env.DABIN_CODEX_CDP_PORT || 9341);

function fail(message, cause) { console.error(cause ? `${message}\n${cause.message || cause}` : message); process.exitCode = 1; }
function readState() { try { return existsSync(statePath) ? JSON.parse(readFileSync(statePath, 'utf8')) : { enabled: false }; } catch { return { enabled: false }; } }
function writeState(state) { mkdirSync(runtime, { recursive: true }); writeFileSync(statePath, `${JSON.stringify(state, null, 2)}\n`, 'utf8'); }

function imagePayload(path) {
  const absolutePath = resolve(path || '');
  if (!existsSync(absolutePath)) throw new Error(`找不到图片：${absolutePath}`);
  const mime = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.bmp': 'image/bmp', '.webp': 'image/webp' }[extname(absolutePath).toLowerCase()];
  if (!mime) throw new Error('只支持 PNG、JPG/JPEG、BMP 或 WebP 图片。');
  const bytes = readFileSync(absolutePath);
  if (bytes.byteLength > 8 * 1024 * 1024) throw new Error('图片超过 8 MB。请先压缩图片后再应用。');
  return { name: basename(absolutePath), mime, data: bytes.toString('base64'), bytes: bytes.byteLength };
}

async function locateTarget() {
  let targets;
  try { const response = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(4000) }); targets = await response.json(); }
  catch { throw new Error(`无法连接 Codex 调试端口 ${port}。请打开 Codex 主界面后重试。`); }
  const target = targets.find((item) => item.type === 'page' && /^app:\/\//.test(item.url || ''));
  if (!target?.webSocketDebuggerUrl) throw new Error('已连接调试端口，但没有发现 Codex 主窗口。请打开含侧栏和输入框的主界面后重试。');
  return target;
}

async function evaluate(target, expression) {
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolveOpen, rejectOpen) => {
    const timer = setTimeout(() => rejectOpen(new Error('连接 Codex 页面超时。')), 5000);
    socket.addEventListener('open', () => { clearTimeout(timer); resolveOpen(); }, { once: true });
    socket.addEventListener('error', () => { clearTimeout(timer); rejectOpen(new Error('无法连接 Codex 页面。')); }, { once: true });
  });
  try {
    return await new Promise((resolveResult, rejectResult) => {
      const timer = setTimeout(() => rejectResult(new Error('Codex 页面未响应样式注入请求。')), 6000);
      socket.addEventListener('message', (event) => {
        let message; try { message = JSON.parse(String(event.data)); } catch { return; }
        if (message.id !== 1) return;
        clearTimeout(timer);
        if (message.error) rejectResult(new Error(message.error.message || 'CDP 执行失败。'));
        else resolveResult(message.result?.result?.value);
      });
      socket.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression, returnByValue: true, awaitPromise: true } }));
    });
  } finally { socket.close(); }
}

function injectExpression(state) {
  const image = `data:${state.image.mime};base64,${state.image.data}`;
  const css = `:root{color-scheme:dark;background:#07111f!important}html{min-height:100%;background-color:#07111f!important;background-image:linear-gradient(105deg,rgba(5,12,25,.84),rgba(7,17,31,.58)),url("${image}")!important;background-size:cover!important;background-position:center!important;background-attachment:fixed!important}body{min-height:100%;background:transparent!important;color:#f4f7fb!important}main,[role="main"],[data-slot="main"],[data-testid="main-content"]{background:rgba(8,18,34,.60)!important;backdrop-filter:blur(12px)}aside,nav,[role="navigation"],[data-slot="sidebar"]{background:rgba(7,17,31,.84)!important;backdrop-filter:blur(16px)}button,input,textarea,select{color:#f4f7fb!important}textarea,input{background-color:rgba(7,17,31,.86)!important;border-color:rgba(148,163,184,.44)!important}[data-message-author-role="user"],[data-testid*="user-message"],.user-message{background:#101827!important;color:#fff!important;border:1px solid rgba(148,163,184,.38)!important}[data-message-author-role="assistant"],[data-testid*="assistant-message"],.assistant-message{background:rgba(8,18,34,.76)!important;color:#f4f7fb!important}`;
  return `(()=>{const id='dabin-original-skin-style';let style=document.getElementById(id);if(!style){style=document.createElement('style');style.id=id;document.head.appendChild(style)}style.dataset.themeId=${JSON.stringify(state.themeId)};style.textContent=${JSON.stringify(css)};document.documentElement.dataset.dabinSkin=${JSON.stringify(state.themeId)};return{injected:true,themeId:style.dataset.themeId,url:location.href}})()`;
}

const removeExpression = `(()=>{document.getElementById('dabin-original-skin-style')?.remove();delete document.documentElement.dataset.dabinSkin;return{removed:true,url:location.href}})()`;
const inspectExpression = `(()=>{const style=document.getElementById('dabin-original-skin-style');return{injected:Boolean(style),themeId:style?.dataset.themeId||null,url:location.href}})()`;
async function inject(state) { return evaluate(await locateTarget(), injectExpression(state)); }
async function remove() { return evaluate(await locateTarget(), removeExpression); }
function controllerRunning() { try { const pid = Number(readFileSync(pidPath, 'utf8')); process.kill(pid, 0); return true; } catch { return false; } }
function startController() { if (controllerRunning()) return; const child = spawn(process.execPath, [scriptPath, 'watch'], { detached: true, stdio: 'ignore', windowsHide: true }); child.unref(); writeFileSync(pidPath, String(child.pid), 'utf8'); }

async function check() { if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('需要 Node.js 22 或更高版本。'); const target = await locateTarget(); return { ready: true, port, target: target.url }; }
async function status() {
  const state = readState(); if (!state.enabled) return { mode: 'native', controller: 'stopped', injected: false, themeId: null };
  try { const page = await evaluate(await locateTarget(), inspectExpression); return { mode: page.injected && page.themeId === state.themeId ? 'active' : 'pending', controller: controllerRunning() ? 'running' : 'stopped', injected: page.injected, themeId: state.themeId, image: state.image.name, updatedAt: state.updatedAt }; }
  catch (error) { return { mode: 'pending', controller: controllerRunning() ? 'running' : 'stopped', injected: false, themeId: state.themeId, image: state.image.name, updatedAt: state.updatedAt, reason: error.message }; }
}
async function apply(imagePath) { await check(); const image = imagePayload(imagePath); const state = { schemaVersion: 1, enabled: true, themeId: `dabin-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`, image, updatedAt: new Date().toISOString() }; writeState(state); const page = await inject(state); startController(); return { mode: 'active', themeId: state.themeId, image: image.name, injected: page.injected, controller: 'running' }; }
async function pause() { const state = readState(); if (!state.enabled) return { mode: 'native', removed: false }; state.enabled = false; state.updatedAt = new Date().toISOString(); writeState(state); const page = await remove(); return { mode: 'native', removed: page.removed }; }
async function watch() { writeFileSync(pidPath, String(process.pid), 'utf8'); while (readState().enabled) { try { await inject(readState()); } catch {} await new Promise((resolveWait) => setTimeout(resolveWait, 3500)); } try { unlinkSync(pidPath); } catch {} }

async function main() {
  const [action, imagePath] = process.argv.slice(2);
  if (action === 'check') console.log(JSON.stringify(await check(), null, 2));
  else if (action === 'status') console.log(JSON.stringify(await status(), null, 2));
  else if (action === 'apply') console.log(JSON.stringify(await apply(imagePath), null, 2));
  else if (action === 'pause' || action === 'restore') console.log(JSON.stringify(await pause(), null, 2));
  else if (action === 'watch') await watch();
  else throw new Error('用法：check | status | apply <图片路径> | pause | restore');
}
main().catch((error) => fail('操作未完成。', error));
