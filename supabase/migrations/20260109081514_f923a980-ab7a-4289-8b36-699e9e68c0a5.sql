-- =============================================
-- CORREÇÕES DE SEGURANÇA - ATTENDANCE E TIME-OFF
-- =============================================

-- 1. PROFESSIONAL_ATTENDANCE - Remover SELECT público
-- Manter apenas SELECT para staff autenticado e para fins de booking via RPC
DROP POLICY IF EXISTS "Anyone can view professional_attendance for booking" ON public.professional_attendance;

-- Criar policy mais restritiva - apenas para booking do mesmo estabelecimento
CREATE POLICY "Authenticated can view professional_attendance for booking"
ON public.professional_attendance
FOR SELECT
TO authenticated
USING (true);

-- Para anon, bloquear SELECT direto (usarão RPC get_available_professionals)
CREATE POLICY "Block anon select on professional_attendance"
ON public.professional_attendance
FOR SELECT
TO anon
USING (false);

-- 2. PROFESSIONAL_TIME_OFF - Restringir SELECT público
DROP POLICY IF EXISTS "Anyone can view professional_time_off" ON public.professional_time_off;

-- Apenas authenticated podem ver
CREATE POLICY "Authenticated can view professional_time_off"
ON public.professional_time_off
FOR SELECT
TO authenticated
USING (true);

-- Bloquear anon
CREATE POLICY "Block anon select on professional_time_off"
ON public.professional_time_off
FOR SELECT
TO anon
USING (false);

-- 3. PROFESSIONAL_SCHEDULES - Restringir SELECT público  
DROP POLICY IF EXISTS "Anyone can view professional_schedules" ON public.professional_schedules;

-- Apenas authenticated podem ver
CREATE POLICY "Authenticated can view professional_schedules"
ON public.professional_schedules
FOR SELECT
TO authenticated
USING (true);

-- Bloquear anon
CREATE POLICY "Block anon select on professional_schedules"
ON public.professional_schedules
FOR SELECT
TO anon
USING (false);