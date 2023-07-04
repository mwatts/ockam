* install redpanda
* install kafka if you haven't already (using the kafka console to make sure it's 100% compatible)
* `rpk container start`
    * export the env var it tells you to
* `rpk container status`
    * export `REDPANDA_API_ADMIN_ADDRS` with the value of the admin api
* still working out the rest... probably `./start_rp` and then the `plain-` commands to make sure it works as expected. The ockam bits defibitely don't yet, but `./setup_ockam` is where those dreams exist. 