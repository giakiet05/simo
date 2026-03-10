-- Create exchange_rates table
CREATE TABLE IF NOT EXISTS exchange_rates (
  id BIGSERIAL PRIMARY KEY,
  base_currency TEXT NOT NULL,
  rates JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for fast lookup
CREATE INDEX IF NOT EXISTS idx_exchange_rates_base_currency ON exchange_rates(base_currency);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_updated_at ON exchange_rates(updated_at);

-- Enable RLS (Row Level Security)
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Allow public read access" ON exchange_rates
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Create policy to allow service role to insert/update
CREATE POLICY "Allow service role to insert/update" ON exchange_rates
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Create function to upsert exchange rates
CREATE OR REPLACE FUNCTION upsert_exchange_rates(
  p_base_currency TEXT,
  p_rates JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO exchange_rates (base_currency, rates, updated_at)
  VALUES (p_base_currency, p_rates, NOW())
  ON CONFLICT (base_currency)
  DO UPDATE SET
    rates = p_rates,
    updated_at = NOW();
END;
$$;

-- Add unique constraint for base_currency
ALTER TABLE exchange_rates
ADD CONSTRAINT unique_base_currency UNIQUE (base_currency);

COMMENT ON TABLE exchange_rates IS 'Stores exchange rates fetched from external API, updated every 6 hours';
