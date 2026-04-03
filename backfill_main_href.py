#!/usr/bin/env python3
"""
backfill_main_href.py
─────────────────────
기존 docs/main/manifest.json 에 href 필드를 소급 추가하고
git add / commit / push 까지 실행합니다.

실행 방법 (sales_report 폴더에서):
    python3 backfill_main_href.py
"""
import json, subprocess
from pathlib import Path

BASE_URL   = "https://315seconds.github.io/sales_report"
MANIFEST   = Path("docs/main/manifest.json")
MAIN_ROOT  = Path("docs/main")

if not MANIFEST.exists():
    print("❌ docs/main/manifest.json 파일이 없습니다.")
    exit(1)

manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
months   = manifest.get("months", [])

changed = []
for entry in months:
    folder = entry.get("url", "").split("/main/")[-1].replace("/meta.json", "")
    if not folder:
        continue

    report_path = MAIN_ROOT / folder / "index.html"
    href        = f"{BASE_URL}/main/{folder}/"

    if "href" not in entry and report_path.exists():
        entry["href"] = href
        changed.append(f"  ✅ {entry['label']} ({folder}) → href 추가")
    elif "href" in entry:
        changed.append(f"  ℹ️  {entry['label']} ({folder}) → 이미 href 있음 (건너뜀)")
    else:
        changed.append(f"  ⚠️  {entry['label']} ({folder}) → index.html 없음 (href 추가 안 함)")

if not changed:
    print("변경사항 없음.")
    exit(0)

print("\n처리 결과:")
for c in changed: print(c)

# href가 실제로 추가된 항목이 있을 때만 저장 & push
actually_changed = [c for c in changed if "href 추가" in c]
if not actually_changed:
    print("\n소급할 항목이 없습니다.")
    exit(0)

manifest["months"] = months
MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"\n📝 manifest.json 저장 완료 ({len(actually_changed)}개 업데이트)")

# git push
subprocess.run(["git", "add", str(MANIFEST)], check=True)
result = subprocess.run(["git", "diff", "--cached", "--quiet"])
if result.returncode == 0:
    print("ℹ️  변경사항 없음 (commit 생략)")
else:
    subprocess.run(["git", "commit", "-m", "backfill: add href to existing main reports"], check=True)
    subprocess.run(["git", "push"], check=True)
    print("✅ GitHub push 완료!")
    print(f"\n🏠 홈: {BASE_URL}/")
