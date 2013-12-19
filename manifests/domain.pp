define weblogic11g::domain (
  $wlUser          = undef,
  $password        = undef,
  $wlHome          = undef,
  $mdwHome         = undef,
  $domain          = undef,
  $adminServerName = "AdminServer",
  $adminListenAdr  = "localhost",
  $adminListenPort = '7001',
  $nodemanagerPort = '5556',
  $wlsTemplate     = 'standard',
  $developmentMode = false,
  $JAVA_HOME       = undef,
){

  #This defined type will select the appropriate template from the installed WL instance, 
  #then create a python script using the appropriate domain.xml file as a template filling
  #in variables with information passed in here.

  #NOTE: If these are updated to be customizable, make sure that they get created.  This has not been done in this version.
  $domainPath         = "${mdwHome}/user_projects/domains"
  $nodeMgrLogDir      = "${domainPath}/${domain}/nodemanager/nodemanager.log"
  $adminNodeMgrLogDir = "${domainPath}/${domain}/servers/${adminServerName}/logs"
  $appPath            = "${mdwHome}/user_projects/applications"
  ##TODO: check if domain exists
   
  #Basic WebLogic Server Domain Template
  $template             = "${wlHome}/common/templates/domains/wls.jar"
  #WebLogic Server Starter Domain Template
  $templateWS           = "${wlHome}/common/templates/applications/wls_webservice.jar"
  #Enterprise Manager Template
  $templateEM           = "${mdwHome}/oracle_common/common/templates/applications/oracle.em_11_1_1_0_0_template.jar"
  #Oracle Java Required Files (JRF) Template
  $templateJRF          = "${mdwHome}/oracle_common/common/templates/applications/jrf_template_11.1.1.jar"

  #Select the template we'll use
  if $wlsTemplate == 'standard' {
    $templateFile  = "wls/domains/domain.xml.erb"
    $wlstPath      = "${wlHome}/common/bin"

  } elsif $wlsTemplate == 'adf' {
      $templateFile  = "wls/domains/domain_adf.xml.erb"
      $wlstPath      = "${mdwHome}/oracle_common/common/bin"
      $oracleHome    = "${mdwHome}/oracle_common"
  }

  $execPath         = "${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin"
  $path             = $downloadDir
  $nodeMgrMachine   = "UnixMachine"

  Exec { path      => $execPath,
         user      => $user,
         group     => $group,
         logoutput => true,
       }
  File {
         ensure  => present,
         replace => true,
         mode    => 0775,
         owner   => $user,
         group   => $group,
         backup  => false,
       }

  #Make the python script to create the domain
  file { "domain.py ${domain} ${title}":
    path    => "${path}/domain_${domain}.py",
    content => template($templateFile),
  }

  # double check for the projects, domain, and applications folders
  if !defined(File["weblogic_domain_folder"]) {
    # check oracle install folder
    file { "weblogic_domain_folder":
      path    => "${mdwHome}/user_projects",
      ensure  => directory,
      recurse => false,
      replace => false,
    }
  }
  if !defined(File[$domainPath]) {
    file { $domainPath:
      ensure  => directory,
      recurse => false,
      replace => false,
      require => File["weblogic_domain_folder"],
    }
  }
  if !defined(File[$appPath]) {
    file { $appPath:
      ensure  => directory,
      recurse => false,
      replace => false,
      require => File["weblogic_domain_folder"],
    }
  }
  #Use the Weblogic Scripting Tool with the templated domain.py script
  #This won't run again if the domain already exists (using test)
  exec { "execwlst ${domain} ${title}":
    command     => "${wlstPath}/wlst.sh ${path}/domain_${domain}.py",
    environment => ["JAVA_HOME=${JAVA_HOME}"],
    unless      => "/usr/bin/test -e ${domainPath}/${domain}",
    creates     => "${domainPath}/${domain}",
    require     => [File["domain.py ${domain} ${title}"],
                    File[$domainPath],
                    File[$appPath]],
    timeout     => 0,
  }
  #Check and turn off debug
  exec { "setDebugFlagOnFalse ${domain} ${title}":
    command => "sed -i -e's/debugFlag=\"true\"/debugFlag=\"false\"/g' ${domainPath}/${domain}/bin/setDomainEnv.sh",
    onlyif  => "/bin/grep debugFlag=\"true\" ${domainPath}/${domain}/bin/setDomainEnv.sh | /usr/bin/wc -l",
    require => Exec["execwlst ${domain} ${title}"],
  }
  #Cleanup the generated domain script
  exec { "domain.py ${domain} ${title}":
    command     => "rm ${path}/domain_${domain}.py",
    require     => Exec["execwlst ${domain} ${title}"],
  }
  
  $nodeMgrHome  = "${domainPath}/${domain}/nodemanager"
  $listenPort   = $nodemanagerPort
}
