-- Enable pg_net extension for HTTP calls from triggers
create extension if not exists pg_net;

-- Trigger: send push notification when recovery request status changes
-- Uses fcm_token stored on the recovery request (new device's token)
create or replace function notify_recovery_status_change()
returns trigger as $func$
declare
  v_title text;
  v_body text;
begin
  if OLD.status = NEW.status then
    return NEW;
  end if;

  if NEW.fcm_token is null then
    return NEW;
  end if;

  if NEW.status = 'accepted' then
    v_title := 'داواکارییەکەت پەسەندکرا';
    v_body  := 'داواکارییەکەت پەسەندکرا، ئێستا دەتوانیت هەژمارەکەت بەکاربێنیت';
  elsif NEW.status = 'rejected' then
    v_title := 'داواکارییەکەت ڕەتکرایەوە';
    v_body  := 'داواکارییەکەت ڕەتکرایەوە، دووبارە هەوڵ بدەرەوە';
  else
    return NEW;
  end if;

  perform net.http_post(
    url := 'https://wqgejuwgjpchzghiicrw.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZ2VqdXdnanBjaHpnaGlpY3J3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjE2MTMwMCwiZXhwIjoyMDg3NzM3MzAwfQ.V6yORoYDFkYmZG4ikMi9NDYZkbXXwEMK-7qtpn1PmfU'
    ),
    body := jsonb_build_object(
      'fcm_token', NEW.fcm_token,
      'title', v_title,
      'body', v_body
    )
  );

  return NEW;
end;
$func$ language plpgsql security definer;

drop trigger if exists on_recovery_status_change on recovery_requests;
create trigger on_recovery_status_change
  after update on recovery_requests
  for each row
  execute function notify_recovery_status_change();


-- Trigger: send push notification to targeted users when a new broadcast notification is inserted
create or replace function notify_new_broadcast_notification()
returns trigger as $func$
declare
  v_token record;
  v_has_sub boolean;
begin
  for v_token in select user_id from fcm_tokens loop

    -- Check subscription status for this user
    select exists(
      select 1 from user_subscriptions
      where user_id = v_token.user_id::uuid
        and is_active = true
    ) into v_has_sub;

    -- Filter by user_type
    if NEW.user_type = 'all'
      or (NEW.user_type = 'pro' and v_has_sub = true)
      or (NEW.user_type = 'free' and v_has_sub = false)
    then
      perform net.http_post(
        url := 'https://wqgejuwgjpchzghiicrw.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxZ2VqdXdnanBjaHpnaGlpY3J3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjE2MTMwMCwiZXhwIjoyMDg3NzM3MzAwfQ.V6yORoYDFkYmZG4ikMi9NDYZkbXXwEMK-7qtpn1PmfU'
        ),
        body := jsonb_build_object(
          'user_id', v_token.user_id,
          'title', NEW.title,
          'body', NEW.text
        )
      );
    end if;

  end loop;

  return NEW;
end;
$func$ language plpgsql security definer;

drop trigger if exists on_new_notification on notifications;
create trigger on_new_notification
  after insert on notifications
  for each row
  execute function notify_new_broadcast_notification();
