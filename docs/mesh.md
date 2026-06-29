# RLM Mesh

RLM mesh is the Quilt-native multi-agent extension for RLM workflows.

It keeps the single-agent path simple while making coordinated isolated execution a first-class production mode.

## Topology

Each mesh session includes:

- one coordinator
- one or more workers
- one shared volume
- one shared admitted context boundary
- one mesh manifest
- one JETS namespace
- one accelerator contract that can be applied per agent

## Planes

### Shared Data Plane

All agents mount the same shared workspace volume at:

```text
/workspace
```

Only files present inside that workspace are valid shared RLM context for the mesh.

### Communication Plane

Agents discover peers through stable ICC DNS aliases and exchange envelopes through JETS.

### Execution Plane

Each agent runs in its own isolated container runtime.

An agent may run CPU-only or with GPU passthrough, but it keeps the same RLM protocol shape either way.

### Observability Plane

Each agent persists:

- trajectory manifests
- artifact paths
- message history references
- ack and replay state

## Agent Roles

Allowed roles:

- `coordinator`
- `worker`

The coordinator:

- assigns work
- observes worker state
- aggregates results
- owns the top-level mesh manifest

Workers:

- receive task envelopes
- run RLM work
- persist local trajectories
- publish status and result envelopes

The coordinator may assign paths inside the shared workspace, but it must not assign host-local paths or out-of-environment context references.

## Routing

Each agent has:

- `agent_id`
- `dns_alias`
- `jets_inbox`

Agents may also carry per-agent accelerator metadata in the mesh manifest so coordinator logic can schedule GPU-sensitive work explicitly.

Optional routing patterns:

- direct worker targeting
- topic fanout
- coordinator broadcast

## Replay And Recovery

Mesh sessions are resumable when:

- the workspace volume still exists
- the mesh manifest is present
- the agent configs are present
- the JETS history needed for recovery remains available

Recovery should not depend on reconstructing agent topology from container names alone.

Recovery also must not depend on reacquiring context from the caller machine. The resumed mesh session should remain self-contained inside the shared workspace and persisted manifests.
