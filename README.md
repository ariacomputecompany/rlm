# RLM

`RLM` is Quilt's protocol and helper contract for running Recursive Language Model workflows inside isolated remote environments.

It defines two production surfaces:

- `quilt-nightly --rlm` for a zero-friction single-agent RLM runner
- `quilt-nightly --rlm-mesh` for a Quilt-native multi-agent extension built on ICC and JETS

This repository does not replace upstream RLM research or inference code. It defines the production environment contract that lets Quilt host RLM workflows safely, repeatably, and with persistent session state.

The core design rule is strict environment locality:

- the REPL acts only on the filesystem that exists inside the Quilt environment
- admitted context must be present inside that environment before execution begins
- local files become RLM context only after explicit sync into `/workspace`
- the protocol does not assume implicit access to the caller's laptop, editor state, or host filesystem

## Scope

RLM in this repository is about:

- remote isolated execution
- environment-local REPL semantics
- explicit context admission into the workspace
- workspace and artifact persistence
- trajectory and session manifests
- helper CLI behavior inside the environment
- mesh topology and coordination contracts
- Nightly launcher integration points

RLM in this repository is not:

- a reimplementation of upstream `rlms`
- a generic model provider SDK
- a replacement for Quilt runtime, ICC, or JETS

## Product Model

There are two supported execution modes.

### `--rlm`

Single-agent RLM mode provides:

- one remote Python and RLM environment
- optional local context sync into `/workspace`
- named session reuse
- persistent trajectories, artifacts, and workspace state
- built-in accelerator scaffolding so the same session shape can run with or without GPU passthrough
- no Quilt-specific RLM code required for the happy path

### `--rlm-mesh`

Mesh mode provides:

- one coordinator container plus N worker containers
- one shared workspace volume
- one isolated runtime per agent
- stable ICC DNS aliases for peer discovery
- JETS inbox, publish, ack, and replay semantics for coordination
- resumable session state and inspectable message history
- the same accelerator contract per agent when GPU-backed execution is needed

## Why Quilt

Upstream RLM is Python-first and deliberately lightweight. That is the right starting point for broad adoption.

Quilt adds the production environment boundary around that workflow:

- isolated remote execution
- clean session reuse
- persistent workspace and trajectory storage
- volume-backed shared data
- container-scoped or session-scoped credentials
- optional GPU-capable runtime attachment through the existing Quilt accelerator surface
- ICC and JETS for multi-agent coordination

That is the intended split:

- plain RLM should work immediately
- Quilt mesh is the beyond-Docker mode

## Upstream RLM References

- upstream repo: [alexzhang13/rlm](https://github.com/alexzhang13/rlm)
- documentation: [alexzhang13.github.io/rlm](https://alexzhang13.github.io/rlm/)
- launch essay: [Recursive Language Models blog post](https://alexzhang13.github.io/blog/2025/rlm/)
- paper: [arXiv:2512.24601](https://arxiv.org/abs/2512.24601)

## Helper Contract

The environment exposes a single helper CLI:

- `quilt-rlm doctor`
- `quilt-rlm run`
- `quilt-rlm shell`
- `quilt-rlm examples`
- `quilt-rlm trajectories ls`
- `quilt-rlm trajectories show`
- `quilt-rlm trajectories export`

The helper standardizes:

- workspace location
- trajectory layout
- session manifest format
- provider env forwarding
- accelerator metadata exposure
- mesh bootstrap configuration

## Workspace Layout

The canonical in-container workspace root is:

```text
/workspace
```

The canonical RLM state root is:

```text
/workspace/.quilt/rlm
```

Subdirectories:

- `/workspace/.quilt/rlm/sessions`
- `/workspace/.quilt/rlm/trajectories`
- `/workspace/.quilt/rlm/artifacts`
- `/workspace/.quilt/rlm/manifests`
- `/workspace/.quilt/rlm/mesh`

Only content inside `/workspace` is in scope for RLM execution. If the user wants local files available to the model, `quilt-nightly` must sync them into `/workspace` first.

## Environment Shape

The base `--rlm` environment is expected to include:

- Python 3.11+
- `uv`
- upstream `rlms`
- `quilt-rlm`
- common shell and runtime tools

The contract assumes GPU-capable launch scaffolding is available through Quilt when requested. Users should not need a separate RLM-specific accelerator workflow to opt in.

The launcher may forward provider credentials through an allowlist such as:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `OPENROUTER_API_KEY`
- `PORTKEY_API_KEY`

Provider credentials let the environment call model backends. They do not expand the RLM context boundary beyond the environment-local workspace and persisted artifacts.

## Protocol Documents

- [Protocol v1](./docs/protocol-v1.md)
- [Nightly Integration](./docs/nightly-integration.md)
- [Mesh Semantics](./docs/mesh.md)

## Schemas

- [session-manifest.v1.schema.json](./schemas/session-manifest.v1.schema.json)
- [trajectory-manifest.v1.schema.json](./schemas/trajectory-manifest.v1.schema.json)
- [mesh-manifest.v1.schema.json](./schemas/mesh-manifest.v1.schema.json)
- [agent-config.v1.schema.json](./schemas/agent-config.v1.schema.json)
- [jets-envelope.v1.schema.json](./schemas/jets-envelope.v1.schema.json)

## Examples

- [single-agent session manifest](./examples/session-manifest.v1.json)
- [trajectory manifest](./examples/trajectory-manifest.v1.json)
- [mesh manifest](./examples/mesh-manifest.v1.json)
- [agent config](./examples/agent-config.v1.json)
- [JETS envelope](./examples/jets-envelope.v1.json)

## Verification

Validate example manifests against the published schemas:

```bash
./scripts/validate-examples.sh
```

## Relationship To Quilt Nightly

RLM is typically entered through `quilt-nightly`, which owns:

- profile selection
- image selection
- named session reuse
- archive sync
- terminal attach
- mesh container creation
- scoped credential injection

This repository defines the contract that `quilt-nightly` and the in-environment helper must both honor.
