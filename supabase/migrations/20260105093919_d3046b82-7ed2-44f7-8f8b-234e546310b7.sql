-- 1. Update existing barbershops to approved
UPDATE public.barbershops SET approval_status = 'approved' WHERE active = true;

-- 2. Create is_superadmin function
CREATE OR REPLACE FUNCTION public.is_superadmin(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = 'superadmin'
  )
$$;

-- 3. Drop old trigger and function for admin assignment
DROP TRIGGER IF EXISTS on_profile_created_assign_admin ON public.profiles;
DROP FUNCTION IF EXISTS public.assign_admin_role();

-- 4. Create new function that assigns superadmin to specific email
CREATE OR REPLACE FUNCTION public.assign_superadmin_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email = 'gumissanheelmer@gmail.com' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'superadmin')
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_profile_created_assign_superadmin
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.assign_superadmin_role();

-- 5. Update existing user role from admin to superadmin
DELETE FROM public.user_roles 
WHERE user_id = 'bd078ec7-9f60-4065-be43-fd3d6bbdaa10' 
AND role = 'admin';

INSERT INTO public.user_roles (user_id, role)
VALUES ('bd078ec7-9f60-4065-be43-fd3d6bbdaa10', 'superadmin')
ON CONFLICT (user_id, role) DO NOTHING;

-- 6. Create RLS policy for superadmin to view ALL barbershops
CREATE POLICY "Superadmin can view all barbershops" 
ON public.barbershops FOR SELECT TO authenticated
USING (is_superadmin(auth.uid()));

-- 7. Create RLS policy for superadmin to manage ALL barbershops
CREATE POLICY "Superadmin can manage all barbershops" 
ON public.barbershops FOR UPDATE TO authenticated
USING (is_superadmin(auth.uid()))
WITH CHECK (is_superadmin(auth.uid()));

-- 8. Create RLS policy for superadmin to view all user_roles
CREATE POLICY "Superadmin can view all user_roles"
ON public.user_roles FOR SELECT TO authenticated
USING (is_superadmin(auth.uid()));

-- 9. Create RLS policy for superadmin to manage user_roles
CREATE POLICY "Superadmin can manage user_roles"
ON public.user_roles FOR ALL TO authenticated
USING (is_superadmin(auth.uid()))
WITH CHECK (is_superadmin(auth.uid()));