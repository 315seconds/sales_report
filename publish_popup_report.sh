#!/usr/bin/env bash
set -e

REPORT_PATH="${1:-}"
FOLDER="${2:-}"

if [ -z "$REPORT_PATH" ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> [폴더명]"
  echo "예:   ./publish_popup_report.sh ~/Downloads/report.html"
  echo "또는: ./publish_popup_report.sh ~/Downloads/report.html 2026-02-04_2026-02-09_chabot"
  exit 1
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ report.html 파일을 찾을 수 없습니다: $REPORT_PATH"
  exit 1
fi

# -----------------------------------------
# 폴더명 자동 생성 (start_end_store)
# - 기간: HTML에서 YYYY-MM-DD ~ YYYY-MM-DD 찾기
# - 매장명: HTML에서 <h1>...</h1> 추출
# - 매장명은 URL 안전 slug로 변환 (한글/특수문자 방지)
# -----------------------------------------
if [ -z "$FOLDER" ]; then
  RANGE_LINE="$(grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*~[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$REPORT_PATH" | head -n 1 || true)"

  START_DATE=""
  END_DATE=""

  if [ -n "$RANGE_LINE" ]; then
    START_DATE="$(echo "$RANGE_LINE" | sed -E 's/^([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')"
    END_DATE="$(echo "$RANGE_LINE"   | sed -E 's/.*~[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')"
  fi

  # 매장명 추출 + slug 변환 (python 사용)
  STORE_SLUG="$(python3 - << 'PY'
import re, sys, unicodedata
p = sys.argv[1]
html = open(p, 'r', encoding='utf-8', errors='ignore').read()

# 1) <h1>...</h1> 우선
m = re.search(r'<h1[^>]*>\s*([^<]{1,80})\s*</h1>', html, re.I)
store = m.group(1).strip() if m else "popup"

# normalize unicode (NFC)
store = unicodedata.normalize("NFC", store)

# 2) slug: 공백 -> -, 영문/숫자/하이픈/언더바만 유지
store = re.sub(r"\s+", "-", store)
store = re.sub(r"[^0-9A-Za-z_-]+", "", store)
store = store.strip("-_").lower() or "popup"

# 너무 길면 컷
print(store[:30])
PY
"$REPORT_PATH")"

  if [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    TODAY="$(date +%F)"
    echo "⚠️ HTML에서 기간(YYYY-MM-DD ~ YYYY-MM-DD)을 못 찾아서 오늘 날짜로 대체합니다."
    START_DATE="$TODAY"
    END_DATE="$TODAY"
  fi

  FOLDER="${START_DATE}_${END_DATE}_${STORE_SLUG}"
  echo "✅ 폴더명 자동 생성: $FOLDER"
fi

# -----------------------------------------
# 리포트 파일 복사 (index.html)
# -----------------------------------------
mkdir -p "docs/popup/$FOLDER"

if [ -f "docs/popup/$FOLDER/index.html" ]; then
  echo "⚠️ 이미 같은 폴더($FOLDER)에 리포트가 있습니다. 덮어씁니다."
fi

cp "$REPORT_PATH" "docs/popup/$FOLDER/index.html"

# -----------------------------------------
# meta.json 생성
# - 폴더명에서 start/end/store 파싱
# - HTML에서 총매출/국내비중/해외비중/해외TOP국가(가능하면) 추출
# -----------------------------------------
python3 - << 'PY'
import json, re, sys, os

folder = sys.argv[1]
html_path = sys.argv[2]

# 폴더명 파싱: start_end_store
start=end=store=""
parts = folder.split("_")
if len(parts) >= 3 and re.match(r"\d{4}-\d{2}-\d{2}", parts[0]) and re.match(r"\d{4}-\d{2}-\d{2}", parts[1]):
    start, end = parts[0], parts[1]
    store = "_".join(parts[2:])
elif len(parts) >= 2:
    # fallback: end_store
    end = parts[0]
    start = end
    store = "_".join(parts[1:])
else:
    store = folder

html = open(html_path, "r", encoding="utf-8", errors="ignore").read()

def parse_money(patterns, default=0):
    for pat in patterns:
        m = re.search(pat, html, re.I)
        if m:
            s = m.group(1)
            s = re.sub(r"[^0-9]", "", s)
            return int(s) if s else default
    return default

def parse_pct(patterns, default=0.0):
    for pat in patterns:
        m = re.search(pat, html, re.I)
        if m:
            s = m.group(1).replace("%","").strip()
            try:
                return float(s)/100.0
            except:
                pass
    return default

# v5 리포트 KPI에서 추출 시도 (없으면 0)
total_sales = parse_money([
    r"Total Sales</div>\s*<div class=\"v\">([^<]+)</div>",
    r"총 매출</div>\s*<div class=\"v\">([^<]+)</div>",
], 0)

foreign_share = parse_pct([
    r"Foreign Share</div>\s*<div class=\"v\">([^<]+)</div>",
    r"해외 비중</div>\s*<div class=\"v\">([^<]+)</div>",
], 0.0)

dom_share = parse_pct([
    r"Domestic Share</div>\s*<div class=\"v\">([^<]+)</div>",
    r"국내 비중</div>\s*<div class=\"v\">([^<]+)</div>",
], 0.0)

# 해외 TOP 국가 (가능하면)
top_country = "UNK"
m = re.search(r"<h2>Foreign Countries</h2>.*?<table.*?</table>", html, re.S|re.I)
if m:
    table = m.group(0)
    m2 = re.search(r"<td>\s*([A-Z]{2})\s*</td>", table)
    if m2:
        top_country = m2.group(1)

meta = {
    "folder": folder,
    "store": store,
    "start": start,
    "end": end,
    "total_sales": total_sales,
    "dom_share": dom_share,
    "foreign_share": foreign_share,
    "top_country": top_country
}

out_path = os.path.join("docs", "popup", folder, "meta.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(meta, f, ensure_ascii=False, indent=2)

print("✅ meta.json written:", out_path)
PY \
"$FOLDER" "docs/popup/$FOLDER/index.html"

# -----------------------------------------
# 아카이브 홈 재생성
# -----------------------------------------
./rebuild_index.sh

# -----------------------------------------
# git add / commit / push
# -----------------------------------------
git add "docs/popup/$FOLDER/index.html" "docs/popup/$FOLDER/meta.json" docs/index.html

# 변경사항 없으면 종료
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
