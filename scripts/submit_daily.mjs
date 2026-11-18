#!/usr/bin/env node
/**
 * 每天自动提交一条策略到 42Space AI Strategy Contest。
 * 取 queue.json 里第一条未提交的，提交后写入 state.json，不会重复。
 *
 * 用法：
 *   TRADE_ADDRESS=0x... P42_PIN=$(cat ~/42space/PIN.txt) node submit_daily.mjs
 *   ... --dry    只打印将要提交哪一条，不发请求
 *
 * 依赖同目录（skill）的：lib.mjs / vault.mjs / clawby.mjs / ethers
 */
import fs from "node:fs";
import { readState } from "./lib.mjs";
import { decryptKey } from "./vault.mjs";
import { getKeyFromWallet } from "./clawby.mjs";
import { Wallet } from "ethers";

const DRY = process.argv.includes("--dry");
const BASE = process.env.P42_BASE || `${process.env.HOME}/42space/strategies`;
const ADDR = process.env.TRADE_ADDRESS;
if (!ADDR && !DRY) {
  console.error("need TRADE_ADDRESS=0x... (42 交易钱包地址)");
  process.exit(1);
}

const queue = JSON.parse(fs.readFileSync(`${BASE}/queue.json`, "utf8"));
const statePath = `${BASE}/state.json`;
const state = fs.existsSync(statePath)
  ? JSON.parse(fs.readFileSync(statePath, "utf8"))
  : { submitted: [] };

const next = queue.find((s) => !state.submitted.includes(s.slug));
if (!next) {
  console.log("QUEUE_EMPTY");
  process.exit(0);
}
console.log("next:", next.slug, "| brief", next.brief_en?.length, next.brief_zh?.length);
if (DRY) {
  console.log("DRY_RUN");
  process.exit(0);
}

// 用钱包签名换 Clawby API key（幂等：同一钱包永远拿到同一把）
const st = readState();
const wallet = new Wallet(decryptKey(st.vault, process.env.P42_PIN || ""));
const { api_key } = await getKeyFromWallet(wallet);

const body = {
  trade_address: ADDR,
  brief_en: next.brief_en,
  brief_zh: next.brief_zh,
  full_prompt_en: next.full_en,
  full_prompt_zh: next.full_zh,
};

const res = await fetch("https://analyze-api.openclawby.com/api/space42/strategies", {
  method: "POST",
  headers: { "content-type": "application/json", "X-API-Key": api_key },
  body: JSON.stringify(body),
});
const text = await res.text();
console.log("POST", res.status, text.slice(0, 160));

if (res.ok) {
  const { id } = JSON.parse(text);
  state.submitted.push(next.slug);
  fs.writeFileSync(
    statePath,
    JSON.stringify({ ...state, last: { slug: next.slug, id, at: new Date().toISOString() } }, null, 2)
  );
  console.log("SAVED id", id);
}
