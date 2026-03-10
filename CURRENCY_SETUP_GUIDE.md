# Hướng dẫn setup Currency Conversion với Supabase

## Tổng quan

Hệ thống sử dụng:
- **exchangerate-api.com** (free tier: 1,500 requests/month)
- **Supabase Edge Function** để fetch rates mỗi 6 tiếng (4 lần/ngày = 120 requests/tháng)
- **Supabase Database** để cache rates
- **App** query từ Supabase (không limit) + local cache 6 tiếng

## Lợi ích

✅ Tất cả users share 1 cached copy → tiết kiệm API quota
✅ Chỉ tốn ~120 requests/tháng (còn dư 1,380 cho test)
✅ App response nhanh vì query từ Supabase
✅ Offline support với local cache
✅ Support đầy đủ 20 currencies including VND

## Setup Steps

### 1. Tạo table trong Supabase

```bash
# Vào Supabase Dashboard → SQL Editor
# Copy và chạy file: supabase_migrations/create_exchange_rates_table.sql
```

Hoặc chạy SQL trực tiếp:

```sql
-- Xem nội dung file supabase_migrations/create_exchange_rates_table.sql
```

### 2. Đăng ký exchangerate-api.com

1. Vào: https://www.exchangerate-api.com/
2. Sign up (miễn phí)
3. Verify email
4. Copy API key (dạng: `abc123def456...`)

Free tier:
- 1,500 requests/month
- No credit card required
- Access to 161 currencies

### 3. Deploy Supabase Edge Function

**Cài Supabase CLI:**

```bash
npm install -g supabase
```

**Login:**

```bash
supabase login
```

**Link project:**

```bash
cd /home/giakiet05/programming/pet/simo
supabase link --project-ref <your-project-ref>
```

Tìm project-ref: Supabase Dashboard → Settings → General → Reference ID

**Set API key:**

```bash
supabase secrets set EXCHANGE_RATE_API_KEY=your_api_key_here
```

**Deploy function:**

```bash
# Copy folder supabase_edge_function/update-exchange-rates vào supabase/functions/
mkdir -p supabase/functions
cp -r supabase_edge_function/update-exchange-rates supabase/functions/

# Deploy
supabase functions deploy update-exchange-rates
```

**Test:**

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

Nếu thành công sẽ thấy response:

```json
{
  "success": true,
  "base_currency": "USD",
  "currencies_count": 20,
  "updated_at": "2026-02-15T10:30:00.000Z"
}
```

### 4. Setup Cron Job (chạy mỗi 6 tiếng)

**Option A: cron-job.org (Recommended - Free & Easy)**

1. Vào: https://console.cron-job.org/
2. Sign up
3. Create new cronjob:
   - Title: `Simo Exchange Rates Update`
   - URL: `https://<project-ref>.supabase.co/functions/v1/update-exchange-rates`
   - Schedule: `0 */6 * * *` (Every 6 hours)
   - Request Method: `POST`
   - Enable: ✅
4. Save

Sẽ chạy vào: 00:00, 06:00, 12:00, 18:00 UTC mỗi ngày.

**Option B: GitHub Actions (nếu có repo)**

Tạo `.github/workflows/update-exchange-rates.yml`:

```yaml
name: Update Exchange Rates
on:
  schedule:
    - cron: '0 */6 * * *'
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Edge Function
        run: |
          curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

### 5. Verify data

**Check table:**

```sql
SELECT * FROM exchange_rates;
```

Nên thấy 1 row với:
- `base_currency`: USD
- `rates`: JSON object với 20 currencies
- `updated_at`: timestamp gần đây

**Check app:**

```bash
flutter run
```

Test currency conversion:
1. Vào Add Transaction
2. Nhập số tiền (ví dụ: 100)
3. Tap "Chuyển đổi tiền tệ"
4. Chọn USD
5. Xem formula tự động thành "100*25000" (rate thực tế)
6. Note tự động thêm "(USD->VND)"

## Monitoring

**Check Edge Function logs:**

```bash
supabase functions logs update-exchange-rates
```

**Check cron-job.org:**

Vào Dashboard → Jobs → Execution History

**Check Supabase table:**

```sql
SELECT
  base_currency,
  updated_at,
  jsonb_object_keys(rates) as currency,
  (rates->>'VND')::float as vnd_rate
FROM exchange_rates;
```

## Troubleshooting

### Edge Function không chạy

```bash
# Check logs
supabase functions logs update-exchange-rates

# Trigger manually
curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates
```

### Table empty

Chạy Edge Function thủ công 1 lần để seed data.

### App không fetch được rates

Check:
1. Table có data không? (`SELECT * FROM exchange_rates`)
2. RLS policy đã enable? (Check SQL migration)
3. App có internet không?
4. Supabase client initialized? (check main.dart)

### Rates không update

Check:
1. Cron job có chạy không? (cron-job.org dashboard)
2. Edge Function có log errors không?
3. API key còn valid không? (check exchangerate-api.com dashboard)

## Cost Analysis

**FREE tier breakdown:**

| Service | Quota | Usage | Cost |
|---------|-------|-------|------|
| exchangerate-api.com | 1,500/month | 120/month | $0 |
| Supabase Edge Functions | 500K/month | 120/month | $0 |
| Supabase Database | 500MB | <1MB | $0 |
| Supabase API Calls | Unlimited | ~1000/day | $0 |
| cron-job.org | Unlimited | 120/month | $0 |

**TOTAL: $0/month** 🎉

## Scalability

Với free tier:
- **exchangerate-api**: 1,500 requests/month → 50 requests/day
- **Current usage**: 4 requests/day (mỗi 6h)
- **Buffer**: 46 requests/day cho test/manual trigger
- **Max users**: Unlimited (vì app không gọi API trực tiếp)

Khi cần scale (>1,500 users hoặc cần real-time rates):
- Upgrade exchangerate-api.com: $10/month = 100K requests
- Hoặc switch sang fixer.io, currencyapi.com (có free tier khác)

## Files Created

```
simo/
├── supabase_migrations/
│   └── create_exchange_rates_table.sql      # SQL to create table
├── supabase_edge_function/
│   └── update-exchange-rates/
│       └── index.ts                          # Edge Function code
├── lib/services/
│   └── currency_service.dart                 # Updated to use Supabase
├── SUPABASE_SETUP.md                         # Detailed setup guide
└── CURRENCY_SETUP_GUIDE.md                   # This file
```

## Next Steps

1. ✅ Run SQL migration
2. ✅ Deploy Edge Function
3. ✅ Setup cron job
4. ✅ Test app
5. 🚀 Publish to store!
