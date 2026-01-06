-- Add business_type column to barbershops table
ALTER TABLE public.barbershops 
ADD COLUMN IF NOT EXISTS business_type TEXT NOT NULL DEFAULT 'barbearia';

-- Add check constraint for business_type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'barbershops_business_type_check'
  ) THEN
    ALTER TABLE public.barbershops 
    ADD CONSTRAINT barbershops_business_type_check 
    CHECK (business_type IN ('barbearia', 'salao', 'salao_barbearia'));
  END IF;
END $$;