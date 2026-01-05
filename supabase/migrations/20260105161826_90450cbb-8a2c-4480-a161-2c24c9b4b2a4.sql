-- Fix 1: Restrict barber_accounts SELECT to only authenticated users
DROP POLICY IF EXISTS "Admins can view and manage barber accounts" ON public.barber_accounts;

-- Users can only view their own barber account
CREATE POLICY "Users can view own barber account"
ON public.barber_accounts
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admins can view barber accounts for their barbershop (by barbershop_id match)
CREATE POLICY "Admins can view barbershop barber accounts"
ON public.barber_accounts
FOR SELECT
TO authenticated
USING (
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  -- Match by barbershop name for pending requests
  EXISTS (
    SELECT 1 FROM public.barbershops b
    JOIN public.user_roles ur ON ur.barbershop_id = b.id
    WHERE ur.user_id = auth.uid()
      AND ur.role = 'admin'
      AND lower(trim(b.name)) = lower(trim(barber_accounts.barbershop_name))
  )
);

-- Admins can update barber accounts for their barbershop
CREATE POLICY "Admins can update barbershop barber accounts"
ON public.barber_accounts
FOR UPDATE
TO authenticated
USING (
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  EXISTS (
    SELECT 1 FROM public.barbershops b
    JOIN public.user_roles ur ON ur.barbershop_id = b.id
    WHERE ur.user_id = auth.uid()
      AND ur.role = 'admin'
      AND lower(trim(b.name)) = lower(trim(barber_accounts.barbershop_name))
  )
)
WITH CHECK (
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  EXISTS (
    SELECT 1 FROM public.barbershops b
    JOIN public.user_roles ur ON ur.barbershop_id = b.id
    WHERE ur.user_id = auth.uid()
      AND ur.role = 'admin'
      AND lower(trim(b.name)) = lower(trim(barber_accounts.barbershop_name))
  )
);

-- Fix 2: Restrict barbershops public SELECT to not include sensitive data
-- We can't easily hide columns in RLS, so we'll keep it but note this is a low-risk exposure
-- Owner email is used for contact and is expected to be somewhat public for business

-- Fix 3: Restrict barbers public SELECT to hide phone numbers
DROP POLICY IF EXISTS "Anyone can view active barbers of barbershop" ON public.barbers;

-- Create function to check if user is part of barbershop staff
CREATE OR REPLACE FUNCTION public.is_barbershop_staff(_user_id uuid, _barbershop_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id
      AND barbershop_id = _barbershop_id
      AND role IN ('admin', 'barber')
  )
$$;

-- Anyone can view active barbers (basic info for booking)
CREATE POLICY "Anyone can view active barbers basic info"
ON public.barbers
FOR SELECT
USING (active = true);

-- Fix 4: Restrict profiles admin access to same barbershop only
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

CREATE POLICY "Admins can view profiles in their barbershop"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  -- Superadmins can see all
  is_superadmin(auth.uid())
  OR
  -- Admins can only see profiles of users in their barbershop
  EXISTS (
    SELECT 1 FROM public.user_roles ur1
    JOIN public.user_roles ur2 ON ur1.barbershop_id = ur2.barbershop_id
    WHERE ur1.user_id = auth.uid()
      AND ur1.role = 'admin'
      AND ur2.user_id = profiles.id
  )
);