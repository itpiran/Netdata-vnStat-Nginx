# Security notes
- This template may create credential files in plain text (for convenience). For production, use a secure secrets manager.
- Limit IPs to the monitoring domain or VPN when possible.
- Consider enabling Netdata's own auth and tighter binding (127.0.0.1) so only Nginx proxies.
