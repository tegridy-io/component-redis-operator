// main template for redis-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prometheus.libsonnet';
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

// Define outputs below
{
  '00_namespace': if hasPrometheus then prom.RegisterNamespace(namespace) else namespace,
}
