-- ============================================
-- MyBuilding App - Supabase Database Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE (extends Supabase auth.users)
-- ============================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    apartment TEXT NOT NULL,
    phone TEXT,
    user_type TEXT CHECK (user_type IN ('owner', 'tenant')) DEFAULT 'tenant',
    is_approved BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. FAULTS TABLE
-- ============================================
CREATE TABLE public.faults (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    category TEXT NOT NULL CHECK (category IN ('water', 'electric', 'elevator', 'cleaning', 'door', 'other')),
    description TEXT NOT NULL,
    location TEXT,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'progress', 'fixed')),
    photos TEXT[], -- Array of storage URLs
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. NOTICES TABLE
-- ============================================
CREATE TABLE public.notices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    type TEXT DEFAULT 'info' CHECK (type IN ('urgent', 'event', 'info', 'maintenance')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. POLLS TABLE (סקרים)
-- ============================================
CREATE TABLE public.polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of {id, text, votes}
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Poll votes (to track who voted)
CREATE TABLE public.poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    option_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(poll_id, user_id) -- One vote per user per poll
);

-- ============================================
-- 5. PROFESSIONALS TABLE (אנשי מקצוע)
-- ============================================
CREATE TABLE public.professionals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    profession TEXT NOT NULL,
    phone TEXT,
    description TEXT,
    rating NUMERIC(2,1) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    recommended_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_approved BOOLEAN DEFAULT FALSE, -- Admin needs to approve
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. MARKETPLACE TABLE (לוח מודעות)
-- ============================================
CREATE TABLE public.marketplace (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2),
    category TEXT CHECK (category IN ('sell', 'buy', 'give', 'seek')),
    photos TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. PAYMENTS TABLE (תשלומים)
-- ============================================
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    apartment TEXT NOT NULL,
    year INTEGER NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. EXPENSES TABLE (הוצאות)
-- ============================================
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category TEXT NOT NULL,
    description TEXT,
    amount NUMERIC(10,2) NOT NULL,
    receipt_url TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    expense_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faults ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES POLICIES
-- ============================================

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- Admins can read all profiles
CREATE POLICY "Admins can read all profiles"
ON public.profiles FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- Users can update their own profile (except is_approved and is_admin)
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admins can update all profiles (including approval)
CREATE POLICY "Admins can update all profiles"
ON public.profiles FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- Allow insert for new users (via trigger)
CREATE POLICY "Enable insert for new users"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================
-- FAULTS POLICIES
-- ============================================

-- Approved users can read all faults
CREATE POLICY "Approved users can read faults"
ON public.faults FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Approved users can create faults
CREATE POLICY "Approved users can create faults"
ON public.faults FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Users can update their own faults
CREATE POLICY "Users can update own faults"
ON public.faults FOR UPDATE
USING (user_id = auth.uid());

-- Admins can update/delete all faults
CREATE POLICY "Admins can manage all faults"
ON public.faults FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- ============================================
-- NOTICES POLICIES
-- ============================================

-- Approved users can read active notices
CREATE POLICY "Approved users can read notices"
ON public.notices FOR SELECT
USING (
    is_active = TRUE AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Admins can manage all notices
CREATE POLICY "Admins can manage notices"
ON public.notices FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- ============================================
-- POLLS POLICIES
-- ============================================

-- Approved users can read active polls
CREATE POLICY "Approved users can read polls"
ON public.polls FOR SELECT
USING (
    is_active = TRUE AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Admins can manage polls
CREATE POLICY "Admins can manage polls"
ON public.polls FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- Approved users can vote
CREATE POLICY "Approved users can vote"
ON public.poll_votes FOR INSERT
WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Users can see their own votes
CREATE POLICY "Users can see own votes"
ON public.poll_votes FOR SELECT
USING (user_id = auth.uid());

-- ============================================
-- PROFESSIONALS POLICIES
-- ============================================

-- Approved users can read approved professionals
CREATE POLICY "Users can read approved professionals"
ON public.professionals FOR SELECT
USING (
    is_approved = TRUE AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Approved users can recommend professionals
CREATE POLICY "Users can recommend professionals"
ON public.professionals FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Admins can manage all professionals
CREATE POLICY "Admins can manage professionals"
ON public.professionals FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- ============================================
-- MARKETPLACE POLICIES
-- ============================================

-- Approved users can read active marketplace items
CREATE POLICY "Users can read marketplace"
ON public.marketplace FOR SELECT
USING (
    is_active = TRUE AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Approved users can create items
CREATE POLICY "Users can create marketplace items"
ON public.marketplace FOR INSERT
WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Users can update/delete their own items
CREATE POLICY "Users can manage own marketplace items"
ON public.marketplace FOR UPDATE
USING (user_id = auth.uid());

CREATE POLICY "Users can delete own marketplace items"
ON public.marketplace FOR DELETE
USING (user_id = auth.uid());

-- Admins can manage all items
CREATE POLICY "Admins can manage marketplace"
ON public.marketplace FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- ============================================
-- PAYMENTS & EXPENSES (Admin only for write)
-- ============================================

-- Approved users can read their own payments
CREATE POLICY "Users can read own payments"
ON public.payments FOR SELECT
USING (
    user_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- Admins can manage payments
CREATE POLICY "Admins can manage payments"
ON public.payments FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- Approved users can read expenses
CREATE POLICY "Users can read expenses"
ON public.expenses FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_approved = TRUE
    )
);

-- Admins can manage expenses
CREATE POLICY "Admins can manage expenses"
ON public.expenses FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    )
);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, apartment, user_type)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'apartment', ''),
        COALESCE(NEW.raw_user_meta_data->>'user_type', 'tenant')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_faults_updated_at
    BEFORE UPDATE ON public.faults
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_profiles_is_approved ON public.profiles(is_approved);
CREATE INDEX idx_profiles_is_admin ON public.profiles(is_admin);
CREATE INDEX idx_faults_status ON public.faults(status);
CREATE INDEX idx_faults_user_id ON public.faults(user_id);
CREATE INDEX idx_notices_is_active ON public.notices(is_active);
CREATE INDEX idx_polls_is_active ON public.polls(is_active);
CREATE INDEX idx_professionals_is_approved ON public.professionals(is_approved);
CREATE INDEX idx_marketplace_is_active ON public.marketplace(is_active);
CREATE INDEX idx_payments_user_id ON public.payments(user_id);

-- ============================================
-- SET INITIAL ADMIN (run manually after first signup)
-- ============================================
-- UPDATE public.profiles
-- SET is_admin = TRUE, is_approved = TRUE
-- WHERE email = 'gabiaharon@gmail.com';
