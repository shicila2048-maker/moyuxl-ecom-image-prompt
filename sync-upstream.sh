#!/usr/bin/env bash
# ============================================================
# moyuxl-ecom-image-prompt 上游同步脚本
# 用法: ./sync-upstream.sh [upstream_url] [upstream_branch]
# 默认上游: https://github.com/AlephAITech/moyuxl-ecom-image-prompt.git (main)
# 作者换仓库时: ./sync-upstream.sh https://github.com/新作者/新仓库.git
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DEFAULT_UPSTREAM="https://github.com/AlephAITech/moyuxl-ecom-image-prompt.git"
UPSTREAM_URL="${1:-$DEFAULT_UPSTREAM}"
UPSTREAM_BRANCH="${2:-main}"
LOCAL_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

echo "=========================================="
echo "  上游同步 / Upstream Sync"
echo "=========================================="
echo "本地分支: $LOCAL_BRANCH"
echo "上游地址: $UPSTREAM_URL"
echo "上游分支: $UPSTREAM_BRANCH"
echo "=========================================="

# 添加或更新 upstream remote
if git remote get-url upstream &>/dev/null; then
  git remote set-url upstream "$UPSTREAM_URL"
else
  git remote add upstream "$UPSTREAM_URL"
fi

# Fetch 上游
echo ""
echo "[1/3] 正在获取上游更新..."
if ! git fetch upstream "$UPSTREAM_BRANCH" 2>&1; then
  echo ""
  echo "❌ 无法从上游获取更新。"
  echo "可能原因：作者更换了仓库地址、网络问题、或上游分支名变更。"
  echo ""
  echo "如果作者换了仓库，请用新地址重新运行："
  echo "  ./sync-upstream.sh https://github.com/新作者/新仓库.git"
  exit 1
fi

# 检查是否有更新
LOCAL_SHA="$(git rev-parse HEAD)"
UPSTREAM_SHA="$(git rev-parse "upstream/$UPSTREAM_BRANCH")"
if [ "$LOCAL_SHA" = "$UPSTREAM_SHA" ]; then
  echo ""
  echo "✅ 已是最新，无需同步。"
  exit 0
fi

BEHIND="$(git rev-list --count HEAD.."upstream/$UPSTREAM_BRANCH" 2>/dev/null || echo 0)"
AHEAD="$(git rev-list --count "upstream/$UPSTREAM_BRANCH"..HEAD 2>/dev/null || echo 0)"
echo ""
echo "本地领先 $AHEAD 个提交，落后 $BEHIND 个提交。"

# Merge
echo ""
echo "[2/3] 正在合并上游更新..."
if git merge "upstream/$UPSTREAM_BRANCH" --no-edit 2>&1; then
  echo ""
  echo "[3/3] 合并成功！"
else
  echo ""
  echo "⚠️  合并产生冲突，请手动解决后提交："
  echo "  git status          # 查看冲突文件"
  echo "  git add <文件>      # 标记已解决"
  echo "  git commit          # 完成合并"
  exit 1
fi

# 推送到 origin
echo ""
echo "[3/3] 推送到你的仓库..."
if git push origin "$LOCAL_BRANCH" 2>&1; then
  echo ""
  echo "✅ 同步完成并已推送！"
else
  echo ""
  echo "⚠️  本地已合并，但推送失败。请检查权限后手动 git push。"
  exit 1
fi
