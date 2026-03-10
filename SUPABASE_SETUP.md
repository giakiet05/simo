# Supabase Exchange Rates Setup

## Bước 1: Tạo table trong Supabase

1. Vào Supabase Dashboard: https://supabase.com/dashboard
2. Chọn project của mày
3. Vào **SQL Editor**
4. Copy và chạy nội dung file `supabase_migrations/create_exchange_rates_table.sql`
5. Click **Run** để tạo table

## Bước 2: Đăng ký exchangerate-api.com

1. Vào https://www.exchangerate-api.com/
2. Đăng ký tài khoản free (1,500 requests/month)
3. Copy API key của mày

## Bước 3: Deploy Edge Function

### Cài đặt Supabase CLI (nếu chưa có)

```bash
npm install -g supabase
```

### Login vào Supabase

```bash
supabase login
```

### Link project

```bash
cd /home/giakiet05/programming/pet/simo
supabase link --project-ref <your-project-ref>
```

Project ref tìm ở: Settings → General → Reference ID

### Set secrets cho Edge Function

```bash
# Set API key
supabase secrets set EXCHANGE_RATE_API_KEY=your_api_key_here

# Các biến SUPABASE_URL và SUPABASE_SERVICE_ROLE_KEY đã có sẵn
```

### Deploy Edge Function

```bash
supabase functions deploy update-exchange-rates --project-ref <your-project-ref>
```

Sau khi deploy xong, mày sẽ có URL:
```
https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

### Test Edge Function

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

## Bước 4: Setup Cron Job (chạy mỗi 6 tiếng)

### Option A: Dùng cron-job.org (Free, dễ nhất)

1. Vào https://console.cron-job.org/
2. Đăng ký tài khoản free
3. Tạo cronjob mới:
   - Title: "Update Simo Exchange Rates"
   - URL: `https://<project-ref>.supabase.co/functions/v1/update-exchange-rates`
   - Execution schedule: Every 6 hours
   - Request method: POST
   - Enable: Yes
4. Save

Free plan cho phép tạo nhiều jobs, chạy mỗi 1 phút 1 lần (6 tiếng không vấn đề gì).

### Option B: Dùng GitHub Actions (nếu mày có GitHub repo)

Tạo file `.github/workflows/update-exchange-rates.yml`:

```yaml
name: Update Exchange Rates

on:
  schedule:
    # Chạy mỗi 6 tiếng (0:00, 6:00, 12:00, 18:00 UTC)
    - cron: '0 */6 * * *'
  workflow_dispatch: # Cho phép trigger thủ công

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Supabase Edge Function
        run: |
          curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

## Bước 5: Test xem rates đã được update chưa

Vào Supabase Dashboard → Table Editor → `exchange_rates` → Check dữ liệu

Hoặc chạy query:

```sql
SELECT base_currency, updated_at, jsonb_object_keys(rates) as currencies
FROM exchange_rates;
```

## Bước 6: Update Flutter app

Code đã được update sẵn trong `lib/services/currency_service.dart` để fetch từ Supabase thay vì API trực tiếp.

Chạy app:

```bash
flutter run
```

---

## Monitoring

Để check Edge Function logs:

```bash
supabase functions logs update-exchange-rates
```

## Quota

- exchangerate-api.com free: 1,500 requests/month
- Chạy mỗi 6h = 4 lần/ngày = 120 lần/tháng
- Còn dư 1,380 requests để test/debug

## Troubleshooting

### Edge Function fail

Check logs:
```bash
supabase functions logs update-exchange-rates
```

### Table empty

Trigger function manually:
```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```
