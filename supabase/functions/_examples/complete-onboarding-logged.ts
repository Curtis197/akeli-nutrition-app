// supabase/functions/_examples/complete-onboarding-logged.ts
/**
 * EXAMPLE: Complete Edge Function with Comprehensive Logging
 * 
 * This example demonstrates how to implement comprehensive logging
 * in a Supabase Edge Function following Akeli's logging standards.
 * 
 * You can use this as a template for other edge functions.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';

// Import userClient helper (assumes it exists in _shared/supabase.ts)
// If not, create it similar to:
// export function userClient(req: Request) {
//   const authHeader = req.headers.get('Authorization')!;
//   return createClient(
//     Deno.env.get('SUPABASE_URL')!,
//     Deno.env.get('SUPABASE_ANON_KEY')!,
//     { global: { headers: { Authorization: authHeader } } }
//   );
// }
import { userClient } from '../_shared/supabase.ts';

serve(async (req: Request) => {
  // Step 1: Create logger and generate unique request ID
  const logger = createLogger('complete-onboarding');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  
  logger.info('Function invoked');
  
  try {
    // Step 2: Validate authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      logger.error('Missing Authorization header');
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Step 3: Initialize Supabase client with user context (RLS enforced)
    const supabase = userClient(req);
    logger.debug('🔐 Auth: Initialized userClient (RLS enforced)');
    
    // Step 4: Extract and verify user from JWT
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      logger.error('🔐 Auth: User authentication failed', {
        error: authError?.message,
      });
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Set userId for all subsequent log messages
    logger.setUserId(user.id);
    logger.info('👤 User authenticated successfully');
    
    // Step 5: Parse request body
    let body: any;
    try {
      body = await req.json();
    } catch (parseError) {
      logger.error('Invalid JSON in request body');
      return new Response(
        JSON.stringify({ error: 'Invalid request body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    logger.debug('Request body parsed', { 
      keys: Object.keys(body) // Log keys only, not full body for security
    });
    
    // Step 6: Validate input
    const { dietary_preferences, allergies, fitness_goal } = body;
    
    if (!dietary_preferences || !fitness_goal) {
      logger.warn('Validation failed: Missing required fields', {
        missing: [
          !dietary_preferences ? 'dietary_preferences' : null,
          !fitness_goal ? 'fitness_goal' : null,
        ].filter(Boolean),
      });
      
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: dietary_preferences, fitness_goal' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Step 7: Perform database operation with RLS logging
    logRLSCheck(logger, 'user_profile', 'UPDATE', user.id);
    
    const startTime = Date.now();
    
    const { data: profile, error: updateError } = await supabase
      .from('user_profile')
      .update({
        onboarding_complete: true,
        dietary_preferences,
        allergies: allergies || [],
        fitness_goal,
        onboarding_completed_at: new Date().toISOString(),
      })
      .eq('id', user.id)
      .select()
      .single();
    
    const duration = Date.now() - startTime;
    logger.debug(`⏱️ DB operation completed in ${duration}ms`);
    
    if (updateError) {
      logQueryResult(logger, 'user_profile', 'UPDATE', 0, updateError);
      logger.error('Failed to update user profile');
      
      return new Response(
        JSON.stringify({ error: 'Failed to complete onboarding' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    logQueryResult(logger, 'user_profile', 'UPDATE', 1);
    logger.info('✅ Onboarding completed successfully');
    
    // Step 8: Log additional operations (e.g., sending welcome notification)
    try {
      logger.debug('Sending welcome notification');
      
      const { error: notificationError } = await supabase
        .from('notification')
        .insert({
          user_id: user.id,
          type: 'welcome',
          title: 'Welcome to Akeli! 🎉',
          message: 'Your profile is set up. Start exploring recipes!',
          is_read: false,
        });
      
      if (notificationError) {
        // Log but don't fail the whole operation
        logger.warn('Failed to send welcome notification (non-critical)', {
          error: notificationError.message,
        });
      } else {
        logger.debug('✅ Welcome notification sent');
      }
    } catch (notifError) {
      logger.warn('Welcome notification failed (non-critical)', {
        error: notifError,
      });
    }
    
    // Step 9: Return success response
    logger.info('Function completed successfully', {
      duration: `${Date.now() - startTime}ms`,
    });
    
    return new Response(
      JSON.stringify({
        success: true,
        profile,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    // Step 10: Catch-all error handler
    logger.error('💥 Unhandled error in function', {
      error: error.message,
      stack: error.stack,
    });
    
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
