-- Migration: Add recovery_requests table for manual account recovery approval
-- This table tracks all recovery requests with their status (pending/accepted/rejected)

CREATE TABLE IF NOT EXISTS recovery_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- User information
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  recovery_code TEXT NOT NULL,
  submitted_name TEXT NOT NULL,
  actual_name TEXT NOT NULL, -- Stored from user_profiles table for comparison
  
  -- Device information
  old_device_id TEXT NOT NULL, -- Original device
  new_device_id TEXT NOT NULL, -- Device requesting recovery
  
  -- Request status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  
  -- Review information
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  notes TEXT, -- Admin notes for manual review
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX idx_recovery_requests_status ON recovery_requests(status);
CREATE INDEX idx_recovery_requests_user_id ON recovery_requests(user_id);
CREATE INDEX idx_recovery_requests_device ON recovery_requests(new_device_id);
CREATE INDEX idx_recovery_requests_submitted_at ON recovery_requests(submitted_at DESC);

-- Enable Row Level Security
ALTER TABLE recovery_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own recovery requests
CREATE POLICY "Users can view own recovery requests"
  ON recovery_requests
  FOR SELECT
  USING (new_device_id = current_setting('app.device_id', true));

-- Policy: Users can insert their own recovery requests
CREATE POLICY "Users can create recovery requests"
  ON recovery_requests
  FOR INSERT
  WITH CHECK (new_device_id = current_setting('app.device_id', true));

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_recovery_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_recovery_requests_updated_at
  BEFORE UPDATE ON recovery_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_recovery_requests_updated_at();

-- Function to submit a recovery request
CREATE OR REPLACE FUNCTION submit_recovery_request(
  p_recovery_code TEXT,
  p_submitted_name TEXT,
  p_new_device_id TEXT
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_actual_name TEXT;
  v_old_device_id TEXT;
  v_request_id UUID;
  v_existing_pending_count INT;
BEGIN
  -- Find user by recovery code (plain text)
  SELECT id, kurdish_name, device_fingerprint
  INTO v_user_id, v_actual_name, v_old_device_id
  FROM public.user_profiles
  WHERE recovery_code = p_recovery_code;
  
  -- Check if user exists
  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'invalid_code',
      'message', 'کۆدی گەڕانەوە هەڵەیە'
    );
  END IF;
  
  -- Check if there's already a pending request for this user
  SELECT COUNT(*)
  INTO v_existing_pending_count
  FROM recovery_requests
  WHERE user_id = v_user_id
    AND status = 'pending';
  
  IF v_existing_pending_count > 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'pending_request_exists',
      'message', 'داواکارییەکی چاوەڕوان هەیە'
    );
  END IF;
  
  -- Insert recovery request
  INSERT INTO recovery_requests (
    user_id,
    recovery_code,
    submitted_name,
    actual_name,
    old_device_id,
    new_device_id,
    status
  ) VALUES (
    v_user_id,
    p_recovery_code,
    p_submitted_name,
    v_actual_name,
    v_old_device_id,
    p_new_device_id,
    'pending'
  )
  RETURNING id INTO v_request_id;
  
  RETURN json_build_object(
    'success', true,
    'request_id', v_request_id,
    'status', 'pending',
    'message', 'داواکارییەکەت نێردرا، تکایە چاوەڕێ بە'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check recovery request status
CREATE OR REPLACE FUNCTION check_recovery_request_status(
  p_new_device_id TEXT
)
RETURNS JSON AS $$
DECLARE
  v_request RECORD;
BEGIN
  -- Get the most recent request for this device
  SELECT *
  INTO v_request
  FROM recovery_requests
  WHERE new_device_id = p_new_device_id
  ORDER BY submitted_at DESC
  LIMIT 1;
  
  -- Check if request exists
  IF v_request IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'no_request',
      'message', 'هیچ داواکارییەک نەدۆزرایەوە'
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'request_id', v_request.id,
    'status', v_request.status,
    'submitted_at', v_request.submitted_at,
    'reviewed_at', v_request.reviewed_at,
    'rejection_reason', v_request.rejection_reason
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to approve recovery request (admin only - call from database)
CREATE OR REPLACE FUNCTION approve_recovery_request(
  p_request_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_request RECORD;
BEGIN
  -- Get request details
  SELECT *
  INTO v_request
  FROM recovery_requests
  WHERE id = p_request_id
    AND status = 'pending';
  
  IF v_request IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'request_not_found',
      'message', 'Request not found or already processed'
    );
  END IF;
  
  -- Update request status
  UPDATE recovery_requests
  SET status = 'accepted',
      reviewed_at = NOW()
  WHERE id = p_request_id;
  
  -- Update user's device_fingerprint to new device
  UPDATE public.user_profiles
  SET device_fingerprint = v_request.new_device_id,
      updated_at = NOW()
  WHERE id = v_request.user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Recovery request approved and device updated'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject recovery request (admin only - call from database)
CREATE OR REPLACE FUNCTION reject_recovery_request(
  p_request_id UUID,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSON AS $$
BEGIN
  -- Update request status
  UPDATE recovery_requests
  SET status = 'rejected',
      reviewed_at = NOW(),
      rejection_reason = p_rejection_reason
  WHERE id = p_request_id
    AND status = 'pending';
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'request_not_found',
      'message', 'Request not found or already processed'
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Recovery request rejected'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION submit_recovery_request(TEXT, TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_recovery_request_status(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION approve_recovery_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_recovery_request(UUID, TEXT) TO authenticated;

-- Comment on table
COMMENT ON TABLE recovery_requests IS 'Tracks account recovery requests with manual approval workflow';
COMMENT ON COLUMN recovery_requests.status IS 'Request status: pending (waiting review), accepted (approved), rejected (denied)';
COMMENT ON COLUMN recovery_requests.actual_name IS 'Actual name from users table for manual comparison';
COMMENT ON COLUMN recovery_requests.old_device_id IS 'Original device ID from users table';
COMMENT ON COLUMN recovery_requests.new_device_id IS 'New device ID requesting recovery';
