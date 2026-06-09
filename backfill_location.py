#!/usr/bin/env python3
"""
backfill_location.py
기존 meta.json에 location 필드를 소급 추가합니다.

사용법:
  python3 backfill_location.py

LOCATIONS 딕셔너리에 매장명(store 값) → 주소를 채워서 실행하세요.
같은 매장명이 여러 곳(예: 한칸)이면 폴더명으로 구분하는 오버라이드 항목을 활용하세요.
"""
import json
from pathlib import Path

DOCS = Path(__file__).parent / "docs"

# ── 여기에 주소를 채우세요 ──────────────────────────────────
LOCATIONS: dict[str, str] = {
    "성수":  "서울특별시 성동구 아차산로 166 1층",
    "차봇":  "서울 성동구 성수이로 72 1층",
    "한칸":  "서울 성동구 연무장길 17 1층",
    "연무장": "서울 성동구 성수이로7가길 13 1층",
    "오이":  "서울 성동구 성수일로4길 52 1층",
    "무성":  "서울특별시 성동구 연무장11길 7 1층",
    "연오":  "서울특별시 성동구 연무장길 115 1층",
    "삼성":  "서울 성동구 연무장길 35 1층",
}

# 같은 store명이 여러 번 등장할 때 폴더명으로 주소를 개별 지정 (선택)
# 키: docs/popup/ 또는 docs/main/ 아래 폴더명
FOLDER_OVERRIDE: dict[str, str] = {
    # "2026-02-05_2026-03-01_popup": "서울 마포구 연남동 XXX",  # 한칸 1차
    # "2026-03-31_2026-04-20_한칸":   "서울 종로구 세종대로 YYY",  # 한칸 2차
}
# ─────────────────────────────────────────────────────────────


def update_meta(path: Path, location: str) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("location") == location:
        return False
    data["location"] = location
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return True


def main():
    changed = 0
    skipped = 0
    for section in ("popup", "main"):
        section_dir = DOCS / section
        if not section_dir.exists():
            continue
        for folder in sorted(section_dir.iterdir()):
            meta_path = folder / "meta.json"
            if not meta_path.exists():
                continue
            data = json.loads(meta_path.read_text(encoding="utf-8"))
            store = data.get("store", "")

            # 폴더 오버라이드 우선
            loc = FOLDER_OVERRIDE.get(folder.name) or LOCATIONS.get(store, "")
            if not loc:
                print(f"  ⚠️  주소 없음: {section}/{folder.name} (store={store!r})")
                skipped += 1
                continue
            if update_meta(meta_path, loc):
                print(f"  ✅ 업데이트: {section}/{folder.name}  →  {loc}")
                changed += 1
            else:
                print(f"  ─  변경 없음: {section}/{folder.name}")

    print(f"\n완료: {changed}개 업데이트, {skipped}개 주소 미입력 스킵")


if __name__ == "__main__":
    main()
