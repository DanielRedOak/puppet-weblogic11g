# == Define: wls::wlstexec
#
# generic wlst script
#
# pass on the weblogic username or password
# or provide userConfigFile and userKeyFile file locations
#
# === Examples
#
#  case $operatingsystem {
#     centos, redhat, OracleLinux, Ubuntu, debian: {
#       $osMdwHome    = "/opt/oracle/wls/wls11g"
#       $osWlHome     = "/opt/oracle/wls/wls11g/wlserver_10.3"
#       $osDomainPath = "/opt/oracle/wls/wls11g/admin"
#       $user         = "oracle"
#       $group        = "dba"
#     }
#  }
#
#  # default parameters for the wlst scripts
#  Wls::Wlstexec {
#    wlsDomain    => "${osDomainPath}/osbDomain",
#    wlHome       => $osWlHome,
#    fullJDKName  => $jdkWls11gJDK,
#    user         => $user,
#    group        => $group,
#    address      => "localhost",
#    wlsUser      => "weblogic",
#    password     => "weblogic1",
#    port         => "5556",
#  }
#
#  # create jdbc datasource for osb_server1
#  wls::wlstexec {
#
#    'createJdbcDatasourceHr':
#     wlstype       => "jdbc",
#     wlsObjectName => "hrDS",
#     script        => 'createJdbcDatasource.py',
#     params        => ["dsName                      = 'hrDS'",
#                      "jdbcDatasourceTargets       = 'AdminServer,osb_server1'",
#                      "dsJNDIName                  = 'jdbc/hrDS'",
#                      "dsDriverName                = 'oracle.jdbc.xa.client.OracleXADataSource'",
#                      "dsURL                       = 'jdbc:oracle:thin:@master.alfa.local:1521/XE'",
#                      "dsUserName                  = 'hr'",
#                      "dsPassword                  = 'hr'",
#                      "datasourceTargetType        = 'Server'",
#                      "globalTransactionsProtocol  = 'xxxx'"
#                      ],
#  }
#
#
define wls::wlstexec ($version        = '1111',
                      $wlsDomain      = undef,
                      $wlstype        = undef,
                      $wlsObjectName  = undef,
                      $wlHome         = undef,
                      $JAVA_HOME      = undef,
                      $script         = undef,
                      $address        = "localhost",
                      $port           = '7001',
                      $wlsUser        = undef,
                      $password       = undef,
                      $user           = 'oracle',
                      $group          = 'oinstall',
                      $params         = undef,
                      $logOutput      = false,
                      ) {
   #prep the main java command
   $javaCommand    = "java -Dweblogic.security.SSL.ignoreHostnameVerification=true weblogic.WLST -skipWLSModuleScanning "
   #set our overall exec path
   $execPath         = "${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
   #do the running from tmp
   $path             = '/tmp'

   Exec { path      => $execPath,
          user      => $user,
          group     => $group,
          logoutput => $logOutput,
        }
   File {
          ensure  => present,
          replace => true,
          mode    => 0555,
          owner   => $user,
          group   => $group,
          backup  => false,
        }

   #get the script from templates
   file { "${path}/${title}${script}":
      path    => "${path}/${title}${script}",
      content => template("${script}.erb"),
   }

   #execure WLST with the specified script
   exec { "execwlst ${title}${script}":
      command     => "${javaCommand} ${path}/${title}${script}",
      environment => ["CLASSPATH=${wlHome}/server/lib/weblogic.jar",
                      "JAVA_HOME=${JAVA_HOME}"],
      require     => File["${path}/${title}${script}"],
   }
   
   #clean things up when we are done
   exec { "rm ${path}/${title}${script}":
      command => "rm ${path}/${title}${script}",
      require => Exec["execwlst ${title}${script}"],
  }
}
