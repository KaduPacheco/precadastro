const REQUIRED_ENV = "CADASTRO_WEBHOOK_URL";
const ALLOWED_ORIGIN_ENV = "APP_ORIGIN";
const WEBHOOK_TIMEOUT_MS = 10000;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 5;
const rateLimitStore = new Map();

function json(res, status, payload) {
  res.status(status).setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  return res.end(JSON.stringify(payload));
}

function text(value, maxLength = 500) {
  return String(value ?? "").trim().slice(0, maxLength);
}

function digits(value, maxLength) {
  return String(value ?? "").replace(/\D/g, "").slice(0, maxLength);
}

function clientIp(req) {
  return text(
    req.headers["x-forwarded-for"]?.split(",")[0] ||
    req.socket?.remoteAddress ||
    "unknown",
    80
  );
}

function validRequestOrigin(req) {
  const allowedOrigin = text(process.env[ALLOWED_ORIGIN_ENV], 300);
  if (!allowedOrigin) return true;

  const origin = text(req.headers.origin, 300);
  if (!origin) return true;

  return origin === allowedOrigin;
}

function checkRateLimit(key) {
  const now = Date.now();
  const current = rateLimitStore.get(key);

  if (!current || current.resetAt <= now) {
    rateLimitStore.set(key, {
      count: 1,
      resetAt: now + RATE_LIMIT_WINDOW_MS
    });
    return { allowed: true, retryAfter: 0 };
  }

  current.count += 1;

  if (current.count > RATE_LIMIT_MAX_REQUESTS) {
    return {
      allowed: false,
      retryAfter: Math.ceil((current.resetAt - now) / 1000)
    };
  }

  return { allowed: true, retryAfter: 0 };
}

function parseBody(body) {
  if (typeof body !== "string") return body;

  try {
    return JSON.parse(body);
  } catch (error) {
    return null;
  }
}

function validCpf(value) {
  const cpf = digits(value, 11);
  if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) return false;

  let sum = 0;
  for (let index = 0; index < 9; index += 1) {
    sum += Number(cpf[index]) * (10 - index);
  }

  let check = (sum * 10) % 11;
  if (check === 10) check = 0;
  if (check !== Number(cpf[9])) return false;

  sum = 0;
  for (let index = 0; index < 10; index += 1) {
    sum += Number(cpf[index]) * (11 - index);
  }

  check = (sum * 10) % 11;
  if (check === 10) check = 0;

  return check === Number(cpf[10]);
}

function validCnpj(value) {
  const cnpj = digits(value, 14);
  if (cnpj.length !== 14 || /^(\d)\1{13}$/.test(cnpj)) return false;

  const calculate = (base, weights) => {
    const sum = base
      .split("")
      .reduce((total, digit, index) => total + Number(digit) * weights[index], 0);
    const remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  };

  const digit1 = calculate(cnpj.slice(0, 12), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  const digit2 = calculate(cnpj.slice(0, 12) + digit1, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);

  return cnpj.endsWith(`${digit1}${digit2}`);
}

function validPayload(body) {
  const empresa = body?.empresa;
  const endereco = body?.endereco;
  const administradora = body?.administradora;

  return Boolean(
    validCnpj(empresa?.cnpj) &&
    text(empresa?.razaoSocial) &&
    text(empresa?.nomeFantasia) &&
    text(empresa?.naturezaJuridica) &&
    text(empresa?.dataConstituicao) &&
    endereco?.cep?.length === 8 &&
    text(endereco?.logradouro) &&
    text(endereco?.numero) &&
    text(endereco?.bairro) &&
    text(endereco?.cidade) &&
    text(endereco?.uf).length === 2 &&
    validCpf(administradora?.cpf) &&
    text(administradora?.nome) &&
    administradora?.whatsapp?.length >= 10 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text(administradora?.email)) &&
    body?.consentimento === true
  );
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return json(res, 405, { message: "Método não permitido." });
  }

  if (!validRequestOrigin(req)) {
    return json(res, 403, {
      message: "Origem da requisicao nao permitida."
    });
  }

  const rateLimit = checkRateLimit(clientIp(req));
  if (!rateLimit.allowed) {
    res.setHeader("Retry-After", String(rateLimit.retryAfter));
    return json(res, 429, {
      message: "Muitas tentativas. Aguarde alguns minutos e tente novamente."
    });
  }

  const webhookUrl = process.env[REQUIRED_ENV];

  if (!webhookUrl) {
    console.error(`Variavel de ambiente obrigatoria ausente: ${REQUIRED_ENV}`);
    return json(res, 500, {
      message: "Estamos ajustando o envio do cadastro. Fale com nosso suporte para concluir."
    });
  }

  const body = parseBody(req.body);

  if (!body) {
    return json(res, 400, {
      message: "Corpo da requisicao invalido."
    });
  }

  // Honeypot: bots costumam preencher este campo invisível.
  if (text(body?.website)) {
    return json(res, 200, {
      ok: true,
      protocolo: text(body?.protocolo) || "RECEBIDO"
    });
  }

  const clean = {
    protocolo: text(body?.protocolo, 80),
    origem: text(body?.origem, 120),
    enviadoEm: text(body?.enviadoEm, 60),
    perfil: "PROPRIETARIA_ADMINISTRADORA",
    empresa: {
      cnpj: digits(body?.empresa?.cnpj, 14),
      razaoSocial: text(body?.empresa?.razaoSocial, 180),
      nomeFantasia: text(body?.empresa?.nomeFantasia, 180),
      naturezaJuridica: text(body?.empresa?.naturezaJuridica, 180),
      dataConstituicao: text(body?.empresa?.dataConstituicao, 20)
    },
    endereco: {
      cep: digits(body?.endereco?.cep, 8),
      logradouro: text(body?.endereco?.logradouro, 180),
      numero: text(body?.endereco?.numero, 30),
      complemento: text(body?.endereco?.complemento, 120),
      bairro: text(body?.endereco?.bairro, 120),
      cidade: text(body?.endereco?.cidade, 120),
      uf: text(body?.endereco?.uf, 2).toUpperCase()
    },
    administradora: {
      nome: text(body?.administradora?.nome, 180),
      cpf: digits(body?.administradora?.cpf, 11),
      whatsapp: digits(body?.administradora?.whatsapp, 13),
      email: text(body?.administradora?.email, 180).toLowerCase()
    },
    consentimento: body?.consentimento === true,
    metadata: {
      ip: text(
        req.headers["x-forwarded-for"]?.split(",")[0] ||
        req.socket?.remoteAddress ||
        "",
        80
      ),
      userAgent: text(req.headers["user-agent"], 300),
      recebidoEm: new Date().toISOString()
    }
  };

  if (!validPayload(clean)) {
    return json(res, 400, {
      message: "Revise os campos obrigatórios e tente novamente."
    });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), WEBHOOK_TIMEOUT_MS);

  try {
    const webhookResponse = await fetch(webhookUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Jornada-Source": "cadastro-web"
      },
      signal: controller.signal,
      body: JSON.stringify(clean)
    });

    if (!webhookResponse.ok) {
      const detail = await webhookResponse.text().catch(() => "");
      console.error("Falha no webhook:", webhookResponse.status, detail);
      return json(res, 502, {
        message: "O cadastro não pôde ser registrado agora. Tente novamente."
      });
    }

    return json(res, 200, {
      ok: true,
      protocolo: clean.protocolo
    });
  } catch (error) {
    const timedOut = error?.name === "AbortError";
    console.error(
      timedOut ? "Timeout ao encaminhar cadastro:" : "Erro ao encaminhar cadastro:",
      error
    );
    return json(res, 502, {
      message: "O cadastro não pôde ser registrado agora. Tente novamente."
    });
  } finally {
    clearTimeout(timeout);
  }
}
