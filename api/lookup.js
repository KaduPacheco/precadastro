const LOOKUP_TIMEOUT_MS = 8000;

function json(res, status, payload) {
  res.status(status).setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  return res.end(JSON.stringify(payload));
}

function digits(value, maxLength) {
  return String(value ?? "").replace(/\D/g, "").slice(0, maxLength);
}

async function fetchJson(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), LOOKUP_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      headers: {
        Accept: "application/json"
      },
      signal: controller.signal
    });
    const body = await response.json().catch(() => ({}));

    return {
      ok: response.ok,
      status: response.status,
      body
    };
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeCnpjWs(body) {
  const estabelecimento = body?.estabelecimento ?? {};
  const cidade = estabelecimento?.cidade ?? {};
  const estado = estabelecimento?.estado ?? {};
  const telefone = [estabelecimento.ddd1, estabelecimento.telefone1].filter(Boolean).join("");

  return {
    razao_social: body?.razao_social,
    nome_fantasia: estabelecimento.nome_fantasia,
    natureza_juridica: body?.natureza_juridica?.descricao,
    data_inicio_atividade: estabelecimento.data_inicio_atividade,
    cep: estabelecimento.cep,
    descricao_tipo_de_logradouro: estabelecimento.tipo_logradouro,
    logradouro: estabelecimento.logradouro,
    numero: estabelecimento.numero,
    complemento: estabelecimento.complemento,
    bairro: estabelecimento.bairro,
    municipio: cidade.nome,
    uf: estado.sigla,
    ddd_telefone_1: telefone
  };
}

async function lookupCnpj(value) {
  const cnpj = digits(value, 14);
  if (cnpj.length !== 14) {
    return { status: 400, body: { message: "CNPJ invalido." } };
  }

  let result;

  try {
    result = await fetchJson(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`);
  } catch (error) {
    console.error("Falha na BrasilAPI:", error);
    result = { ok: false, status: 503, body: {} };
  }

  if (result.ok) {
    return {
      status: 200,
      body: result.body
    };
  }

  if (result.status === 404) {
    return { status: 404, body: result.body };
  }

  try {
    const fallback = await fetchJson(`https://publica.cnpj.ws/cnpj/${cnpj}`);

    if (fallback.ok) {
      return {
        status: 200,
        body: normalizeCnpjWs(fallback.body)
      };
    }

    return {
      status: fallback.status === 404 ? 404 : 503,
      body: fallback.body
    };
  } catch (error) {
    console.error("Falha na CNPJ.ws:", error);
  }

  return {
    status: 503,
    body: result.body
  };
}

async function lookupCep(value) {
  const cep = digits(value, 8);
  if (cep.length !== 8) {
    return { status: 400, body: { message: "CEP invalido." } };
  }

  const result = await fetchJson(`https://viacep.com.br/ws/${cep}/json/`);

  if (!result.ok) {
    return {
      status: result.status === 404 ? 404 : 503,
      body: result.body
    };
  }

  return {
    status: result.body?.erro ? 404 : 200,
    body: result.body
  };
}

export default async function handler(req, res) {
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return json(res, 405, { message: "Metodo nao permitido." });
  }

  const kind = String(req.query?.kind ?? "").toLowerCase();
  const value = String(req.query?.value ?? "");

  try {
    const result =
      kind === "cnpj"
        ? await lookupCnpj(value)
        : kind === "cep"
          ? await lookupCep(value)
          : { status: 400, body: { message: "Tipo de consulta invalido." } };

    return json(res, result.status, result.body);
  } catch (error) {
    console.error("Falha na consulta automatica:", error);
    return json(res, 503, {
      message: "Servico de consulta temporariamente indisponivel."
    });
  }
}
