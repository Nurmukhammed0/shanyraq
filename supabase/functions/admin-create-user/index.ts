// Админ создаёт нового пользователя из админ-панели.
// Работает через service_role ключ, поэтому только здесь, на сервере
// (Edge Function) — этот ключ никогда не должен попадать в Flutter-клиент.
//
// Деплой: supabase functions deploy admin-create-user
// (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY
// подставляются автоматически, отдельно настраивать не нужно).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Нет авторизации" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Клиент от имени вызывающего — чтобы проверить, что он реально админ.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    if (userError || !userData?.user) {
      return json({ error: "Не удалось определить пользователя" }, 401);
    }

    const { data: callerProfile, error: profileError } = await callerClient
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profileError || callerProfile?.role !== "admin") {
      return json({ error: "Только администратор может добавлять пользователей" }, 403);
    }

    const body = await req.json();
    const email = (body.email as string | undefined)?.trim();
    const password = body.password as string | undefined;
    const displayName = (body.displayName as string | undefined)?.trim();
    const role = body.role === "admin" ? "admin" : "user";
    const isSubscribed = body.isSubscribed === true;

    if (!email || !password || password.length < 8) {
      return json({ error: "Нужен email и пароль (минимум 8 символов)" }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: created, error: createError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (createError || !created?.user) {
      return json({ error: createError?.message ?? "Не удалось создать пользователя" }, 400);
    }

    // Триггер on_auth_user_created уже создал строку в profiles —
    // дозаполняем роль/подписку/имя, если админ их указал.
    const updates: Record<string, unknown> = {};
    if (role === "admin") updates.role = "admin";
    if (isSubscribed) updates.is_subscribed = true;
    if (displayName) updates.display_name = displayName;
    if (Object.keys(updates).length > 0) {
      await adminClient.from("profiles").update(updates).eq("id", created.user.id);
    }

    return json({ id: created.user.id, email: created.user.email });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
