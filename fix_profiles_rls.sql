-- =============================================
-- FIX PROFILES RLS - Allow all authenticated users to view all profiles
-- =============================================

-- Step 1: Check current policies on profiles
SELECT policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'profiles';

-- Step 2: Drop ALL existing profile policies
DROP POLICY IF EXISTS "Users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;

-- Step 3: Create simple permissive policies for profiles
-- Allow ALL authenticated users to SELECT ANY profile
CREATE POLICY "Allow authenticated to view all profiles"
ON profiles
FOR SELECT
TO authenticated
USING (true);

-- Allow users to INSERT their own profile
CREATE POLICY "Allow users to insert own profile"
ON profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Allow users to UPDATE their own profile
CREATE POLICY "Allow users to update own profile"
ON profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- Step 4: Verify the new policies
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'profiles';

-- Step 5: Test query - this should return all profiles
SELECT id, username, display_name FROM profiles LIMIT 5;
