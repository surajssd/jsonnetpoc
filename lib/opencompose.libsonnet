local core = import "core.libsonnet";
local kubeUtil = import "util.libsonnet";

local container = core.v1.container;
local deployment = core.extensions.v1beta1.deployment + kubeUtil.app.v1beta1.deployment;
local service = core.v1.service;
local ingress = core.extensions.v1beta1.ingress;
local env = core.v1.env + kubeUtil.app.v1.env;
local port = core.v1.port + kubeUtil.app.v1.port;
local volume = core.v1.volume;

{
    local openlib = self,
    compact(array):: (
      {"kind": "List", "apiVersion": "v1"} +
      {"items": [x for x in array if x != null]}
    ),

    createIngress(name, params):: (
        if std.objectHas(params, "domain") then
            ingress.Default(name) +
            ingress.mixin.spec.Rule(params['domain'],
            ingress.httpIngressPath.Default(name, params['ports'][0].port))
        else
            null
    ),
    createSvc(name, params):: (
        if std.objectHas(params, 'ports') then
            service.Default(name,
                [{"port": p.port, "targetPort": p.port}
                for p in params['ports']],) +
            service.mixin.spec.Selector({ app: name })
    ),

    createPVC(name, mount):: (
        volume.claim.DefaultPersistent(name, [mount.accessMode], mount.size)
    ),

    createServices(services)::
        openlib.compact(std.flattenArrays(
            [openlib.createApp(service_name, services[service_name]),
             for service_name in std.objectFields(services)],)
        ),

    createApp(name, params)::
        local volumeMounts = [volume.mount.Default(m.name, m.mount) for m in params['mounts']];
        local containerApp =
            container.Default(name, params["image"]) +
            (if std.objectHas(params, 'env') then
               container.Env(env.array.FromObj(params["env"])) else {}) +
            (if std.objectHas(params, 'ports') then
                container.NamedPort(params['ports'][0].name,
                    params['ports'][0].port) else {}) +
            (if std.objectHas(params, 'mounts') then
                container.VolumeMounts(volumeMounts) else {});

        local deployApp = deployment.FromContainer(name, 2, containerApp) +
                          (if std.objectHas(params, 'mounts') then
                          deployment.mixin.podTemplate.Volumes([volume.persistent.Default(m.name, m.name) for m in params['mounts']])
                          else {});
        local svcApp = openlib.createSvc(name, params);
        local ingressApp = openlib.createIngress(name, params);

        local pvcs = if std.objectHas(params, 'mounts') then
                        [openlib.createPVC(name, mount) for mount in params['mounts']] else [];

        [ingressApp, svcApp, deployApp] + pvcs,

}
