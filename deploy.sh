#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="beaconchain-horizon"
REPO_NAME="horizon-security-assessment"
BRANCH="main"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
PAGES_URL="https://${GITHUB_USER}.github.io/${REPO_NAME}/"

echo "════════════════════════════════════════"
echo "  Horizon Deploy — $(date)"
echo "════════════════════════════════════════"

# 1) ابزارها
command -v git  >/dev/null || { echo "❌ git نصب نیست"; exit 1; }
command -v curl >/dev/null || { echo "❌ curl نصب نیست"; exit 1; }
echo "✅ git و curl موجودند"

# 2) فایل‌ها
echo ""
echo "▶ فایل‌های HTML موجود:"
ls -1 *.html 2>/dev/null || { echo "❌ هیچ HTML پیدا نشد"; exit 1; }

# 3) اگر index.html نبود، از monitor.html بساز
if [ ! -f index.html ]; then
  if [ -f monitor.html ]; then
    cp monitor.html index.html
    echo "✅ index.html از monitor.html ساخته شد"
  else
    echo "⚠️ index.html و monitor.html نیستند"
  fi
fi

# 4) git init
if [ ! -d .git ]; then
  git init
  git branch -M "$BRANCH"
  echo "✅ git init انجام شد"
else
  git checkout -B "$BRANCH" 2>/dev/null || git branch -M "$BRANCH"
  echo "✅ مخزن محلی موجود است"
fi

# 5) .gitignore
cat > .gitignore <<'GITEOF'
config.local.js
*.local.js
.env
.env.*
secrets/
*.key
*.pem
.DS_Store
Thumbs.db
desktop.ini
*.log
.vscode/
.idea/
node_modules/
dist/
build/
GITEOF
echo "✅ .gitignore ساخته شد"

# 6) .nojekyll
touch .nojekyll
echo "✅ .nojekyll ساخته شد"

# 7) کامیت
git add -A
if git diff --cached --quiet; then
  echo "⚠️ چیزی برای کامیت نیست"
else
  git commit -m "deploy: $(date +%Y-%m-%d_%H-%M)"
  echo "✅ کامیت انجام شد"
fi

# 8) ریموت
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
  echo "✅ ریموت origin تنظیم شد"
else
  git remote add origin "$REMOTE_URL"
  echo "✅ ریموت origin اضافه شد"
fi

# 9) push
echo ""
echo "▶ push به GitHub…"
git push -u origin "$BRANCH" || {
  echo ""
  echo "❌ push ناموفق — احتمالاً احراز هویت لازم است"
  echo ""
  echo "راه حل:"
  echo "  ۱. برو به https://github.com/settings/tokens"
  echo "  ۲. Generate new token (classic)"
  echo "  ۳. Scope: repo + workflow"
  echo "  ۴. توکن را کپی کن"
  echo "  ۵. دوباره push بزن و به‌جای پسورد، توکن را پیست کن"
  exit 1
}
echo "✅ push موفق"

# 10) فعال‌سازی Pages (اگر gh باشد)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo ""
  echo "▶ فعال‌سازی GitHub Pages…"
  gh api -X POST "repos/${GITHUB_USER}/${REPO_NAME}/pages" \
    -f "source[branch]=${BRANCH}" -f "source[path]=/" 2>/dev/null \
    && echo "✅ Pages فعال شد" \
    || echo "ℹ️ Pages از قبل فعال است یا نیاز به تنظیم دستی دارد"
else
  echo ""
  echo "ℹ️ gh CLI نیست — Pages را دستی فعال کن:"
  echo "   https://github.com/${GITHUB_USER}/${REPO_NAME}/settings/pages"
  echo "   Source: Deploy from a branch → ${BRANCH} → / (root) → Save"
fi

# 11) انتظار + تست
echo ""
echo "▶ انتظار ۳۰ ثانیه برای دیپلوی…"
sleep 30

echo ""
echo "▶ تست URL…"
CODE=$(curl -sS -L -o /dev/null -w "%{http_code}" --max-time 15 "$PAGES_URL" || echo "000")

echo ""
echo "════════════════════════════════════════"
if [ "$CODE" = "200" ]; then
  echo "🎉 سایت آنلاین شد!"
  echo ""
  echo "   ریشه    : $PAGES_URL"
  echo "   فروشگاه : ${PAGES_URL}store.html"
  echo "   مانیتور : ${PAGES_URL}monitor.html"
  echo "   لایسنس  : ${PAGES_URL}offline-license.html"
  echo "   دمو     : ${PAGES_URL}demo.html"
elif [ "$CODE" = "404" ]; then
  echo "⚠️ هنوز 404 — ممکن است دیپلوی کامل نشده باشد"
  echo "   ۱ دقیقه صبر کن و دوباره تست کن"
  echo "   Actions: https://github.com/${GITHUB_USER}/${REPO_NAME}/actions"
else
  echo "⚠️ کد HTTP: $CODE"
  echo "   Actions را چک کن: https://github.com/${GITHUB_USER}/${REPO_NAME}/actions"
fi
echo "════════════════════════════════════════"
