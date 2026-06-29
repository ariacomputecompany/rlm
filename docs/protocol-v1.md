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
- one helper CLI surface
- one session manifest
- trajectory persistence under `/workspace/.quilt/rlm/trajectories`

Expected launch patterns:

```bash
npx quilt-nightly --rlm
npx quilt-nightly --rlm -- quilt-rlm run --script app.py
npx quilt-nightly --rlm -- quilt-rlm run --prompt-file prompt.txt
npx quilt-nightly --rlm -- python script.py
```

## Session Identity

A session is identified by:

- `session_id`
- optional `session_name`
- `container_id`
- `workspace_root`
- `created_at`
- `updated_at`

`session_name` is the reuse key for named Nightly launches.

## Trajectory Contract

Each trajectory has:

- `trajectory_id`
- `session_id`
- `entrypoint`
- `provider`
- `model`
- `environment`
- `status`
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

## Path Contract

Canonical paths:

- workspace root: `/workspace`
- state root: `/workspace/.quilt/rlm`
- session manifests: `/workspace/.quilt/rlm/sessions`
- trajectory manifests: `/workspace/.quilt/rlm/trajectories`
- artifacts: `/workspace/.quilt/rlm/artifacts`
- mesh configs: `/workspace/.quilt/rlm/mesh`

## Mesh Contract

Mesh mode guarantees:

- one coordinator
- one or more workers
- one shared volume mounted at `/workspace`
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
