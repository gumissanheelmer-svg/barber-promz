-- =====================================================
-- CONSOLIDAÇÃO DE SEGURANÇA - LOCKDOWN FINAL
-- =====================================================

-- 1. Atualizar get_available_professionals para remover campos desnecessários
-- Mantém apenas: id, name, working_hours, attendance_status, is_day_off
DROP FUNCTION IF EXISTS public.get_available_professionals(uuid, date);

CREATE OR REPLACE FUNCTION public.get_available_professionals(p_barbershop_id uuid, p_date date)
RETURNS TABLE(
  id uuid, 
  name text, 
  working_hours jsonb, 
  attendance_status text, 
  is_day_off boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_day_of_week INTEGER;
BEGIN
  v_day_of_week := EXTRACT(DOW FROM p_date)::INTEGER;
  
  RETURN QUERY
  SELECT 
    b.id,
    b.name,
    b.working_hours,
    COALESCE(pa.status, 'pending') as attendance_status,
    CASE 
      WHEN pto.id IS NOT NULL THEN true
      WHEN ps.id IS NOT NULL AND ps.is_working_day = false THEN true
      ELSE false
    END as is_day_off
  FROM public.barbers b
  LEFT JOIN public.professional_attendance pa 
    ON pa.barber_id = b.id AND pa.attendance_date = p_date
  LEFT JOIN public.professional_time_off pto 
    ON pto.barber_id = b.id AND pto.off_date = p_date
  LEFT JOIN public.professional_schedules ps 
    ON ps.barber_id = b.id AND ps.day_of_week = v_day_of_week
  WHERE b.barbershop_id = p_barbershop_id
    AND b.active = true
  ORDER BY b.name;
END;
$$;

-- Re-grant execute permission to anon
GRANT EXECUTE ON FUNCTION public.get_available_professionals(uuid, date) TO anon;
GRANT EXECUTE ON FUNCTION public.get_available_professionals(uuid, date) TO authenticated;

-- 2. Criar função segura para listar appointments sem dados sensíveis (para relatórios públicos se necessário)
CREATE OR REPLACE FUNCTION public.get_appointment_summary_for_professional(p_barber_id uuid, p_date date)
RETURNS TABLE(
  appointment_time time,
  service_name text,
  duration integer,
  status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    a.appointment_time,
    s.name as service_name,
    s.duration,
    a.status
  FROM public.appointments a
  JOIN public.services s ON s.id = a.service_id
  WHERE a.barber_id = p_barber_id
    AND a.appointment_date = p_date
    AND a.status != 'cancelled'
  ORDER BY a.appointment_time;
$$;

-- Apenas authenticated podem usar esta função
GRANT EXECUTE ON FUNCTION public.get_appointment_summary_for_professional(uuid, date) TO authenticated;

-- 3. Adicionar comentários de segurança nas tabelas para documentação
COMMENT ON TABLE public.appointments IS 'Agendamentos - RLS ativo. Dados sensíveis (client_name, client_phone) protegidos. Acesso: Admin/Manager da barbearia, Barber próprio, Superadmin.';
COMMENT ON TABLE public.barber_accounts IS 'Contas de barbeiros - RLS ativo. Dados sensíveis (email, phone) protegidos. Acesso: Admin da barbearia, próprio usuário, Superadmin.';
COMMENT ON TABLE public.barbers IS 'Profissionais - RLS ativo. Campo phone é PII. Acesso público via RPCs filtradas que omitem phone.';
COMMENT ON TABLE public.barbershops IS 'Negócios - RLS ativo. Campo owner_email é PII. Acesso público via get_public_barbershop que omite owner_email.';

-- 4. Verificar e reforçar política de barbers para garantir que phone nunca vaza
-- A política atual permite SELECT para staff autenticado, o que é correto
-- mas vamos garantir que não há brecha

-- Remover qualquer política permissiva antiga que possa existir
DROP POLICY IF EXISTS "Public can view barbers" ON public.barbers;
DROP POLICY IF EXISTS "Anyone can view barbers" ON public.barbers;

-- 5. Garantir que appointments não tem políticas permissivas demais
-- Verificar se a política de INSERT valida corretamente
-- (já existe e está correta com validações de business ativo)

-- 6. Criar função helper para validar acesso a dados sensíveis de cliente
CREATE OR REPLACE FUNCTION public.can_view_client_data(p_appointment_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.appointments a
    WHERE a.id = p_appointment_id
    AND (
      -- Superadmin
      public.is_superadmin(auth.uid())
      -- Admin da barbearia
      OR public.is_barbershop_admin(auth.uid(), a.barbershop_id)
      -- Manager da barbearia
      OR public.is_barbershop_manager(auth.uid(), a.barbershop_id)
      -- Barber do agendamento
      OR EXISTS (
        SELECT 1 FROM public.barber_accounts ba
        WHERE ba.user_id = auth.uid()
        AND ba.barber_id = a.barber_id
        AND ba.approval_status = 'approved'
      )
    )
  );
$$;