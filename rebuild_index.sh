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
  echo 'a{color:#111;text-decoration:none}'
  echo '.item{border:1px solid #eee;border-radius:14px;padding:12px 14px;margin:10px 0}'
  echo '.item:hover{background:#fafafa}'
  echo '.meta{color:#666;font-size:12px;margin-top:4px}'
  echo '</style></head><body>'
  echo '<h1>📊 Popup Report Archive</h1>'
  echo '<p class="sub">자동 생성된 리포트 목록입니다.</p>'

  if [ ! -d "$ROOT" ]; then
    echo '<p>아직 리포트가 없습니다.</p>'
  else
    # 폴더명 역순 정렬(최근이 위로 오게). 폴더명 규칙을 YYYY-MM-DD_지점 으로 하면 잘 정렬됨.
    for d in $(ls -1 "$ROOT" | sort -r); do
      if [ -f "$ROOT/$d/index.html" ]; then
        echo "<div class='item'>"
        echo "<a href='$BASE_URL/popup/$d/'><b>$d</b></a>"
        echo "<div class='meta'>$BASE_URL/popup/$d/</div>"
        echo "</div>"
      fi
    done
  fi

  echo '</body></html>'
} > docs/index.html

echo "✅ rebuilt docs/index.html"
