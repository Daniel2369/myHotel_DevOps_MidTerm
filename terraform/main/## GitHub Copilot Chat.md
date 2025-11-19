## GitHub Copilot Chat

- Extension Version: 0.31.5 (prod)
- VS Code: vscode/1.104.1
- OS: Mac

## Network

User Settings:
```json
  "github.copilot.advanced.debug.useElectronFetcher": true,
  "github.copilot.advanced.debug.useNodeFetcher": false,
  "github.copilot.advanced.debug.useNodeFetchFetcher": true
```

Connecting to https://api.github.com:
- DNS ipv4 Lookup: 20.217.135.0 (30 ms)
- DNS ipv6 Lookup: ::ffff:20.217.135.0 (9 ms)
- Proxy URL: None (3 ms)
- Electron fetch (configured): HTTP 200 (39 ms)
- Node.js https: HTTP 200 (35 ms)
- Node.js fetch: HTTP 200 (35 ms)

Connecting to https://api.individual.githubcopilot.com/_ping:
- DNS ipv4 Lookup: 140.82.113.22 (7 ms)
- DNS ipv6 Lookup: ::ffff:140.82.113.22 (1 ms)
- Proxy URL: None (0 ms)
- Electron fetch (configured): HTTP 200 (428 ms)
- Node.js https: HTTP 200 (424 ms)
- Node.js fetch: HTTP 200 (440 ms)

## Documentation

In corporate networks: [Troubleshooting firewall settings for GitHub Copilot](https://docs.github.com/en/copilot/troubleshooting-github-copilot/troubleshooting-firewall-settings-for-github-copilot).