# Hiero Network Addresses

## Abstract
When dealing with Hiero networks, there are several easily conflated concepts
related to the term Address Book and its analogs that it may help to clarify.
These concepts are critical to understand how to find and interact with the
nodes of a Hiero network and how to produce well-formed transactions. This
document seeks to provide concrete and non-overlapping definitions that can be
used when describing these concepts to avoid confusion and enhance accurate and
reliable communication. This document further seeks to make use of those
definitions to offer a clear and unambiguous description of how updates to node
data in the network state affect the behavior of the network and how clients
(SDK or custom) and explorers, or mirror nodes, can ensure the available
information is presented in a clear, timely, and relevant manner without
unnecessary confusion or complexity.

## A Very Short Summary
1. All updates to Node Entry information are immediate when the transaction
   completes.
1. The Consensus Roster is not the Node Store and is not an Address Book.
1. A new Consensus Roster is only _adopted_ after certain triggering events.
   Even then the roster is only adopted if there are changes from the previous
   Roster, and the consensus network comes to agreement on the new roster.
1. Node Account is part of the Node Store and any change made is active
   immediately.
1. Node Service Endpoints are part of the Node Store and any changes made are
   active _and_ effective immediately.
1. Staking Calculations use the values in the Node Store at the moment of that
   calculation, which is only performed occasionally (UTC midnight for
   Hedera mainnet).
1. Node Rewards are calculated and paid at the same time as Staking Calculations
   and use the values in the Node Store at the moment of that calculation.
1. The legacy Address Book Files are a convenience and should not be relied
   upon long-term. These should be replaced by an index for the Node Store. 
1. Roster representation should be separate and updated based on detecting the 
   adoption of a new Roster (synthetic transactions and/or state updates).
   Currently this _may_ occur after the network is upgraded, but future releases
   will change that timing.

## Definitions
<dl>
<dt>Node Entry</dt>
<dd>A Node Entry, in a Hiero network, is an entry in the network state that
represents one instance of the Hiero consensus node software that is a "member"
of that Hiero network.</dd>
<dt>Node ID</dt>
<dd>A simple unsigned `long` integer (64-bit range) that <i>uniquely</i>, and
<i>immutably</i> identifies a Node within a particular Hiero network. The Node
ID is set when the Node Entry is created, and cannot be updated. The only
mechanism to "change" a Node ID is to delete the node and re-create it.</dd>
<dt>Node Account</dt>
<dd>A Node Account is a Hiero account that receives node rewards, and pays
penalties if necessary, on behalf of a node operator.<br/>
A Node Account is also included in each transaction submitted to the network
as a mechanism for ensuring the user has approved, by signing the transaction,
which node will perform initial intake and basic transaction validation,
and submit the transaction to the network.</dd>
<dt>Gossip Endpoint</dt>
<dd>The "internal" <i>network</i> address(es) that a Node exposes to the rest
of the Hiero network for gossip as part of executing the Hashgraph
consensus algorithm.</dd>
<dt>Service Endpoint</dt>
<dd>The "external" <i>network</i> address(es) that a Node exposes to the whole
internet to receive new transactions.</dd>
<dt>Node Admin Key</dt>
<dd>A Hiero `Key` message that establishes signature requirements to update a
Node Entry.</dd>
<dt>Address</dt>
<dd>The combination of Node ID, one or both of gossip endpoints or service
endpoints, and other information from the Node Entry.<br/>
An Address provides everything needed to identify and connect to a particular
Node for gossip or user transactions.
</dd>
<dt>Stake Calculation</dt>
<dd>A Stake Calculation is a process executed according to a schedule
configured for each Hiero network (typically once per day just after
UTC midnight). This calculation determines the total native tokens staked
to Nodes in the network (for the Hedera network the native token is HBAR)
and calculates the Consensus Weight of each node proportional to the relative
amount of native tokens staked to the node. This calculation ensures that the
total weight assigned to all nodes remains stable, even if the total tokens
staked varies. The calculation also tries to ensure that no single Node holds
so much weight that it might place at-risk the byzantine fault tolerance of the
network.</dd>
<dt>Reward Calculations</dt>
<dd>A calculation performed by the `execution` subsystem at the same time as
the Stake Calculation that determines the rewards and penalties to be assessed
to each node for the stake period that just ended. This process (subject to the
implementation of HIP 1259) also makes the actual transfer of tokens between
the fee collection account and the Node Accounts.<br/>
Note that Daily Node Rewards is an input to this calculation, but is not
specifically the goal of this process.</dd>
<dt>Roster Adoption</dt>
<dd>At certain times (which vary by Hiero network and software version)
the network must update the Roster used by the consensus algorithm. This process
is initiated and guided by the `execution` subsystem and delivered to the
`consensus` subsystem according to a well-defined process. The Roster to be
adopted is determined by the values stored in the Node Store and the most recent
Stake Calculation result at the consensus time when the Roster Adoption
process <i>begins</i>.</dd>
<dt>Consensus Weight</dt>
<dd>The relative weight (described as Κ of Ν or "Κ<sub>n</sub>") that a given
Node holds in the Hashgraph algorithm. The algorithm is guaranteed to be
"byzantine fault tolerant" so long as nodes with <i>total weight</i>
Σ(Κ<sub>n</sub>) strictly greater than one third of the total network
weight (Ν) are "honest".</dd>
<dt>Node Store</dt>
<dd>A virtual map in network state that holds all of the current Node Entry
information for all Nodes known to the network.</dd>
<dt>Roster</dt>
<dd>A list of Addresses combined with weight information that is used by the
Consensus algorithm to determine network membership and gossip connections.</dd>
<dt>Roster Entry</dt>
<dd>A single Address with Gossip Endpoint(s) and consensus weight value.</dd>
<dt>Address Book File</dt>
<dd>A HFS `File` (Entities `0.0.101` and `0.0.102` in the Hedera network) that
contains Addresses for each node with "user" information,</dd>
<dt>Address Book</dt>
<dd>An older term that might refer to the Roster, Address Book File, Node Store,
or the collected addresses readable from a Mirror Node.</dd>
</dl>
<!-- <dt></dt><dd></dd> -->

## The Node Store and Node Transactions
The Hiero Node Store holds the _current state_ of every node known to the
network, this includes active, inactive, and deleted nodes. The Node Store is
updated _immediately_ by any `nodeCreate`, `nodeUpdate`, or `nodeDelete`
transaction. There is no "queue" or "deferred update" for node information.
Some early documents describe updates as being "queued" or "held" until a later
event. This view was mistaken and based on a misunderstanding of the
interactions between the Node Store, the Roster, and the various published
"address book" representations.

Any element of a Node Entry may be updated with a `nodeUpdate` transaction and
that update is "visible" and "live" immediately with respect to the Node Store.
That change _might not_ affect other subsystems, however, if those subsystems do
not read from the Node Store. This is most relevant to the `consensus` subsystem
which relies on the Roster, not the Node Store.

The primary consumer of the Node Store, and the "owner" of that data is the
`execution` subsystem. Any change to the Node Store is always visible to
the `execution` subsystem immediately.

## The Roster and Consensus Weight
The Roster is a point-in-time snapshot of a portion of the Node Store. The
Roster is created by the `execution` subsystem in response to a triggering
event, and contains contents from the Node Store at the instant of the
triggering event. The `execution` subsystem provides the roster to the
`platform` when created (currently, see [Future Direction](#Future Direction)
below). As of release `0.65.1` the triggering event is a `Freeze` transaction
of type `PREPARE_UPGRADE`, which causes the Roster to be written; and this
Roster is then provided to the `platform` when it is created on startup.

The Roster includes the Consensus Weight for each node determined by the most
recent Stake Calculation performed prior to the triggering event that led to
the `execution` subsystem creating the Roster. This Consensus Weight may be
updated more often than the remainder of the Roster.

It is important to understand that the Roster is separate from the Node Store
and is _not_ an Address Book. It is a separate store of data used exclusively
by the Hashgraph algorithm and `consensus` subsystem.

## The Address Book File and File updates
The Address Book File is a point-in-time snapshot of most of the data in the
Node Store (though not all). The Address Book File (really two file entries
at `101` and `102` in Hedera) is a legacy form of the Node Entry data that used
to be manually managed through `fileUpdate` and `fileAppend` transactions.

As of release `0.65.1` these two file entries are overwritten by the
`execution` subsystem when the node restarts after a `freeze` transaction of
type `UPGRADE`.  The content of these files is written in a synthetic
`fileUpdate` transaction that uses the _current_ data from the Node Store as of
the instant when the transaction is created.  This _may not_ exactly match
the latest Roster information, and the Node Store may change immediately after
these files are updated.

Continued use of these two files is not recommended.

## Changes that depend on Node Operators
Node operators control their nodes and the service endpoints for their nodes
with complete autonomy. A node operator may change their endpoints at any
time. In the past this had to be coordinated with a network upgrade or the
node would become inaccessible. Now (as of release `0.65.1`) a node operator
can submit a `nodeUpdate` transaction to change the Service Endpoint data
for their node and _immediately_ make the same change on their node. SDKs then
need only query for the current state of that Node (if supported by their chosen
mirror node) to obtain the new endpoint information.

A node operator _might_, however, send a `nodeUpdate` transaction and not
immediately update the actual node. This is entirely within the control of that
node operator, and an SDK must handle this situation gracefully (typically by
resigning the transaction and sending to a different node). A node operator
might also update node endpoints without updating the information stored in
the network, and that should be handled similarly by SDKs.

## The Mirror Node and SDK Interactions
The Mirror Node will, in order to have current and accurate information for
all consensus nodes in the network (and in the future other node types),
need to monitor `nodeUpdate`, `nodeCreate`, and `nodeDelete` transactions in
order to maintain a local view of the current state of the Node Store.

SDKs will need to query mirror node (or other explorers) on a regular basis
(perhaps as often as hourly) to get the latest Node Account and Service
Endpoint information for each Node. This information is critical to the
submission of transactions to the network, and should be kept up to date.

## Future Directions
- The Node Store will be the "address book" of record for the system going
  forward, and in a future release the Address Book files and other copies
  of Address data (other than Roster, which will remain) may be removed.
- The Roster will, in a future release, be updated immediately following each
  Stake Calculation. This will enable the `consensus` subsystem to add, update
  or remove participating nodes as often as daily (for Hedera mainnet) and
  potentially even more often for Spheres.  The Roster will continue to be
  generated by the `execution` subsystem in response to the triggering event
  and provided to the `consensus` subsystem as a "candidate" via a platform API.
- Mirror Node should (subject to priority and time availability) reduce or
  eliminate the use of the Address Book File updates and rely on a combination
  of Node Store changes (and related transactions), Roster Update changes and
  transactions, and triggering events to determine what the current contents
  of the Node Store and Roster are at any point in time.
- Mirror Node should, when Block Streams and Block Nodes are enabled, monitor
  state update items for the Node Store and use those to maintain an up to
  date view of the current state of the Node Store. Mirror Nodes might, for
  maximum reliability, even request a State Proof for the current state of the
  Node Store from a Block Node on an hourly or daily basis.
- Mirror Node and SDKs will need to pay attention to real-time updates to the
  Node Entries. These include Node Account and Service Endpoints, because
  the immediate effect of changes to Account or Service Endpoint can result in
  an SDK call being rejected (incorrect Node Account) or not reaching a
  destination node (incorrect service endpoint).
- The Node Store will contain entries for additional Node types in the future,
  these are collectively called "Discoverable Nodes" and include Block Nodes,
  Relay Nodes, Mirror Nodes, and other Community-operated services. Mirror Nodes
  will need to index these new node types (along with reputational attributes)
  and SDKs will likely query explorer services to find these "Discoverable
  Nodes" in order to connect to those services.

