export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // API endpoint for demo form submissions
    if (url.pathname === '/api/book-demo') {
      return handleBookDemo(request, env)
    }

    // Serve static assets from the repository root via ASSETS binding.
    return env.ASSETS.fetch(request)
  },
}

async function handleBookDemo(request, env) {
  const origin = request.headers.get('Origin') || ''
  const corsHeaders = buildCorsHeaders(origin, env)

  if (request.method === 'OPTIONS') {
    if (!corsHeaders) return json({ ok: false, error: 'origin not allowed' }, 403)
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (!corsHeaders) {
    return json({ ok: false, error: 'origin not allowed' }, 403)
  }

  if (request.method !== 'POST') {
    return json({ ok: false, error: 'Method Not Allowed' }, 405, corsHeaders)
  }

  try {
    const { name, email, company, message, turnstileToken } = await request.json()

    if (!name || !email || !turnstileToken) {
      return json(
        { ok: false, error: 'name, email, and turnstileToken are required' },
        400,
        corsHeaders,
      )
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json({ ok: false, error: 'invalid email' }, 400, corsHeaders)
    }

    // Verify Turnstile
    const ip = request.headers.get('CF-Connecting-IP') || ''
    const tsForm = new URLSearchParams()
    tsForm.append('secret', env.TURNSTILE_SECRET_KEY)
    tsForm.append('response', turnstileToken)
    if (ip) tsForm.append('remoteip', ip)

    const tsRes = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      body: tsForm,
    })

    const tsJson = await tsRes.json()
    if (!tsJson.success) {
      return json(
        {
          ok: false,
          error: 'turnstile verification failed',
          detail: tsJson['error-codes'] || [],
        },
        403,
        corsHeaders,
      )
    }

    // Send email via SMTP2GO
    const textBody = [
      'New Demo Request',
      `Name: ${name}`,
      `Email: ${email}`,
      `Company: ${company || '-'}`,
      `Message: ${message || '-'}`,
      `Submitted at: ${new Date().toISOString()}`,
    ].join('\n')

    const smtpRes = await fetch('https://api.smtp2go.com/v3/email/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-Smtp2go-Api-Key': env.SMTP2GO_API_KEY,
      },
      body: JSON.stringify({
        sender: env.FROM_EMAIL,
        to: [env.DEST_EMAIL],
        subject: 'New Book Demo request',
        text_body: textBody,
      }),
    })

    const smtpJson = await smtpRes.json()
    const succeeded = smtpJson?.data?.succeeded ?? 0

    if (!smtpRes.ok || succeeded < 1) {
      return json({ ok: false, error: 'email send failed', detail: smtpJson }, 502, corsHeaders)
    }

    return json({ ok: true }, 200, corsHeaders)
  } catch (err) {
    return json({ ok: false, error: 'bad request', detail: String(err) }, 400, corsHeaders)
  }
}

function json(payload, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  })
}

function buildCorsHeaders(origin, env) {
  const configured = (env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean)

  if (configured.length === 0) {
    // Fail-closed if not configured.
    return null
  }

  if (!origin || !configured.includes(origin)) {
    return null
  }

  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    Vary: 'Origin',
  }
}
