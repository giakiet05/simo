// Supabase Edge Function to fetch and update exchange rates
// Deploy: supabase functions deploy update-exchange-rates --no-verify-jwt
// Invoke: curl -X POST https://<project-ref>.supabase.co/functions/v1/update-exchange-rates

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const EXCHANGE_RATE_API_KEY = Deno.env.get('EXCHANGE_RATE_API_KEY') || ''
const EXCHANGE_RATE_API_URL = 'https://v6.exchangerate-api.com/v6'

interface ExchangeRateResponse {
  result: string
  base_code: string
  conversion_rates: Record<string, number>
  time_last_update_unix: number
}

const SUPPORTED_CURRENCIES = [
  'VND', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'THB', 'SGD', 'AUD', 'CAD',
  'KRW', 'HKD', 'TWD', 'MYR', 'IDR', 'PHP', 'INR', 'CHF', 'NZD', 'RUB'
]

Deno.serve(async (req) => {
  try {
    // Verify request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check API key
    if (!EXCHANGE_RATE_API_KEY) {
      console.error('EXCHANGE_RATE_API_KEY not set')
      return new Response(
        JSON.stringify({ error: 'API key not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log('Fetching exchange rates from API...')

    // Fetch rates from exchangerate-api.com
    const response = await fetch(
      `${EXCHANGE_RATE_API_URL}/${EXCHANGE_RATE_API_KEY}/latest/USD`
    )

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`)
    }

    const data: ExchangeRateResponse = await response.json()

    if (data.result !== 'success') {
      throw new Error(`API returned error: ${data.result}`)
    }

    // Filter only supported currencies
    const filteredRates: Record<string, number> = {}
    for (const currency of SUPPORTED_CURRENCIES) {
      if (data.conversion_rates[currency]) {
        filteredRates[currency] = data.conversion_rates[currency]
      }
    }

    console.log(`Fetched rates for ${Object.keys(filteredRates).length} currencies`)

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Upsert rates into database
    const { error: dbError } = await supabase
      .from('exchange_rates')
      .upsert(
        {
          base_currency: 'USD',
          rates: filteredRates,
          updated_at: new Date().toISOString()
        },
        {
          onConflict: 'base_currency'
        }
      )

    if (dbError) {
      throw new Error(`Database error: ${dbError.message}`)
    }

    console.log('Exchange rates updated successfully')

    return new Response(
      JSON.stringify({
        success: true,
        base_currency: 'USD',
        currencies_count: Object.keys(filteredRates).length,
        updated_at: new Date().toISOString()
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error updating exchange rates:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
