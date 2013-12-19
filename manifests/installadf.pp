define wls::installadf(
  $mdwHome = undef,
  $wlHome = undef,
  $oracleHome = undef,
  $JAVA_HOME = undef,
  $adfFile = undef,
  $mountPoint = undef,
){
  #Setup some file locations
  $commonOracleHome = "${mdwHome}/oracle_common"
  $execPath         = "${JAVA_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
  #Lets put all of the install related stuff in tmp...
  $path             = "/tmp"
  $oraInventory     = "${oracleHome}/oraInventory"
  $adfInstallDir    = "linux64"
  $jreLocDir        = "${JAVA_HOME}"
  $adfTemplate      =  "wls/silent_adf.xml.erb"

  #Defaults for the execs and file
  Exec { path      => $execPath,
         user      => $user,
         group     => $group,
         logoutput => true,
       }
  File {
         ensure  => present,
         mode    => 0775,
         owner   => $user,
         group   => $group,
         backup  => false,
       }
  
  #setup the oraInventory
  wls::utils::orainst{'create adf oraInst':
           oraInventory    => $oraInventory,
           group           => $group,
   }  


  #check and grab the adf installer from the specified mount point
  if ! defined(File["${path}/${adfFile}"]) {
   file { "${path}/${adfFile}":
    source  => "${mountPoint}/${adfFile}",
    require => Wls::Utils::Orainst ['create adf oraInst'],
   }
  }

  #setup the command to run
  $command  = "-silent -response ${path}/${title}silent_adf.xml -waitforcompletion "

  #grab the silent installer
  file { "${path}/${title}silent_adf.xml":
         ensure  => present,
         content => template($adfTemplate),
       }
  #install adf using the grabbed adf installer + the command we build and the jreLocation
  exec { "install adf ${title}":
         command     => "${path}/adf/Disk1/install/${adfInstallDir}/runInstaller ${command} -invPtrLoc /etc/oraInst.loc -ignoreSysPrereqs -jreLoc ${jreLocDir}",
         require     => [File ["${path}/${title}silent_adf.xml"],Exec["extract ${adfFile}"]],
         creates     => $commonOracleHome,
       }
}
