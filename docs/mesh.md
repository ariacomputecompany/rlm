# RLM Mesh

RLM mesh is the Quilt-native multi-agent extension for RLM workflows.

It keeps the single-agent path simple while making coordinated isolated execution a first-class production mode.

## Topology

Each mesh session includes:

- one coordinator
- one or more workers
- one shared volume
- one mesh manifest
- one JETS namespace

## Planes

### Shared Data Plane

All agents mount the same shared workspace volume at:

```text
/workspace
```

### Communication Plane

Agents discover peers through stable ICC DNS aliases and exchange envelopes through JETS.

### Execution Plane

Each agent runs in its own isolated container runtime.

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

## Routing

Each agent has:

- `agent_id`
- `dns_alias`
- `jets_inbox`

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
