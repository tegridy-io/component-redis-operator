// main template for redis-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prometheus.libsonnet';
local redis = import 'lib/redis-operator.libsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.redis_operator;
local hasPrometheus = std.member(inv.applications, 'prometheus');

local namespace = kube.Namespace(params.namespace) {
  //   metadata+: {
  //     labels+: {
  //       'pod-security.kubernetes.io/enforce': 'restricted',
  //     },
  //   },
};

local database(name) = [
  // namespace
  kube.Namespace(params.databases[name].namespace),
  // database
  if params.databases[name].type == 'replication' then
    redis.replication(name + '-redis', params.databases[name].namespace, params.databases[name])
  else if params.databases[name].type == 'cluster' then
    redis.cluster(name + '-redis', params.databases[name].namespace, params.databases[name])
  else {},
];


// Define outputs below
{
  '00_namespace': if hasPrometheus then prom.RegisterNamespace(namespace) else namespace,
} + {
  ['20_db_' + name]: database(name)
  for name in std.objectFields(params.databases)
}
