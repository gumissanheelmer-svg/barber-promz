-- Drop existing function first (has different return type)
DROP FUNCTION IF EXISTS public.get_public_barbershop(text);

-- Recreate get_public_barbershop to include business_type
CREATE FUNCTION public.get_public_barbershop(p_slug text)
RETURNS TABLE(
  id uuid, 
  slug text, 
  name text, 
  logo_url text, 
  whatsapp_number text, 
  primary_color text, 
  secondary_color text, 
  background_color text, 
  text_color text, 
  opening_time time without time zone, 
  closing_time time without time zone,
  business_type text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT id, slug, name, logo_url, whatsapp_number,
         primary_color, secondary_color, background_color, text_color,
         opening_time, closing_time, business_type
  FROM public.barbershops
  WHERE slug = p_slug
    AND active = true
    AND approval_status = 'approved';
$$;

-- Update create_barbershop function to include business_type
DROP FUNCTION IF EXISTS public.create_barbershop(text, text, text, text, text, text, text, text, text);

CREATE FUNCTION public.create_barbershop(
  p_name text, 
  p_slug text, 
  p_whatsapp_number text DEFAULT NULL::text, 
  p_logo_url text DEFAULT NULL::text, 
  p_primary_color text DEFAULT '#D4AF37'::text, 
  p_secondary_color text DEFAULT '#1a1a2e'::text, 
  p_background_color text DEFAULT '#0f0f1a'::text, 
  p_text_color text DEFAULT '#ffffff'::text, 
  p_owner_email text DEFAULT NULL::text,
  p_business_type text DEFAULT 'barbearia'::text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  new_id uuid;
BEGIN
  INSERT INTO public.barbershops (
    name,
    slug,
    whatsapp_number,
    logo_url,
    primary_color,
    secondary_color,
    background_color,
    text_color,
    active,
    approval_status,
    owner_email,
    business_type
  ) VALUES (
    p_name,
    p_slug,
    p_whatsapp_number,
    p_logo_url,
    p_primary_color,
    p_secondary_color,
    p_background_color,
    p_text_color,
    false,
    'pending',
    p_owner_email,
    p_business_type
  )
  RETURNING id INTO new_id;
  
  RETURN new_id;
END;
$function$;