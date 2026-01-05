-- ============================================
-- CREATE SECURE VIEWS FOR PUBLIC DATA
-- This ensures only non-sensitive fields are exposed
-- ============================================

-- Create a secure function to get public barber info (no phone)
CREATE OR REPLACE FUNCTION public.get_public_barbers(p_barbershop_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  working_hours jsonb
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, name, working_hours
  FROM public.barbers
  WHERE barbershop_id = p_barbershop_id
    AND active = true;
$$;

-- Grant execute to anon and authenticated
GRANT EXECUTE ON FUNCTION public.get_public_barbers TO anon, authenticated;

-- Create a secure function to get public services
CREATE OR REPLACE FUNCTION public.get_public_services(p_barbershop_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  price numeric,
  duration integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, name, price, duration
  FROM public.services
  WHERE barbershop_id = p_barbershop_id
    AND active = true;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_services TO anon, authenticated;

-- Create a secure function to get public barbershop info (no owner_email)
CREATE OR REPLACE FUNCTION public.get_public_barbershop(p_slug text)
RETURNS TABLE (
  id uuid,
  slug text,
  name text,
  logo_url text,
  whatsapp_number text, -- Intentionally public for customer contact
  primary_color text,
  secondary_color text,
  background_color text,
  text_color text,
  opening_time time,
  closing_time time
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, slug, name, logo_url, whatsapp_number,
         primary_color, secondary_color, background_color, text_color,
         opening_time, closing_time
  FROM public.barbershops
  WHERE slug = p_slug
    AND active = true
    AND approval_status = 'approved';
$$;

GRANT EXECUTE ON FUNCTION public.get_public_barbershop TO anon, authenticated;

-- ============================================
-- TIGHTEN EXISTING POLICIES
-- ============================================

-- Remove overly permissive barbers policy and replace with staff-only
DROP POLICY IF EXISTS "Anyone can view active barbers name only" ON public.barbers;

-- Barbers table: Only staff can view full details
-- Public must use the get_public_barbers function
CREATE POLICY "Staff can view barbers in their barbershop"
ON public.barbers
FOR SELECT
TO authenticated
USING (
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR is_superadmin(auth.uid())
  OR EXISTS (
    SELECT 1 FROM barber_accounts ba
    WHERE ba.user_id = auth.uid()
      AND ba.barbershop_id = barbers.barbershop_id
      AND ba.approval_status = 'approved'
  )
);

-- For anon users, they MUST use the RPC function - no direct table access
-- This is already enforced because we removed the public policy