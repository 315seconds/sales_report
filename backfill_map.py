#!/usr/bin/env python3
"""기존 HTML 리포트에 Google Maps 임베드 섹션을 소급 추가합니다."""
import json
from pathlib import Path
from urllib.parse import quote

DOCS = Path(__file__).parent / "docs"


def map_section_html(location: str) -> str:
    q = quote(location)
    return (
        f'<div class="section" style="margin-top:16px;">'
        f'<h2>📍 위치</h2>'
        f'<div class="muted" style="margin-bottom:8px">{location}</div>'
        f'<iframe src="https://maps.google.com/maps?q={q}&output=embed&hl=ko" '
        f'width="100%" height="280" frameborder="0" '
        f'style="border:0;border-radius:12px;" allowfullscreen loading="lazy"></iframe>'
        f'</div>'
    )


def main():
    changed = 0
    for section in ("popup", "main"):
        section_dir = DOCS / section
        if not section_dir.exists():
            continue
        for folder in sorted(section_dir.iterdir()):
            meta_path = folder / "meta.json"
            html_path = folder / "index.html"
            if not meta_path.exists() or not html_path.exists():
                continue
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            location = meta.get("location", "").strip()
            if not location:
                print(f"  ⚠️  위치 없음: {section}/{folder.name}")
                continue
            html = html_path.read_text(encoding="utf-8")
            if "maps.google.com" in html:
                print(f"  ─  이미 있음: {section}/{folder.name}")
                continue
            insert = map_section_html(location) + "\n"
            html = html.replace("</div></body></html>", insert + "</div></body></html>")
            html_path.write_text(html, encoding="utf-8")
            print(f"  ✅ 지도 추가: {section}/{folder.name}")
            changed += 1
    print(f"\n완료: {changed}개 업데이트")


if __name__ == "__main__":
    main()
