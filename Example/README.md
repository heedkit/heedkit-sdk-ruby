# FeatureKit Ruby SDK — Example

A runnable, server-side demo that drives the full FeatureKit flow against the
**Rails `/sdk` backend** using `FeatureKit::Client` from this repo (depended on
locally via `path: ".."`, not the published gem).

It walks through:

1. Configure the client (project key + Rails endpoint)
2. Fetch the public **roadmap** and **changelog** (typed objects)
3. **Identify** an end-user — `POST /sdk/init`
4. **List** features — `GET /sdk/features`
5. **Submit** a feature — `POST /sdk/features`
6. **Vote** (toggle) — `POST /sdk/features/:id/vote`
7. **Comment** — `POST /sdk/features/:id/comments`

## Prerequisites

- Ruby >= 3.1 and Bundler.
- The FeatureKit Rails app running locally:

  ```sh
  cd featurekit-rails
  bin/dev            # serves on port 3000
  ```

- A **project key** (public key, `pk_...`). Get one from the Rails console
  Install page, or from `db/seeds` (the seeded `featurekit` / `demo` workspace).
  Never hardcode a real key into source.

## Run

From this `Example/` directory:

```sh
bundle install
FEATUREKIT_PROJECT_KEY=pk_your_real_key bundle exec ruby demo.rb
```

`FEATUREKIT_ENDPOINT` is optional and defaults to `http://127.0.0.1:3000`.

```sh
FEATUREKIT_PROJECT_KEY=pk_... \
FEATUREKIT_ENDPOINT=http://127.0.0.1:3000 \
bundle exec ruby demo.rb
```

## Endpoint / host notes

Auth is the header `X-Project-Key: <publicKey>` on every request — the SDK adds
it for you. Pick the endpoint host for your environment:

| Environment                    | Endpoint                          |
| ------------------------------ | --------------------------------- |
| Non-browser / native (this CLI)| `http://127.0.0.1:3000`           |
| Browser code                   | `http://featurekit.localhost:3000`|
| Android emulator               | `http://10.0.2.2:3000`            |
| iOS simulator                  | `http://localhost:3000`           |

This demo is a plain Ruby process (non-browser), so it defaults to
`http://127.0.0.1:3000`. The Rails apex route matches any `Host`.

## How it maps to the SDK

Every step uses a real method on `FeatureKit::Client`
(see `../lib/featurekit/client.rb`):

| Step      | SDK method                                  | Rails endpoint                     |
| --------- | ------------------------------------------- | ---------------------------------- |
| roadmap   | `client.roadmap`                            | `GET /public/projects/:key/roadmap`|
| changelog | `client.changelog`                          | `GET /public/.../changelog`        |
| identify  | `client.identify(...)`                      | `POST /sdk/init`                   |
| list      | `client.features(end_user_id:, sort:)`      | `GET /sdk/features`                |
| submit    | `client.submit(end_user_id:, title:, ...)`  | `POST /sdk/features`               |
| vote      | `client.vote(id, end_user_id:)`             | `POST /sdk/features/:id/vote`      |
| comment   | `client.comment(id, end_user_id:, body:)`   | `POST /sdk/features/:id/comments`  |

All methods raise `FeatureKit::Error` on a non-2xx response or transport
failure; the demo rescues it and prints a hint.
