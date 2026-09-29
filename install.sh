#!/bin/bash
# 쏙쏙(SsokSsok) 설치: 애플 공증을 받은 최신 릴리스를 받아 응용 프로그램 폴더에 설치합니다.
# 사용법: bash -c "$(curl -fsSL https://raw.githubusercontent.com/hanseolhui/ssokssok/main/install.sh)"
#
# 환경 변수: SSOKSSOK_DEST (설치 폴더), SSOKSSOK_NO_OPEN=1 (설치 후 실행 안 함)
set -euo pipefail

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }

echo "▶ 쏙쏙(SsokSsok) 설치"

# 설치 위치: /Applications 에 쓸 수 있으면 거기, 아니면 ~/Applications
if [ -n "${SSOKSSOK_DEST:-}" ]; then DEST="$SSOKSSOK_DEST"
elif [ -w /Applications ]; then DEST="/Applications"
else DEST="$HOME/Applications"; fi
mkdir -p "$DEST"

TMP=$(mktemp -d -t ssokssok)
trap 'rm -rf "$TMP"' EXIT


TAG=$(curl -fsSL https://api.github.com/repos/hanseolhui/ssokssok/releases/latest 2>/dev/null \
     | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
URL="https://github.com/hanseolhui/ssokssok/releases/latest/download/SsokSsok.zip"
[ -n "$TAG" ] && URL="https://github.com/hanseolhui/ssokssok/releases/download/$TAG/SsokSsok.zip"
if curl -fsSL "$URL" -o "$TMP/SsokSsok.zip" \
   && mkdir -p "$TMP/out" && ditto -x -k "$TMP/SsokSsok.zip" "$TMP/out" \
   && spctl --assess --type execute "$TMP/out/SsokSsok.app" 2>/dev/null; then
  ok "공증된 최신 릴리스 다운로드 (${TAG:-latest})"
else
  warn "다운로드하지 못했어요. 인터넷 연결을 확인하거나 https://github.com/hanseolhui/ssokssok/releases 에서 받아 주세요."
  exit 1
fi

[ "${SSOKSSOK_NO_OPEN:-0}" = "1" ] || pkill -x SsokSsok 2>/dev/null || true
rm -rf "$DEST/SsokSsok.app"
ditto "$TMP/out/SsokSsok.app" "$DEST/SsokSsok.app"
# 예전 위치(~/Applications)에 남은 사본 정리
if [ "$DEST" = "/Applications" ] && [ -d "$HOME/Applications/SsokSsok.app" ]; then
  rm -rf "$HOME/Applications/SsokSsok.app"
fi
ok "설치 완료: $DEST/SsokSsok.app"

if [ "${SSOKSSOK_NO_OPEN:-0}" != "1" ]; then
  open "$DEST/SsokSsok.app"
  ok "실행 완료 (메뉴바의 상자 속 고양이)"
fi
echo
echo "  처음이면 '손쉬운 사용' 권한을 허용해 주세요:"
echo "   • 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > SsokSsok 켜기"
