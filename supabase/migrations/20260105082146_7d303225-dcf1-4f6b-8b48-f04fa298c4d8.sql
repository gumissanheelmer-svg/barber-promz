-- Remover política antiga
DROP POLICY IF EXISTS "Admins can manage own barbershop barber accounts" ON public.barber_accounts;

-- Criar nova política que verifica tanto barbershop_id quanto barbershop_name
CREATE POLICY "Admins can view and manage barber accounts" ON public.barber_accounts
FOR ALL
TO authenticated
USING (
  -- Usuario pode ver sua propria conta
  user_id = auth.uid()
  OR
  -- Admin pode ver contas da sua barbearia (por ID)
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  -- Admin pode ver contas onde o nome da barbearia corresponde (comparacao case-insensitive)
  EXISTS (
    SELECT 1 FROM public.barbershops b
    INNER JOIN public.user_roles ur ON ur.barbershop_id = b.id
    WHERE ur.user_id = auth.uid()
    AND ur.role = 'admin'
    AND LOWER(TRIM(b.name)) = LOWER(TRIM(barber_accounts.barbershop_name))
  )
)
WITH CHECK (
  is_barbershop_admin(auth.uid(), barbershop_id)
  OR
  EXISTS (
    SELECT 1 FROM public.barbershops b
    INNER JOIN public.user_roles ur ON ur.barbershop_id = b.id
    WHERE ur.user_id = auth.uid()
    AND ur.role = 'admin'
    AND LOWER(TRIM(b.name)) = LOWER(TRIM(barber_accounts.barbershop_name))
  )
);