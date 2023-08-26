local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.redis_operator;


/**
  * \brief Helper to create RedisCluster objects.
  *
  * \arg The name of the database.
  * \return A RedisCluster object.
  */
local cluster(name, namespace, spec) = kube._Object('redis.redis.opstreelabs.in/v1beta1', 'RedisCluster', name) {
  assert spec.nodes >= 3 : 'Parameter nodes should be >= 3.',
  assert spec.nodes % 2 != 0 : 'Parameter nodes should be a odd number.',
  metadata+: {
    labels+: {
      'app.kubernetes.io/component': 'cache',
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
    namespace: namespace,
  },
  spec+: {
    clusterSize: spec.nodes,
    clusterVersion: std.split(params.images.redis.version, '.'),
    persistenceEnabled: true,
    //    podSecurityContext: {
    //      runAsUser: 1000,
    //      fsGroup: 1000,
    //    },
    kubernetesConfig: {
      image: '%(registry)s/%(repository)s:%(tag)s' % params.images.redis,
      imagePullPolicy: IfNotPresent,
      //      resources: {
      //        requests:
      //          cpu: 101m
      //          memory: 128Mi
      //        limits:
      //          cpu: 101m
      //          memory: 128Mi
      //          # redisSecret:
      //          #   name: redis-secret
      //          #   key: password
      //          # imagePullSecrets:
      //          #   - name: regcred
    },
    //      redisExporter:
    //        enabled: false
    //        image: quay.io/opstree/redis-exporter:v1.44.0
    //        imagePullPolicy: Always
    //        resources:
    //          requests:
    //            cpu: 100m
    //            memory: 128Mi
    //          limits:
    //            cpu: 100m
    //            memory: 128Mi
    //            # Environment Variables for Redis Exporter
    //            # env:
    //            # - name: REDIS_EXPORTER_INCL_SYSTEM_METRICS
    //            #   value: "true"
    //            # - name: UI_PROPERTIES_FILE_NAME
    //            #   valueFrom:
    //            #     configMapKeyRef:
    //            #       name: game-demo
    //            #       key: ui_properties_file_name
    //            # - name: SECRET_USERNAME
    //            #   valueFrom:
    //            #     secretKeyRef:
    //            #       name: mysecret
    //            #       key: username
    //            #  redisLeader:
    //            #    redisConfig:
    //            #      additionalRedisConfig: redis-external-config
    //            #  redisFollower:
    //            #    redisConfig:
    //            #      additionalRedisConfig: redis-external-config
    //      storage:
    //        volumeClaimTemplate:
    //          spec:
    //            # storageClassName: standard
    //            accessModes: ["ReadWriteOnce"]
    //            resources:
    //              requests:
    //                storage: 1Gi
    //        nodeConfVolume: true
    //        nodeConfVolumeClaimTemplate:
    //          spec:
    //            accessModes: ["ReadWriteOnce"]
    //            resources:
    //              requests:
    //                storage: 1Gi
    //                # nodeSelector:
    //                #   kubernetes.io/hostname: minikube
    //                # priorityClassName:
    //                # Affinity:
    //                # Tolerations: []
  },
};


/**
  * \brief Helper to create CockroachDB client.
  *
  * \arg The name of the database client.
  * \return A Deployment object.
  */
// local client(name, namespace) = kube.Deployment(name + '-client') {
//   metadata+: {
//     labels+: {
//       'app.kubernetes.io/component': 'database-client',
//       'app.kubernetes.io/managed-by': 'commodore',
//       'app.kubernetes.io/name': name + '-client',
//     },
//     namespace: namespace,
//   },
//   spec+: {
//     replicas: 1,
//     template+: {
//       spec+: {
//         serviceAccountName: 'default',
//         securityContext: {
//           seccompProfile: { type: 'RuntimeDefault' },
//         },
//         containers_:: {
//           default: kube.Container('client') {
//             image: '%(registry)s/%(repository)s:%(tag)s' % params.images.cockroach,
//             env_:: {
//               COCKROACH_CERTS_DIR: '/cockroach/certs-dir',
//               COCKROACH_HOST: name + '-public',
//             },
//             command: [ 'sleep', 'infinity' ],
//             securityContext: {
//               allowPrivilegeEscalation: false,
//               capabilities: { drop: [ 'ALL' ] },
//             },
//             volumeMounts_:: {
//               certs: { mountPath: '/cockroach/certs-dir' },
//             },
//           },
//         },
//         volumes_:: {
//           certs: {
//             secret: {
//               secretName: name + '-root',
//               items: [
//                 { key: 'ca.crt', path: 'ca.crt' },
//                 { key: 'tls.crt', path: 'client.root.crt' },
//                 { key: 'tls.key', path: 'client.root.key' },
//               ],
//             },
//           },
//         },
//       },
//     },
//   },
// };


{
  cluster: cluster,
  //   client: client,
}
