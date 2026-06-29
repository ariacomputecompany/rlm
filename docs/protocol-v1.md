# RLM Protocol v1

RLM Protocol v1 defines the stable contract between:

- `quilt-nightly`
- the in-environment `quilt-rlm` helper
- persistent manifests and trajectory artifacts
- optional mesh coordinator and worker runtimes

## Version

```text
rlm_protocol_version = 1
```

Every persisted manifest in this repository uses:

```json
{
  "protocol": {
    "name": "rlm",
    "version": 1
  }
}
```

## Execution Modes

Allowed `mode` values:

- `single_agent`
- `mesh_coordinator`
- `mesh_worker`

## Single-Agent Contract

Single-agent mode guarantees:

- one isolated container
- one canonical workspace at `/workspace`
- one environment-local REPL boundary
- one helper CLI surface
- one session manifest
- one stable accelerator contract whether or not a GPU is attached
- trajectory persistence under `/workspace/.quilt/rlm/trajectories`

Expected launch patterns:

```bash
npx quilt-nightly --rlm
npx quilt-nightly --rlm -- quilt-rlm run --script app.py
npx quilt-nightly --rlm -- quilt-rlm run --prompt-file prompt.txt
npx quilt-nightly --rlm -- python script.py
```

## Execution Boundary

RLM Protocol v1 is intentionally strict about where execution can read context from.

Required boundary rules:

- the helper executes inside one Quilt-managed environment
- the REPL may act only on files and directories available inside that environment
- the canonical admitted context root is `/workspace`
- any caller-local context must be synced into `/workspace` before RLM execution begins
- the helper must not depend on implicit access to host-local files, editor buffers, or shell state outside the environment

The protocol names this boundary with a machine-readable `execution_boundary` object.

## Accelerator Contract

RLM Protocol v1 is GPU-ready by default.

That means:

- the protocol always reserves manifest space for accelerator metadata
- users opt into GPU-backed execution through the existing Quilt accelerator surface
- RLM does not introduce a separate GPU control plane or alternate execution model
- helper behavior stays structurally the same whether the session is CPU-only or GPU-backed

The session and mesh manifests record this through a machine-readable `accelerator` object.

## Session Identity

A session is identified by:

- `session_id`
- optional `session_name`
- `container_id`
- `workspace_root`
- `created_at`
- `updated_at`

The session manifest also records the execution boundary and admitted context roots for that session.
It also records accelerator capability and attachment state for that session.

`session_name` is the reuse key for named Nightly launches.

## Trajectory Contract

Each trajectory has:

- `trajectory_id`
- `session_id`
- `entrypoint`
- `provider`
- `model`
- `environment`
- `accelerator_mode`
- `status`
- `context_paths`
- `artifact_paths`
- `started_at`
- `finished_at`

Allowed `status` values:

- `running`
- `completed`
- `failed`
- `cancelled`

## Artifact Contract

Artifacts are stored under:

```text
/workspace/.quilt/rlm/artifacts/<trajectory_id>/
```

The manifest may reference:

- stdout capture
- stderr capture
- prompt files
- context files
- exported trajectories
- model responses
- mesh coordination logs

All artifact and context paths must resolve inside the admitted context roots recorded for the session or mesh.

## Environment Contract

The helper must tolerate the following environment variables when present:

- `RLM_SESSION_ID`
- `RLM_SESSION_NAME`
- `RLM_PROTOCOL_VERSION`
- `RLM_WORKSPACE_ROOT`
- `RLM_STATE_ROOT`
- `RLM_TRAJECTORY_ROOT`
- `RLM_ARTIFACT_ROOT`
- `RLM_MESH_MODE`
- `RLM_AGENT_ID`
- `RLM_AGENT_ROLE`
- `RLM_COORDINATOR_ALIAS`
- `RLM_JETS_NAMESPACE`
- `RLM_JETS_INBOX`
- `RLM_JETS_DLQ`
- `RLM_GPU_ENABLED`
- `RLM_GPU_PROVIDER`

## Path Contract

Canonical paths:

- workspace root: `/workspace`
- state root: `/workspace/.quilt/rlm`
- session manifests: `/workspace/.quilt/rlm/sessions`
- trajectory manifests: `/workspace/.quilt/rlm/trajectories`
- artifacts: `/workspace/.quilt/rlm/artifacts`
- mesh configs: `/workspace/.quilt/rlm/mesh`

Path enforcement rules:

- helpers must reject `..` traversal that escapes admitted roots
- helpers must reject absolute context paths outside the admitted roots
- synced context becomes in-scope only after it lands under `/workspace`
- mesh workers inherit the same workspace-root confinement as the coordinator

## Mesh Contract

Mesh mode guarantees:

- one coordinator
- one or more workers
- one shared volume mounted at `/workspace`
- one shared execution boundary across all agents
- one stable accelerator contract per agent
- one mesh manifest
- one agent config file per agent
- one ICC alias per agent
- one JETS namespace per mesh session

Coordinator responsibilities:

- accept terminal attach by default
- own top-level session manifest updates
- publish task envelopes
- observe worker acknowledgements and completions

Worker responsibilities:

- consume assigned tasks
- persist local trajectory state
- publish status, ack, and result envelopes

Workers must not assume access to context outside the shared workspace or their own in-environment state.
Workers must also derive accelerator availability from injected manifest and environment metadata, not from ad hoc device probing assumptions alone.

## JETS Envelope Contract

The canonical message envelope fields are:

- `message_id`
- `mesh_id`
- `session_id`
- `from_agent_id`
- `to_agent_id`
- `topic`
- `kind`
- `payload`
- `created_at`
- `requires_ack`

Allowed `kind` values:

- `task`
- `result`
- `status`
- `control`
- `artifact`

## Stability Rules

Production stability rules:

- manifest fields are append-only within a protocol major version
- meaning of existing fields cannot drift within a protocol major version
- path roots remain stable across helper releases unless the protocol major version changes
- mesh routing identifiers remain stable for the life of a session
- execution-boundary semantics cannot loosen within a protocol major version
