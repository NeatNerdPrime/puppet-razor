# == Define: razor::razor_yaml_setting
#
# Helper define for working with yaml configurations settings.
#
# === Authors
#
# Jeremy Custenborder <jcustenborder@gmail.com>
#
define razor::razor_yaml_setting (
  $value, # Untyped - can be many things
  Enum['present', 'absent'] $ensure = 'present',
  Optional[String] $value_type      = undef,
  String $target                    = $::razor::server_config_path,
  String $export_tag                = 'razor-server'
) {
  yaml_setting { $name:
    ensure => $ensure,
    key    => $name,
    target => $target,
    type   => $value_type,
    value  => $value,
    tag    => $export_tag,
  }
}
