#!/bin/bash

# Setup script for Simo Currency Conversion with Supabase
# Run: chmod +x setup_currency.sh && ./setup_currency.sh

set -e

echo "🚀 Simo Currency Conversion Setup"
echo "=================================="
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI not found. Installing..."
    npm install -g supabase
else
    echo "✅ Supabase CLI already installed"
fi

echo ""
echo "📝 Step 1: Login to Supabase"
echo "----------------------------"
supabase login

echo ""
echo "📝 Step 2: Link your project"
echo "----------------------------"
echo "Enter your Supabase project ref (from Settings → General → Reference ID):"
read -r PROJECT_REF

supabase link --project-ref "$PROJECT_REF"

echo ""
echo "📝 Step 3: Create database table"
echo "--------------------------------"
echo "Opening SQL file... Copy and run it in Supabase Dashboard → SQL Editor"
echo "File: supabase_migrations/create_exchange_rates_table.sql"
echo ""
read -p "Press Enter after you've run the SQL migration..."

echo ""
echo "📝 Step 4: Get exchangerate-api.com API key"
echo "-------------------------------------------"
echo "1. Go to: https://www.exchangerate-api.com/"
echo "2. Sign up (free)"
echo "3. Copy your API key"
echo ""
echo "Enter your exchangerate-api.com API key:"
read -r API_KEY

supabase secrets set EXCHANGE_RATE_API_KEY="$API_KEY"

echo ""
echo "📝 Step 5: Deploy Edge Function"
echo "--------------------------------"

# Create supabase/functions directory if not exists
mkdir -p supabase/functions

# Copy Edge Function
cp -r supabase_edge_function/update-exchange-rates supabase/functions/

# Deploy
supabase functions deploy update-exchange-rates --project-ref "$PROJECT_REF"

echo ""
echo "📝 Step 6: Test Edge Function"
echo "------------------------------"

FUNCTION_URL="https://$PROJECT_REF.supabase.co/functions/v1/update-exchange-rates"

echo "Triggering Edge Function..."
RESPONSE=$(curl -s -X POST "$FUNCTION_URL")
echo "$RESPONSE"

if echo "$RESPONSE" | grep -q "success"; then
    echo "✅ Edge Function working!"
else
    echo "❌ Edge Function failed. Check logs:"
    echo "   supabase functions logs update-exchange-rates"
    exit 1
fi

echo ""
echo "📝 Step 7: Setup Cron Job"
echo "-------------------------"
echo "Go to: https://console.cron-job.org/"
echo "Create a cronjob with:"
echo "  - URL: $FUNCTION_URL"
echo "  - Schedule: 0 */6 * * * (Every 6 hours)"
echo "  - Method: POST"
echo ""
read -p "Press Enter after you've setup the cron job..."

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Verify data in Supabase: SELECT * FROM exchange_rates;"
echo "2. Run app: flutter run"
echo "3. Test currency conversion in Add Transaction screen"
echo ""
echo "📚 Full documentation: CURRENCY_SETUP_GUIDE.md"
echo ""
