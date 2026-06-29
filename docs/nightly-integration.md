# Quilt Nightly Integration

`quilt-nightly` is the launcher layer for RLM.

This document defines what Nightly owns and what the in-environment helper owns.

## Launcher-Owned Behavior

Nightly owns:

- profile flag parsing
- image selection
- OCI preload
- named session reuse
- container creation
- local context sync
- volume attachment
- provider env forwarding
- terminal attach
- mesh topology creation
- scoped credential injection

## Supported Launcher Modes

Nightly must support:

- `--rlm`
- `--rlm-mesh`

## `--rlm` Launch Semantics

Single-agent launch must support:

- no-argument interactive shell entry
- passthrough commands after `--`
- optional `--sync <path>`
- optional `--name <session>`
- optional `--keep`
- optional `--mount-volume <name>`
- optional `--env-forward <NAME[,NAME...]>`

Examples:

```bash
npx quilt-nightly --rlm
npx quilt-nightly --rlm -- quilt-rlm run --script app.py
npx quilt-nightly --rlm -- python script.py
```

## `--rlm-mesh` Launch Semantics

Mesh launch must support:

- one coordinator container
- N worker containers
- one shared workspace volume
- one generated mesh manifest
- one stable ICC alias per agent
- one resumable mesh session identity

The coordinator must receive terminal attach by default.

## Sync Contract

When `--sync <path>` is supplied, Nightly must:

- archive local content
- upload it into `/workspace`
- preserve file paths relative to the synced root

## Env Forwarding Contract

Nightly must forward only allowlisted provider keys and runtime metadata.

It must not blindly forward the caller's full environment.

## Session Reuse

Named session reuse must preserve:

- workspace contents
- trajectory manifests
- artifact directories
- session identity

## Mesh Bootstrap

For mesh mode, Nightly must inject:

- mesh id
- session id
- agent id
- agent role
- coordinator alias
- JETS namespace and routing identifiers
- scoped runtime credential material

## Relationship To Quilt Runtime

Nightly relies on Quilt for:

- container lifecycle
- archive upload
- terminal attach
- volumes
- ICC DNS
- JETS messaging
- scoped credentials

Nightly should not reimplement those platform concerns inside the helper.
