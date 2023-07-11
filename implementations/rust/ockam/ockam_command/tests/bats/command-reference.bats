#!/bin/bash

# ===== SETUP

setup() {
  load load/base.bash
  load load/orchestrator.bash
  load_bats_ext
  setup_home_dir
  skip_if_orchestrator_tests_not_enabled
  copy_local_orchestrator_data
}

teardown() {
  teardown_home_dir
}

# ===== TESTS https://docs.ockam.io/reference/command/nodes
@test "nodes" {
  run "$OCKAM" node create
  assert_success

  run "$OCKAM" node create n1
  assert_success

  run "$OCKAM" node create n2 --verbose
  assert_success

  run "$OCKAM" node list
  assert_success
  assert_output --partial "Node n1  UP"

  run "$OCKAM" node stop n1
  assert_success
  assert_output --partial "Stopped node 'n1'"

  run "$OCKAM" node start n1
  assert_success

  run "$OCKAM" node delete n1
  assert_success

  run "$OCKAM" node delete --all
  assert_success
}

@test "workers and services" {
  run "$OCKAM" node create n1
  assert_success

  run "$OCKAM" worker list --at n1
  assert_success

  run "$OCKAM" message send hello --to /node/n1/service/uppercase
  assert_success
  assert_output "HELLO"
}

@test "projects - list" {
  run "$OCKAM" project list
  assert_success
}

@test "space - list" {
  run "$OCKAM" space list
  assert_success
}

# ===== TESTS https://docs.ockam.io/reference/command/routing
@test "routing" {
  run "$OCKAM" reset -y
  run "$OCKAM" node create n1
  assert_success

  run "$OCKAM" message send 'Hello Ockam!' --to /node/n1/service/echo
  assert_success
  assert_output "Hello Ockam!"

  run "$OCKAM" service start hop --addr h1
  assert_success

  run "$OCKAM" message send hello --to /node/n1/service/h1/service/echo
  assert_success
  assert_output "hello"

  run "$OCKAM" service start hop --addr h2
  assert_success
  run "$OCKAM" message send hello --to /node/n1/service/h1/service/h2/service/echo
  assert_success
  assert_output "hello"
}

@test "transports" {
  run "$OCKAM" reset -y
  assert_success
  run "$OCKAM" node create n1
  assert_success
  run "$OCKAM" node create n2 --tcp-listener-address=127.0.0.1:7000
  assert_success
  run "$OCKAM" node create n3 --tcp-listener-address=127.0.0.1:8000
  assert_success

  run "$OCKAM" service start hop --at n2
  assert_success

  n1_id=$("$OCKAM" tcp-connection create --from n1 --to 127.0.0.1:7000 | grep -o "[0-9a-f]\{32\}" | head -1)
  n2_id=$("$OCKAM" tcp-connection create --from n2 --to 127.0.0.1:8000 | grep -o "[0-9a-f]\{32\}" | head -1)

  run "$OCKAM" message send hello --from n1 --to /worker/${n1_id}/service/hop/worker/${n2_id}/service/uppercase
  assert_output "HELLO"
}

# ===== TESTS https://docs.ockam.io/reference/command/advanced-routing
@test "relays and portals" {
  run "$OCKAM" reset -y
  assert_success

  run "$OCKAM" node create n2 --tcp-listener-address=127.0.0.1:7000
  assert_success

  run "$OCKAM" node create n3
  assert_success

  run "$OCKAM" service start hop --at n3
  assert_success

  run "$OCKAM" relay create n3 --at /node/n2 --to /node/n3
  assert_success

  run "$OCKAM" node create n1
  assert_success

  n1_id=$("$OCKAM" tcp-connection create --from n1 --to 127.0.0.1:7000 | grep -o "[0-9a-f]\{32\}" | head -1)

  run "$OCKAM" message send hello --from n1 --to /worker/${n1_id}/service/forward_to_n3/service/uppercase
  assert_success
  assert_output "HELLO"

  run "$OCKAM" tcp-outlet create --at n3 --from /service/outlet --to 127.0.0.1:5000
  assert_success

  run "$OCKAM" tcp-inlet create --at n1 --from 127.0.0.1:6000 --to /worker/${n1_id}/service/forward_to_n3/service/hop/service/outlet
  assert_success

  run curl --fail --head --max-time 10 "127.0.0.1:6000"
  assert_success
}

# ===== TESTS https://docs.ockam.io/reference/command/routing
@test "vaults and identities" {
  run "$OCKAM" vault create v1
  assert_success

  run "$OCKAM" identity create i1 --vault v1
  assert_success

  run "$OCKAM" identity show i1
  assert_success

  run "$OCKAM" identity show i1 --full
  assert_success
}


# ===== TESTS https://docs.ockam.io/reference/command/secure-channels
@test "identifiers" {
  run "$OCKAM" node create a
  assert_success
  run "$OCKAM" node create b
  assert_success

  id=$("$OCKAM" secure-channel create --from a --to /node/b/service/api | grep -o "[0-9a-f]\{32\}" | head -1)

  run "$OCKAM" message send hello --from a --to /service/${id}/service/uppercase
  assert_success
  assert_output "HELLO"

  "$OCKAM" secure-channel create --from a --to /node/b/service/api |
    ockam message send hello --from a --to -/service/uppercase

  output=$(ockam secure-channel create --from a --to /node/b/service/api |
    ockam message send hello --from a --to -/service/uppercase)

  assert [ "$output" == "HELLO" ]
}

@test "through relays" {
  run "$OCKAM" node create relay --tcp-listener-address=127.0.0.1:7000
  assert_success

  run "$OCKAM" node create b
  assert_success

  run "$OCKAM" relay create b --at /node/relay --to b
  assert_success

  run "$OCKAM" node create a
  assert_success

  worker_id=$(ockam tcp-connection create --from a --to 127.0.0.1:7000 | grep -o "[0-9a-f]\{32\}" | head -1)

  output=$(ockam secure-channel create --from a --to /worker/${worker_id}/service/forward_to_b/service/api \
    | ockam message send hello --from a --to -/service/uppercase)
  assert [ "$output" == "HELLO" ]
}

@test "elastic encrypted relays" {
  "$OCKAM" project information --output json > /tmp/project.json

  run "$OCKAM" node create a --project-path /tmp/project.json
  assert_success
  run "$OCKAM" node create b --project-path /tmp/project.json
  assert_success

  run "$OCKAM" relay create b --at /project/default --to /node/a
  assert_success

  output=$(ockam secure-channel create --from a --to /project/default/service/forward_to_b/service/api \
    | ockam message send hello --from a --to -/service/uppercase)
  assert [ "$output" == "HELLO" ]
}

# ===== TESTS https://docs.ockam.io/reference/command/credentials
@test "issuing credentials" {
  run "$OCKAM" reset -y
  assert_success

  run "$OCKAM" identity create a
  assert_success

  run "$OCKAM" identity create b
  assert_success

  id=$("$OCKAM" identity show b --full --encoding hex)

  run "$OCKAM" credential issue --as a --for ${id}
  assert_success

  run "$OCKAM" credential issue --as a --for ${id} --attribute location=Chicago --attribute department=Operations
  assert_success
}

@test "verifying - storing credentials" {
  run "$OCKAM" reset -y
  assert_success

  run "$OCKAM" identity create a
  assert_success
  run "$OCKAM" identity create b
  assert_success

  id=$(ockam identity show b --full --encoding hex)

  "$OCKAM" credential issue --as a --for ${id} --encoding hex > /tmp/b.credential

  run "$OCKAM" credential verify --issuer ${id} --credential-path /tmp/b.credential
  assert_success

  run "$OCKAM" credential store c1 --issuer ${id} --credential-path /tmp/b.credential
  assert_success
}

@test "trust anchors" {
  run "$OCKAM" identity create i1
  assert_success

  "$OCKAM" identity show i1 > /tmp/i1.identifier

  run "$OCKAM" node create n1 --identity i1
  assert_success

  run "$OCKAM" identity create i2
  assert_success

  "$OCKAM" identity show i2 > /tmp/i2.identifier

  run "$OCKAM" node create n2 --identity i2
  assert_success

  run "$OCKAM" secure-channel-listener create l --at n2 \
    --identity i2 --authorized $(cat /tmp/i1.identifier)

  output=$("$OCKAM" secure-channel create \
    --from n1 --to /node/n2/service/l \
    --identity i1 --authorized $(cat /tmp/i1.identifier) \
      | "$OCKAM" message send hello --from n1 --to -/service/uppercase)

  assert [ "$output" == "HELLO" ]
}

@test "anchoring trust in a credential ussuer" {
  run "$OCKAM" reset -y
  assert_success

  run "$OCKAM" identity create authority
  assert_success

  "$OCKAM" identity show authority > /tmp/authority.identifier
  "$OCKAM" identity show authority --full --encoding hex > /tmp/authority

  run "$OCKAM" identity create i1
  assert_success

  "$OCKAM" identity show i1 --full --encoding hex > /tmp/i1
  "$OCKAM" credential issue --as authority --for $(cat /tmp/i1) --attribute city="New York" --encoding hex > /tmp/i1.credential

  run "$OCKAM" credential store c1 --issuer $(cat /tmp/authority) --credential-path /tmp/i1.credential
  assert_success

  run "$OCKAM" identity create i2
  assert_success

  "$OCKAM" identity show i2 --full --encoding hex > /tmp/i2
  "$OCKAM" credential issue --as authority \
    --for $(cat /tmp/i2) --attribute city="San Francisco" \
    --encoding hex > /tmp/i2.credential

  run "$OCKAM" credential store c2 --issuer $(cat /tmp/authority) --credential-path /tmp/i2.credential
  assert_success

  run "$OCKAM" node create n1 --identity i1 --authority-identity $(cat /tmp/authority)
  assert_success
  run "$OCKAM" node create n2 --identity i2 --authority-identity $(cat /tmp/authority) --credential c2
  assert_success

  output=$("$OCKAM" secure-channel create --from n1 --to /node/n2/service/api --credential c1 --identity i1 \
    | "$OCKAM" message send hello --from n1 --to -/service/uppercase)

  assert [ "$output" == "HELLO" ]
}

@test "managed authorities" {
  "$OCKAM" project information --output json > /tmp/project.json

  run "$OCKAM" node create a --project-path /tmp/project.json
  run "$OCKAM" node create b --project-path /tmp/project.json

  run "$OCKAM" relay create b --at /project/default --to /node/a/service/forward_to_b

  output=$("$OCKAM" secure-channel create --from a --to /project/default/service/forward_to_b/service/api \
    | "$OCKAM" message send hello --from a --to -/service/uppercase)

  assert [ "$output" == "HELLO" ]
}
