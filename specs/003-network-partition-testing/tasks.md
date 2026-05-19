# Tasks: Network Partition Testing for PostgreSQL HA

**Input**: Design documents from `/specs/003-network-partition-testing/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Not requested in spec. Testing is manual via `make setup && make break && make verify && make recover && make teardown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic directory structure

- [ ] T001 Create lab-13-a directory at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/`
- [ ] T002 [P] Create lab-13-b directory at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared utilities and patterns that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Create shared test data initialization SQL (`init-partition-test-data.sql`) at `docs/devops/postgres-ha-patroni-book/_companion/docker/common/init-partition-test-data.sql`
- [ ] T004 Create shared `recover.sh` template at `docs/devops/postgres-ha-patroni-book/_companion/docker/common/recover-partition.sh`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 2-Node Partition Test (Priority: P1) 🎯 MVP

**Goal**: Deliver LAB-13-A, a Docker Compose environment with 2 Patroni nodes and 5 etcd nodes, plus three chaos scripts that test clean stop, full partition, and asymmetric partition scenarios.

**Independent Test**: Run `cd docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a && make setup && make break && make verify && make recover && make teardown`. Each break scenario produces deterministic pass/fail outcomes with captured Patroni logs.

### Implementation for User Story 1

- [ ] T005 [P] [US1] Create `docker-compose.yml` for LAB-13-A with 2 Patroni nodes + 5 etcd nodes at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/docker-compose.yml`
- [ ] T006 [P] [US1] Create `patroni-1.yml` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/patroni-1.yml`
- [ ] T007 [US1] Create `patroni-2.yml` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/patroni-2.yml`
- [ ] T008 [P] [US1] Create `break-clean-stop.sh` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/break-clean-stop.sh`
- [ ] T009 [P] [US1] Create `break-full-partition.sh` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/break-full-partition.sh`
- [ ] T010 [US1] Create `break-asymmetric-partition.sh` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/break-asymmetric-partition.sh`
- [ ] T011 [US1] Create `verify.sh` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/verify.sh`
- [ ] T012 [US1] Create `Makefile` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/Makefile`
- [ ] T013 [P] [US1] Create `README.md` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/README.md`
- [ ] T014 [P] [US1] Create `.env.example` for LAB-13-A at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-a/.env.example`

**Checkpoint**: At this point, User Story 1 (LAB-13-A) should be fully functional and testable independently

---

## Phase 4: User Story 2 - 3-Node Quorum Test (Priority: P2)

**Goal**: Deliver LAB-13-B, a Docker Compose environment with 3 Patroni nodes and 5 etcd nodes, reusing the same chaos scripts and test data as LAB-13-A, demonstrating quorum-based recovery.

**Independent Test**: Run `cd docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b && make setup && make break && make verify && make recover && make teardown`. The comparison matrix in the chapter can be populated from the outputs of LAB-13-A and LAB-13-B.

### Implementation for User Story 2

- [ ] T015 [P] [US2] Create `docker-compose.yml` for LAB-13-B with 3 Patroni nodes + 5 etcd nodes at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/docker-compose.yml`
- [ ] T016 [P] [US2] Create `patroni-1.yml` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/patroni-1.yml`
- [ ] T017 [P] [US2] Create `patroni-2.yml` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/patroni-2.yml`
- [ ] T018 [US2] Create `patroni-3.yml` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/patroni-3.yml`
- [ ] T019 [P] [US2] Create `break-clean-stop.sh` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/break-clean-stop.sh`
- [ ] T020 [P] [US2] Create `break-full-partition.sh` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/break-full-partition.sh`
- [ ] T021 [US2] Create `break-asymmetric-partition.sh` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/break-asymmetric-partition.sh`
- [ ] T022 [US2] Create `verify.sh` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/verify.sh`
- [ ] T023 [US2] Create `Makefile` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/Makefile`
- [ ] T024 [P] [US2] Create `README.md` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/README.md`
- [ ] T025 [P] [US2] Create `.env.example` for LAB-13-B at `docs/devops/postgres-ha-patroni-book/_companion/docker/lab-13-b/.env.example`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Chapter content, artifact registration, and build verification

- [ ] T026 Create Chapter 13 MDX at `docs/devops/postgres-ha-patroni-book/13-network-partition-testing.mdx`
- [ ] T027 Update `_companion-links.json` with LAB-13-A and LAB-13-B artifact IDs at `docs/devops/postgres-ha-patroni-book/_companion-links.json`
- [ ] T028 Update `ARTIFACT-IDS.md` with new artifact entries at `docs/devops/postgres-ha-patroni-book/_companion/ARTIFACT-IDS.md`
- [ ] T029 Update `_companion/README.md` with new lab references at `docs/devops/postgres-ha-patroni-book/_companion/README.md`
- [ ] T030 [P] Verify Docusaurus build passes with zero errors
- [ ] T031 [P] Run artifact ID verification script to confirm all paths resolve

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Reuses chaos script patterns from US1 but is independently testable

### Within Each User Story

- Docker Compose and patroni.yml configs before chaos scripts (scripts reference container names and IPs from docker-compose)
- Chaos scripts before verify.sh (verify.sh asserts outcomes of break scenarios)
- verify.sh before Makefile (Makefile orchestrates all targets)
- Core lab files before README.md (README documents what exists)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- Within US1: docker-compose.yml, patroni-1.yml, patroni-2.yml, break scripts, and README can be created in parallel
- Within US2: docker-compose.yml, all three patroni.yml files, break scripts, and README can be created in parallel
- US1 and US2 can be worked on in parallel by different team members once Foundational is complete
- Polish phase tasks T030 and T031 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all lab infrastructure files for User Story 1 together:
Task: "Create docker-compose.yml for LAB-13-A"
Task: "Create patroni-1.yml for LAB-13-A"
Task: "Create patroni-2.yml for LAB-13-A"

# Launch all chaos scripts for User Story 1 together:
Task: "Create break-clean-stop.sh for LAB-13-A"
Task: "Create break-full-partition.sh for LAB-13-A"
Task: "Create break-asymmetric-partition.sh for LAB-13-A"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (LAB-13-A)
4. **STOP and VALIDATE**: Test all three break scenarios in LAB-13-A independently
5. Demo the 2-node partition behavior to stakeholders

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test LAB-13-A independently → Demo (MVP!)
3. Add User Story 2 → Test LAB-13-B independently → Demo comparison
4. Add Phase 5 (Chapter 13 + artifact registration) → Build verification
5. Each increment adds value without breaking previous work

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (LAB-13-A)
   - Developer B: User Story 2 (LAB-13-B)
3. Stories complete and are independently testable
4. Both developers then collaborate on Phase 5 (Chapter 13 MDX)

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- All chaos scripts must be idempotent: running `recover.sh` before any `break-*.sh` is a no-op
- Both labs use the same `ghcr.io/zalando/spilo-16:3.2-p1` image as LAB-03-A for consistency
