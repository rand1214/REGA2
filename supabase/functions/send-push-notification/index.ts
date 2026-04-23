import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);

// Get OAuth2 access token using service account
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Import private key
  const pemKey = FCM_SERVICE_ACCOUNT.private_key;
  const keyData = pemKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}

serve(async (req) => {
  try {
    const { device_id, user_id, fcm_token, title, body, data } = await req.json();

    let tokenToUse: string | null = fcm_token ?? null;

    if (!tokenToUse) {
      const lookupId = user_id ?? device_id;
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
      const { data: tokenRow } = await supabase
        .from("fcm_tokens")
        .select("token")
        .eq("user_id", lookupId)
        .maybeSingle();

      if (!tokenRow?.token) {
        return new Response(JSON.stringify({ error: "No FCM token found" }), { status: 404 });
      }
      tokenToUse = tokenRow.token;
    }

    const accessToken = await getAccessToken();

    const message = {
      message: {
        token: tokenToUse,
        notification: { title, body },
        data: data ?? {},
        android: {
          priority: "high",
          notification: { sound: "default" },
        },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      },
    };

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      }
    );

    const fcmData = await fcmRes.json();
    return new Response(JSON.stringify(fcmData), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: "Internal server error" }), { status: 500 });
  }
});
