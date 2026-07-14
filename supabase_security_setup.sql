-- ============================================================================
-- Supabase Security Setup: Row Level Security (RLS) & Policies
-- ============================================================================

-- 1. Helper function to check if a user is an admin without triggering RLS recursion.
-- SECURITY DEFINER runs the query with the privileges of the function creator (bypassing RLS).
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN SECURITY DEFINER SET search_path = public AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = user_id AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql;

-- 2. Enable Row Level Security (RLS) on all tables
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.daily_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.retry_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cart ENABLE ROW LEVEL SECURITY;

-- 3. Profiles Table Policies
DROP POLICY IF EXISTS "users_read_own" ON public.profiles;
CREATE POLICY "users_read_own" ON public.profiles 
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "users_update_own" ON public.profiles;
CREATE POLICY "users_update_own" ON public.profiles 
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "admin_read_all" ON public.profiles;
CREATE POLICY "admin_read_all" ON public.profiles 
    FOR SELECT USING (public.is_admin(auth.uid()));

-- 4. Orders Table Policies
DROP POLICY IF EXISTS "users_read_own_orders" ON public.orders;
CREATE POLICY "users_read_own_orders" ON public.orders 
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_insert_own_orders" ON public.orders;
CREATE POLICY "users_insert_own_orders" ON public.orders 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "admin_all_orders" ON public.orders;
CREATE POLICY "admin_all_orders" ON public.orders 
    FOR ALL USING (public.is_admin(auth.uid()));

-- 5. Order Items Table Policies
DROP POLICY IF EXISTS "users_own_items" ON public.order_items;
CREATE POLICY "users_own_items" ON public.order_items 
    FOR SELECT USING (EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_all_items" ON public.order_items;
CREATE POLICY "admin_all_items" ON public.order_items 
    FOR ALL USING (public.is_admin(auth.uid()));

-- 6. Items (Menu) Table Policies
DROP POLICY IF EXISTS "public_read_items" ON public.items;
CREATE POLICY "public_read_items" ON public.items 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_modify_items" ON public.items;
CREATE POLICY "admin_modify_items" ON public.items 
    FOR ALL USING (public.is_admin(auth.uid()));

-- 7. Admin Settings Table Policies
DROP POLICY IF EXISTS "public_read_settings" ON public.admin_settings;
CREATE POLICY "public_read_settings" ON public.admin_settings 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_modify_settings" ON public.admin_settings;
CREATE POLICY "admin_modify_settings" ON public.admin_settings 
    FOR UPDATE USING (public.is_admin(auth.uid()));

-- 8. Cart Table Policies
DROP POLICY IF EXISTS "users_own_cart_select" ON public.cart;
CREATE POLICY "users_own_cart_select" ON public.cart 
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_own_cart_insert" ON public.cart;
CREATE POLICY "users_own_cart_insert" ON public.cart 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_own_cart_update" ON public.cart;
CREATE POLICY "users_own_cart_update" ON public.cart 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_own_cart_delete" ON public.cart;
CREATE POLICY "users_own_cart_delete" ON public.cart 
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Restricted System Tables (No Direct Access Allowed)
DROP POLICY IF EXISTS "no_direct_token_access" ON public.daily_tokens;
CREATE POLICY "no_direct_token_access" ON public.daily_tokens 
    FOR ALL USING (false);

DROP POLICY IF EXISTS "no_direct_retry_access" ON public.retry_queue;
CREATE POLICY "no_direct_retry_access" ON public.retry_queue 
    FOR ALL USING (false);
