-- Create raciones_alimentacion table
-- This table stores the daily feeding rations schedule and completion records

CREATE TABLE IF NOT EXISTS public.raciones_alimentacion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    siembra_id UUID NOT NULL REFERENCES public.siembras(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    numero_racion INTEGER NOT NULL,
    hora_programada TIME NOT NULL,
    cantidad_gramos NUMERIC(10,2) NOT NULL,
    completada BOOLEAN DEFAULT FALSE,
    hora_completada TIMESTAMP WITH TIME ZONE,
    observaciones TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_siembra_fecha_racion UNIQUE (siembra_id, fecha, numero_racion)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_raciones_user_id ON public.raciones_alimentacion(user_id);
CREATE INDEX IF NOT EXISTS idx_raciones_siembra_id ON public.raciones_alimentacion(siembra_id);
CREATE INDEX IF NOT EXISTS idx_raciones_fecha ON public.raciones_alimentacion(fecha);
CREATE INDEX IF NOT EXISTS idx_raciones_completada ON public.raciones_alimentacion(completada);
CREATE INDEX IF NOT EXISTS idx_raciones_siembra_fecha ON public.raciones_alimentacion(siembra_id, fecha);

-- Enable Row Level Security
ALTER TABLE public.raciones_alimentacion ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own raciones"
    ON public.raciones_alimentacion FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own raciones"
    ON public.raciones_alimentacion FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own raciones"
    ON public.raciones_alimentacion FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own raciones"
    ON public.raciones_alimentacion FOR DELETE
    USING (auth.uid() = user_id);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_raciones_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_raciones_updated_at
    BEFORE UPDATE ON public.raciones_alimentacion
    FOR EACH ROW
    EXECUTE FUNCTION update_raciones_updated_at();

-- Add comment
COMMENT ON TABLE public.raciones_alimentacion IS 'Daily feeding rations schedule and completion records for siembras';
