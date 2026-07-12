# ACME API Client

Internal API client for ACME services.

## Setup

```bash
npm install
cp .env.example .env
# Fill in your credentials from the team vault
npm run build
npm start
```

## Environment

See `.env.example` for required variables. Get production values from the team 1Password vault.

## Development

```bash
npm run validate:env   # Validate environment before deploy
npm test               # Run test suite
npm run lint           # Lint check
```
