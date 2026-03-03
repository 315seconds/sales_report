#!/usr/bin/env bash
set -euo pipefail

HTML_PATH="${1:-}"
META_PATH="${2:-}"
FOLDER="${3:-}"

if [ -z "$HTML_PATH" ] || [ -z "$META_PATH" ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> <meta.json 경로> [폴더명]"
  echo "예:   ./publish_popup_report.sh ~/Downloads/popup_report_....html ~/Downloads/meta_....json"
  exit 1
fi

if [ ! -f "$HTML_PATH" ]; then
  echo "❌ HTML 파일을 찾을 수 없습니다: $HTML_PATH"
  exit 1
fi

if [ ! -f "$META_PATH" ]; then
  echo "❌ meta.json 파일을 찾을 수 없습니다: $META_PATH"
  exit 1
fi

# 폴더명 자동 생성: meta.json의 start/end/store 사용
if [ -z "$FOLDER" ]; then
  FOLDER="$(python3 - "$META_PATH" << 'PY'
import json, re, sys, unicodedata

meta_path = sys.argv[1]
m = json.load(open(meta_path, 'r', encoding='utf-8'))

start = str(m.get("start","")).strip()
end = str(m.get("end","")).strip()
store = str(m.get("store","popup")).strip()

store = unicodedata.normalize("NFC", store)

# slug: 영문/숫자/_/- 만 허용 (한글/특수문자는 제거하여 404 방지)
store = re.sub(r"\s+", "-", store)
store = re.sub(r"[^0-9A-Za-z_-]+", "", store).strip("-_").lower() or "popup"
store = store[:30]

def ok_date(s): return bool(re.match(r"^\d{4}-\d{2}-\d{2}$", s))
if not ok_date(start): start = end
if not ok_date(end): end = start

print(f"{start}_{end}_{store}")
PY
)"
  echo "✅ 폴더명 자동 생성: $FOLDER"
fi

TARGET_DIR="docs/popup/$FOLDER"
mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_DIR/index.html" ] || [ -f "$TARGET_DIR/meta.json" ]; then
  echo "⚠️ 이미 같은 폴더($FOLDER)에 리포트가 있습니다. 덮어씁니다."
fi

cp "$HTML_PATH" "$TARGET_DIR/index.html"
cp "$META_PATH" "$TARGET_DIR/meta.json"

./rebuild_index.sh

git add "$TARGET_DIR/index.html" "$TARGET_DIR/meta.json" docs/index.html

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