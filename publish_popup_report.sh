#!/usr/bin/env bash
# ============================================================
# publish_popup_report.sh
# 팝업 리포트(HTML + meta.json)를 docs/popup/ 에 저장하고
# docs/popup/manifest.json 을 자동 업데이트한 뒤 GitHub에 push
# ------------------------------------------------------------
# 사용법:
#   ./publish_popup_report.sh <report.html 경로> <meta.json 경로> [폴더명]
#
# 예시:
#   ./publish_popup_report.sh ~/Downloads/popup_report_성수.html ~/Downloads/meta_성수.json
# ============================================================
set -euo pipefail

HTML_PATH="${1:-}"
META_PATH="${2:-}"
FOLDER="${3:-}"

# ── 인수 확인 ──────────────────────────────────────────────
if [ -z "$HTML_PATH" ] || [ -z "$META_PATH" ]; then
  echo "사용법: ./publish_popup_report.sh <report.html 경로> <meta.json 경로> [폴더명]"
  echo "예:     ./publish_popup_report.sh ~/Downloads/popup_report_....html ~/Downloads/meta_....json"
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

# ── 폴더명 자동 생성 (meta.json의 start/end/store 사용) ────
if [ -z "$FOLDER" ]; then
  FOLDER="$(python3 - "$META_PATH" << 'PY'
import json, re, sys, unicodedata

m = json.load(open(sys.argv[1], encoding='utf-8'))
start = str(m.get("start","")).strip()
end   = str(m.get("end","")).strip()
store = str(m.get("store","popup")).strip()
store = unicodedata.normalize("NFC", store)
store = re.sub(r"\s+", "-", store)
store = re.sub(r"[^0-9A-Za-z_-]+", "", store).strip("-_").lower() or "popup"
store = store[:30]

ok = lambda s: bool(re.match(r"^\d{4}-\d{2}-\d{2}$", s))
if not ok(start): start = end
if not ok(end):   end   = start
print(f"{start}_{end}_{store}")
PY
)"
  echo "✅ 폴더명 자동 생성: $FOLDER"
fi

# ── 파일 복사 ───────────────────────────────────────────────
TARGET_DIR="docs/popup/$FOLDER"
mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_DIR/index.html" ] || [ -f "$TARGET_DIR/meta.json" ]; then
  echo "⚠️  이미 같은 폴더($FOLDER)가 있습니다. 파일을 덮어씁니다."
fi

cp "$HTML_PATH" "$TARGET_DIR/index.html"
cp "$META_PATH" "$TARGET_DIR/meta.json"
echo "📁 복사 완료: $TARGET_DIR/"

# ── popup/manifest.json 업데이트 ───────────────────────────
BASE_URL="https://315seconds.github.io/sales_report"
MANIFEST="docs/popup/manifest.json"

python3 - "$META_PATH" "$FOLDER" "$MANIFEST" "$BASE_URL" << 'PY'
import json, sys
from pathlib import Path

meta_path, folder, manifest_path, base_url = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
m  = json.load(open(meta_path, encoding='utf-8'))

# manifest 읽기 (없으면 빈 목록으로 시작)
mf_path = Path(manifest_path)
mf_path.parent.mkdir(parents=True, exist_ok=True)
manifest = json.loads(mf_path.read_text(encoding='utf-8')) if mf_path.exists() else {"popups": []}

entry = {
    "name":     folder,
    "label":    m.get("store", folder),
    "start":    m.get("start", ""),
    "end":      m.get("end", ""),
    "href":     f"{base_url}/popup/{folder}/",
    "meta_url": f"{base_url}/popup/{folder}/meta.json",
}

# 같은 name이 있으면 교체, 없으면 맨 앞에 추가 (최신순)
popups = manifest.get("popups", [])
popups = [p for p in popups if p.get("name") != folder]
popups.insert(0, entry)
manifest["popups"] = popups

mf_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(f"✅ manifest 업데이트: {folder} 추가 (총 {len(popups)}개)")
PY

# ── git add / commit / push ─────────────────────────────────
git add "$TARGET_DIR/index.html" "$TARGET_DIR/meta.json" "$MANIFEST"

if git diff --cached --quiet; then
  echo "ℹ️  변경사항 없음 (commit/push 생략)"
else
  git commit -m "Add popup report: $FOLDER"
  git push
  echo ""
  echo "✅ 업로드 완료!"
fi

echo ""
echo "🏠 홈(목록): $BASE_URL/"
echo "📊 리포트:   $BASE_URL/popup/$FOLDER/"