# Formulário Jornada

Formulário web de pré-cadastro empresarial para liberação de acesso à plataforma Jornada.

## Recursos

- Fluxo responsivo em quatro etapas.
- Consulta automática de CNPJ e CEP por endpoint serverless.
- Validação de CPF, CNPJ, e-mail e campos obrigatórios.
- Máscaras de preenchimento e revisão antes do envio.
- Manifest e assets de marca para favicon, PWA e ícones.
- Endpoint serverless para encaminhar o cadastro ao webhook configurado.
- Proteções básicas com honeypot, validação de origem opcional e rate limit simples.

## Estrutura

```text
index.html
api/
  cadastro.js
  lookup.js
assets/
public/
  brand/
  manifest.webmanifest
tools/
  generate-brand-assets.ps1
package.json
vercel.json
```

## Variáveis de ambiente

Crie as variáveis no ambiente de deploy:

```text
CADASTRO_WEBHOOK_URL
APP_ORIGIN
```

`CADASTRO_WEBHOOK_URL` é obrigatória e deve apontar para o webhook de produção.
`APP_ORIGIN` é opcional; quando definida, limita a origem permitida para envio.

Arquivos `.env` e `.env.local` ficam fora do Git.

## Publicação na Vercel

1. Suba este repositório para o GitHub.
2. Importe o projeto na Vercel.
3. Configure `CADASTRO_WEBHOOK_URL` em Environment Variables.
4. Faça o deploy.

## Link personalizado

Use parâmetros de URL para personalizar origem e nome:

```text
https://seu-dominio.com/?nome=Saminha&origem=whatsapp
```

O formulário exibirá uma saudação com o primeiro nome informado.

## Desenvolvimento

Para regenerar os assets de marca:

```powershell
.\tools\generate-brand-assets.ps1
```

Antes de publicar, valide os links reais de termos de uso e política de privacidade no `index.html`.
