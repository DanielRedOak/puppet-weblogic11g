# == Define: wls::utils::orainst
#
#  creates oraInst.loc
# 
#
## 
define wls::utils::orainst( 
  $oraInventory    = undef,
  $group           = 'oinstall',
) {

  $oraInstPath        = "/etc"
  if ! defined(File["${oraInstPath}/oraInst.loc"]) {
    file { "${oraInstPath}/oraInst.loc":
      ensure  => present,
      content => template("wls/utils/oraInst.loc.erb"),
    }
  }
}
