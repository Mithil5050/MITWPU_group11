CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    subject TEXT NOT NULL,
    type TEXT NOT NULL,
    content JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) to secure user data
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;

-- Create a policy so users can only view and edit their own backed-up topics
CREATE POLICY "Users can manage their own topics" ON public.topics
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Force Supabase's PostgREST API to immediately reload its schema cache
NOTIFY pgrst, 'reload schema';
