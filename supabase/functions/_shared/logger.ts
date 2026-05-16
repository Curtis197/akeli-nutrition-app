// supabase/functions/_shared/logger.ts

/**
 * Centralized logger for Supabase Edge Functions
 * Provides structured logging with emoji indicators and request correlation
 * 
 * ## Usage
 * 
 * ```typescript
 * import { createLogger } from './_shared/logger.ts';
 * 
 * serve(async (req: Request) => {
 *   const logger = createLogger('my-function');
 *   logger.info('Function invoked');
 * });
 * ```
 * 
 * ## Log Levels
 * 
 * - `debug`: Detailed debugging information
 * - `info`: Important events (success, completion)
 * - `warn`: Potential issues (RLS blocks, validation warnings)
 * - `error`: Actual errors (exceptions, failed operations)
 * 
 * ## Emoji Legend
 * 
 * | Emoji | Meaning |
 * |-------|---------|
 * | 🔐 | Authentication |
 * | 📡 | Database query |
 * | 🔍 | RLS check |
 * | ⚡ | Edge function |
 * | ✅ | Success |
 * | ❌ | Error |
 * | ⚠️ | Warning |
 * | 🚫 | Blocked/Denied |
 * | 💥 | Critical failure |
 * | 👤 | User context |
 */

export interface LogMeta {
  [key: string]: any;
}

export interface EdgeLogger {
  debug: (message: string, meta?: LogMeta) => void;
  info: (message: string, meta?: LogMeta) => void;
  warn: (message: string, meta?: LogMeta) => void;
  error: (message: string, meta?: LogMeta) => void;
  setRequestId: (requestId: string) => void;
  setUserId: (userId: string) => void;
}

/**
 * Create a logger instance for an Edge Function
 * @param functionName Name of the edge function (e.g., 'toggle-recipe-like')
 */
export function createLogger(functionName: string): EdgeLogger {
  let requestId = '';
  let userId = '';

  const formatMessage = (level: string, message: string, meta?: LogMeta): string => {
    const emoji = getEmoji(level);
    const reqId = requestId ? `[${requestId}]` : '';
    const usr = userId ? `userId: ${userId}` : '';
    const metaStr = meta ? ` | ${JSON.stringify(sanitizeMeta(meta))}` : '';
    const context = [reqId, usr].filter(Boolean).join(' | ');
    
    return `${emoji} [${functionName}] ${message}${context ? ' | ' + context : ''}${metaStr}`;
  };

  const getEmoji = (level: string): string => {
    switch (level) {
      case 'debug': return '🐛';
      case 'info': return 'ℹ️';
      case 'warn': return '⚠️';
      case 'error': return '❌';
      default: return '📝';
    }
  };

  const sanitizeMeta = (meta: LogMeta): LogMeta => {
    const sanitized = { ...meta };
    
    // Remove sensitive fields
    delete sanitized.password;
    delete sanitized.access_token;
    delete sanitized.refresh_token;
    delete sanitized.api_key;
    delete sanitized.secret;
    delete sanitized.card_number;
    delete sanitized.cvv;
    
    // Mask email if present
    if (sanitized.email) {
      sanitized.email = maskEmail(sanitized.email);
    }
    
    // Mask token if present
    if (sanitized.token) {
      sanitized.token = maskToken(sanitized.token);
    }
    
    return sanitized;
  };

  const maskEmail = (email: string): string => {
    try {
      const parts = email.split('@');
      if (parts.length !== 2) return '***';
      
      const localPart = parts[0];
      const domainPart = parts[1];
      
      const maskedLocal = localPart.length > 3 
        ? `${localPart.substring(0, 3)}***`
        : '***';
      
      const maskedDomain = domainPart.length > 3
        ? `${domainPart.substring(0, 3)}***`
        : '***';
      
      return `${maskedLocal}@${maskedDomain}`;
    } catch {
      return '***';
    }
  };

  const maskToken = (token: string): string => {
    if (token.length <= 20) return '***';
    return `${token.substring(0, 10)}...${token.substring(token.length - 10)}`;
  };

  return {
    debug: (message: string, meta?: LogMeta) => {
      console.log(formatMessage('debug', message, meta));
    },
    info: (message: string, meta?: LogMeta) => {
      console.log(formatMessage('info', message, meta));
    },
    warn: (message: string, meta?: LogMeta) => {
      console.warn(formatMessage('warn', message, meta));
    },
    error: (message: string, meta?: LogMeta) => {
      console.error(formatMessage('error', message, meta));
    },
    setRequestId: (id: string) => {
      requestId = id;
    },
    setUserId: (id: string) => {
      userId = id;
    },
  };
}

/**
 * Helper to log RLS policy checks
 */
export function logRLSCheck(
  logger: EdgeLogger,
  tableName: string,
  operation: 'SELECT' | 'INSERT' | 'UPDATE' | 'DELETE',
  userId: string,
): void {
  logger.debug(`🔍 RLS: ${operation} on "${tableName}" for userId: ${userId}`);
}

/**
 * Helper to log database query results
 */
export function logQueryResult(
  logger: EdgeLogger,
  tableName: string,
  operation: 'SELECT' | 'INSERT' | 'UPDATE' | 'DELETE',
  rowCount: number,
  error?: { code: string; message: string },
): void {
  if (error) {
    if (error.code === '42501') {
      logger.error(`🚫 RLS: Permission denied on ${operation} "${tableName}"`, { 
        code: error.code, 
        message: error.message 
      });
    } else {
      logger.error(`❌ DB: ${operation} on "${tableName}" failed`, { 
        code: error.code, 
        message: error.message 
      });
    }
  } else {
    logger.debug(`✅ DB: ${operation} on "${tableName}" successful | rows: ${rowCount}`);
  }
}
