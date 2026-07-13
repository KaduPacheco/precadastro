# Formulário Premium — Jornada

Pacote pronto para publicar na Vercel e enviar os cadastros para um webhook do n8n.

## O que está incluído

- Formulário responsivo em quatro etapas.
- Consulta automática de CNPJ.
- Consulta automática de CEP.
- Validação real de CPF e CNPJ.
- Máscaras de preenchimento.
- Revisão dos dados antes do envio.
- Personalização do nome pelo link.
- Proteção simples contra bots por honeypot.
- Endpoint serverless que protege a URL do webhook.
- Protocolo de confirmação após o envio.

## Estrutura

```text
index.html
api/
  cadastro.js
package.json
vercel.json
```

## Publicação na Vercel

1. Coloque estes arquivos em um repositório GitHub.
2. Importe o repositório na Vercel.
3. Nas configurações do projeto, abra **Environment Variables**.
4. Crie a variável:

```text
CADASTRO_WEBHOOK_URL
```

5. Use como valor a URL de produção de um webhook do n8n.
6. Marque os ambientes desejados, como Production e Preview.
7. Faça um novo deploy.

## Fluxo básico no n8n

Crie um fluxo com:

```text
Webhook (POST)
→ banco de dados, planilha ou e-mail
→ Respond to Webhook
```

O corpo recebido terá esta estrutura:

```json
{
  "protocolo": "JOR-20260713-ABC123",
  "origem": "whatsapp",
  "perfil": "PROPRIETARIA_ADMINISTRADORA",
  "empresa": {},
  "endereco": {},
  "administradora": {},
  "consentimento": true,
  "metadata": {}
}
```

## Link personalizado para a Saminha

Depois do deploy, envie o link assim:

```text
https://seu-dominio.com/?nome=Saminha&origem=whatsapp
```

O formulário exibirá:

```text
Saminha, vamos preparar sua empresa.
```

## Antes de publicar

Troque os links abaixo no `index.html` pelos endereços reais:

```text
/termos-de-uso
/politica-de-privacidade
```

Também é possível substituir o wordmark textual pela logo oficial da Jornada.


## Webhook já conectado para testes

Este pacote já está configurado com o endpoint informado:

```text
https://n8n.forteia.com.br/webhook-test/precadastro
```

Como esse é um webhook de teste do n8n, abra o nó **Webhook** e clique em
**Listen for test event / Escutar evento de teste** antes de enviar o formulário.

Para publicação definitiva, ative o workflow e cadastre na Vercel a variável:

```text
CADASTRO_WEBHOOK_URL
```

Use como valor a URL de produção exibida no próprio nó Webhook do n8n.
A variável da Vercel terá prioridade sobre o endpoint de teste incluído no código.
