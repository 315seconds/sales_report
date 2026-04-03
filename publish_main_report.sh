#!/usr/bin/env bash
# ============================================================
# publish_main_report.sh
# 성수본점 월별 HTML + meta.json 을 docs/main/ 에 저장하고
# docs/main/manifest.json 을 자동 업데이트한 뒤 GitHub에 push
# ------------------------------------------------------------
# 사용법:
#   ./publish_main_report.sh <report.html 경로> <meta.json 경로> [월 레이블(선택)]
#
# 예시:
#   ./publish_main_report.sh ~/Downloads/popup_report_성수.html ~/Downloads/meta_성수_2026-03.json
#   ./publish_main_report.sh ~/Downloads/popup_report_성수.html ~/Downloads/meta_성수_2026-03.json 2026-03
# ============================================================
set -euo pipefail

HTML_PATH="${1:-}"
META_PATH="${2:-}"
LABEL="${3:-}"   # 선택: 지정 안 하면 start 날짜에서 자동 생성

# ── 인수 확인 ──────────────────────────────────────────────
if [ -z "$HTML_PATH" ] || [ -z "$META_PATH" ]; then
  echo "사용법: ./publish_main_report.sh <report.html 경로> <meta.json 경로> [월 레이블]"
  echo "예:     ./publish_main_report.sh ~/Downloads/popup_report_성수.html ~/Downloads/meta_성수.json"
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

# ── 폴더명 & 레이블 자동 생성 ──────────────────────────────
RESULT="$(python3 - "$META_PATH" "$LABEL" << 'PY'
import json, re, sys, unicodedata

m      = json.load(open(sys.argv[1], encoding='utf-8'))
label  = sys.argv[2].strip()
start  = str(m.get("start","")).strip()
store  = str(m.get("store","seongsu")).strip()

store = unicodedata.normalize("NFC", store)
store = re.sub(r"\s+", "-", store)
store = re.sub(r"[^0-9A-Za-z_-]+", "", store).strip("-_").lower() or "seongsu"
store = store[:20]

# 레이블: 지정 없으면 start의 YYYY-MM
if not label:
    m2 = re.match(r"(\d{4}-\d{2})", start)
    label = m2.group(1) if m2 else start

# 폴더명: YYYY-MM_store
m3 = re.match(r"(\d{4}-\d{2})", start)
ym = m3.group(1) if m3 else label.replace("/","-")
folder = f"{ym}_{store}"

print(f"{label}|{folder}")
PY
)"

LABEL_OUT="${RESULT%%|*}"
FOLDER="${RESULT##*|}"
echo "✅ 레이블: $LABEL_OUT  /  폴더명: $FOLDER"

# ── 파일 복사 ───────────────────────────────────────────────
TARGET_DIR="docs/main/$FOLDER"
mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_DIR/meta.json" ] || [ -f "$TARGET_DIR/index.html" ]; then
  echo "⚠️  이미 같은 폴더($FOLDER)가 있습니다. 덮어씁니다."
fi

cp "$HTML_PATH" "$TARGET_DIR/index.html"
cp "$META_PATH" "$TARGET_DIR/meta.json"
echo "📁 복사 완료: $TARGET_DIR/"

# ── main/manifest.json 업데이트 ────────────────────────────
BASE_URL="https://315seconds.github.io/sales_report"
MANIFEST="docs/main/manifest.json"

python3 - "$FOLDER" "$LABEL_OUT" "$MANIFEST" "$BASE_URL" << 'PY'
import json, sys
from pathlib import Path

folder, label, manifest_path, base_url = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

mf_path = Path(manifest_path)
mf_path.parent.mkdir(parents=True, exist_ok=True)
manifest = json.loads(mf_path.read_text(encoding='utf-8')) if mf_path.exists() else {"months": []}

entry = {
    "label": label,
    "url":   f"{base_url}/main/{folder}/meta.json",
    "href":  f"{base_url}/main/{folder}/",
}

# 같은 label이 있으면 교체, 없으면 맨 앞에 추가 (최신순)
months = manifest.get("months", [])
months = [mo for mo in months if mo.get("label") != label]
months.insert(0, entry)
manifest["months"] = months

mf_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(f"✅ manifest 업데이트: {label} 추가 (총 {len(months)}개월)")
PY

# ── git add / commit / push ─────────────────────────────────
git add "$TARGET_DIR/index.html" "$TARGET_DIR/meta.json" "$MANIFEST"

if git diff --cached --quiet; then
  echo "ℹ️  변경사항 없음 (commit/push 생략)"
else
  git commit -m "Add main store report: $LABEL_OUT ($FOLDER)"
  git push
  echo ""
  echo "✅ 업로드 완료!"
fi

echo ""
echo "🏠 홈(목록): $BASE_URL/"
echo "📊 리포트:   $BASE_URL/main/$FOLDER/"