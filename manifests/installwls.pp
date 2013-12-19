#This module requires jrockit to be installed
class weblogic11g::installwls (
  $oracle_home = '/u01/app/oracle/middleware',
  $wl_install_dir = '/u01/app/oracle/middleware/wlserver_10.3',
  $JAVA_HOME = '/u01/app/oracle/jrockit',
  $oracle_user = 'oracle',
  $oracle_group = 'oinstall',
  $mountPoint = undef,
  $install_jar = 'wls1036_generic.jar',
){
  File {
    owner => $oracle_user,
    group => $oracle_group,
  }

  file {"/tmp/wl11g_silent.xml":
    ensure  => present,
    content => template('weblogic11g/silent.xml.erb'),
    replace => true,
  }

  exec {'install_weblogic':
    path      => "/bin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:${JAVA_HOME}/bin",
    provider  => 'shell',
    user      => $oracle_user,
    command   => "${JAVA_HOME}/bin/java -jar ${mountPoint}/${install_jar} -mode=silent -silent_xml=\"/tmp/wl11g_silent.xml\"",
    creates   => $wl_install_dir,
    require   => File ['/tmp/wl11g_silent.xml'],
    logoutput => true,
  }
}


