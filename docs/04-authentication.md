# Authentication

Complete guide to authenticating with the Causely API.

## Table of Contents

- [Overview](#overview)
- [Frontegg OAuth (Recommended)](#frontegg-oauth-recommended)
- [Direct JWT Token](#direct-jwt-token)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

## Overview

All API requests use GraphQL and require authentication using a JWT token. The Causely API Client supports two authentication methods:

1. **Frontegg OAuth** (Recommended for CI/CD and production)
2. **Direct JWT Token** (For development and testing)

## Frontegg OAuth (Recommended)

Frontegg OAuth is the recommended authentication method for production use and CI/CD pipelines. It provides automatic token management and is more secure than passing tokens directly.

### Step 1: Create Frontegg API Token

1. Login to [Causely Portal](https://portal.causely.app/)
2. At the top right, click **User Settings** (bubble icon with your initials)
3. Click **Admin Portal** (opens new tab to Frontegg dashboard)
4. Navigate to **API Tokens** (bottom of left menu)
5. Click **Generate Token**
6. Fill in:
   - **Description**: Name for your token (e.g., "CI/CD Pipeline")
   - **Role**: Select "Admin"
   - Click **Create**
7. **IMPORTANT**: Copy and save the **Client ID** and **Client Secret** immediately - they are shown only once!

### Step 2: Set Environment Variables

```bash
export FRONTEGG_CLIENT_ID="your-client-id"
export FRONTEGG_CLIENT_SECRET="your-client-secret"
export APP_BASE_URL="https://api.causely.app/query"  # Optional
export FRONTEGG_IDENTITY_HOST="https://auth.causely.app/identity/resources/auth/v2/api-token"  # Optional
```

### Step 3: Use in Scripts

The scripts automatically detect Frontegg credentials and authenticate:

```bash
# Shell scripts automatically use Frontegg auth when env vars are set
./shell/create_snapshot.sh \
  --name "My Snapshot" \
  --description "Test" \
  --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

### GitHub Actions Setup

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add:
   - `FRONTEGG_CLIENT_ID`: Your client ID
   - `FRONTEGG_CLIENT_SECRET`: Your client secret

Then use in workflows:

```yaml
env:
  FRONTEGG_CLIENT_ID: ${{ secrets.FRONTEGG_CLIENT_ID }}
  FRONTEGG_CLIENT_SECRET: ${{ secrets.FRONTEGG_CLIENT_SECRET }}
```

## Direct JWT Token

For development and testing, you can use a direct JWT token. This method requires you to obtain a token manually and pass it to scripts.

### Obtaining a JWT Token

You can obtain a JWT token using the Frontegg authentication endpoint:

```bash
curl -X POST "https://auth.causely.app/identity/resources/auth/v2/api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "your-client-id",
    "secret": "your-client-secret"
  }'
```

The response will contain an `accessToken` field with your JWT token.

### Using Direct Token

```bash
./shell/create_snapshot.sh \
  --api-url "https://api.causely.app/query" \
  --token "YOUR_JWT_TOKEN" \
  --name "My Snapshot" \
  --description "Test" \
  --start-time "$(date -u -d '2 hours ago' +'%Y-%m-%dT%H:%M:%SZ')"
```

**Note:** Direct tokens expire after a period of time. Frontegg OAuth automatically handles token refresh.

## Environment Variables

### Frontegg Authentication

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FRONTEGG_CLIENT_ID` | Frontegg client ID | - | Yes |
| `FRONTEGG_CLIENT_SECRET` | Frontegg client secret | - | Yes |
| `APP_BASE_URL` | API endpoint | `https://api.causely.app/query` | No |
| `FRONTEGG_IDENTITY_HOST` | Auth endpoint | `https://auth.causely.app/identity/resources/auth/v2/api-token` | No |

### Authentication Mode Detection

The Shell library automatically detects which authentication method to use:

- **Frontegg Mode**: If `FRONTEGG_CLIENT_ID` and `FRONTEGG_CLIENT_SECRET` are set
- **Direct Token Mode**: Otherwise (caller must provide `--token` and `--api-url`)

## Troubleshooting

### Authentication Failed

**Problem:** `❌ Authentication failed`

**Solutions:**
1. Verify `FRONTEGG_CLIENT_ID` and `FRONTEGG_CLIENT_SECRET` are set correctly
2. Check that credentials are valid and not expired
3. Ensure credentials haven't been revoked in Frontegg dashboard
4. Verify the auth endpoint URL is correct (check `FRONTEGG_IDENTITY_HOST`)

### Token Expired

**Problem:** `401 Unauthorized` errors

**Solutions:**
1. If using Frontegg OAuth, the library automatically refreshes tokens
2. If using direct tokens, obtain a new token
3. Check token expiration time in Frontegg dashboard

### Invalid Credentials

**Problem:** `Invalid client credentials`

**Solutions:**
1. Verify you copied the Client ID and Client Secret correctly
2. Ensure there are no extra spaces or newlines
3. Check that the token hasn't been deleted in Frontegg dashboard
4. Create a new API token if needed

### GitHub Actions Secrets Not Working

**Problem:** Secrets not accessible in workflow

**Solutions:**
1. Verify secrets are set in **Settings** → **Secrets and variables** → **Actions**
2. Check secret names match exactly (case-sensitive)
3. Ensure workflow has permission to access secrets
4. For environment-specific secrets, check environment protection rules

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use secrets management** (GitHub Secrets, AWS Secrets Manager, etc.)
3. **Rotate credentials regularly**
4. **Use least privilege** - create tokens with minimum required permissions
5. **Monitor token usage** in Frontegg dashboard
6. **Revoke unused tokens** immediately

## Related Documentation

- **[Quick Start](02-quick-start.md)** - Get started with authentication
- **[Shell Implementation](05-shell-implementation.md)** - Shell library authentication functions
- **[GitHub Actions](06-github-actions.md)** - CI/CD authentication setup
