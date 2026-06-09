import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("compute-group-vectors");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    const isInternal = verifyInternalSecret(req);
    if (!isInternal) {
      logger.warn("EARLY RETURN | reason: missing or invalid x-internal-secret");
      return unauthorized("Invalid internal secret");
    }

    const admin = serviceClient();

    logger.debug("[STEP 2] Fetch public community groups");
    const { data: groups, error: groupsError } = await admin
      .from("community_group")
      .select("id")
      .eq("is_public", true);
      
    if (groupsError) throw groupsError;

    if (!groups || groups.length === 0) {
      logger.info("✅ EXIT | status: 200 | computed: 0 | skipped: 0 | failed: 0 | duration: " + (Date.now() - start) + "ms");
      return ok({ computed: 0, skipped: 0, failed: 0, duration_ms: Date.now() - start });
    }

    let computed = 0;
    let skipped = 0;
    let failed = 0;

    logger.debug(`[STEP 3] Processing ${groups.length} groups in batches of 50`);
    
    const batchSize = 50;
    for (let i = 0; i < groups.length; i += batchSize) {
      const batch = groups.slice(i, i + batchSize);
      
      for (const group of batch) {
        try {
          const { data: avgData, error: avgError } = await admin
            .rpc("get_group_vector_avg", { p_group_id: group.id })
            .maybeSingle();

          if (avgError) {
            throw avgError;
          }

          if (avgData && avgData.avg_vector) {
            // Upsert into group_vector
            const { error: upsertError } = await admin
              .from("group_vector")
              .upsert({
                group_id: group.id,
                vector: avgData.avg_vector,
                last_computed: new Date().toISOString(),
                member_count_sampled: avgData.sampled
              });

            if (upsertError) {
              throw upsertError;
            }
            computed++;
          } else {
            // 0 vectorized members
            skipped++;
          }
        } catch (groupError) {
          logger.error(`[STEP 4] Error processing group ${group.id}:`, groupError);
          failed++;
        }
      }
    }

    logger.info(`✅ EXIT | status: 200 | computed: ${computed} | skipped: ${skipped} | failed: ${failed} | duration: ${Date.now() - start}ms`);
    return ok({ computed, skipped, failed, duration_ms: Date.now() - start });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
