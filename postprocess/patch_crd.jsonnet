local com = import 'lib/commodore.libjsonnet';

local listTemplates = [
  {
    name: std.strReplace(name, '.yaml', ''),
    manifest: com.yaml_load_all(std.extVar('output_path') + '/' + name),
  }
  for name in com.list_dir(std.extVar('output_path'), basename=true)
];

{
  [template.name]: std.filter(function(it) it != null, template.manifest)
  for template in listTemplates
}
