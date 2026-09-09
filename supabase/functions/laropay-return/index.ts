import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

const appScheme = "autolab";
const appHost = "laropay-callback";
const appPath = "/payment-return";

Deno.serve(async (request) => {
  if (request.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const paymentLinkId = new URL(request.url).searchParams.get("paymentLinkId")
    ?.trim() ?? "";
  if (!isUuid(paymentLinkId)) {
    return new Response("Invalid payment callback", { status: 400 });
  }

  try {
    const supabase = createClient(
      requiredEnv("SUPABASE_URL"),
      requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );

    const { data: paymentLink, error: paymentLinkError } = await supabase
      .from("laropay_payment_links")
      // id is the primary key, so this public callback lookup uses an indexed
      // equality filter even when callers send random UUIDs.
      .select("internal_transaction_id")
      .eq("id", paymentLinkId)
      .maybeSingle();
    if (paymentLinkError !== null || paymentLink === null) {
      return new Response("Payment callback not found", { status: 404 });
    }

    const internalTransactionId = String(paymentLink.internal_transaction_id ?? "").trim();
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("workshop_id")
      .eq("id", internalTransactionId)
      .maybeSingle();
    const workshopId = String(order?.workshop_id ?? "").trim();
    if (orderError !== null || !isUuid(workshopId)) {
      return new Response("Payment callback not found", { status: 404 });
    }

    const destination = new URL(`${appScheme}://${appHost}${appPath}`);
    destination.searchParams.set("workshopId", workshopId);
    destination.searchParams.set("paymentLinkId", paymentLinkId);
    if (!(await hasAppointmentForOrder(supabase, internalTransactionId))) {
      destination.searchParams.set("target", "purchases");
    }

    return new Response(null, {
      status: 302,
      headers: {
        "cache-control": "no-store",
        location: destination.toString(),
      },
    });
  } catch (error) {
    console.error("laropay_return_failed", safeError(error));
    return new Response("Payment callback unavailable", { status: 500 });
  }
});

function requiredEnv(key: string) {
  const value = Deno.env.get(key)?.trim() ?? "";
  if (value === "") {
    throw new Error(`missing_env_${key}`);
  }

  return value;
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(value);
}

async function hasAppointmentForOrder(
  supabase: SupabaseClient,
  orderId: string,
) {
  const { data: services, error: servicesError } = await supabase
    .from("order_services")
    .select("id")
    .eq("order_id", orderId);
  if (servicesError !== null || services === null || services.length === 0) {
    return false;
  }

  const serviceIds = services
    .map((service) => String(service.id ?? "").trim())
    .filter(isUuid);
  if (serviceIds.length === 0) {
    return false;
  }

  const { data: appointment, error: appointmentError } = await supabase
    .from("appointments")
    .select("id")
    .in("order_service_id", serviceIds)
    .limit(1)
    .maybeSingle();

  return appointmentError === null && appointment !== null;
}

function safeError(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
