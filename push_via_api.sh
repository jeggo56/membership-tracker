#!/usr/bin/env bash
# 通过 GitHub Git Data API 推送代码（只用 curl，绕过 python ssl 问题）
set -e
TOKEN="$GH_TOKEN"
OWNER="jeggo56"
REPO="membership-tracker"
BRANCH="main"
API="https://api.github.com"
DIR="$(cd "$(dirname "$0")" && pwd)"
TMP="$DIR/.push_tmp"
rm -rf "$TMP"; mkdir -p "$TMP"

api() { # method path [jsonfile]
  local method="$1" path="$2" file="$3"
  if [ -n "$file" ]; then
    local wfile; wfile=$(cygpath -w "$file")
    curl -s -X "$method" -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Content-Type: application/json" --data-binary "@$wfile" "$API$path" -w "\n%{http_code}"
  else
    curl -s -X "$method" -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$API$path" -w "\n%{http_code}"
  fi
}
code_of(){ echo "$1" | tail -1; }
body_of(){ echo "$1" | sed '$d'; }

# --- 收集文件列表（排除忽略项）---
cd "$DIR"
FILES=$(find . -type f \
  -not -path "./.git/*" -not -path "./.push_tmp/*" \
  -not -name "*.pyc" -not -name "*.log" -not -name "*.bak" \
  -not -path "*/__pycache__/*" -not -path "./build/*" \
  -not -name ".repo.json" -not -name "resp.json" \
  -not -name "push_via_api.py" \
  | sed 's|^\./||' | sort)
echo "文件数: $(echo "$FILES" | wc -l)"

# --- 确保仓库已初始化（创建 .gitignore 作为首个 commit）---
printf 'init' > "$TMP/init.txt"
B64=$(base64 -w0 ".gitignore")
cat > "$TMP/init.json" <<EOF
{"message":"chore: init","content":"$B64"}
EOF
R=$(api PUT "/repos/$OWNER/$REPO/contents/.gitignore" "$TMP/init.json")
echo "初始化: $(code_of "$R")"
rm -f .gitignore.bak 2>/dev/null || true

# 若已存在会 422，忽略即可

# --- 取父提交 ---
R=$(api GET "/repos/$OWNER/$REPO/git/refs/heads/$BRANCH")
PARENT=$(body_of "$R" | python -c "import sys,json;print(json.load(sys.stdin).get('object',{}).get('sha',''))" 2>/dev/null || echo "")
echo "父提交: ${PARENT:0:10}"

# --- 为每个文件创建 blob，组装 tree ---
TREE_JSON="$TMP/tree.json"
echo '{"tree":[' > "$TREE_JSON"
FIRST=1
for f in $FILES; do
  B64=$(base64 -w0 "$f")
  cat > "$TMP/blob.json" <<EOF
{"content":"$B64","encoding":"base64"}
EOF
  R=$(api POST "/repos/$OWNER/$REPO/git/blobs" "$TMP/blob.json")
  C=$(code_of "$R")
  if [ "$C" != "201" ] && [ "$C" != "200" ]; then
    echo "❌ blob 失败 $f (HTTP $C)"; echo "$R" | head -3; exit 1
  fi
  SHA=$(body_of "$R" | python -c "import sys,json;print(json.load(sys.stdin)['sha'])")
  [ $FIRST -eq 1 ] || echo ',' >> "$TREE_JSON"
  FIRST=0
  # JSON 转义路径中的特殊字符
  ESC=$(python -c "import json,sys;print(json.dumps(sys.argv[1]))" "$f")
  printf '{"path":%s,"mode":"100644","type":"blob","sha":"%s"}' "$ESC" "$SHA" >> "$TREE_JSON"
done
echo ']}' >> "$TREE_JSON"
echo "  ✓ 已创建 $(echo "$FILES" | wc -l) 个 blob"

# --- 创建 tree ---
R=$(api POST "/repos/$OWNER/$REPO/git/trees" "$TREE_JSON")
TREE_SHA=$(body_of "$R" | python -c "import sys,json;print(json.load(sys.stdin).get('sha',''))")
echo "tree: ${TREE_SHA:0:10}"

# --- 创建 commit ---
MSG="feat: 会员管家 - 会员订阅管理应用（Web PWA + iOS SwiftUI）\n\n- Web/PWA 版：原生 HTML/CSS/JS，离线可用、可添加到主屏幕\n- iOS 原生版：SwiftUI + SwiftData + 本地通知（13 个 Swift 文件）\n- 功能：订阅管理、月度支出统计、分类筛选、到期提醒\n- 智能提醒：到期前一天自动通知（可配置天数与时间）\n- 修复：日期时区 bug"
cat > "$TMP/commit.json" <<EOF
{"message":"$MSG","tree":"$TREE_SHA","parents":["$PARENT"]}
EOF
R=$(api POST "/repos/$OWNER/$REPO/git/commits" "$TMP/commit.json")
COMMIT_SHA=$(body_of "$R" | python -c "import sys,json;print(json.load(sys.stdin).get('sha',''))")
echo "commit: ${COMMIT_SHA:0:10}"

# --- 更新分支引用 ---
cat > "$TMP/ref.json" <<EOF
{"sha":"$COMMIT_SHA","force":true}
EOF
R=$(api PATCH "/repos/$OWNER/$REPO/git/refs/heads/$BRANCH" "$TMP/ref.json")
C=$(code_of "$R")
if [ "$C" != "200" ]; then
  cat > "$TMP/refcreate.json" <<EOF
{"ref":"refs/heads/$BRANCH","sha":"$COMMIT_SHA"}
EOF
  R=$(api POST "/repos/$OWNER/$REPO/git/refs" "$TMP/refcreate.json")
  C=$(code_of "$R")
fi
echo "ref 更新: HTTP $C"
rm -rf "$TMP"
echo ""
echo "✅ 完成: https://github.com/$OWNER/$REPO"
