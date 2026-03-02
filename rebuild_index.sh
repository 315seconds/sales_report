#!/usr/bin/env bash
set -e

BASE_URL="https://315seconds.github.io/sales_report"
ROOT="docs/popup"

mkdir -p docs

# 카드 HTML 만들기
CARDS=""
if [ -d "$ROOT" ]; then
  for d in $(ls -1 "$ROOT" | sort -r); do
    if [ -f "$ROOT/$d/index.html" ]; then
      # 카드 한 장
      CARDS="${CARDS}
      <a class='card' href='${BASE_URL}/popup/${d}/' data-name='${d}'>
        <div class='title'>${d}</div>
        <div class='meta'>${BASE_URL}/popup/${d}/</div>
      </a>"
    fi
  done
fi

cat > docs/index.html << EOF
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Popup Report Archive</title>
  <style>
    :root{
      --bg:#0b0f19;
      --panel:#0f172a;
      --card:#ffffff;
      --muted:#6b7280;
      --line:#e5e7eb;
      --accent:#7c3aed;
    }
    body{
      margin:0;
      font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Apple SD Gothic Neo","Noto Sans KR",Arial,sans-serif;
      background: radial-gradient(1200px 800px at 10% -10%, rgba(124,58,237,0.35), transparent 60%),
                  radial-gradient(1200px 800px at 90% 0%, rgba(59,130,246,0.25), transparent 55%),
                  #0b0f19;
      color:#fff;
    }
    .wrap{max-width:1100px;margin:0 auto;padding:26px 18px 40px;}
    .header{
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.10);
      border-radius: 18px;
      padding: 18px 18px;
      backdrop-filter: blur(10px);
    }
    h1{margin:0;font-size:22px;letter-spacing:-0.2px}
    .sub{margin-top:6px;color:rgba(255,255,255,0.72);font-size:13px;line-height:1.4}
    .badge{
      display:inline-block;margin-top:10px;
      padding:6px 10px;border-radius:999px;
      background: rgba(255,255,255,0.10);
      border: 1px solid rgba(255,255,255,0.14);
      font-size:12px;color:rgba(255,255,255,0.85)
    }

    .controls{display:flex;gap:10px;flex-wrap:wrap;margin:14px 0 14px}
    .search{
      flex:1 1 280px;
      background:#fff;border-radius:14px;
      padding:12px 12px;border:0;outline:none;
      font-size:14px;color:#111;
    }
    .hint{font-size:12px;color:rgba(255,255,255,0.65);margin-top:6px}

    .grid{
      display:grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap:12px;
      margin-top: 10px;
    }
    .card{
      display:block;
      text-decoration:none;
      background: rgba(255,255,255,0.95);
      color:#111;
      border-radius: 18px;
      padding: 14px 16px;
      border: 1px solid rgba(255,255,255,0.65);
      box-shadow: 0 10px 30px rgba(0,0,0,0.20);
      transition: transform .12s ease, box-shadow .12s ease;
    }
    .card:hover{
      transform: translateY(-2px);
      box-shadow: 0 14px 40px rgba(0,0,0,0.26);
    }
    .title{font-weight:900;font-size:14px;letter-spacing:-0.1px}
    .meta{margin-top:6px;color:#6b7280;font-size:12px;word-break:break-all}

    .empty{
      margin-top:14px;
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.10);
      border-radius: 18px;
      padding: 14px 16px;
      color: rgba(255,255,255,0.75);
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="header">
      <h1>📊 Popup Report Archive</h1>
      <div class="sub">최신 리포트가 위로 정렬됩니다. 아래 검색창에서 날짜/지점명을 빠르게 찾을 수 있어요.</div>
      <div class="badge">Auto-updated</div>
    </div>

    <div class="controls">
      <input id="q" class="search" placeholder="검색 (예: 2026-03, seongsu, hongdae)" />
    </div>
    <div class="hint">폴더명 규칙: <b>YYYY-MM-DD_YYYY-MM-DD_store</b> 또는 <b>YYYY-MM-DD_store</b></div>

    <div id="grid" class="grid">
      ${CARDS}
    </div>

    <div id="empty" class="empty" style="display:none;">검색 결과가 없습니다.</div>
  </div>

  <script>
    const q = document.getElementById('q');
    const cards = Array.from(document.querySelectorAll('.card'));
    const empty = document.getElementById('empty');

    function run(){
      const s = (q.value || '').toLowerCase().trim();
      let shown = 0;
      for(const c of cards){
        const name = (c.dataset.name || '').toLowerCase();
        const ok = !s || name.includes(s);
        c.style.display = ok ? '' : 'none';
        if(ok) shown++;
      }
      empty.style.display = (shown === 0) ? '' : 'none';
    }
    q.addEventListener('input', run);
    run();
  </script>
</body>
</html>
EOF

echo "✅ rebuilt docs/index.html (pretty list + search)"
