local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.redis_operator;


local defaultKubeConfig(image) = {
  image: '%(registry)s/%(repository)s:%(tag)s' % image,
  imagePullPolicy: 'IfNotPresent',
  resources: {
    requests: {
      cpu: '100m',
      memory: '128Mi',
    },
    limits: {
      cpu: '100m',
      memory: '128Mi',
    },
  },
};

local defaultExporter(image) = {
  enabled: true,
  image: '%(registry)s/%(repository)s:%(tag)s' % image,
  imagePullPolicy: 'IfNotPresent',
  resources: {
    requests: {
      cpu: '100m',
      memory: '128Mi',
    },
    limits: {
      cpu: '100m',
      memory: '128Mi',
    },
  },
};

local defaultAffinity(name) = {
  podAntiAffinity: {
    requiredDuringSchedulingIgnoredDuringExecution: [
      {
        labelSelector: {
          matchExpressions: [
            {
              key: 'app.kubernetes.io/component',
              operator: 'In',
              values: [ 'redis' ],
            },
            {
              key: 'app.kubernetes.io/name',
              operator: 'In',
              values: [ name ],
            },
          ],
        },
        topologyKey: 'kubernetes.io/hostname',
      },
    ],
  },
};


/**
  * \brief Helper to create RedisReplication objects.
  *
  * \arg The name of the database.
  * \return A RedisReplication object.
  */
local replication(name, namespace, spec) = kube._Object('redis.redis.opstreelabs.in/v1beta2', 'RedisReplication', name) {
  assert spec.nodes >= 3 : 'Parameter nodes should be >= 3.',
  assert spec.nodes % 2 != 0 : 'Parameter nodes should be a odd number.',
  metadata+: {
    labels+: {
      'app.kubernetes.io/component': 'redis',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: namespace,
  },
  spec+: {
    affinity: defaultAffinity(name),
    clusterSize: spec.nodes,
    kubernetesConfig: defaultKubeConfig(params.images.redis),
    redisExporter: defaultExporter(params.images.exporter),
    storage: {
      volumeClaimTemplate: {
        spec: {
          accessModes: [ spec.storage.accessMode ],
          storageClassName: spec.storage.storageClass,
          resources: {
            requests: { storage: spec.storage.size },
          },
        },
      },
    },
  },
};


/**
  * \brief Helper to create RedisCluster objects.
  *
  * \arg The name of the database.
  * \return A RedisCluster object.
  */
local cluster(name, namespace, spec) = kube._Object('redis.redis.opstreelabs.in/v1beta2', 'RedisCluster', name) {
  assert spec.nodes >= 3 : 'Parameter nodes should be >= 3.',
  assert spec.nodes % 2 != 0 : 'Parameter nodes should be a odd number.',
  local persistenceEnabled = std.get(spec, 'persistenceEnabled', false),
  metadata+: {
    labels+: {
      'app.kubernetes.io/component': 'redis',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: namespace,
  },
  spec+: {
    affinity: defaultAffinity(name),
    clusterVersion: std.split(params.images.redis.tag, '.')[0],
    clusterSize: spec.nodes,
    persistenceEnabled: persistenceEnabled,
    kubernetesConfig: defaultKubeConfig(params.images.redis),
    redisExporter: defaultExporter(params.images.exporter),
    storage: if !persistenceEnabled then {
      volumeMount: {
        volume: [
          { name: 'node-conf', emptyDir: { sizeLimit: '1Mi' } },
        ],
        mountPath: [
          { name: 'node-conf', mountPath: '/node-conf' },
        ],
      },
    } else {
      volumeClaimTemplate: {
        spec: {
          accessModes: [ spec.storage.accessMode ],
          storageClassName: spec.storage.storageClass,
          resources: {
            requests: { storage: spec.storage.size },
          },
        },
      },
    },
  },
};


{
  replication: replication,
  cluster: cluster,
}
