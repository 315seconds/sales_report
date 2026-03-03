#!/usr/bin/env bash
set -e

HTML_PATH="${1:-}"
META_PATH="${2:-}"
FOLDER="${3:-}"

if [ -z "$HTML_PATH" ] || [ -z "$META_PATH" ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> <meta.json 경로> [폴더명]"
  echo "예:   ./publish_popup_report.sh ~/Downloads/popup_report.html ~/Downloads/meta.json"
  echo "또는: ./publish_popup_report.sh ~/Downloads/popup_report.html ~/Downloads/meta.json 2026-02-04_2026-02-09_chabot"
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
# 규칙: YYYY-MM-DD_YYYY-MM-DD_store(slug)
if [ -z "$FOLDER" ]; then
  FOLDER="$(python3 - << 'PY'
import json, re, sys, unicodedata
meta_path = sys.argv[1]
m = json.load(open(meta_path, 'r', encoding='utf-8'))

start = str(m.get("start","")).strip()
end = str(m.get("end","")).strip()
store = str(m.get("store","popup")).strip()

# normalize
store = unicodedata.normalize("NFC", store)

# slug: 영문/숫자/_/- 만 허용 (한글은 URL 404 방지 위해 제거)
store = re.sub(r"\s+", "-", store)
store = re.sub(r"[^0-9A-Za-z_-]+", "", store).strip("-_").lower() or "popup"
store = store[:30]

# date fallback
def ok_date(s): return bool(re.match(r"^\d{4}-\d{2}-\d{2}$", s))
if not ok_date(start): start = end
if not ok_date(end): end = start

folder = f"{start}_{end}_{store}"
print(folder)
PY
"$META_PATH")"
  echo "✅ 폴더명 자동 생성: $FOLDER"
fi

TARGET_DIR="docs/popup/$FOLDER"
mkdir -p "$TARGET_DIR"

# 덮어쓰기 경고
if [ -f "$TARGET_DIR/index.html" ] || [ -f "$TARGET_DIR/meta.json" ]; then
  echo "⚠️ 이미 같은 폴더($FOLDER)에 리포트가 있습니다. 덮어씁니다."
fi

# 복사
cp "$HTML_PATH" "$TARGET_DIR/index.html"
cp "$META_PATH" "$TARGET_DIR/meta.json"

# 홈(아카이브) 재생성
./rebuild_index.sh

# 스테이징
git add "$TARGET_DIR/index.html" "$TARGET_DIR/meta.json" docs/index.html

# 변경 없으면 종료
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