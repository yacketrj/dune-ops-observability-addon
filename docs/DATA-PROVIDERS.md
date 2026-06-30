# Data Provider Strategy

The addon uses a small data provider abstraction between UI components and data sources.

## Supported providers

### `sample`

Used when `web/index.html` is opened directly in a browser.

Purpose:

- local layout work;
- safe preview mode;
- no Console dependency;
- no permissions required.

### `bridge`

Used when the addon is loaded inside Dune Docker Console as an iframe and `window.DuneAddon` is available.

Purpose:

- production/default data path;
- permissioned Console bridge calls;
- server-owner permission review;
- stable addon contract.

## Deliberately not supported yet

### Direct local API provider

The addon should not call raw host-local ports from the browser as its default data path.

Avoid patterns like:

```text
Addon iframe -> browser -> http://localhost:<port>/api
```

Reasons:

- weak permission review;
- brittle port and Docker network assumptions;
- CORS and browser-origin issues;
- harder community review;
- inconsistent behavior across server deployments.

A future local API provider is acceptable only if it is same-origin through Console or another reviewed proxy boundary:

```text
Addon iframe -> Console same-origin endpoint -> internal local service/API
```

That provider must remain optional and read-only until explicitly reviewed.

## Runtime selection

```text
Direct browser open  -> sample provider
Console iframe       -> bridge provider
Future operator mode -> same-origin local API provider, if reviewed
```

The bridge remains the default supported provider.
