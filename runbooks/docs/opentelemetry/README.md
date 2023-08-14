<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Jaeger & New Relic Service

* [Service Overview](https://dashboards.gitlab.net/d/jaeger-main/jaeger-overview)

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22jaeger%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Jaeger"

## Summary

The primary goal of this system is to aid in understanding system behaviour and diagnosis of latency.

Jaeger stores traces consisting of spans, which provide a fine-grained execution trace of the execution of a single request, through multiple layers of RPCs.
This allows engineers to understand the full end-to-end flow.


# Architecture

![otel-arch.png](./otel-arch.png)

## Summary

[Jaeger](https://jaegertracing.io) is a distributed tracing system modeled after
[Dapper](https://research.google/pubs/pub36356/). It is intended to replace most
uses of our correlation dashboard as well as
[peek](https://github.com/peek/peek) with a design that is:

* More scaleable: By using Elasticsearch as a backing store.
* More complete: By tracking a sample of all traffic.
* More user-friendly: By providing a cross-service visualization that shows gaps
  in execution.

The primary goal of this system is to aid in understanding system behaviour and
diagnosis of latency.

It provides additional value, such as being a living architecture diagram for
use in onboarding.

Jaeger stores traces consisting of spans, which provide a fine-grained execution
trace of the execution of a single request, through multiple layers of RPCs.
This allows engineers to understand the full end-to-end flow.

## Architecture

The architecture of Jaeger is documented in [the Jaeger
docs](https://www.jaegertracing.io/docs/latest/architecture/).

Here is a diagram of how it is deployed in our infrastructure:

![jaeger architecture diagram](img/jaeger_arch.png)

![otel-arch.png](./otel-arch.png)

The configuration we are running consists of:

* [labkit](https://gitlab.com/gitlab-org/labkit) and
  [labkit-ruby](https://gitlab.com/gitlab-org/labkit-ruby) as integration points
  between [OpenTracing](https://opentracing.io/), jaeger client libraries, and
  application code.
* Agent: Deployed per-host (and as a DaemonSet in Kubernetes), is a local buffer
  that listens for spans over UDP, batches them up, and forwards them to a
  collector.
* Collector: Running in Kubernetes, this component receives spans from agents
  and writes them to Elasticsearch.
* Query: Running in Kubernetes, this component queries Elasticsearch and
  provides the user-facing UI for Jaeger.
* Elasticsearch: This is the storage backend for the Jaeger system. We run a
  dedicated Elasticsearch cluster for Jaeger in production.

We deploy these components to Kubernetes via
[the Jaeger Operator](https://www.jaegertracing.io/docs/latest/operator/).

The primary tuning parameter in distributed tracing systems is sampling rate.

Because of the high volume of data being collected for any given request, it is
not feasible to track this data for all requests. Instead, a sample of all
traffic is instrumented.

This gives us a lever with which to manage overhead and capacity demands, in
particular storage.



## Performance

Since we want to keep tracing always-on, it needs to have a negligible
performance overhead.

This can be accomplished via sampling. Depending on the volume of the incoming
traffic we may want to sample at less than 1%. This configuration is expected
to evolve over time.

Any expensive instrumentation calls must only run when a request is actively
being traced. Since sampling occurs at the head, this information is available
in the request context.

## Scalability

Jaeger is designed as a horizontally scaleable system. The main constraint here
is storage. By storing span data in Elasticsearch, we can scale out the storage
backend as needed.

We target a retention window of 7 days, and will adjust sample rate in
accordance with our budget in order to achieve this window.

Additionally, the collector service is backed by a Kubernetes Horizontal Pod
Autoscaler (HPA), allowing it to respond to increased demand by increasing
capacity.

When we reach saturation on Elasticsearch, there are essentially two options:

* Adjust sampling rate, to sample fewer traces
* Scale out Elasticsearch, adding more capacity (and potentially increasing number of shards)

We are trading off fidelity of the data against storage cost.

## Availability

The most important design consideration when it comes to availability is the
fact that Jaeger stays out of the critical path. A failure in any Jaeger
subsystem is not expected to impact the availability of the application.

As a result, Jaeger collects data on a best-effort basis. Data may be dropped at
several stages.

The application uses labkit to instrument its code and generate spans. This
instrumentation is designed to be lightweight, but there is no strict isolation,
as it runs within the application process.

Labkit sends trace data to the Jaeger Agent over loopback UDP, this ensures that
if the agent is unavailable, data will be dropped without blocking the
application.

The Jager Agent maintains an in-memory buffer of trace data that is batched up
and sent to the collector. This in-memory buffer is sized dynamically and has a
limited capacity. Large bursts may result in spans getting dropped.

The collector receives batches from agents and writes them to Elasticsearch. If
Elasticsearch is unavailable, data will be dropped at this stage.

Overall, we favour availability of the application -- should any of these components
fail, span data may be dropped. This keeps Jaeger out of the critical path.

We have monitoring and alerting in place for the Jaeger service to know when
this is occurring. See [the Jaeger service
dashboard](https://dashboards.gitlab.net/d/jaeger-main/jaeger-overview).

We do not expect to be able to withstand a zonal outage. This would require
operating the Elasticsearch cluster with twice the capacity. We choose instead
to sacrifice availability in this scenario, as is already the case with our
Elasticsearch logging cluster.

## Durability

Once data reaches Elasticsearch, we do replicate it, so that it will remain
durable and available for querying.

This should allow us to withstand single-node failures in Elasticsearch.

We perform periodic snapshots of the Elasticsearch cluster that allow restoring
indices after accidental deletion within Elasticsearch or a multi-node failure.

Snapshots are stored in a GCS bucket, this is tied to the Elastic Cloud
deployment, deletion of the deployment implies the deletion of snapshots.

## Security/Compliance

Fine-grained traces are a vector for data leaks. We sanitize all emitted spans
in an effort to remove PII. This includes removing parameters from Redis and
SQL queries. This redaction logic lives in [labkit](https://gitlab.com/gitlab-org/labkit) and [labkit-ruby](https://gitlab.com/gitlab-org/labkit-ruby).

Data in Jaeger is not archived and expires once the retention window of 7 days
has passed.

Jaeger is accessed through the Jaeger Query service. This service is fronted by
an IAP (Identity-Aware Proxy), named `jaeger/jaeger-query-tanka-managed`.

Access to Jaeger is granted to anyone within the `gitlab.com` domain. This
matches the access level provided for similar services, such as Kibana and
Thanos.

Regarding security updates, these are managed manually by the team owning the
Jaeger service, and applied via tanka and chef respectively. See the Deployment
section for more details.

## Monitoring/Alerting

We actively monitor the key components of Jaeger:

* Agent
* Collector
* Query
* Elasticsearch

SRE on-call is alerted on SLO violations.

See also: [the Jaeger grafana
dashboard](https://dashboards.gitlab.net/d/jaeger-main/jaeger-overview).

## Deployment

Jaeger is deployed and managed through
[tanka-deployments](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/tree/master/environments/jaeger).
We run the [Jaeger
Operator](https://www.jaegertracing.io/docs/latest/operator/), which is
responsible for provisioning all of the Jaeger components in Kubernetes.

We also deploy the Jaeger Agent to VMs, this is done through the [gitlab-jaeger
cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-jaeger).

## Configuration

### Client

Sample rates are tuned via [the `GITLAB_TRACING` environment
variable](https://docs.gitlab.com/ee/development/distributed_tracing.html#enabling-distributed-tracing). There are configured per-service.

* For VMs, this is done in [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo).
* For Kubernetes, this is done in [k8s-workloads](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads), for example [gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com) has an `extraEnv` setting.

A sample value used for the `api` service in gstg:

```
opentracing://jaeger?udp_endpoint=localhost%3A6831&sampler=probabilistic&sampler_param=0.1&service_name=api
```

Some third party components may support Jaeger without going through labkit, and
can be configured through custom config
([thanos](https://thanos.io/tip/thanos/tracing.md/)), or [the jaeger-client-go
environment
variables](https://github.com/jaegertracing/jaeger-client-go#environment-variables)
(prometheus).

The sampling rate should be below 1%, introduce negligible overhead on the
application, and be calibrated for our Elasticsearch storage capacity, based on
the target retention of 7 days.

Sampling rate configuration as supported by Jaeger is documented [in the Jaeger
docs](https://www.jaegertracing.io/docs/latest/sampling/).

### Jaeger Agent

The agent needs to be able to talk to the collector. In Kubernetes, discovery of
collectors is handled by the Jaeger Operator.

On VMs however, we need to configure the IP of the collector ingress. This is
done in:

* [`roles/gprd-base.json`](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gprd-base.json)
* [`roles/gstg-base.json`](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/gstg-base.json)

### Jaeger Collector and Jaeger Query

The Jaeger core services, collector and query, are managed through the Jaeger
Operator, and their config lives in
[tanka-deployments])(<https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments>).

## Ownership

The primary ownership of the Jaeger service lies with SRE Observability.

## Links to further Documentation

* [Jaeger](https://www.jaegertracing.io/docs/latest/)
* [Jaeger Operator](https://www.jaegertracing.io/docs/latest/operator/)
* [Distributed Tracing - development guidelines](https://docs.gitlab.com/ee/development/distributed_tracing.html)
* [OpenTelemetry](https://opentelemetry.io/)

