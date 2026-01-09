-- =============================================
-- RPC PARA ACESSO PÚBLICO A SERVICE_PROFESSIONALS
-- =============================================

-- Criar RPC que retorna mapeamento serviço-profissional para booking
CREATE OR REPLACE FUNCTION public.get_service_professional_mappings(p_barbershop_id uuid)
RETURNS TABLE(service_id uuid, professional_id uuid)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT sp.service_id, sp.professional_id
  FROM public.service_professionals sp
  WHERE sp.barbershop_id = p_barbershop_id;
$$;

-- Permitir anon acessar services via RPC (já existe get_public_services)
-- Verificar se get_valid_services pode ser usado por anon
GRANT EXECUTE ON FUNCTION public.get_valid_services(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_services(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_professionals(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_barbers(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_barbershop(text) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_business(text) TO anon;
GRANT EXECUTE ON FUNCTION public.get_available_professionals(uuid, date) TO anon;
GRANT EXECUTE ON FUNCTION public.get_professionals_for_service(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_service_professional_mappings(uuid) TO anon;