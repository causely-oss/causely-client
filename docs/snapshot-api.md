# Snapshots

Causely provides the capability to capture and store the state of your environment for a given timeframe. Users can 
provide a name, description, and tags to each snapshot to conveniently organize, identify, and retrieve them for later
use.
Snapshots can then be compared with one another, providing a way to readily assess the health and stability of the 
environment given changes to the underlying systems and/or behavior over time. The Causely snapshot comparison aims to 


Some example use cases:

## Shift Left

Teams which utilize staging and/or test environments for pending release candidates can leverage the Causely snapshot 
and comparison feature to confidently make informed decisions around their release cycles. For example, by creating 
snapshots routinely, teams can compare their current release candidate with the snapshot for the previous release.
By creating snapshots over the duration of a system load test, you can compare how a pending release-candidate for this
week may have improved or degraded compared to the previous release candidate. This type of comparison enables teams to 
make decisions about whether to move ahead with the rollout of the release or to withhold it while necessary changes are 
made to remediate newly identified problems.

## Release Confidence

One may opt to take a snapshot of their environment for some duration of time prior to a release and another snapshot 
for some (presumably the equivalent) duration after release. This type of comparison can provide insights about whether 
the newly released changes are stable or identify signs of regressions which may need to be remediated right away.


# Snapshot Comparisons

Users can select 2 previously generated Snapshots and compare them against one another. Additionally, the comparison 
supports the Causely scoping functionality, allowing the user to focus the comparison to a specified subset of the overall
environment which is relevant to their concerns - such as a specific cluster, namespace, or team area. 

The comparison results provide the user with the information required to make informed decisions and assessments about 
the behavior and stability of their environment with respect to underlying changes. The comparison aims to answer the 
following questions:

- Can I feel confident that the later version is stable, or should it be rejected/revised to remediate serious problems?
- Are there any new Errors/Malfunctions? Have previous root causes been remediated?
- Is there increased Latency/Congestion?
- Am I using more or fewer Resources (e.g. CPU and Memory)?

---

# Snapshot API Documentation

## Overview

The Snapshot API provides endpoints for creating snapshots of your system state and comparing snapshots to identify changes in entities, defects, resources, and services.

## Table of Contents

- [Authentication](#authentication)
- [Endpoints](#endpoints)
  - [createSnapshot](#createsnapshot)
  - [compareSnapshots](#comparesnapshots)
- [Example Scripts](#example-scripts)
  - [Python](#python-examples)
  - [Bash](#bash-examples)
  - [Node.js](#nodejs-examples)

## Authentication

All API requests use GraphQL and require authentication using a JWT token. Include the token in the `Authorization` header:

```
Authorization: Bearer <YOUR_JWT_TOKEN>
```

Retrieving your JWT token requires authenticating against frontegg. For the purpose of scripting it is suggested to create
a dedicated frontegg API Token and using the resulting `client_id` and `client_secret` to retrieve a valid JWT token.

### Creating API Token (frontegg)

1. Login to [Causely](https://portal.causely.app/)
2. At the top right of the screen, open User Settings by clicking on the bubble icon (showing your user initials)
3. Click `Admin Portal` which opens a new tab to your frontegg account dashboard
4. At bottom of left menu select `API Tokens`
5. Click button `Generate Token`
6. Fill in `description` (name), set `Role` = "Admin", etc... finally, click `Create`
7. Copy and save the `Client ID` and `Client Secret` (this is the only time it will be available to do so!)
8. Ideally, save those credentials to an appropriate secrets/vault for secure retrieval later

## Endpoints

### createSnapshot

Creates a new snapshot of the system state for a specified time range.

#### GraphQL Mutation

```graphql
mutation CreateSnapshot($options: SnapshotOptionsInput) {
  createSnapshot(options: $options) {
    id
    name
    description
    createdAt
    startTime
    endTime
  }
}
```

#### Input Parameters

**SnapshotOptionsInput**

| Field         | Type            | Required | Default           | Description                                                               |
|---------------|-----------------|----------|-------------------|---------------------------------------------------------------------------|
| `name`        | String          | Yes      | N/A - must be set | Name of the snapshot                                                      |
| `description` | String          | Yes      | N/A - must be set | Description of the snapshot                                               |
| `tags`        | [TagEntryInput] | No       | Empty             | Array of key-value tag pairs                                              |
| `startTime`   | Time            | No       | -2 hours          | Start time of the snapshot period (YYYY-MM-DDTHH:MM:SSZ - RFC3339 format) |
| `endTime`     | Time            | No       | now               | End time of the snapshot period (defaults to current time)                |

**TagEntryInput**

| Field   | Type   | Required | Description |
|---------|--------|----------|-------------|
| `key`   | String | Yes      | Tag key     |
| `value` | String | Yes      | Tag value   |

#### Response

Returns a `Snapshot` object:

```graphql
type Snapshot {
  id: String!
  name: String!
  description: String!
  tags: [TagEntry]
  createdAt: Time!
  startTime: Time!
  endTime: Time!
}
```

#### Example Request

```graphql
mutation {
  createSnapshot(options: {
    name: "Production v1.2.3"
    description: "Automated snapshot for v1.2.3"
    startTime: "2025-10-20T10:00:00Z"
    endTime: "2025-10-20T11:00:00Z"
    tags: [
      { key: "environment", value: "production" }
      { key: "version", value: "1.2.3" }
      { key: "load test", value: "100K Users"}
    ]
  }) {
    id
    name
    description
    tags { key, value}
    createdAt
    startTime
    endTime
  }
}
```

#### Example Response

```json
{
  "data": {
    "createSnapshot": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Production Baseline",
      "description": "Baseline snapshot before deployment",
      "tags": [
        { "key": "environment", "value": "production" },
        { "key": "version", "value": "1.2.3" },
        { "key": "load test", "value": "100K Users"}
      ],
      "createdAt": "2025-10-20T10:05:00Z",
      "startTime": "2025-10-20T10:00:00Z",
      "endTime": "2025-10-20T11:00:00Z"
    }
  }
}
```

---

### compareSnapshots

Compare two snapshots, and optionally provide a Causely scope, to return the comparison findings.

#### GraphQL Query

```graphql
query CompareSnapshots($input: CompareSnapshotsInput!) {
  compareSnapshots(input: $input) {
    comparisonMetadata {
      snapshotIds
      comparisonDate
      totalSnapshots
      timespanCovered
      comparisonDuration
      snapshotsInfo {
        id
        name
        description
        startTime
        endTime
        version
      }
      scopeInfo {
        scopeId
        scopeName
      }
    }
    comparisonDiffs {
      comparisonId
      snapshotId1
      snapshotId2
      assessment
      entityDiff {
        stableCount
        beforeOnlyCount
        afterOnlyCount
        both {
          id
          typeName
          name
        }
        beforeOnly {
          id
          typeName
          name
        }
        afterOnly {
          id
          typeName
          name
        }
      }
      defectDiff {
        totalNewCount
        totalClearedCount
        newDefectsByEntityTypes {
          entityType
          defectName
          totalCount
          defects {
            id
            name
            entityType
            entityName
            defect {
              id
              name
              severity
              active
            }
          }
        }
        clearedDefectsByEntityTypes {
          entityType
          defectName
          totalCount
          defects {
            id
            name
            entityType
            entityName
          }
        }
        countsByEntityType {
          entityType
          count
        }
        countsByDefectType {
          defectType
          count
        }
      }
      resourceSummary {
        entityCountChange
        before {
          snapshotId
          entityCount
          maxCPUUtilization
          avgCPUUtilization
          maxMemoryUtilization
          avgMemoryUtilization
        }
        after {
          snapshotId
          entityCount
          maxCPUUtilization
          avgCPUUtilization
          maxMemoryUtilization
          avgMemoryUtilization
        }
        changes {
          metricName
          changeValue
          changePercent
          beforeValue
          afterValue
          entityType
          unit
          aggregateType
        }
      }
      serviceSummary {
        entityCountChange
        before {
          snapshotId
          entityCount
          requestsTotal
          requestRate
          requestDuration
          requestErrorRate
          networkReceiveThroughput
          networkTransmitThroughput
        }
        after {
          snapshotId
          entityCount
          requestsTotal
          requestRate
          requestDuration
          requestErrorRate
          networkReceiveThroughput
          networkTransmitThroughput
        }
        changes {
          metricName
          changeValue
          changePercent
          beforeValue
          afterValue
          entityType
          unit
          aggregateType
        }
      }
    }
  }
}
```

#### Input Parameters

**CompareSnapshotsInput**

| Field          | Type              | Required | Description                                   |
|----------------|-------------------|----------|-----------------------------------------------|
| `snapshotIds`  | [String!]!        | Yes      | Array of snapshot IDs to compare (2 or more)  |
| `userScopeId`  | String            | No       | ID of a saved user scope to filter comparison |
| `scopesFilter` | ScopesFilterInput | No       | Custom scope filter for comparison            |

**Note:** Either `userScopeId` OR `scopesFilter` can be provided, not both.

**ScopesFilterInput**

| Field    | Type           | Required | Description            |
|----------|----------------|----------|------------------------|
| `scopes` | [ScopeInput!]! | Yes      | Array of scope filters |

**ScopeInput**

| Field        | Type       | Required | Description                                  |
|--------------|------------|----------|----------------------------------------------|
| `typeName`   | String     | Yes      | Entity type name (e.g., "Service", "Pod")    |
| `typeValues` | [String!]! | Yes      | Specific entity names to include             |
| `nameExpr`   | String     | No       | Regular expression for entity name filtering |
| `exclude`    | Boolean    | No       | Whether to exclude matching entities         |

#### Response

Returns a `SnapshotComparisonResult` object with detailed comparison information including:

- **comparisonMetadata**: Overall comparison information
- **comparisonDiffs**: Array of pairwise comparisons between snapshots containing:
  - **entityDiff**: Changes in entities (added, removed, stable)
  - **defectDiff**: Changes in defects (new, cleared)
  - **resourceSummary**: Changes in resource metrics (CPU, memory)
  - **serviceSummary**: Changes in service metrics (requests, latency, errors)
  - **assessment**: Overall assessment (ACCEPTED or REJECTED)

#### Example Request

```graphql
query {
  compareSnapshots(input: {
    snapshotIds: [
      "550e8400-e29b-41d4-a716-446655440000",
      "660f9511-f30c-52e5-b827-557766551111"
    ]
  }) {
    comparisonMetadata {
      snapshotIds
      totalSnapshots
      timespanCovered
      snapshotsInfo {
        id
        name
        startTime
        endTime
      }
    }
    comparisonDiffs {
      snapshotId1
      snapshotId2
      assessment
      entityDiff {
        stableCount
        beforeOnlyCount
        afterOnlyCount
      }
      defectDiff {
        totalNewCount
        totalClearedCount
      }
      resourceSummary {
        before {
          avgCPUUtilization
          avgMemoryUtilization
        }
        after {
          avgCPUUtilization
          avgMemoryUtilization
        }
      }
    }
  }
}
```

#### Example Request with Scope Filter

```graphql
query {
  compareSnapshots(input: {
    snapshotIds: [
      "550e8400-e29b-41d4-a716-446655440000",
      "660f9511-f30c-52e5-b827-557766551111"
    ]
    scopesFilter: {
      scopes: [
        {
          typeName: "Service"
          typeValues: ["frontend", "backend", "database"]
        }
        {
          typeName: "Namespace"
          typeValues: ["production"]
        }
      ]
    }
  }) {
    comparisonMetadata {
      snapshotIds
      scopeInfo {
        scopeName
      }
    }
    comparisonDiffs {
      assessment
      defectDiff {
        totalNewCount
        totalClearedCount
      }
    }
  }
}
```

## Example Scripts

### Python Examples

See the example scripts in the `examples/python/` directory:
- `create_snapshot.py` - Create a new snapshot
- `compare_snapshots.py` - Compare multiple snapshots
- `snapshot_workflow.py` - Complete workflow example

### Bash Examples

See the example scripts in the `examples/bash/` directory:
- `create_snapshot.sh` - Create a new snapshot using curl
- `compare_snapshots.sh` - Compare multiple snapshots using curl

### Node.js Examples

See the example scripts in the `examples/nodejs/` directory:
- `create_snapshot.js` - Create a new snapshot
- `compare_snapshots.js` - Compare multiple snapshots
- `snapshot_workflow.js` - Complete workflow example

## Common Use Cases

### 1. Pre/Post Deployment Comparison

Create snapshots before and after deployments to identify:
- New defects introduced
- Changes in resource utilization
- Service performance degradation
- Entity changes (added/removed services)

```
1. Create "before" snapshot
2. Perform deployment
3. Wait desired length of time (up to 2 hours) then Create "after" snapshot
4. Compare snapshots
5. Review assessment (ACCEPTED/REJECTED)
```

### 2. Performance Testing Baseline

Establish performance baselines and compare test runs:

```
1. Create baseline snapshot during normal operation
2. Create snapshot during load test
3. Compare to identify performance impacts
4. Review resource and service metric changes
```

### 3. Environment Drift Detection

Compare production and staging environments:

```
1. Create snapshot in production
2. Create snapshot in staging
3. Compare with scope filter for specific services
4. Identify configuration or behavior differences
```

## Assessment Criteria

The comparison assessment (ACCEPTED/REJECTED) is based on:

- **New defects**: Significant increase in defects results in REJECTED
- **Resource changes**: Large increases in CPU/memory utilization may trigger REJECTED
- **Service degradation**: Increased error rates or latency may result in REJECTED
- **Entity stability**: Large numbers of removed entities may indicate issues

## Tips and Best Practices

1. **Time Range Selection**: Choose snapshot time ranges that represent steady-state behavior
2. **Scope Filtering**: Use scopes to focus comparisons on relevant parts of your system
3. **Tagging**: Use tags to organize snapshots by environment, version, or test type
4. **Baseline Snapshots**: Create regular baseline snapshots during known-good states
5. **Automation**: Integrate snapshot creation/comparison into CI/CD pipelines
