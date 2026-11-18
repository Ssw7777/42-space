#!/usr/bin/env bash
# 42.space 定时往返执行脚本：每 N 小时跑一轮，单笔固定金额，轮末清仓
#
# 用法：
#   MARKET=0x.... AMOUNT=20 TRIPS=4 GAP=21120 ./roundtrip.sh
#
# 环境变量：
#   MARKET   必填，要刷的那个 42 市场地址（0x + 40 hex）
#   TOKEN_ID 结果 tokenId，默认 1（tokenId = 2^outcomeIndex）
#   AMOUNT   单笔 USDT，默认 20
#   TRIPS    每轮笔数，默认 4
#   GAP      轮间隔秒数，默认 21120（≈6 小时减去一轮耗时）
#   MAXR     最多跑多少轮，默认 96
#   BASE     工作目录，默认 ~/42space
#   NODE_BIN Node 目录，默认 ~/.local/node22/bin
#
# 停止：touch $BASE/STOP （下一轮开始前生效）
set -uo pipefail

BASE="${BASE:-$HOME/42space}"
MOD="$BASE/clawby-data/script/42space"
export PATH="${NODE_BIN:-$HOME/.local/node22/bin}:$PATH"
LOG="$BASE/logs/$(date +%F)-slow.log"
MARKET="${MARKET:?need MARKET=0x...}"
TOKEN_ID="${TOKEN_ID:-1}"
AMOUNT="${AMOUNT:-20}"
TRIPS="${TRIPS:-4}"
GAP="${GAP:-21120}"
MAXR="${MAXR:-96}"

mkdir -p "$BASE/logs"
PIN=$(cat "$BASE/PIN.txt")
cd "$MOD" || { echo "skill 未安装：$MOD"; exit 1; }

bal() { node 42space.mjs balance | python3 -c "import sys,json;print(float(json.load(sys.stdin)['usdt']))"; }
bnb() { node 42space.mjs balance | python3 -c "import sys,json;print(float(json.load(sys.stdin)['bnb']))"; }

echo "$(date -Is) START usdt=$(bal) amount=$AMOUNT trips=$TRIPS gap=$GAP" >> "$LOG"

for r in $(seq 1 "$MAXR"); do
  if [ -f "$BASE/STOP" ]; then echo "$(date -Is) STOP file, exit" >> "$LOG"; break; fi

  S0=$(bal); B0=$(bnb)
  python3 -c "import sys;sys.exit(0 if $S0 < 10 else 1)"   && { echo "$(date -Is) LOW USDT $S0" >> "$LOG"; break; }
  python3 -c "import sys;sys.exit(0 if $B0 < 0.004 else 1)" && { echo "$(date -Is) LOW BNB $B0" >> "$LOG"; break; }

  echo "$(date -Is) ROUND $r begin usdt=$S0 bnb=$B0" >> "$LOG"

  fails=0
  for i in $(seq 1 "$TRIPS"); do
    [ -f "$BASE/STOP" ] && break
    printf '{"pin":"%s"}' "$PIN" \
      | timeout 240 node trade.mjs roundtrip "$MARKET" "$TOKEN_ID" "$AMOUNT" \
          --live --slippage 3 --approve-max >> "$LOG" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then fails=$((fails+1)); else fails=0; fi
    echo "$(date -Is) r$r t$i rc=$rc" >> "$LOG"
    if [ $fails -ge 3 ]; then echo "$(date -Is) 3 consecutive fails, abort round" >> "$LOG"; break; fi
    sleep 30
  done

  # 轮末清仓：把残余 outcome token 全部卖回 USDT
  printf '{"pin":"%s"}' "$PIN" | timeout 240 node trade.mjs sell "$MARKET" "$TOKEN_ID" all --live >> "$LOG" 2>&1

  S1=$(bal)
  echo "$(date -Is) ROUND $r done wear=$(python3 -c "print(round($S0-$S1,4))") usdt=$S1" >> "$LOG"
  [ "$r" -lt "$MAXR" ] && sleep "$GAP"
done

echo "$(date -Is) END" >> "$LOG"
