#!/usr/bin/env bash
set -e

if [ $# -lt 2 ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> <폴더명 예: 2026-03-02_seongsu>"
  exit 1
fi

REPORT_PATH="$1"
FOLDER="$2"

# 입력 파일 존재 확인
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ report.html 파일을 찾을 수 없습니다: $REPORT_PATH"
  exit 1
fi

mkdir -p "docs/popup/$FOLDER"

# 기존 리포트가 있으면 경고 (덮어쓰기)
if [ -f "docs/popup/$FOLDER/index.html" ]; then
  echo "⚠️ 이미 같은 폴더($FOLDER)에 리포트가 있습니다. 덮어씁니다."
fi

cp "$REPORT_PATH" "docs/popup/$FOLDER/index.html"

# 아카이브 재생성
./rebuild_index.sh

# 스테이징
git add "docs/popup/$FOLDER/index.html" docs/index.html

# 변경사항 없으면 종료
if git diff --cached --quiet; then
  echo "ℹ️ 변경사항 없음 (commit/push 생략)"
  echo "홈(목록): https://315seconds.github.io/sales_report/"
  echo "리포트:   https://315seconds.github.io/sales_report/popup/$FOLDER/"
  exit 0
fi

# 커밋/푸시
git commit -m "Add popup report $FOLDER"
git push

echo "✅ 업로드 완료:"
echo "홈(목록): https://315seconds.github.io/sales_report/"
echo "리포트:   https://315seconds.github.io/sales_report/popup/$FOLDER/"
