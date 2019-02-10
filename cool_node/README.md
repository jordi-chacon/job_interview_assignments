# Job interview home assignment

### Assignment specification

Think of a set of K (K > 1) connected nodes that form together a distributed system. This task is about implementing an algorithm that allows selecting a Leader from those nodes. There can only be one Leader at each point in time, and if Leader is unavailable, stopped, died or disappeared in a singularity the algorithm should elect a new Leader as soon as possible.

There are two major parts in the implementation.

##### Current Leader Monitoring

Once in T seconds, each node sends a message `PING` to the Leader. If no response is received in 4xT seconds then the current Leader is considered dead and the node that sent that message begins a new Leader election.

##### Leader Election

All nodes know each other (each node knows address and port of any other node). Each node has a unique identifier and identifiers are sortable. There are 3 types of messages: `ALIVE?`, `FINETHANKS`, `IAMTHEKING`.

1. The node that starts the election sends a message `ALIVE?` to all nodes that have ID greater than ID of the current node.
   - If nobody responded `FINETHANKS` in T seconds then the current node becomes the Leader and sends out messages `IAMTHEKING` to all other nodes.
   - If the current node received a `FINETHANKS` message, then it waits T seconds for a `IAMTHEKING` message and if it's not received then the current node starts the election process again.
2. If a node receives an `ALIVE?` message then it responds with a `FINETHANKS` message and immediately starts an election process.
   - If the node that received `ALIVE?` has the biggest ID then it immediately sends out `IAMTHEKING` message to all other nodes.
3. If a node receives `IAMTHEKING` then it remembers the sender of this message as the Leader.
4. If a node joins the system then it immediately initiates an election process.

Upon completion of the test task source code and clear instructions on how to build and run it should be provided.

### Dependencies

- Elixir 1.7 or higher

### Run tests

```
make get-deps
make test
```

### Run nodes locally

```
make get-deps
make build
NAME=n1 make start-local-node
NAME=n2 make start-local-node
NAME=n3 make start-local-node
NAME=n4 make start-local-node
```

Each node logs both sent and received messages to its own log file. Log files can be found in `/tmp/cool_node.*.log`.

To stop the nodes:

```
NAME=n1 make stop-local-node
NAME=n2 make stop-local-node
NAME=n3 make stop-local-node
NAME=n4 make stop-local-node
```
