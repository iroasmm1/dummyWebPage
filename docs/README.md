# PSD2 Testing Application - Authorization Gateway

This GitHub Pages site serves as the OAuth callback endpoint for the PSD2 Testing Application.

## Usage

### Callback URL
```
https://YOUR-USERNAME.github.io/PSD2TestingApplication/callback.html?code={authorization_code}
```

### Deep Link Integration
When accessed, the page will attempt to open the PSD2 Banking app with the custom URL scheme:
```
psd2banking://callback?code={authorization_code}
```

## Deployment

1. Push this repository to GitHub
2. Go to repository Settings → Pages
3. Set source to `main` branch and `/docs` folder
4. Your site will be available at: `https://YOUR-USERNAME.github.io/PSD2TestingApplication/`

## Universal Links (Optional)

For universal links to work, you need to:
1. Add Associated Domains capability in Xcode
2. Add domain: `applinks:YOUR-USERNAME.github.io`
3. Rebuild the app

The `apple-app-site-association` file is included in `.well-known/` directory.
