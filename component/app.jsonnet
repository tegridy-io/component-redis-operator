local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.redis_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('redis-operator', params.namespace);

{
  'redis-operator': app,
}
