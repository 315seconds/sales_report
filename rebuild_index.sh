#!/usr/bin/env bash
set -e

BASE_URL="https://315seconds.github.io/sales_report"
ROOT="docs/popup"

mkdir -p docs

{
  echo '<!doctype html><html lang="ko"><head><meta charset="utf-8"/>'
  echo '<meta name="viewport" content="width=device-width, initial-scale=1"/>'
  echo '<title>Popup Report Archive</title>'
  echo '<style>'
  echo 'body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Apple SD Gothic Neo","Noto Sans KR",Arial,sans-serif;margin:24px;color:#111}'
  echo 'h1{font-size:22px;margin:0 0 8px}'
  echo '.sub{color:#666;margin:0 0 18px;font-size:13px}'
  echo '.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px;max-width:1100px}'
  echo '.card{border:1px solid #eee;border-radius:16px;padding:14px 16px;background:#fff}'
  echo '.card:hover{background:#fafafa}'
  echo '.title{font-weight:800;font-size:14px;margin:0 0 6px}'
  echo '.meta{color:#666;font-size:12px}'
  echo 'a{color:#111;text-decoration:none}'
  echo '</style></head><body>'
  echo '<h1>📊 Popup Report Archive</h1>'
  echo '<p class="sub">최신 리포트가 위로 오도록 자동 정렬됩니다.</p>'
  echo '<div class="grid">'

  if [ ! -d "$ROOT" ]; then
    echo '<div class="card"><div class="title">아직 리포트가 없습니다</div><div class="meta">docs/popup 아래에 리포트를 추가해 주세요.</div></div>'
  else
    for d in $(ls -1 "$ROOT" | sort -r); do
      if [ -f "$ROOT/$d/index.html" ]; then
        echo "<a class='card' href='$BASE_URL/popup/$d/'>"
        echo "<div class='title'>$d</div>"
        echo "<div class='meta'>$BASE_URL/popup/$d/</div>"
        echo "</a>"
      fi
    done
  fi

  echo '</div></body></html>'
} > docs/index.html

echo "✅ rebuilt docs/index.html (list archive)"
