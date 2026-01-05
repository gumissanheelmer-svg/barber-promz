-- Drop the overly permissive public SELECT policy
DROP POLICY IF EXISTS "Anyone can view barbershop appointments" ON public.appointments;

-- Create a new restrictive policy for viewing appointments
-- Only barbershop admins and assigned barbers can view appointments
CREATE POLICY "Authenticated users can view relevant appointments"
ON public.appointments
FOR SELECT
USING (
  -- Barbershop admins can view their barbershop's appointments
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  -- Barbers can view appointments assigned to them (via barber_accounts)
  EXISTS (
    SELECT 1 FROM public.barber_accounts ba
    WHERE ba.user_id = auth.uid()
      AND ba.barber_id = appointments.barber_id
      AND ba.approval_status = 'approved'
  )
  OR
  -- Superadmins can view all appointments
  is_superadmin(auth.uid())
);