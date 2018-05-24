# == Class: icingaweb2::module::monitoring
#
# Manage the monitoring module. This module is mandatory for probably every setup.
#
# === Parameters
#
# [*ensure*]
#   Enable or disable module. Defaults to `present`
#
# [*protected_customvars*]
#   Custom variables in Icinga 2 may contain sensible information. Set patterns for custom variables that should be
#   hidden in the web interface. Defaults to `*pw*,*pass*,community`
#
# [*ido_type*]
#   Type of your IDO database. Either `mysql` or `pgsql`. Defaults to `mysql`
#
# [*ido_host*]
#   Hostname of the IDO database.
#
# [*ido_port*]
#   Port of the IDO database. Defaults to `3306`
#
# [*ido_db_name*]
#   Name of the IDO database.
#
# [*ido_db_username*]
#   Username for IDO DB connection.
#
# [*ido_db_password*]
#   Password for IDO DB connection.
#
# [*ido_db_charset*]
#   The character set to use for the database connection.
#
# [*commandtransports*]
#   A hash of command transports.
#
class icingaweb2::module::monitoring(
  Enum['absent', 'present']      $ensure               = 'present',
  Variant[String, Array[String]] $protected_customvars = ['*pw*', '*pass*', 'community'],
  Enum['mysql', 'pgsql']         $ido_type             = 'mysql',
  Optional[String]               $ido_host             = undef,
  Integer[1,65535]               $ido_port             = 3306,
  Optional[String]               $ido_db_name          = undef,
  Optional[String]               $ido_db_username      = undef,
  Optional[String]               $ido_db_password      = undef,
  Optional[String]               $ido_db_charset       = undef,
  Boolean                        $ido_db_use_ssl       = false,
  Optional[Stdlib::Absolutepath] $ido_db_ssl_cert      = undef,
  Optional[Stdlib::Absolutepath] $ido_db_ssl_key       = undef,
  Optional[Stdlib::Absolutepath] $ido_db_ssl_ca        = undef,
  Optional[Stdlib::Absolutepath] $ido_db_ssl_capath    = undef,
  Optional[String]               $ido_db_ssl_cipher    = undef,
  Hash                           $commandtransports    = undef,
){

  $conf_dir        = $::icingaweb2::params::conf_dir
  $module_conf_dir = "${conf_dir}/modules/monitoring"

  case $::osfamily {
    'Debian': {
      $install_method = 'package'
      $package_name   = 'icingaweb2-module-monitoring'
    }
    default: {
      $install_method = 'none'
      $package_name   = undef
    }
  }

  icingaweb2::config::resource { 'icingaweb2-module-monitoring':
    type          => 'db',
    db_type       => $ido_type,
    host          => $ido_host,
    port          => $ido_port,
    db_name       => $ido_db_name,
    db_username   => $ido_db_username,
    db_password   => $ido_db_password,
    db_charset    => $ido_db_charset,
    db_use_ssl    => $ido_db_use_ssl,
    db_ssl_cert   => $ido_db_ssl_cert,
    db_ssl_key    => $ido_db_ssl_key,
    db_ssl_ca     => $ido_db_ssl_ca,
    db_ssl_capath => $ido_db_ssl_capath,
    db_ssl_cipher => $ido_db_ssl_cipher,
  }

  $backend_settings = {
    'type'     => 'ido',
    'resource' => 'icingaweb2-module-monitoring',
  }

  $security_settings = {
    'protected_customvars' => $protected_customvars ? {
      String        => $protected_customvars,
      Array[String] => join($protected_customvars, ','),
    }
  }

  $settings = {
    'module-monitoring-backends' => {
      'section_name' => 'backends',
      'target'       => "${module_conf_dir}/backends.ini",
      'settings'     => delete_undef_values($backend_settings)
    },
    'module-monitoring-security' => {
      'section_name' => 'security',
      'target'       => "${module_conf_dir}/config.ini",
      'settings'     => delete_undef_values($security_settings)
    }
  }

  create_resources('icingaweb2::module::monitoring::commandtransport', $commandtransports)

  icingaweb2::module {'monitoring':
    ensure         => $ensure,
    install_method => $install_method,
    package_name   => $package_name,
    settings       => $settings,
  }
}
