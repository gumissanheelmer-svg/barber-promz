-- Add barbershop_name column to barber_accounts table
ALTER TABLE public.barber_accounts 
ADD COLUMN barbershop_name text;