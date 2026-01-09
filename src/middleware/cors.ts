import { defineEventHandler, setResponseHeaders, getHeader } from 'h3';

export default defineEventHandler((event) => {
  const allowedDomains = process.env.ALLOWED_DOMAINS?.split(',').map(d => d.trim()) || [];
  const origin = getHeader(event, 'origin');
  
  // If no origin (e.g. direct browser access), we don't need to set CORS
  if (!origin) return;

  // Determine if the origin is allowed
  // Allowed if:
  // 1. ALLOWED_DOMAINS is empty or contains '*'
  // 2. The origin matches one of the allowed domains
  const isAllowed = allowedDomains.length === 0 || 
                    allowedDomains.includes('*') || 
                    allowedDomains.some(domain => origin === domain || origin.endsWith(`.${domain}`));

  const corsOrigin = isAllowed ? origin : (allowedDomains[0] || '*');

  setResponseHeaders(event, {
    'Access-Control-Allow-Origin': corsOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Expose-Headers': '*',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  });

  // Handle preflight requests
  if (event.node.req.method === 'OPTIONS') {
    event.node.res.statusCode = 204;
    event.node.res.statusMessage = 'No Content';
    return '';
  }
});
