-- =============================================
-- STEP 1: TEST - Disable RLS to confirm issue
-- =============================================
ALTER TABLE room_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE rooms DISABLE ROW LEVEL SECURITY;

-- Test your mobile app now. If participants show, RLS is the issue.
-- Then continue with steps below.

-- =============================================
-- STEP 2: Re-enable RLS
-- =============================================
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 3: Drop existing policies (if any)
-- =============================================
DROP POLICY IF EXISTS "Users can join rooms" ON room_participants;
DROP POLICY IF EXISTS "Users can view room participants" ON room_participants;
DROP POLICY IF EXISTS "Users can update own participant" ON room_participants;
DROP POLICY IF EXISTS "Users can leave rooms" ON room_participants;
DROP POLICY IF EXISTS "Users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can view rooms" ON rooms;
DROP POLICY IF EXISTS "Users can create rooms" ON rooms;
DROP POLICY IF EXISTS "Hosts can update rooms" ON rooms;
DROP POLICY IF EXISTS "Hosts can delete rooms" ON rooms;

-- =============================================
-- STEP 4: Create room_participants policies
-- =============================================
CREATE POLICY "Users can join rooms"
ON room_participants
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view room participants"
ON room_participants
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can update own participant"
ON room_participants
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can leave rooms"
ON room_participants
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- =============================================
-- STEP 5: Create profiles policies
-- =============================================
CREATE POLICY "Users can view profiles"
ON profiles
FOR SELECT
TO authenticated
USING (true);

-- =============================================
-- STEP 6: Create rooms policies
-- =============================================
CREATE POLICY "Users can view rooms"
ON rooms
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can create rooms"
ON rooms
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Hosts can update rooms"
ON rooms
FOR UPDATE
TO authenticated
USING (auth.uid() = host_id);

CREATE POLICY "Hosts can delete rooms"
ON rooms
FOR DELETE
TO authenticated
USING (auth.uid() = host_id);

-- =============================================
-- HELPER: Check existing policies
-- =============================================
SELECT policyname, tablename, cmd FROM pg_policies
WHERE tablename IN ('room_participants', 'profiles', 'rooms');

-- =============================================
-- HELPER: Check RLS status
-- =============================================
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname IN ('room_participants', 'profiles', 'rooms');
