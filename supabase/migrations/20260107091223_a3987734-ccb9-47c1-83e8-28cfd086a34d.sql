-- Add policy to allow public read access to active professionals
CREATE POLICY "Anyone can view active professionals"
ON public.barbers
AS PERMISSIVE
FOR SELECT
TO anon, authenticated
USING (active = true);