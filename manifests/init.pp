#This module requires jrockit to be installed
class weblogic11g (
  $oracle_home = '/u01/app/oracle/middleware',
  $wl_install_dir = '/u01/app/oracle/middleware/wlserver_10.3',
  $jrockit_path = '/u01/app/oracle/jrockit',
  $oracle_user = 'oracle',
  $oracle_group = 'oinstall',
  $install_jar = '/tmp/wls1036_generic.jar',
){
  File {
    owner => $oracle_user,
    group => $oracle_group,
  }

  file {"/tmp/wl11g_silent.xml":
    ensure  => file,
    content => template('weblogic11g/silent.xml.erb'),
    replace => false,
  }

  exec {'install_weblogic':
    path     => "/bin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:${jrockit_path}/bin",
    provider => 'shell',
    user     => $oracle_user,
    command  => "${jrockit_path}/bin/java -jar ${install_jar} -mode=silent -silent_xml=\"/tmp/wl11g_silent.xml\"",
    creates  => $wl_install_dir,
    require  => File ['/tmp/wl11g_silent.xml'],
  }
}


