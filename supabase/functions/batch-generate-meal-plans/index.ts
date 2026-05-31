import { createClient } from 'jsr:@supabase/supabase-js@2'
import { createLogger } from '../_shared/logger.ts'

const BATCH_SIZE = 500;

Deno.serve(async (req: Request): Promise<Response> => {
  const logger = createLogger('batch-generate-meal-plans');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  const secret = Deno.env.get('INTERNAL_SECRET');
  const authHeader = req.headers.get('Authorization');
  if (!secret || authHeader !== `Bearer ${secret}`) {
    logger.warn('EARLY RETURN | reason: unauthorized');
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const offset: number = typeof body.offset === 'number' ? body.offset : 0;

    logger.debug('[STEP 1] Computing next Monday start date');
    const nextMonday = getNextMonday();

    logger.debug('[STEP 2] Fetching user batch | offset: ' + offset + ' | batch_size: ' + BATCH_SIZE);
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: users, error: usersError } = await supabase
      .from('user_profile')
      .select('id')
      .range(offset, offset + BATCH_SIZE - 1);

    if (usersError) {
      logger.error('💥 Failed to fetch users', { message: usersError.message });
      return new Response(JSON.stringify({ error: usersError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    logger.info('[STEP 3] Processing ' + users.length + ' users | start_date: ' + nextMonday);

    let success = 0;
    let skipped = 0;
    let failed = 0;
    const errors: { userId: string; error: string }[] = [];

    for (const user of users) {
      logger.debug('[STEP 3] generate_meal_plan_internal | userId: ' + user.id);
      const { error } = await supabase.rpc('generate_meal_plan_internal', {
        p_user_id: user.id,
        p_start_date: nextMonday,
      });
      if (error) {
        if (error.message.includes('insufficient_recipes')) {
          skipped++;
          logger.warn('Skipped | userId: ' + user.id + ' | reason: insufficient_recipes');
        } else {
          failed++;
          errors.push({ userId: user.id, error: error.message });
          logger.warn('Failed | userId: ' + user.id + ' | error: ' + error.message);
        }
      } else {
        success++;
      }
    }

    logger.info(
      '[STEP 4] Batch complete | success: ' + success +
      ' | skipped: ' + skipped +
      ' | failed: ' + failed
    );

    if (users.length === BATCH_SIZE) {
      const nextOffset = offset + BATCH_SIZE;
      logger.info('[STEP 5] Self-chaining | next offset: ' + nextOffset);
      fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/batch-generate-meal-plans`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${secret}`,
        },
        body: JSON.stringify({ offset: nextOffset }),
      }).catch((e: Error) =>
        logger.error('💥 Self-chain request failed', { message: e.message })
      );
    }

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return new Response(
      JSON.stringify({ offset, success, skipped, failed, errors: errors.slice(0, 20) }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (e) {
    logger.error('💥 Unhandled error', { message: (e as Error).message, stack: (e as Error).stack });
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

function getNextMonday(): string {
  const today = new Date();
  const dayOfWeek = today.getUTCDay(); // 0 = Sunday
  const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek;
  const nextMonday = new Date(today);
  nextMonday.setUTCDate(today.getUTCDate() + daysUntilMonday);
  return nextMonday.toISOString().split('T')[0];
}
