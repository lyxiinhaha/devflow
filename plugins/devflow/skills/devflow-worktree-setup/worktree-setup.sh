#!/usr/bin/env bash
set -euo pipefail

# devflow-worktree-setup.sh
#
# 在新建的 git worktree 里完成「本地文件软链 + 环境初始化」，
# 使 worktree 可以直接构建并安装到真机，无需手动处理。
#
# 用法：
#   ./devflow-worktree-setup.sh <worktree-path>
#
# 自动检测项目类型（Android / iOS），按需执行：
#   Android：软链 local.properties（及其他 .gitignore 中的本地文件）
#   iOS：    软链 local.properties（若有），执行 pod install

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 颜色 ─────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*" >&2; }

# ── 参数 ─────────────────────────────────────────────
WORKTREE_PATH="${1:-}"
if [[ -z "$WORKTREE_PATH" ]]; then
  err "用法: $0 <worktree-path>"
  exit 1
fi

WORKTREE_ABS="$(cd "$WORKTREE_PATH" && pwd)"
# 主工程根目录 = worktree 所在目录的父级（.worktrees/{slug} → 项目根）
PROJECT_ROOT="$(git -C "$WORKTREE_ABS" worktree list | head -1 | awk '{print $1}')"

echo ""
echo "DevFlow Worktree 环境初始化"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  主工程：$PROJECT_ROOT"
echo "  Worktree：$WORKTREE_ABS"
echo ""

# ── 检测项目类型 ──────────────────────────────────────
detect_project_type() {
  # iOS：有 .xcodeproj / .xcworkspace / Podfile
  if find "$PROJECT_ROOT" -maxdepth 1 \( -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Podfile" \) 2>/dev/null | grep -q .; then
    echo "ios"
    return
  fi
  # Android：有 gradlew + AndroidManifest.xml
  if [[ -f "$PROJECT_ROOT/gradlew" ]] && \
     find "$PROJECT_ROOT" -maxdepth 4 -name "AndroidManifest.xml" 2>/dev/null | grep -q .; then
    echo "android"
    return
  fi
  echo "unknown"
}

PROJECT_TYPE="$(detect_project_type)"
echo "  项目类型：$PROJECT_TYPE"
echo ""

# ── 通用：软链 .gitignore 中的本地文件 ───────────────
# 找出主工程里存在、但在 .gitignore 中列出的本地配置文件
symlink_local_files() {
  local files=(
    "local.properties"
    "keystore.properties"
    "signing.properties"
  )

  local linked=0
  for f in "${files[@]}"; do
    local src="$PROJECT_ROOT/$f"
    local dst="$WORKTREE_ABS/$f"

    [[ -f "$src" ]] || continue      # 主工程里没有，跳过
    [[ -e "$dst" ]] && continue      # worktree 里已存在（可能是追踪文件），跳过

    ln -s "$src" "$dst"
    ok "软链：$f → $src"
    linked=$((linked + 1))
  done

  [[ $linked -eq 0 ]] && ok "无需软链（未发现 local.properties 等本地配置文件）"
}

# ── Android 专项 ─────────────────────────────────────
setup_android() {
  echo "── Android 初始化 ───────────────────────────────"

  # 1. 软链本地配置文件
  symlink_local_files

  # 2. 验证 Gradle 可执行
  if [[ -f "$WORKTREE_ABS/gradlew" ]]; then
    ok "gradlew 可用，可直接执行：cd $WORKTREE_ABS && ./gradlew installDebug"
  else
    # worktree 里没有 gradlew，软链主工程的
    ln -s "$PROJECT_ROOT/gradlew" "$WORKTREE_ABS/gradlew" 2>/dev/null || true
    warn "gradlew 不在 worktree 根目录，已软链"
  fi

  echo ""
  echo "  构建命令："
  echo "    cd $WORKTREE_ABS"
  echo "    ./gradlew :app-kaz:installDebug     # 安装到真机"
  echo "    ./gradlew :app-kaz:assembleDebug    # 只构建 APK"
}

# ── iOS 专项 ─────────────────────────────────────────
setup_ios() {
  echo "── iOS 初始化 ───────────────────────────────────"

  # 1. 软链本地配置文件（iOS 项目通常没有 local.properties，但有可能有）
  symlink_local_files

  # 2. 检查 Podfile
  local podfile="$WORKTREE_ABS/Podfile"
  if [[ ! -f "$podfile" ]]; then
    warn "Podfile 不在 worktree 根目录，跳过 pod install"
    return
  fi

  # 3. 检查 path Pod 路径是否全为项目内部路径（相对路径以 kotlin-base/ Modules/ Lib/ 开头）
  local external_path_pods
  external_path_pods="$(grep -E ":path\s*=>" "$podfile" | grep -v "^\s*#" | \
    grep -v ":path => '\.\|:path => \"\./" | \
    grep -E ":path => '\.\.|:path => \"\.\." || true)"

  if [[ -n "$external_path_pods" ]]; then
    warn "检测到外部 path Pod（路径在项目目录外），pod install 可能需要调整路径："
    echo "$external_path_pods" | sed 's/^/    /'
    echo ""
    warn "建议：先确认这些 Pod 在当前机器上的绝对路径，或在 Podfile 中改用绝对路径"
  fi

  # 4. 执行 pod install
  echo "  执行 pod install..."
  cd "$WORKTREE_ABS"
  if pod install --silent 2>/dev/null; then
    ok "pod install 完成"
  else
    echo "  pod install（显示输出）..."
    pod install || {
      err "pod install 失败，请检查上方错误信息"
      echo ""
      echo "  常见原因："
      echo "  · Podfile.lock 与本地 Pod 版本不一致 → pod install --repo-update"
      echo "  · 外部 path Pod 路径不存在 → 检查 Podfile 中的 :path => 路径"
    }
  fi

  echo ""
  echo "  构建方式："
  echo "  · 命令行：xcodebuild -workspace *.xcworkspace -scheme <scheme> -destination 'id=<udid>' build"
  echo "  · Xcode：用 Xcode 打开 $WORKTREE_ABS/*.xcworkspace，选设备后 Cmd+R"
}

# ── 执行 ─────────────────────────────────────────────
case "$PROJECT_TYPE" in
  android)
    setup_android
    ;;
  ios)
    setup_ios
    ;;
  *)
    warn "未能识别项目类型（Android/iOS），执行通用软链..."
    symlink_local_files
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ Worktree 环境初始化完成${RESET}"
echo "  Worktree 路径：$WORKTREE_ABS"
echo ""
