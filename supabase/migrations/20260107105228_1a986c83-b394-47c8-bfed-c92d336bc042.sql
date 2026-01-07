-- Recreate views with SECURITY INVOKER (default, no security definer)
-- This ensures RLS policies of the underlying tables are applied

DROP VIEW IF EXISTS public.professionals;
DROP VIEW IF EXISTS public.businesses;
DROP VIEW IF EXISTS public.professional_accounts;
DROP VIEW IF EXISTS public.professional_services;

-- Create view for professionals with security invoker (default)
CREATE VIEW public.professionals 
WITH (security_invoker = on)
AS
SELECT 
  id,
  name,
  phone,
  active,
  working_hours,
  barbershop_id AS business_id,
  created_at,
  updated_at
FROM public.barbers;

-- Create view for businesses with security invoker
CREATE VIEW public.businesses 
WITH (security_invoker = on)
AS
SELECT 
  id,
  slug,
  name,
  logo_url,
  whatsapp_number,
  primary_color,
  secondary_color,
  background_color,
  text_color,
  opening_time,
  closing_time,
  active,
  approval_status,
  owner_email,
  business_type,
  created_at,
  updated_at
FROM public.barbershops;

-- Create view for professional_accounts with security invoker
CREATE VIEW public.professional_accounts 
WITH (security_invoker = on)
AS
SELECT 
  id,
  user_id,
  name,
  email,
  phone,
  barbershop_id AS business_id,
  barbershop_name AS business_name,
  barber_id AS professional_id,
  approval_status,
  created_at,
  updated_at
FROM public.barber_accounts;

-- Create view for professional_services with security invoker
CREATE VIEW public.professional_services 
WITH (security_invoker = on)
AS
SELECT 
  id,
  barber_id AS professional_id,
  service_id
FROM public.barber_services;