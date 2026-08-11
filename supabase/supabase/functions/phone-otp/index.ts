import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const moceanToken = Deno.env.get("MOCEAN_API_TOKEN")!;
const moceanFrom = Deno.env.get("MOCEAN_FROM") || "KANCHANPUR";

const supabase = createClient(
  supabaseUrl,
  serviceRoleKey,
);

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function normalizePhone(phone: string) {
  let p = phone.trim().replace(/\s+/g, "");

  if (p.startsWith("01")) {
    p = "880" + p.substring(1);
  }

  if (p.startsWith("+")) {
    p = p.substring(1);
  }

  return p;
}

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sha256(text: string) {
  const data = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest("SHA-256", data);

  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function sendSms(phone: string, otp: string) {
  const response = await fetch(
    "https://rest.moceanapi.com/rest/2/sms",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${moceanToken}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        "mocean-from": moceanFrom,
        "mocean-to": phone,
        "mocean-text":
          `Kanchanpur Sporting Club: আপনার OTP হলো ${otp}। এটি 5 মিনিটের মধ্যে ব্যবহার করুন।`,
      }),
    },
  );

  const text = await response.text();

  if (!response.ok) {
    throw new Error(`Mocean SMS failed: ${text}`);
  }

  let result: any;

  try {
    result = JSON.parse(text);
  } catch {
    result = text;
  }

  if (
    result?.messages?.[0]?.status !== undefined &&
    String(result.messages[0].status) !== "0"
  ) {
    throw new Error(
      result.messages[0].err_msg || "SMS sending failed",
    );
  }

  return result;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    if (!moceanToken) {
      return json(
        { success: false, error: "Mocean API token is not configured." },
        500,
      );
    }

    const body = await req.json();

    const action = body.action;
    const phone = normalizePhone(body.phone || "");

    if (!phone) {
      return json(
        { success: false, error: "মোবাইল নম্বর দিন।" },
        400,
      );
    }

    // =========================
    // SEND OTP
    // =========================
    if (action === "send") {
      const name = String(body.name || "").trim();

      if (!name) {
        return json(
          { success: false, error: "নাম দিন।" },
          400,
        );
      }

      const otp = generateOtp();
      const otpHash = await sha256(otp);

      const expiresAt = new Date(
        Date.now() + 5 * 60 * 1000,
      ).toISOString();

      // Remove old OTP
      await supabase
        .from("phone_otps")
        .delete()
        .eq("phone", phone);

      const { error: insertError } = await supabase
        .from("phone_otps")
        .insert({
          phone,
          name,
          otp_hash: otpHash,
          expires_at: expiresAt,
          attempts: 0,
        });

      if (insertError) {
        return json(
          {
            success: false,
            error: "OTP সংরক্ষণ করা যায়নি।",
            details: insertError.message,
          },
          500,
        );
      }

      await sendSms(phone, otp);

      return json({
        success: true,
        message: "OTP পাঠানো হয়েছে।",
      });
    }

    // =========================
    // VERIFY OTP + CREATE USER
    // =========================
    if (action === "verify") {
      const otp = String(body.otp || "").trim();
      const password = String(body.password || "");

      if (!/^\d{6}$/.test(otp)) {
        return json(
          { success: false, error: "৬ সংখ্যার OTP দিন।" },
          400,
        );
      }

      if (password.length < 6) {
        return json(
          {
            success: false,
            error: "পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।",
          },
          400,
        );
      }

      const { data: pending, error: pendingError } =
        await supabase
          .from("phone_otps")
          .select("*")
          .eq("phone", phone)
          .maybeSingle();

      if (pendingError || !pending) {
        return json(
          {
            success: false,
            error: "OTP পাওয়া যায়নি। আবার OTP নিন।",
          },
          400,
        );
      }

      if (new Date(pending.expires_at).getTime() < Date.now()) {
        await supabase
          .from("phone_otps")
          .delete()
          .eq("phone", phone);

        return json(
          {
            success: false,
            error: "OTP-এর সময় শেষ হয়ে গেছে।",
          },
          400,
        );
      }

      const attempts = Number(pending.attempts || 0);

      if (attempts >= 5) {
        return json(
          {
            success: false,
            error: "অনেকবার ভুল OTP দেওয়া হয়েছে। নতুন OTP নিন।",
          },
          429,
        );
      }

      const enteredHash = await sha256(otp);

      if (enteredHash !== pending.otp_hash) {
        await supabase
          .from("phone_otps")
          .update({
            attempts: attempts + 1,
          })
          .eq("phone", phone);

        return json(
          {
            success: false,
            error: "OTP সঠিক নয়।",
          },
          400,
        );
      }

      // OTP verified — create Supabase Auth account
      const { data: userData, error: createError } =
        await supabase.auth.admin.createUser({
          phone: phone,
          password: password,
          phone_confirm: true,
          user_metadata: {
            full_name: pending.name,
          },
        });

      if (createError) {
        if (
          createError.message
            .toLowerCase()
            .includes("already")
        ) {
          return json(
            {
              success: false,
              error: "এই মোবাইল নম্বর দিয়ে আগে থেকেই অ্যাকাউন্ট আছে।",
            },
            409,
          );
        }

        return json(
          {
            success: false,
            error: createError.message,
          },
          400,
        );
      }

      await supabase
        .from("phone_otps")
        .delete()
        .eq("phone", phone);

      return json({
        success: true,
        message: "অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে।",
        user_id: userData.user?.id,
      });
    }

    return json(
      {
        success: false,
        error: "Invalid action.",
      },
      400,
    );
  } catch (error) {
    console.error(error);

    return json(
      {
        success: false,
        error:
          error instanceof Error
            ? error.message
            : "Server error",
      },
      500,
    );
  }
});
