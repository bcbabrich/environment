Write-Host "Importing vi alias..." -NoNewline
New-Alias -Name vi -value 'C:\Users\Z3882\Programs\vim\vim82\vim.exe'
Write-Host "Done."

Write-Host "Importing nvim alias..." -NoNewline
New-Alias -Name nvim -value 'C:\Users\Z3882\Programs\nvim-win64\bin\nvim.exe'
Write-Host "Done."

Write-Host "Importing git alias..." -NoNewline
$env:PATH += ';C:\Program Files\Git\bin;'
Write-Host "Done."

Write-Host "Importing mvn alias..." -NoNewline
$env:PATH += 'C:\devtools\Apache\Maven_3.8.1\bin;'
Write-Host "Done."

Write-Host "Importing posh-git module..." -NoNewline
Import-Module posh-git
Write-Host "Done."

$NvimExe = 'C:\Users\Z3882\Programs\nvim-win64\bin\nvim.exe'

function ConvertTo-CamelCase {
	param([string]$Dir)
	$CamelCased = ''
	($Dir -replace '_', '-') -split '-' | Select-Object -Skip 2 | ForEach-Object {
		$CamelCased += $_.substring(0,1).toupper()+$_.substring(1).tolower()
	}
	return $CamelCased
}
$Root = 'C:\GitHubRepos'
$FrontEnd = Join-Path $Root 'FE'
$MidTier = Join-Path $Root 'MT'

$Dirs = $FrontEnd, $MidTier
$DirVars = @{}

Get-Childitem $Dirs | ForEach-Object {
	$Name = ConvertTo-CamelCase $_
	$Value = $_.FullName
	$DirVars.add("`$$Name", $Value)
	Set-Variable -Name $Name -Value $Value
}

Write-Host "Available dir vars to jump to:"
$DirVars | Format-Table

function prompt {
 $p = Split-Path -leaf -path (Get-Location)
 "$p> "
}

function Reset-Npm {
	& npm cache clean --force
	& npm config set registry https://repo.artifactory.csx.com/artifactory/api/npm/npmjs-group/
	& npm config set cafile "C:\Users\Z3882\OneDrive - CSX\Documents\zscalerrootca-1.0.0.crt"
	& npm config set strict-ssl false
}

function Open-Jenkins {
		param(
			[string]$Repo,
			[string]$Branch
		)
		[system.Diagnostics.Process]::Start("chrome",'https://jenkins.apps.ocpjaxp001.csx.com/job/Asset%20-%20Infrastructure%20Mgmt/job/'+ $Repo +'/job/'+($Branch -replace '\/', '%252F'))
}

function Push-AllGitChanges {
		param([string]$CommitMessage)
		
		Write-Host "Adding all changes..." -ForegroundColor Blue
		& git add . | Out-Null
		Write-Host "Committing changes with message" -ForegroundColor Blue -NoNewline
		Write-Host " '$CommitMessage' " -ForegroundColor Yellow -NoNewline
		Write-Host "..." -ForegroundColor Blue
		& git commit -m $CommitMessage | Out-Null
		Set-Clipboard $CommitMessage
		Write-Host "Your commit message has been copied to your clipboard" -ForegroundColor Blue
		Write-Host "Pulling..." -ForegroundColor Blue
		& git pull | Out-Null
		Write-Host "Pushing..." -ForegroundColor Blue
		& git push
		Write-Host "Done" -ForegroundColor Green

}

Set-Alias -Name cd -Value pushd  -Option AllScope -Force
Set-Alias -Name bd -Value popd  -Option AllScope

Write-Host "Importing Set-GitSsh function..."

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

# Copy this into your powershell profile (type '$profile' to get path)
# Lets you use Set-GitSsh whenever you want, without need padding to this file...
function Set-GitSsh {

  param (
    [string]$Profile,
    [switch]$InSecure
  )

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

}
