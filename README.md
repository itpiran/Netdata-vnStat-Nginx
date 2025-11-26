# Monitoring Stack: Netdata + vnStat + Nginx

این مخزن قالبی آماده برای نصب مجموعه‌ی مانیتورینگ **Netdata + vnStat** با **Nginx (reverse-proxy + SSL)** است.
هدف: نصب آسان روی Ubuntu/Debian با یک اسکریپت و قابلیت گرفتن پارامترها (دامنه، ایمیل، احراز هویت پایه، و ...).

## محتویات
- `install.sh` — اسکریپت اصلی که تمام مراحل نصب را انجام می‌دهد (نیاز به اجرای با sudo).
- `templates/nginx_netdata.conf.tpl` — قالب پیکربندی Nginx برای پروکسی Netdata.
- `scripts/setup_htpasswd.sh` — ایجاد فایل htpasswd برای Basic Auth.
- `scripts/install_netdata_vnstat.sh` — مراحل نصب Netdata و vnStat و فعال‌سازی سرویس‌ها.
- `README.md` — همین فایل.

## پیش‌نیازها
- توزیع: Ubuntu 18.04/20.04/22.04 یا Debian معادل
- دسترسی `sudo` یا root
- پورت‌های 80 و 443 آزاد (برای Let's Encrypt)

## نحوه استفاده سریع
1. کلون یا دانلود این مخزن:
   ```bash
   wget https://your-git-host/monitoring-github-template.zip
   unzip monitoring-github-template.zip
   cd monitoring-github-template
   ```
2. اجرای اسکریپت نصب:
   ```bash
   sudo bash install.sh
   ```
   اسکریپت از شما مقادیر زیر را می‌پرسد:
   - دامنه (مثال: monitor.example.com)
   - ایمیل برای Let's Encrypt
   - آیا Basic Auth فعال شود؟ (y/n)
   - نام کاربری و پسورد (در صورت انتخاب)

## خروجی
- سایت مانیتورینگ در `https://<your-domain>/` در دسترس خواهد بود.
- اطلاعات ورود (در صورت فعال بودن Basic Auth) در فایل `~/monitoring_credentials.txt` ذخیره می‌شود (با هشدار درباره امنیت).

## هشدارها
- اسکریپت‌ها برای استفاده در محیط تولید طراحی شده‌اند، اما قبل از اجرای نهایی حتماً بررسی کنید.
- اسکریپت رمزها را به‌صورت Cleartext در فایل خروجی ذخیره می‌کند — در صورت نیاز باید آن را امن کنید.
