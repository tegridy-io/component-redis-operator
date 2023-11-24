local com = import 'lib/commodore.libjsonnet';

local listTemplates = [
  {
    name: std.strReplace(name, '.yaml', ''),
    manifest: com.yaml_load_all(std.extVar('output_path') + '/' + name),
  }
  for name in com.list_dir(std.extVar('output_path'), basename=true)
];

local argocdPatch = {
  metadata+: {
    annotations+: {
      'argocd.argoproj.io/sync-options': 'Replace=true',
    },
  },
};

{
  [template.name]: std.filterMap(function(it) it != null, function(it) it + argocdPatch, template.manifest)
  for template in listTemplates
}
