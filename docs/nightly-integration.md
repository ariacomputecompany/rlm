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
- accelerator request passthrough
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

GPU-backed launch should reuse the standard Quilt accelerator request path rather than inventing a separate RLM-only flag family.

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
- record the admitted in-environment roots in the session manifest

Nightly must not expose unsynced caller-local paths to the helper as if they were valid RLM context.

## Env Forwarding Contract

Nightly must forward only allowlisted provider keys and runtime metadata.

It must not blindly forward the caller's full environment.

Forwarded provider keys are for model access only. They do not change the environment-local context boundary.

## Accelerator Integration Contract

Nightly must treat GPU-backed RLM as the same product surface with additional runtime capability, not as a different execution mode.

That means:

- accelerator opt-in should flow through Quilt's existing GPU request surface
- the launcher should inject the resulting accelerator metadata into manifests and helper env
- helpers should see a stable contract whether no GPU is attached or a compatible GPU is present
- resume flows must preserve the recorded accelerator intent and attachment state

## Session Reuse

Named session reuse must preserve:

- workspace contents
- trajectory manifests
- artifact directories
- session identity
- execution-boundary metadata

## Mesh Bootstrap

For mesh mode, Nightly must inject:

- mesh id
- session id
- agent id
- agent role
- coordinator alias
- JETS namespace and routing identifiers
- scoped runtime credential material
- execution-boundary metadata shared by the mesh
- per-agent accelerator metadata when applicable

## REPL Confinement Contract

Nightly must launch RLM so that the helper and REPL operate on environment-local state only.

That means:

- working context is whatever exists inside `/workspace` and the helper state roots
- user-local files become available only through explicit sync into `/workspace`
- command examples and generated manifests should use in-environment paths, not host-local paths
- resume flows must reuse the existing in-environment workspace instead of trying to reconstruct context from the caller machine

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
