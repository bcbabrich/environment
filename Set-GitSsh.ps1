# --------------------------------------------------------------------------
# Different computers have different ssh homes, key names, emails...
# Make these parameters first.
# Password-protected "Add-GitSshProfile"?
# Perhaps even okta-integrated
# Someday this could be for linux...
# Probaly not secure to keep different private ssh keys in the same place
#  - https://mcpmag.com/articles/2017/07/20/save-and-read-sensitive-data-with-powershell.aspx
#  - https://latacora.singles/2018/08/03/the-default-openssh.html
#  Network drive provides one current layer of security though

# script-scoped params have to be first thing in file
param (
  [string]$Profile,
  [switch]$InSecure
)

function Copy-Keys {
  param(
    [string]$SshDir,
    [string]$PrivateKeyName,
    [string]$PublicKeyName,
    [string]$IdRsa,
    [string]$IdRsaPub,
    [switch]$InSecure
  )

  $PrivateKeyPath = Join-Path $SshDir $PrivateKeyName
  $NewPrivateKeyPath = Join-Path $SshDir $IdRsa

  $PublicKeyPath = Join-Path $SshDir $PublicKeyName
  $NewPublicKeyPath = Join-Path $SshDir $IdRsaPub
  
  Write-Host "Copying over ssh keys..." -ForeGroundColor Blue

  if ($InSecure){

    Write-Host "You probably already know this, but the -Insecure switch was used... watch your back" -ForeGroundColor Red
    Copy-Item -Path $PrivateKeyPath -Destination $NewPrivateKeyPath
    Copy-Item -Path $PublicKeyPath -Destination $NewPublicKeyPath

  } else {

    Get-Content -Path $PrivateKeyPath `
    | ConvertTo-SecureString  -AsPlainText -Force `
    | Set-Content -Path $NewPrivateKeyPath -Value `
      [Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR((($_))))

    Get-Content -Path $PublicKeyPath `
    | ConvertTo-SecureString  -AsPlainText -Force `
    | Set-Content -Path $NewPublicKeyPath -Value `
      [Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR((($_))))

  }

}

function Set-GitConfig {
  param (
    [string]$UserName,
    [string]$UserEmail
  )
  Write-Host "... and setting git config credentials using '$UserEmail' and '$UserName'" -ForeGroundColor Blue
  & git config --global user.email $UserEmail
  & git config --global user.name $SwitchOn
}

######################################################################### BEGIN


# These should be constants
$IdRsa = 'id_rsa'
$IdRsaPub = 'id_rsa.pub'
Write-Host "Assuming your current ssh keys are named '$IdRsa' and '$IdRsaPub'" -ForeGroundColor Blue

# I don't trust powershell's null checking ability
$ProfileFound = $false

# User can omit 'profile' param and see if their profile is added
if ($PSBoundParameters.ContainsKey('Profile')){
  $SwitchOn = $Profile
  Write-Host "No profile passed in, using '$SwitchOn' as profile!" -ForeGroundColor Yellow
} else {
  $SwitchOn = $env:UserName
}

######################### Get info for profile passed in

Write-Host "Getting profile for '$SwitchOn'..." -ForeGroundColor Blue
switch ( $SwitchOn ) 
{     
  'Z3882' { 

    $SshDir         = 'H:\.ssh' ;
    $PrivateKeyName = 'id_rsa_csx';
    $PublicKeyName  = $PrivateKeyName + '.pub';
    $UserEmail      = $SwitchOn + '@csx.com';

    $ProfileFound = $true

}
  'bcbabrich' { 

    $SshDir         = 'H:\.ssh' 
    $PrivateKeyName = 'id_rsa_personal'
    $PublicKeyName  = $PrivateKeyName + '.pub'
    $UserEmail      = $SwitchOn + '@gmail.com'

    $ProfileFound = $true

}
  default { Write-Host 'Sorry, your profile was not found' -ForeGroundColor Red }
}

################################## Copy keys over using profile info

if ($ProfileFound){

  Write-Host "Your profile was found! Your ssh dir is located at '$SshDir'" -ForeGroundColor Magenta
  Set-GitConfig -UserName $SwitchOn -UserEmail $UserEmail
  $Params = @{
    'SshDir' = $SshDir;
    'IdRsa' = $IdRsa
    'IdRsaPub' = $IdRsaPub
    'PublicKeyName' = $PublicKeyName
    'PrivateKeyName' = $PrivateKeyName
    'InSecure' = $InSecure
  }
  Copy-Keys @Params
  Write-Host "Done" -ForeGroundColor Green

}

