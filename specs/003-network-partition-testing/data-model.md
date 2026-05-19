# Data Model: Network Partition Testing for PostgreSQL HA

**Date**: 2026-05-19
**Feature**: 003-network-partition-testing

## Entity: PatroniNode

A PostgreSQL instance managed by Patroni participating in the partition test.

| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | Node identifier (e.g., `patroni1`, `patroni2`, `patroni3`) |
| role | enum | `Leader` or `Replica` |
| state | enum | `running`, `stopped`, `starting` |
| timeline | integer | PostgreSQL timeline ID (increments on promotion) |
| replication_lag_mb | float | Lag behind leader in megabytes |
| rest_api_host | string | IP:port for Patroni REST API (e.g., `10.0.0.11:8008`) |
| patroni_config_path | string | Path to mounted patroni.yml inside container |
| data_checksum | string | MD5 checksum of `partition_test.transactions` on this node |

**Relationships**:
- Belongs to exactly one `PatroniCluster`
- Reads/writes `DcsLease` via etcd REST API
- Replicates from `PatroniNode` where `role = Leader`

## Entity: PatroniCluster

The logical cluster under test.

| Attribute | Type | Description |
|-----------|------|-------------|
| scope | string | Cluster name (e.g., `partition-test`) |
| node_count | integer | Number of Patroni nodes (2 for LAB-13-A, 3 for LAB-13-B) |
| sync_mode | boolean | Whether `synchronous_mode` is enabled |
| sync_mode_strict | boolean | Whether `synchronous_mode_strict` is enabled |
| failsafe_mode | boolean | Whether DCS failsafe mode is enabled |
| ttl | integer | Leader lock TTL in seconds |
| loop_wait | integer | Patroni heartbeat interval |

**Relationships**:
- Contains 2 or 3 `PatroniNode` instances
- Uses exactly one `EtcdCluster` for DCS

## Entity: EtcdCluster

The distributed configuration store providing consensus for leader election.

| Attribute | Type | Description |
|-----------|------|-------------|
| member_count | integer | Number of etcd members (5 for both labs) |
| quorum_size | integer | Majority threshold (`member_count / 2 + 1` = 3) |
| healthy_members | list<string> | List of currently reachable etcd endpoints |
| raft_index | integer | Current Raft log index |

**Relationships**:
- Serves 1 or more `PatroniCluster` instances (namespace isolation via `scope`)

## Entity: DcsLease

The leader lock held in etcd.

| Attribute | Type | Description |
|-----------|------|-------------|
| key | string | etcd key path (e.g., `/service/partition-test/leader`) |
| holder | string | Name of the PatroniNode currently holding the lease |
| ttl | integer | Seconds until lease expires if not renewed |
| acquired_at | timestamp | When the lease was last acquired/renewed |

**Relationships**:
- Held by at most one `PatroniNode` at any time
- Read by all `PatroniNode` instances to determine leader identity

## Entity: NetworkPartition

A simulated network failure injected during the test.

| Attribute | Type | Description |
|-----------|------|-------------|
| type | enum | `clean_stop`, `full_partition`, `asymmetric_partition` |
| source_node | string | Node where the disruption originates |
| target_node | string | Node(s) being isolated (comma-separated for multiple) |
| affected_ports | list<integer> | TCP ports being blocked (e.g., `8008,5432,2379`) |
| iptables_rule | string | The exact `iptables` command used for injection |
| reversible | boolean | Whether `recover.sh` can cleanly restore connectivity |

**Relationships**:
- Applied to one `PatroniCluster`
- Targets one or more `PatroniNode` instances

## Entity: TestDataSet

Pre-loaded schema and data used for consistency verification.

| Attribute | Type | Description |
|-----------|------|-------------|
| schema_name | string | Always `partition_test` |
| table_name | string | Always `transactions` |
| row_count | integer | Number of rows pre-loaded before partition |
| checksum_aggregate | string | `MD5(string_agg(row_hash, ',' ORDER BY id))` across the table |
| last_insert_id | integer | Highest `id` inserted before partition |

**Relationships**:
- Stored on every `PatroniNode` in the cluster
- Verified by `verify.sh` to detect divergence after partition recovery

## Entity: TestResult

The outcome of a single break scenario.

| Attribute | Type | Description |
|-----------|------|-------------|
| scenario | string | Name of the break script executed |
| lab_id | string | `LAB-13-A` or `LAB-13-B` |
| failover_occurred | boolean | Whether a new leader was elected |
| new_leader | string | Name of the node that promoted (if any) |
| stale_reads_detected | boolean | Whether the replica served outdated data during partition |
| split_brain_risk | enum | `none`, `low`, `medium`, `high` |
| data_loss_rows | integer | Number of rows lost between leader crash and replica promotion |
| recovery_method | string | How the former leader rejoined (`pg_rewind`, `reinit`, `manual`) |
| patroni_logs | string | Path to captured Patroni log excerpt for this run |

**Relationships**:
- Produced by executing one `NetworkPartition` against one `PatroniCluster`
- Referenced in the chapter's results table
