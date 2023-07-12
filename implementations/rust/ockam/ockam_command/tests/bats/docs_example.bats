#!/bin/bash

# ===== SETUP

setup_file() {
  load load/base.bash
}

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

start_consumer_listener() {
  kafka-console-consumer.sh --topic demo-topic \
    --bootstrap-server localhost:4000 --consumer.config kafka.config > consumer.out 2>&1 &

  consumer_pid="$!"
  echo "$consumer_pid" > /tmp/consumer.pid
}

teardown_kafka() {
  kafka-topics.sh --bootstrap-server localhost:4000 --command-config kafka.config --delete --topic demo-topic
  rm consumer.token producer1.token producer2.token kafka.config consumer.out

  if consumer_pid=$(cat /tmp/consumer.pid); then
    kill $consumer_pid
    rm /tmp/consumer.pid
  fi

  OCKAM_HOME="$ENROLLED_HOME" $OCKAM node delete --all
  OCKAM_HOME="$OCKAM_HOME_CONSUMER" $OCKAM node delete --all
  OCKAM_HOME="$OCKAM_HOME_PRODUCER_1" $OCKAM node delete --all
  OCKAM_HOME="$OCKAM_HOME_PRODUCER_2" $OCKAM node delete --all
}


@test "end-to-end encryption with kafka" {
  skip
  if [[ -z $CONFLUENT_BOOTSTRAP_SERVER || -z $CONFLUENT_API_SECRET || -z $CONFLUENT_API_KEY ]]; then
    exit 1
  fi

  run $OCKAM project addon configure confluent --bootstrap-server $CONFLUENT_BOOTSTRAP_SERVER

  export OCKAM_HOME_CONSUMER=$(mktemp -d)
  export OCKAM_HOME_PRODUCER_1=$(mktemp -d)
  export OCKAM_HOME_PRODUCER_2=$(mktemp -d)

  OCKAM_HOME=$ENROLLED_HOME $OCKAM project ticket --attribute role=member > consumer.token
  OCKAM_HOME=$ENROLLED_HOME $OCKAM project ticket --attribute role=member > producer1.token
  OCKAM_HOME=$ENROLLED_HOME $OCKAM project ticket --attribute role=member > producer2.token

  cat > kafka.config <<EOF
  request.timeout.ms=30000
  security.protocol=SASL_PLAINTEXT
  sasl.mechanism=PLAIN
  sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
          username="$CONFLUENT_API_KEY" \
          password="$CONFLUENT_API_SECRET";
  EOF

  # Consumer
  run bash -c "OCKAM_HOME=$OCKAM_HOME_CONSUMER $OCKAM identity create consumer"
  assert_success
  run bash -c "OCKAM_HOME=$OCKAM_HOME_CONSUMER $OCKAM project enroll consumer.token --identity consumer"
  assert_success

  run bash -c "OCKAM_HOME=$OCKAM_HOME_CONSUMER $OCKAM node create consumer --identity consumer"
  run bash -c "OCKAM_HOME=$OCKAM_HOME_CONSUMER $OCKAM kafka-consumer create --at consumer"
  assert_success

  run kafka-topics.sh --bootstrap-server localhost:4000 --command-config kafka.config \
    --create --topic demo-topic --partitions 3
  assert_success

  start_consumer_listener


  # Producer 1
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_1 $OCKAM identity create producer1"
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_1 $OCKAM project enroll producer1.token --identity producer1"
  assert_success

  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_1 $OCKAM node create producer1 --identity producer1"
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_1 $OCKAM kafka-producer create --at producer1"
  assert_success

  run bash -c "echo 'Hello from producer 1' | kafka-console-producer.sh --topic demo-topic\
    --bootstrap-server localhost:5000 --producer.config kafka.config"
  assert_success

  run cat consumer.out
  assert_output "Hello from producer 1"


  # Producer 2
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_2 $OCKAM identity create producer2"
  assert_success
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_2 $OCKAM project enroll producer2.token --identity producer2"
  assert_success

  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_2 $OCKAM node create producer2 --identity producer2"
  assert_success
  run bash -c "OCKAM_HOME=$OCKAM_HOME_PRODUCER_2 $OCKAM kafka-producer create --at producer2 --bootstrap-server 127.0.0.1:6000 --brokers-port-range 6001-6100"
  assert_success

  run bash -c "echo 'Hello from producer 2' | kafka-console-producer.sh --topic demo-topic\
   --bootstrap-server localhost:6000 --producer.config kafka.config"
  assert_success

  run cat consumer.out
  assert_output --partial "Hello from producer 2"

  teardown_kafka
}

teardown_python_server() {
  pid=$(cat "$FLASK_PID_FILE")
  kill -9 "$pid"
  wait "$pid" 2>/dev/null || true

  rm -rf $ENROLLED_HOME
}

setup_python_server() {
  load "$BATS_LIB/bats-support/load.bash"
  load "$BATS_LIB/bats-assert/load.bash"

  $OCKAM node delete --all

  cat > $FLASK_SERVER <<- EOM
  import os
  import psycopg2
  from flask import Flask

  CREATE_TABLE = (
    "CREATE TABLE IF NOT EXISTS events (id SERIAL PRIMARY KEY, name TEXT);"
  )

  INSERT_RETURN_ID = "INSERT INTO events (name) VALUES (%s) RETURNING id;"

  app = Flask(__name__)
  url = "postgres://postgres:password@localhost/"
  connection = psycopg2.connect(port=$OCKAM_PG_PORT, database="postgres", host="localhost", user="postgres", password="password")

  @app.route("/")
  def hello_world():
    with connection:
      with connection.cursor() as cursor:
          cursor.execute(CREATE_TABLE)
          cursor.execute(INSERT_RETURN_ID, ("",))
          id = cursor.fetchone()[0]
    return "I've been visited {} times".format(id), 201


  if __name__ == "__main__":
    app.run(port=6000)
  EOM
}

start_python_server() {
  python3 $FLASK_SERVER &>/dev/null  &
  pid="$!"
  echo $pid > $FLASK_PID_FILE

  sleep 5
}

@test "database relay" {
  export DB_TOKEN=$(ockam project ticket --attribute component=db)
  export WEB_TOKEN=$(ockam project ticket --attribute component=web)
  export PG_PORT=5432
  export OCKAM_PG_PORT=5433

  export FLASK_PID_FILE="/tmp/python.pid"
  export FLASK_SERVER="/tmp/server.py"

  run setup_python_server
  assert_success

  run $OCKAM identity create db
  assert_success
  run $OCKAM project enroll $DB_TOKEN --identity db
  assert_success
  run $OCKAM node create db --identity db
  assert_success
  run $OCKAM policy create --at db --resource tcp-outlet --expression '(= subject.component "web")'
  assert_success
  run $OCKAM tcp-outlet create --at /node/db --from /service/outlet --to $PG_HOST:$PG_PORT
  assert_success

  run $OCKAM relay create db --to /node/db --at /project/default
  assert_success

  run $OCKAM identity create web
  assert_success
  run $OCKAM project enroll $WEB_TOKEN --identity web
  assert_success
  run $OCKAM node create web --identity web
  assert_success
  run $OCKAM policy create --at web --resource tcp-inlet --expression '(= subject.component "db")'
  assert_success
  run $OCKAM tcp-inlet create --at /node/web --from 127.0.0.1:$OCKAM_PG_PORT --to /project/default/service/forward_to_db/secure/api/service/outlet
  assert_success

  # Kickstart webserver
  run touch $FLASK_PID_FILE
  run start_python_server
  assert_success

  # Visit website
  run curl http://127.0.0.1:6000
  assert_success
  assert_output --partial "I've been visited 1 times"

  # Visit website second time
  run curl http://127.0.0.1:6000
  assert_success
  assert_output --partial "I've been visited 2 times"

  assert_success
}
