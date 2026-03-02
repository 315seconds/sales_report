#!/usr/bin/env bash
set -e

REPORT_PATH="${1:-}"
FOLDER="${2:-}"

if [ -z "$REPORT_PATH" ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> [폴더명]"
  echo "예:   ./publish_popup_report.sh ~/Downloads/report.html"
  echo "또는: ./publish_popup_report.sh ~/Downloads/report.html 2026-03-01_2026-03-10_hongdae"
  exit 1
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ report.html 파일을 찾을 수 없습니다: $REPORT_PATH"
  exit 1
fi

# --- 폴더명 자동 생성: 시작일_종료일_매장명 ---
if [ -z "$FOLDER" ]; then
  # 1) HTML에서 날짜 범위 찾기: YYYY-MM-DD ~ YYYY-MM-DD
  RANGE_LINE="$(grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*~[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$REPORT_PATH" | head -n 1 || true)"

  START_DATE=""
  END_DATE=""

  if [ -n "$RANGE_LINE" ]; then
    START_DATE="$(echo "$RANGE_LINE" | sed -E 's/^([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')"
    END_DATE="$(echo "$RANGE_LINE"   | sed -E 's/.*~[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')"
  fi

  # 2) HTML에서 매장명 추출: <h1>매장명</h1> 우선
  STORE="$(python - << 'PY'
import re, sys
p = sys.argv[1]
html = open(p, 'r', encoding='utf-8', errors='ignore').read()

m = re.search(r'<h1[^>]*>\s*([^<]{1,60})\s*</h1>', html, re.I)
store = m.group(1).strip() if m else "popup"

# 폴더 안전 문자만 남기기
store = re.sub(r'\s+', '-', store)
store = re.sub(r'[^0-9A-Za-z가-힣_-]+', '', store)
store = store[:30] if store else "popup"
print(store)
PY
"$REPORT_PATH")"

  # 3) 날짜를 못 찾으면 오늘 날짜로 대체(최악의 경우)
  if [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    TODAY="$(date +%F)"
    echo "⚠️ HTML에서 기간(YYYY-MM-DD ~ YYYY-MM-DD)을 못 찾아서 오늘 날짜로 대체합니다."
    START_DATE="$TODAY"
    END_DATE="$TODAY"
  fi

  FOLDER="${START_DATE}_${END_DATE}_${STORE}"
  echo "✅ 폴더명 자동 생성: $FOLDER"
fi

mkdir -p "docs/popup/$FOLDER"

if [ -f "docs/popup/$FOLDER/index.html" ]; then
  echo "⚠️ 이미 같은 폴더($FOLDER)에 리포트가 있습니다. 덮어씁니다."
fi

cp "$REPORT_PATH" "docs/popup/$FOLDER/index.html"

# 아카이브 재생성
./rebuild_index.sh

git add "docs/popup/$FOLDER/index.html" docs/index.html

if git diff --cached --quiet; then
  echo "ℹ️ 변경사항 없음 (commit/push 생략)"
  echo "홈(목록): https://315seconds.github.io/sales_report/"
  echo "리포트:   https://315seconds.github.io/sales_report/popup/$FOLDER/"
  exit 0
fi

git commit -m "Add popup report $FOLDER"
git push

echo "✅ 업로드 완료:"
echo "홈(목록): https://315seconds.github.io/sales_report/"
echo "리포트:   https://315seconds.github.io/sales_report/popup/$FOLDER/"
