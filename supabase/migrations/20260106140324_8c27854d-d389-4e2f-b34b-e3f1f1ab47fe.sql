-- Create subscriptions table for monthly payments
CREATE TABLE public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barbershop_id uuid REFERENCES public.barbershops(id) ON DELETE CASCADE NOT NULL,
  plan_name text NOT NULL DEFAULT 'mensal',
  amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  due_date date NOT NULL,
  paid_at timestamp with time zone,
  payment_method text,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Superadmin can manage all subscriptions
CREATE POLICY "Superadmin can manage all subscriptions"
  ON public.subscriptions FOR ALL
  USING (is_superadmin(auth.uid()))
  WITH CHECK (is_superadmin(auth.uid()));

-- Admins can view their own subscriptions
CREATE POLICY "Admins can view own subscriptions"
  ON public.subscriptions FOR SELECT
  USING (is_barbershop_admin(auth.uid(), barbershop_id));

-- Create trigger for updated_at
CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Add index for better performance
CREATE INDEX idx_subscriptions_barbershop_id ON public.subscriptions(barbershop_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_due_date ON public.subscriptions(due_date);