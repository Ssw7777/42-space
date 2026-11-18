# 42 Space · 成本受控的往返交易与 AI 策略大赛参赛教程

**42.space** 是部署在 BNB Smart Chain 上的事件/预测市场：每个事件拆成若干互斥结果，每个结果本身是一个可交易的 outcome token（OT），事件结算时押中的人分池子。
**Clawby** 提供一层 AI Agent 可调用的数据与执行接口，把 42 的注册、领徽章、下单、往返执行、领奖全部变成一句自然语言指令。

本仓库记录：如何用 AI Agent 在 42 上完成 **注册 → 领身份徽章 → 低成本执行往返交易 → 把策略提交进 Clawby × 42 的「42Space AI Strategy Contest」**。全部命令可直接复制，适合直接交给 AI Agent 执行。

> 本文所有地址、密钥、路径均为占位符，请替换成你自己的。

---

## 目录

1. [前置条件](#1-前置条件)
2. [安装 Clawby Skill](#2-安装-clawby-skill)
3. [登录 42：四种方式，先选对](#3-登录-42四种方式先选对)
4. [领取 Clawby Identity SBT](#4-领取-clawby-identity-sbt)
5. [充值：只认 BSC 上的 USDT](#5-充值只认-bsc-上的-usdt)
6. [开始交易：五种模式](#6-开始交易五种模式)
7. [磨损与「必须清仓」](#7-磨损与必须清仓)
8. [参加 AI 策略大赛：条件与提交](#8-参加-ai-策略大赛条件与提交)
9. [Binance Agentic Wallet：能做什么、不能做什么](#9-binance-agentic-wallet能做什么不能做什么)
10. [常见报错对照表](#10-常见报错对照表)
11. [风险提示](#11-风险提示)
12. [附：一句话丢给 AI 的提示词](#12-附一句话丢给-ai-的提示词)

---

## 1. 前置条件

| 项目 | 要求 |
|---|---|
| 系统 | Linux（Ubuntu 22.04+ 推荐）或 macOS |
| Node.js | ≥ 18（推荐 22） |
| 钱包 | 一个**新钱包**，只放准备玩掉的钱 |
| 资金 | 少量 **USDT（BEP-20）** 作本金 + **BNB** 作 gas |
| 网络 | 能访问 `www.openclawby.com`、`api.openclawby.com`、`rest.ft.42.space`、BSC RPC |

> 强烈建议用独立钱包，不要用主钱包。往返执行本质是**花钱买积分/成交量**。

## 2. 安装 Clawby Skill

```bash
mkdir -p ~/42space && cd ~/42space
curl -fsSL https://www.openclawby.com/clawby-data.zip -o clawby-data.zip
unzip -oq clawby-data.zip
cd clawby-data/script/42space
npm install --no-audit --no-fund
node 42space.mjs status
```

看到 `{"logged_in":false,...}` 就说明装好了。

如果机器上没有 Node，**不要动系统包**，装到用户目录即可：

```bash
ARCH=$(uname -m); case "$ARCH" in x86_64) A=x64;; aarch64) A=arm64;; esac
cd ~/.local && curl -fsSL "https://nodejs.org/dist/v22.11.0/node-v22.11.0-linux-$A.tar.xz" -o node.tar.xz
tar -xf node.tar.xz && mv "node-v22.11.0-linux-$A" node22
export PATH="$HOME/.local/node22/bin:$PATH"
```

装完后，对 Agent 说 **「42space」**，它会读取 skill 的 `SKILL.md` 并接管后续流程。

## 3. 登录 42：四种方式，先选对

> 注册入口：<https://42.space/join/dWf92ZH7> —— 从该链接进入完成注册，邀请关系会自动绑定到你的内嵌钱包；绑错或不绑不影响交易，但绑定后积分加成可追溯。

| 方式 | 命令 | 需要邮箱 | 能建 42 账号 | 能领 SBT | 能拿 Clawby key |
|---|---|---|---|---|---|
| A. 邮箱验证码 | `login-email-init` / `login-email-verify` | ✅ | ✅ | ✅ | ✅ |
| B. 新建钱包 | `create-wallet` | ❌ | ✅ | ✅ | ✅ |
| C. 导入助记词 | `import-mnemonic` | ❌ | ✅ | ✅ | ✅ |
| D. Binance Agentic Wallet | `login-baw` | ❌ | ❌ | ✅ | ❌ |

**怎么选：**

- 想以后能用邮箱找回 → 选 **A**
- 想一步到位、不碰邮箱 → 选 **B**（助记词就是唯一钥匙，丢了就没了）
- 已有钱包想复用 → 选 **C**
- 只想要 Binance 阵营身份 → 选 **D**，但看第 9 节，它建不了账号

示例（邮箱）：

```bash
node 42space.mjs login-email-init you@example.com
# 收邮件拿 6 位验证码
printf '%s' '{"code":"123456","pin":"你的6-12位PIN"}' | node 42space.mjs login-email-verify you@example.com
node 42space.mjs status
```

返回里的 `address` 就是你的 **42 交易钱包**，之后所有充值和交易都用它。

> PIN 用来加密本地私钥，**只存在内存**，不会上传。忘了就重新登录重设。

## 4. 领取 Clawby Identity SBT

免费，只花 gas，一个钱包一枚，**不可转让**。

```bash
printf '%s' '{"pin":"你的PIN"}' | node 42space.mjs identity --pin-stdin
```

成功返回 `{"key_ok":true,"sbt":{"had":false,"minted":true,"tx":"0x..."},"bound":true}`。

- `sbt.had:true` = 之前已经领过，不会重复 mint
- 这枚徽章是 **1.5× 积分加成**和参赛资格的门票，**必须领在「实际交易的那个钱包」上**

## 5. 充值：只认 BSC 上的 USDT

往 `status` 返回的 `address` 打两样，**都走 BSC / BEP-20**：

| 币 | 建议数量 | 用途 |
|---|---|---|
| USDT | 50–150 | 交易本金（循环使用） |
| BNB | 0.01–0.02 | gas（没有就直接停摆） |

```bash
node 42space.mjs balance
# {"usdt":"99.9","bnb":"0.02","needs_funding":false,"bnb_status":"ok"}
```

> 其他链的 USDT 不会被读取，也不能用。

## 6. 开始交易：五种模式

| 模式 | 做什么 | 命令 |
|---|---|---|
| **Fast** | 在最便宜的盘上反复原子买卖，刷成交量 | `node daemon.mjs fast --amount 5 --target 500 --live` |
| **AI 单发** | 读一个盘的数据，挑胜率最高的结果买一次 | `node trade.mjs buy <market> <tokenId> 5 --live` |
| **Blitz** | 30 秒一轮的 BTC/ETH/SOL 竞速，随机押注 | `node daemon.mjs blitz --amount 1 --max-loss 5 --take-profit 10 --live` |
| **止盈** | 持仓涨到设定比例自动卖 | `node daemon.mjs take-profit --pct 50 --live` |
| **领奖** | 收取已结算市场的奖金 | `node 42space.mjs claim-settled --live --pin-stdin` |

所有 `--live` 之前都有一个 **dry-run**：不加 `--live` 只报价、不发交易。**先看数字，再决定。**

> Blitz 只在 UTC 04:00–18:00 开（北京时间 12:00–次日 02:00）。

## 7. 磨损与「必须清仓」

这是整套流程里**最容易亏钱的地方**。

**实测数据（5 USDT 单笔，四个往返 + 一次清仓）：**

| 项目 | 数值 |
|---|---|
| 4 个往返 USDT 流出 | 1.0032 |
| 累积 OT | 38.88 枚 |
| 清仓换回 USDT | 0.5877 |
| **净磨损** | **0.4155 USDT** |
| 成交量 | ≈ 39 USDT |
| **真实磨损率** | **≈ 1.07%** |

**关键结论：**

1. 每次原子往返会留下约 **9.7 枚 OT 碎仓**，不清仓就等于把钱扔在钱包里；
2. 只看 USDT 流出会**高估磨损**（看起来像 2.5%），把 OT 卖回后才是真实值（1.07%）；
3. 所以每一轮结束必须执行：

```bash
printf '%s' '{"pin":"你的PIN"}' | node trade.mjs sell <market> <tokenId> all --live
node trade.mjs status <market> <tokenId>   # 确认 OT 余额为 0
```

**成本预估：**

| 目标成交量 | 磨损（按 1.07%） |
|---|---|
| 500 USDT | ≈ 5.4 USDT |
| 1,000 USDT | ≈ 10.7 USDT |
| 10,000 USDT | ≈ 107 USDT |

## 8. 参加 AI 策略大赛：条件与提交

**比赛规则（官方口径）：**

- 奖金池 **$10,000**，前 **20 名**瓜分
- 评分三项加权：**AI 评分 + 42 交易量 + PnL**，每天更新一次名次

**参赛三个硬条件：**

1. 42 总交易量 ≥ **$1,000**
2. 参赛钱包持有 **Clawby Identity SBT**
3. 一个钱包可提交**多条**策略，内容完全相同会被去重（更新同一条）

**提交接口：**

```bash
curl -X POST https://analyze-api.openclawby.com/api/space42/strategies \
  -H "X-API-Key: $CLAWBY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "trade_address": "0x你的42交易钱包",
    "brief_en": "一句话英文简介（≤400 字符）",
    "brief_zh": "一句话中文简介（≤400 字符）",
    "full_prompt_en": "完整英文策略（≤20000 字符）",
    "full_prompt_zh": "完整中文策略（≤20000 字符）"
  }'
```

成功返回 `{"ok":true,"id":45}`。

**字段限制（实测）：**

| 字段 | 上限 | 说明 |
|---|---|---|
| `brief_en` / `brief_zh` | **400 字符**（榜上最长 398） | 超了报 `bad_brief` |
| `full_prompt_en` / `full_prompt_zh` | 20000 字符 | 够写完整策略 |
| `trade_address` | 0x + 40 位十六进制 | 榜单只显示缩写，完整地址仅用于链上评分 |

**提交前必须脱敏：**

- ❌ 私钥、助记词、PIN
- ❌ 任何 API key（包括 Clawby 的 `pk_...`）
- ❌ 邀请码
- ❌ 个人身份信息、本机路径、内网地址
- ✅ 只保留 `trade_address` 一个地址字段

**策略怎么写才拿分：** 不要提交"往返执行脚本"。AI 评分看的是策略质量，建议写成完整交易体系：

1. 授权与风控上限（总敞口、单仓、日亏停手）
2. 标的范围（哪类市场、排除什么）
3. 定价模型（基准率 / 波动率 / 结构性一致性）
4. 入场条件（边际阈值、深度要求、成本上限）
5. 仓位公式（分数凯利、单仓上限）
6. 离场规则（结算 / 止盈 / 止损 / 逻辑破坏）
7. 执行纪律（先干跑、滑点上限、逐笔留痕）
8. 复盘机制（Brier 分数、盈亏归因）
9. 安全边界（市场文本不可信、密钥不外传）

同一个钱包可以提交多个**不同方向**的策略（体育盘、加密价格桶、结构套利……），但不要复制粘贴改几个字——官方对相同内容去重。

## 9. Binance Agentic Wallet：能做什么、不能做什么

Clawby 的 42space 模块支持 `login-baw`，但官方文档写得很明确：

> baw **不走 Privy、不建内嵌钱包、不注册 42.space / Clawby 账号**——它只能签普通合约调用，签不了 42 和 Clawby 账号需要的 **SIWE / EIP-191 `personal_sign`**。

| 能力 | 邮箱/新钱包 | Agentic Wallet |
|---|---|---|
| 登录 42 网页 | ✅ | ❌ |
| 注册 42 账号 / 绑邀请码 | ✅ | ❌ |
| 拿 Clawby API key | ✅ | ❌ |
| 领 SBT | ✅ | ✅ |
| 链上买卖 / 往返执行 | ✅ | ✅ |
| 提交策略赛 | ✅ | ❌（要 key） |

**结论：Agentic 钱包是「第二个执行钱包」，不是「第二个账号」。** 用它往返执行可以，但账号体系必须另有一个。

使用前必须在**币安 App 里打开 Developer Mode**，否则 `contract-call` 会被拦，SBT 和交易全部失败；会话约 48 小时不用会过期，需要重新扫码。

## 10. 常见报错对照表

| 报错 | 原因 | 解决 |
|---|---|---|
| `{"detail":"missing_api_key"}` | 请求没带 `X-API-Key` | 加上 header |
| `{"detail":"invalid_api_key"}` | key 传错（常见：把返回对象当字符串发了） | 取 `.api_key` 字段本身 |
| `{"detail":"bad_brief"}` | brief 超长或内容不合规 | 压到 400 字符以内 |
| `{"error":"missing revert data"}` | 交易 revert（滑点/流动性） | 看日志，重试或换盘 |
| `{"event":"error","error":"server response 403 Forbidden"}` | 请求太密被限流 | 加大间隔 |
| `bnb_status: "none"` | 没有 gas | 先充 BNB |

## 11. 风险提示

- 往返执行是**花钱买成交量**，磨损 1% 左右是常态，不是套利
- 42 协议处于 alpha，合约与接口都可能变
- 平台保留剔除"破坏公平性"钱包的权利，不要多号批量刷
- SBT 没有承诺任何代币或空投，价值仅为生态内身份
- 本文不构成投资建议

## 12. 附：一句话丢给 AI 的提示词

```text
帮我接入 42.space 并参加 Clawby × 42 的 AI 策略大赛，全程你操作，我只负责确认和转钱。

1. 安装 Clawby skill（https://www.openclawby.com/clawby-data.zip），装到 skills 目录，按 SKILL.md 执行。
2. 用邮箱登录 42.space（我会把验证码发你），PIN 我来定。
3. 领 Clawby Identity SBT（免费，只花 gas）。
4. 告诉我收款地址和建议充值的 USDT / BNB 数量。
5. 充值到账后，用 fast 模式往返执行：单笔 5U，每轮 14 笔，每轮结束必须把残余 OT 全部卖回 USDT 并确认余额为 0。
6. 记录每轮：起始余额、结束余额、成交量、磨损率 = 净亏 / 成交量。
7. 累计成交量超过 1000 USDT 后，帮我把策略提交到
   POST https://analyze-api.openclawby.com/api/space42/strategies
   （X-API-Key 用环境变量，字段：trade_address / brief_en / brief_zh / full_prompt_en / full_prompt_zh，
    brief 各 ≤400 字符，提交前务必脱敏）。
8. 任何时候不要把私钥、PIN、邀请码发到聊天里。
```

---


---

## 13. 自动化运行与看板（参数更新）

> 这一节是跑通之后回头补的工程化部分：**怎么让它在 VPS 上无人值守地跑，并且一眼看懂**。

### 13.1 当前参数

| 参数 | 值 | 说明 |
|---|---|---|
| 单笔金额 | **20 USDT** | 原子往返（买 + 卖同一笔交易） |
| 每轮笔数 | **4 笔** | ≈ 152 USDT 成交量 |
| 轮间隔 | **6 小时** | 跑完休眠 5h52m |
| 每日 | **4 轮 ≈ 610 USDT** | 16 笔交易 |
| 磨损基准 | **1.07%** 成交量 | 含清仓回收后的真实值 |

**为什么从 5 USDT 提到 20 USDT**：成本率对单笔不敏感（实测 2/5/10/20 USDT 都是 5.01%），但 **gas 是按笔计的**。14 笔/轮 → 4 笔/轮，gas 直接降到 1/4：

| | 5 USDT × 14 笔 | 20 USDT × 4 笔 |
|---|---|---|
| 每轮成交量 | 137 | 152 |
| 每天笔数 | 56 | **16** |
| gas/天 | ~0.9 USDT | **~0.26 USDT** |

> 一笔往返 = 转出 20 USDT + 同笔卖回 ~19 USDT，钱包净变化 **-1.00 USDT**（5%）。交易历史里满屏 `-0.25 / -1.00` 是**净现金流**，不是交易额。

### 13.2 轮次脚本（`scripts/roundtrip.sh`）

核心循环只有三件事：**跑 N 笔 → 清仓 → 睡到下一轮**。

```bash
./roundtrip.sh          # 用默认参数跑
AMOUNT=20 TRIPS=4 GAP=21120 ./roundtrip.sh
```

四个硬停止条件：

1. `touch $BASE/STOP` —— 下一轮开始前生效
2. BNB < 0.004 —— gas 不够
3. USDT < 10 —— 本金见底
4. 连续 3 笔失败 —— 防止空转烧 gas

### 13.3 每日自动提交策略（`scripts/submit_daily.mjs`）

把多条策略放进 `queue.json`，脚本每天取**第一条未提交**的发出去，发过的记在 `state.json`，不会重复：

```json
[{"slug":"sports-base-rate","brief_en":"...","brief_zh":"...","full_en":"...","full_zh":"..."}]
```

用 systemd 定时器托管：

```ini
# /etc/systemd/system/42submit.timer
[Timer]
OnCalendar=*-*-* 10:00:00 Asia/Shanghai
Persistent=true
```

```bash
sudo systemctl enable --now 42submit.timer
systemctl list-timers 42submit.timer
```

### 13.4 看板

一个单文件 Python 服务（`http.server` + 服务端渲染），挂在反向代理后面复用主站登录：

**一屏之内能看到：**

| 区块 | 内容 |
|---|---|
| 状态胶囊 | 往返执行运行中 / 已暂停、每日提交是否启用、今日完成轮数 |
| 六张指标卡 | USDT、BNB、今日成交量、今日盈亏、磨损率、成交笔数 |
| 轮次进度 | 第几轮、已成交 X/N 笔、上一轮磨损、下一轮时间 |
| 最近成交 | 时间 / USDT 变化 / OT 变化 / 往返 or 清仓 |
| 策略提交 | 队列方向、状态、剩余条数、下次提交时间 |
| 我的参赛条目 | 从大赛接口实时拉的 id + 简介 + AI 分 |
| 控制 | 暂停 / 恢复按钮（写 STOP 文件）+ 命令行等价写法 |

两个按钮的实现就两行：

```python
if self.path.startswith("/api/stop"):   open(f"{BASE}/STOP","w").write(...)
if self.path.startswith("/api/resume"): os.remove(f"{BASE}/STOP")
```

> 版式要点：**一屏放完 ≠ 字号调小**。先算高度（表头 + 行数 × 行高），再决定显示几行；剩余高度用 `flex:1` 让某一块拉伸，而不是留白。

### 13.5 部署清单

```
~/42space/
├── clawby-data/            # skill（官方 zip 解压）
├── PIN.txt                 # 600，钱包 PIN
├── STOP                    # 存在即暂停
├── roundtrip.sh                 # 轮次脚本
├── slow2.sh                # roundtrip.sh 的包装（环境变量版）
├── logs/YYYY-MM-DD-*.log   # 每日日志
└── strategies/
    ├── queue.json          # 待提交策略
    └── state.json          # 已提交记录
```

```bash
# 常用
tail -f ~/42space/logs/$(date +%F)-slow.log     # 看实时
touch ~/42space/STOP                            # 停
rm -f ~/42space/STOP                            # 恢复
systemctl is-active 42submit.timer              # 提交器状态
```

---

# English Guide

**42.space** is an event/prediction market on BNB Smart Chain: each event is split into mutually exclusive outcomes, and every outcome is a tradable token. **Clawby** exposes the whole flow (sign-up, badge, trading, round-trip execution, claims) to any AI agent through one skill.

This repo documents how to **register → claim the identity badge → execute cost-capped round trips → submit a strategy** to the Clawby × 42 "42Space AI Strategy Contest". Every command is copy-paste ready.

## 1. Requirements

- Linux or macOS, Node.js ≥ 18 (22 recommended)
- A **fresh wallet** holding only what you plan to spend
- USDT on BSC (BEP-20) as principal + BNB for gas
- Outbound access to `www.openclawby.com`, `api.openclawby.com`, `rest.ft.42.space`

## 2. Install the skill

```bash
mkdir -p ~/42space && cd ~/42space
curl -fsSL https://www.openclawby.com/clawby-data.zip -o clawby-data.zip
unzip -oq clawby-data.zip
cd clawby-data/script/42space && npm install --no-audit --no-fund
node 42space.mjs status
```

Then just say **"42space"** to your agent; it reads `SKILL.md` and drives the flow.

## 3. Log in — four ways

> Sign-up entry: <https://42.space/join/dWf92ZH7> — registering through this link binds the referral to your embedded wallet automatically. Trading works either way; binding only makes the points attribution traceable.

| Method | Command | Email | Creates a 42 account | SBT | Clawby key |
|---|---|---|---|---|---|
| Email code | `login-email-init` / `login-email-verify` | yes | yes | yes | yes |
| New wallet | `create-wallet` | no | yes | yes | yes |
| Import mnemonic | `import-mnemonic` | no | yes | yes | yes |
| Binance Agentic Wallet | `login-baw` | no | **no** | yes | no |

```bash
node 42space.mjs login-email-init you@example.com
printf '%s' '{"code":"123456","pin":"your-pin"}' | node 42space.mjs login-email-verify you@example.com
node 42space.mjs status      # -> address = your 42 trading wallet
```

## 4. Claim the Clawby Identity SBT

```bash
printf '%s' '{"pin":"your-pin"}' | node 42space.mjs identity --pin-stdin
```

Free, soulbound, one per wallet, gas only. It is the ticket for the 1.5× points boost and contest eligibility — claim it **on the wallet you actually trade with**.

## 5. Fund the wallet

Send **USDT on BSC (BEP-20)** and a little **BNB** to the `address` from `status`. Nothing else is read.

## 6. Trading modes

| Mode | What it does | Command |
|---|---|---|
| Fast | atomic buy/sell round trips for volume | `node daemon.mjs fast --amount 5 --target 500 --live` |
| AI one-shot | read a market, buy the best-rated outcome once | `node trade.mjs buy <market> <tokenId> 5 --live` |
| Blitz | 30-second BTC/ETH/SOL race, random pick | `node daemon.mjs blitz --amount 1 --max-loss 5 --take-profit 10 --live` |
| Take profit | auto-sell at a target gain | `node daemon.mjs take-profit --pct 50 --live` |
| Claim | collect settled winnings | `node 42space.mjs claim-settled --live --pin-stdin` |

Everything is a dry run until you pass `--live`.

## 7. Wear, and why you must sweep

Measured with 5 USDT tickets, four round trips + one sweep:

| Item | Value |
|---|---|
| USDT out | 1.0032 |
| OT accumulated | 38.88 |
| USDT recovered by sweep | 0.5877 |
| **Net wear** | **0.4155 USDT** |
| Volume | ≈ 39 USDT |
| **Real wear rate** | **≈ 1.07%** |

Each round trip leaves ~9.7 OT of dust. If you never sweep, you misread your cost as ~2.5% instead of ~1.07%. Sweep every round:

```bash
printf '%s' '{"pin":"your-pin"}' | node trade.mjs sell <market> <tokenId> all --live
```

## 8. Submitting to the contest

Eligibility: ≥ $1,000 of 42 volume, SBT held, and one or more strategies submitted (identical content is de-duplicated).

```bash
curl -X POST https://analyze-api.openclawby.com/api/space42/strategies \
  -H "X-API-Key: $CLAWBY_API_KEY" -H "Content-Type: application/json" \
  -d '{"trade_address":"0x...","brief_en":"...","brief_zh":"...","full_prompt_en":"...","full_prompt_zh":"..."}'
```

- `brief_*`: **≤ 400 characters** (empirically 398 max on the board)
- `full_prompt_*`: ≤ 20,000 characters
- Sanitise: no keys, no mnemonics, no invite codes, no personal data — only `trade_address` as an address.

Scoring is AI rating + volume + PnL, ranked daily; the top 20 split $10,000. Submit a real trading system (risk limits, pricing model, entry/exit rules, review loop), not a volume script.

## 9. Binance Agentic Wallet

`login-baw` works, but per the official skill docs baw **does not create a 42.space or Clawby account** — it cannot sign the SIWE / EIP-191 `personal_sign` those accounts require. It can mint the SBT and execute trades, but it cannot log into 42, bind an invite, obtain a Clawby key, or submit a strategy. Developer Mode must be on in the Binance App, and the session expires after ~48 idle hours.

## 10. Error cheat sheet

| Error | Cause | Fix |
|---|---|---|
| `missing_api_key` | header absent | add `X-API-Key` |
| `invalid_api_key` | wrong value (e.g. object instead of string) | pass `.api_key` itself |
| `bad_brief` | brief too long | keep ≤ 400 chars |
| `missing revert data` | tx reverted (slippage/liquidity) | inspect log, retry or switch market |
| `403 Forbidden` | rate limited | increase interval |
| `bnb_status: none` | no gas | top up BNB |

## 11. Risks

Round-trip execution buys volume at roughly 1% wear; it is not arbitrage. 42 is in alpha. Platforms may exclude wallets that undermine fairness. The SBT carries no token or airdrop promise. Nothing here is financial advice.

## 12. Automation and dashboard (updated parameters)

Unattended operation on a VPS, plus a single-screen console.

### 12.1 Parameters

| Parameter | Value |
|---|---|
| Ticket size | **20 USDT** per atomic round trip |
| Trips per round | **4** (≈152 USDT volume) |
| Round interval | **6 hours** |
| Daily | **4 rounds ≈ 610 USDT** |
| Wear baseline | **1.07%** of volume (after sweeping) |

Cost percentage is flat across ticket sizes (2/5/10/20 USDT all ≈5.01%), but **gas is charged per transaction**. Going from 14 trips to 4 trips per round cuts gas by ~71%: 56 → 16 transactions/day, ~0.9 → ~0.26 USDT/day.

### 12.2 Round runner (`scripts/roundtrip.sh`)

Loop: run N round trips → sweep all residual OT → sleep until the next round. Four hard stops: `STOP` file, BNB < 0.004, USDT < 10, three consecutive failures.

```bash
MARKET=0x... AMOUNT=20 TRIPS=4 GAP=21120 ./scripts/roundtrip.sh
touch ~/42space/STOP     # pause before the next round
```

### 12.3 Daily submission (`scripts/submit_daily.mjs`)

Keep a `queue.json` of strategies; the script submits the first one not yet in `state.json`, so nothing is duplicated. Driven by a systemd timer at 10:00 local.

```bash
TRADE_ADDRESS=0x... P42_PIN=$(cat ~/42space/PIN.txt) node scripts/submit_daily.mjs
```

### 12.4 Dashboard

A single-file Python service (`http.server`, server-side rendered) behind the same reverse proxy and login. One screen shows: run state, six KPI cards (balance, gas, volume, PnL, wear rate, trades), round progress, last trades (cash and OT delta per trip), submission queue, my contest entries with live AI scores, and pause/resume buttons that simply create or remove the `STOP` file.

Layout lesson: fitting one screen is not about smaller fonts — count the rows first (header + rows × row height), pick how many to show, and let the remaining height be absorbed by a `flex:1` panel instead of leaving whitespace.

---
