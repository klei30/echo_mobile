# OAuth 2.0 + PKCE Auto-Discovery for MCP Servers

This feature adds automatic OAuth 2.0 authentication support for remote MCP servers, enabling seamless integration with OAuth-protected services like Notion MCP and Atlassian MCP.

## Features

- **🔍 Auto-Discovery**: Automatically detects OAuth requirements using RFC 8414 (OAuth 2.0 Authorization Server Metadata)
- **🔐 Dynamic Client Registration**: Supports RFC 7591 for automatic client registration when supported by the server
- **🛡️ PKCE Security**: Implements RFC 7636 (Proof Key for Code Exchange) for secure public client authentication
- **🌐 Public Client Support**: Works with servers that don't require client_id (like Notion MCP)
- **🔄 Token Management**: Automatic token refresh and expiry handling
- **🚫 Extension Filtering**: Filters out browser extension interference during OAuth callbacks

## Platform Support

**✅ Web Platform**: Full OAuth support with popup-based authentication flow  
**❌ Mobile/Desktop**: OAuth authentication is **web-only** due to browser security requirements

On non-web platforms:
- OAuth discovery still works (detects requirements)
- OAuth authentication throws `UnsupportedError`
- Fallback to manual configuration or other auth methods

## Tested OAuth Providers

- ✅ **Notion MCP** (`https://mcp.notion.com/mcp`)
- ✅ **Atlassian MCP** (specific URL varies)
- 🔄 **Other RFC 8414 compliant servers** (should work automatically)

## How It Works

1. **Discovery Phase**: When you enter an MCP server URL, the system:
   - Checks `/.well-known/oauth-authorization-server` for OAuth metadata
   - Attempts dynamic client registration if available
   - Falls back to public client mode if no client registration

2. **Authentication Phase**: 
   - Opens OAuth authorization popup
   - Handles PKCE code challenge/verifier generation
   - Processes OAuth callback with state validation
   - Exchanges authorization code for access token

3. **Usage Phase**:
   - Automatically includes `Authorization: Bearer <token>` in MCP requests
   - Handles token refresh when needed
   - Validates token expiry

## Architecture

```
┌─────────────────┐    ┌────────────────────┐    ┌─────────────────┐
│   MCP Server    │    │  OAuth Discovery   │    │  OAuth Handler  │
│                 │◄──►│                    │◄──►│                 │
│ /.well-known/   │    │ RFC 8414 Compliant │    │ PKCE + Popup    │
│ oauth-auth...   │    │                    │    │ Cross-origin    │
└─────────────────┘    └────────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌────────────────────┐
                       │   MCP Client       │
                       │                    │
                       │ Bearer Token Auth  │
                       │ StreamableClient   │
                       │ SSEClient          │
                       └────────────────────┘
```

## Usage

1. Go to **Settings → MCP Servers**
2. Enter an OAuth-protected MCP server URL (e.g., `https://mcp.notion.com/mcp`)
3. Click **Add Server** - OAuth requirements are detected automatically
4. If OAuth is required, you'll be prompted to authenticate
5. Complete the OAuth flow in the popup window
6. The server will be ready to use with automatic token authentication

## Security Features

- **PKCE Protection**: Prevents authorization code interception attacks
- **State Parameter Validation**: Prevents CSRF attacks
- **Origin Validation**: Ensures callbacks come from expected sources
- **Browser Extension Filtering**: Ignores interference from development tools
- **Token Expiry Handling**: Automatic refresh before expiration

## Future Enhancements

- Mobile/Desktop OAuth support via external browser
- Additional OAuth flows (device code, etc.)
- OAuth provider-specific optimizations
- Enhanced error handling and user feedback

---

This implementation follows OAuth 2.0 security best practices and modern web standards for a robust, user-friendly authentication experience.
