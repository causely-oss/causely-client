# Snapshot API Reference

Complete GraphQL API documentation for the Causely Snapshot API.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Endpoints](#endpoints)
  - [createSnapshot](#createsnapshot)
  - [getSnapshot](#getsnapshot)
  - [getSnapshots](#getsnapshots)
  - [getSnapshotsPaginated](#getsnapshotspaginated)
  - [getUserScopes](#getuserscopes)
  - [compareSnapshots](#comparesnapshots)
- [Snapshot Processing](#snapshot-processing)
- [Common Use Cases](#common-use-cases)
- [Assessment Criteria](#assessment-criteria)
- [Best Practices](#best-practices)

## Overview

The Snapshot API provides endpoints for creating snapshots of your system state and comparing snapshots to identify changes in entities, defects, resources, and services.

**Key Concepts:**
- **Snapshots**: Capture system state over a time window
- **Comparisons**: Analyze differences between snapshots
- **Assessment**: Automated ACCEPTED/REJECTED evaluation
- **Scopes**: Filter comparisons to specific parts of your environment

## Authentication

All API requests use GraphQL and require authentication using a JWT token. Include the token in the `Authorization` header:

```
Authorization: Bearer <YOUR_JWT_TOKEN>
```

### Creating Frontegg API Token

1. Login to [Causely Portal](https://portal.causely.app/)
2. At the top right, open **User Settings** (bubble icon with your initials)
3. Click **Admin Portal** (opens new tab)
4. Navigate to **API Tokens** (bottom of left menu)
5. Click **Generate Token**
6. Fill in description, set `Role` = "Admin", click **Create**
7. **Save the Client ID and Client Secret** (shown only once!)

For detailed authentication setup, see the [Authentication Guide](04-authentication.md).

## Endpoints

### createSnapshot

Creates a new snapshot of the system state for a specified time range.

**Important:** This mutation returns immediately with `id`, `name`, and `status` fields. Snapshot processing happens asynchronously in the background (see [Snapshot Processing](#snapshot-processing)).

#### GraphQL Mutation

```graphql
mutation CreateSnapshot($options: SnapshotOptionsInput!) {
  createSnapshot(options: $options) {
    id
    name
    description
    status
    tags {
      key
      value
    }
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
| `name`        | String          | Yes      | N/A               | Name of the snapshot                                                      |
| `description` | String          | Yes      | N/A               | Description of the snapshot                                               |
| `tags`        | [TagEntryInput] | No       | Empty             | Array of key-value tag pairs                                              |
| `startTime`   | Time            | No       | -2 hours          | Start time (RFC3339: YYYY-MM-DDTHH:MM:SSZ); Max -2 hours from endTime    |
| `endTime`     | Time            | No       | now               | End time (defaults to current time)                                       |

**TagEntryInput**

| Field   | Type   | Required | Description |
|---------|--------|----------|-------------|
| `key`   | String | Yes      | Tag key     |
| `value` | String | Yes      | Tag value   |

#### Response

Returns a `Snapshot` object with initial status:

```graphql
type Snapshot {
  id: String!
  name: String!
  description: String!
  status: SnapshotStatus!  # PENDING, COMPLETE, or FAILED
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
    ]
  }) {
    id
    name
    status
  }
}
```

---

### getSnapshot

Query a snapshot by ID to check its status and retrieve details.

#### GraphQL Query

```graphql
query GetSnapshot($id: String!) {
  getSnapshot(id: $id) {
    id
    name
    description
    status
    tags {
      key
      value
    }
    createdAt
    startTime
    endTime
  }
}
```

#### Input Parameters

| Field | Type   | Required | Description   |
|-------|--------|----------|---------------|
| `id`  | String | Yes      | Snapshot ID   |

#### Response

Returns a `Snapshot` object with current status.

**Status Values:**
- `PENDING`: Snapshot is being processed
- `COMPLETE`: Snapshot finished successfully
- `FAILED`: Snapshot processing failed

#### Example Request

```graphql
query {
  getSnapshot(id: "550e8400-e29b-41d4-a716-446655440000") {
    id
    name
    status
    createdAt
  }
}
```

---

### getSnapshots

Retrieve a list of all existing snapshots with optional filtering.

#### GraphQL Query

```graphql
query GetSnapshots($filter: SnapshotFilterInput) {
  getSnapshots(filter: $filter) {
    id
    name
    description
    status
    createdAt
    startTime
    endTime
  }
}
```

#### Input Parameters

**SnapshotFilterInput** (Optional)

| Field       | Type   | Required | Description                                    |
|-------------|--------|----------|------------------------------------------------|
| `name`      | String | No       | Filter snapshots by name (exact match)         |
| `startTime` | Time   | No       | Filter snapshots that start after this time    |
| `endTime`   | Time   | No       | Filter snapshots that end before this time     |
| `createdAt` | Time   | No       | Filter snapshots created after this time       |

**Note:** If no filter is provided, returns all snapshots.

---

### getSnapshotsPaginated

Retrieve snapshots with cursor-based pagination support.

#### GraphQL Query

```graphql
query GetSnapshotsPaginated(
  $filter: SnapshotFilterInput
  $first: Int
  $after: String
  $last: Int
  $before: String
) {
  getSnapshotsPaginated(
    filter: $filter
    first: $first
    after: $after
    last: $last
    before: $before
  ) {
    edges {
      node {
        id
        name
        description
        status
        createdAt
        startTime
        endTime
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
  }
}
```

---

### getUserScopes

Retrieve user-defined scopes with pagination support. Scopes are used to filter comparisons to specific parts of your environment.

#### GraphQL Query

```graphql
query GetUserScopes(
  $filter: UserScopeFilter
  $first: Int
  $after: String
  $last: Int
  $before: String
) {
  getUserScopes(
    filter: $filter
    first: $first
    after: $after
    last: $last
    before: $before
  ) {
    totalCount
    edges {
      node {
        id
        name
        audience
        ownerId
        lastUpdate
        scopes {
          typeName
          typeValues
        }
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
      totalCount
    }
  }
}
```

#### Input Parameters

| Field    | Type             | Required | Description                                               |
|----------|------------------|----------|-----------------------------------------------------------|
| `filter` | UserScopeFilter  | No       | Filter criteria for user scopes                           |
| `first`  | Int              | No       | Number of items to return (forward pagination)            |
| `after`  | String           | No       | Cursor to start from (forward pagination)                 |
| `last`   | Int              | No       | Number of items to return (backward pagination)           |
| `before` | String           | No       | Cursor to start from (backward pagination)                 |

**UserScopeFilter**

| Field      | Type    | Required | Description                           |
|------------|---------|----------|---------------------------------------|
| `name`     | String  | No       | Filter by scope name (partial match)  |
| `audience` | String  | No       | Filter by audience type               |
| `ownerId`  | String  | No       | Filter by owner user ID               |

**Note:** Use either (`first` + `after`) for forward pagination OR (`last` + `before`) for backward pagination, not both.

---

### compareSnapshots

Compare two or more snapshots, optionally with a scope filter, to return detailed comparison findings.

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

## Snapshot Processing

**Important:** The `createSnapshot` mutation returns immediately with `id`, `name`, and `status` fields. Snapshot processing happens asynchronously in the background.

### Processing Behavior

1. **Immediate Response**: Returns with `status: PENDING`
2. **Background Processing**: Can take anywhere from a few minutes to 45 minutes depending on environment size
3. **Status Updates**: Use `getSnapshot` query to poll for status changes
4. **Terminal States**: `COMPLETE` (success) or `FAILED` (error)

### Polling for Completion

Use the `getSnapshot` query to check status:

```graphql
query {
  getSnapshot(id: "snapshot-id") {
    id
    name
    status  # PENDING, COMPLETE, or FAILED
  }
}
```

For shell scripts, use the `poll_snapshot_status()` helper function (see [Shell Implementation](05-shell-implementation.md#polling-for-completion)).

## Common Use Cases

### 1. Pre/Post Deployment Comparison

Create snapshots before and after deployments to identify:
- New defects introduced
- Changes in resource utilization
- Service performance degradation
- Entity changes (added/removed services)

**Workflow:**
1. Create "before" snapshot
2. Perform deployment
3. Wait for system stabilization (up to 2 hours)
4. Create "after" snapshot
5. Poll both snapshots until `COMPLETE`
6. Compare snapshots
7. Review assessment (ACCEPTED/REJECTED)

### 2. Performance Testing Baseline

Establish performance baselines and compare test runs:

1. Create baseline snapshot during normal operation
2. Create snapshot during load test
3. Poll until both are `COMPLETE`
4. Compare to identify performance impacts
5. Review resource and service metric changes

### 3. Environment Drift Detection

Compare production and staging environments:

1. Create snapshot in production
2. Create snapshot in staging
3. Poll until both are `COMPLETE`
4. Compare with scope filter for specific services
5. Identify configuration or behavior differences

## Assessment Criteria

The comparison assessment (ACCEPTED/REJECTED) is based on:

**❌ REJECTED** if:
- Significant new defects detected
- Large resource utilization increases
- Service degradation (errors, latency)
- Many entities removed

**✅ ACCEPTED** if:
- No significant issues detected
- Metrics within acceptable ranges
- System remains stable

## Best Practices

1. **Time Range Selection**: Choose snapshot time ranges that represent steady-state behavior
2. **Scope Filtering**: Use scopes to focus comparisons on relevant parts of your system
3. **Tagging**: Use tags to organize snapshots by environment, version, or test type
4. **Baseline Snapshots**: Create regular baseline snapshots during known-good states
5. **Polling**: Always poll for `COMPLETE` status before comparing snapshots
6. **Automation**: Integrate snapshot creation/comparison into CI/CD pipelines

## Related Documentation

- **[Quick Start](02-quick-start.md)** - Quick start guide
- **[Shell Implementation](05-shell-implementation.md)** - GraphQL library functions and helpers
- **[GitHub Actions](06-github-actions.md)** - CI/CD integration examples
- **[Examples](07-examples-and-use-cases.md)** - Real-world examples
