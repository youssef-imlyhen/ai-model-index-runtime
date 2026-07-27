# AI Model Index Runtime

Runtime-only publisher for the private `ai-model-index` application.

This repository intentionally contains **no application source**. A GitHub Actions workflow checks out the private source through a read-only deploy key, builds the production Wasp server and React client, and publishes an immutable runtime image to GHCR for deployment.

The public image contains deployable build output only. Source development remains in the private application repository.
