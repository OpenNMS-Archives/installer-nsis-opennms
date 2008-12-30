!define POLICY_LOOKUP_NAMES 0x00000800
!define POLICY_LOOKUP_NAMES_CREATE_ACCOUNT 0x00000810
!define strLSA_OBJECT_ATTRIBUTES '(i,i,w,i,i,i)i'
!define strLSA_UNICODE_STRING '(&i2,&i2,w)i'

!define BUNDLED_JAVA_VERSION '1.6.0_11'
!define BUNDLED_JAVA_INSTALLER 'jdk-6u11-windows-i586-p.exe'

!define BUNDLED_PG_VERSION '8.3'
!define BUNDLED_PG_INSTALLER 'postgresql-8.3-int.msi'

!define MULTIUSER_EXECUTIONLEVEL 'Admin'

!include MultiUser.nsh

#----------------------
# Declare some vars that we will use in .onInit
Var ComputerName

#----------------------
# Declare some variables related to JDK installation
Var JdkCanBYO
Var JdkShouldBYO
Var JdkShouldBYOCtrl
Var JavaHome

#----------------------
# Declare some variables related to PostgreSQL installation
Var PgCanBYO
Var PgShouldBYO
Var PgShouldBYOCtrl
Var PgServiceUser
Var PgServicePassword
Var PgServiceDomain

# PostgreSQL database superuser username and password
Var PgAdminUsername
Var PgAdminPassword

#----------------------
# Declare some variables related to OpenNMS service installation
Var OnmsServiceUser
Var OnmsServicePassword
Var OnmsServiceDomain

# OpenNMS database username and password
Var OnmsDbUsername
Var OnmsDbPassword

# Filename of the uninstaller that we will write
Var UNINSTALLER_FILE_NAME

# MSI GUID of the JDK that we laid down, if any
Var JDK_MSI_GUID

# Short name, display name, and description for PostgreSQL service
Var PG_SVC_NAME
Var PG_SVC_DISP_NAME
Var PG_SVC_DESCRIPTION

# MSI GUID of the PostgreSQL that we laid down, if any
Var PG_MSI_GUID

# Short name, display name, and description for OpenNMS service
Var ONMS_SVC_NAME
Var ONMS_SVC_DISP_NAME
Var ONMS_SVC_DESCRIPTION

Var OPENNMS_HOME

# Java-fied versions of OPENNMS_HOME and USERPROFILE
Var OPENNMS_HOME_JAVA
Var PROFILE_JAVA

# We cannot use defines in .onInit, so put it at the top for easy access
Function .onInit
  # First, prevent multiple instances of this installer.
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "openNmsMutex") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
  MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
  Abort
  !insertmacro MULTIUSER_INIT
  ReadEnvStr $OnmsServiceUser "USERNAME"
  ReadEnvStr $OnmsServiceDomain "USERDOMAIN"
  ReadEnvStr $ComputerName "COMPUTERNAME"
  ClearErrors
  UserInfo::GetName
  IfErrors Win9x NotWin9x
Win9x:
  MessageBox MB_OK|MB_ICONEXCLAMATION "This installer cannot be run on Windows 95, 98, or ME."
  Abort
NotWin9x:
  Pop $0
  StrCmp $ServiceDomain $ComputerName UserLocal UserNotLocal
UserNotLocal:
  Abort "This installer must be run as a local user."
UserLocal:
  SrCpy JDK_MSI_GUID "32A3A4F4-B792-11D6-A78A-00B0D0160110"
  # 0 on the stack means push only the number
  Push 0
  Call GetJavaHomeCandidates
  Pop $1
  StrCmp $1 "0" GotNoJava GotJava
GotNoJava:
  StrCpy $JdkCanBYO "false"
  Goto DoneJava
GotJava:
  StrCpy $JdkCanBYO "true"
  Goto DoneJava
DoneJava:
  StrCpy $UNINSTALLER_FILE_NAME "uninstall-opennms.exe"
  StrCpy $PG_SVC_NAME "pgsql-8.3"
  StrCpy $PG_SVC_DISP_NAME "PostgreSQL 8.3"
  StrCpy $PG_MSI_GUID "B823632F-3B72-4514-8861-B961CE263224"
  StrCpy $ONMS_SVC_NAME "OpenNMS"
  StrCpy $ONMS_SVC_DISP_NAME "OpenNMS"
  StrCpy $ONMS_SVC_DESCRIPTION "Open Network Management System"
FunctionEnd


Function un.onInit
  # First, prevent multiple instances of this installer.
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "openNmsMutex") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
  MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
  Abort
  !insertmacro MULTIUSER_UNINIT
  ReadRegStr $ServiceUser HKLM "Software\The OpenNMS Group\OpenNMS" "ServiceUser"
  ReadRegStr $ServiceDomain HKLM "Software\The OpenNMS Group\OpenNMS" "ServiceDomain"
  StrCpy $UNINSTALLER_FILE_NAME "uninstall-opennms.exe"
  StrCpy $PG_SVC_NAME "PostgreSQL"
  StrCpy $ONMS_SVC_NAME "OpenNMS"
  StrCpy $ONMS_SVC_DISP_NAME "OpenNMS"
  StrCpy $ONMS_SVC_DESCRIPTION "Open Network Management System"
FunctionEnd


#----------------------
# Include modern UI 2.0, sections, and nsDialogs plugins
!include "MUI2.nsh"
!include "Sections.nsh"
!include "nsDialogs.nsh"

# Configure the interface
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "resources\opennms-nsis-brand.bmp"
!define MUI_ABORTWARNING

# Include WinMessages.nsh so that we can send messages
# using symbolic names
!include "WinMessages.nsh"


# Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "resources\GPL.TXT"

Page custom javaCheckPage javaCheckPageLeave

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS

PageEx instfiles
  CompletedText "Click Next to configure OpenNMS on your system."
PageExEnd

Page custom onmsSvcUserPage onmsSvcUserPageLeave

Page custom svcCreationPage svcCreationPageLeave

Page custom svcStartPage

!insertmacro MUI_PAGE_FINISH


# Uninstaller pages

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
UninstPage custom un.OptionsPage un.OptionsPageLeave
UninstPage instfiles


#----------------------
# Language
!insertmacro MUI_LANGUAGE "English"


#----------------------
# Basic attributes of this installer
Name "OpenNMS"
Icon resources\big-o-install.ico
UninstallIcon resources\big-o-uninstall.ico
OutFile opennms-windows-inst.exe

# Where we want to be installed
InstallDir "$PROGRAMFILES\OpenNMS"

# If set in a previous install, use that instead of InstallDir
InstallDirRegKey HKLM "SOFTWARE\The OpenNMS Group\OpenNMS" InstallLocation

# On Vista and later, request administrator privilege
RequestExecutionLevel admin

# Include an XP manifest
XPStyle On

BrandingText "© 2008-2009 The OpenNMS Group, Inc.  Installer made with NSIS."

LicenseData resources\GPL.TXT
LicenseForceSelection checkbox

#----------------------
# Variables used in our custom dialogs
Var Dialog
Var UserLabel
Var UserText
Var PasswordLabel
Var PasswordText
Var PasswordRepLabel
Var PasswordRepText

Var TopLabel

Var WantSystray

Var JavaListBox

Var ShouldRemoveRrdFiles
Var ShouldRemoveAvailReports
Var ShouldRemoveEtcFiles
Var ShouldDropDatabase

#----------------------
# A few temporary variables
Var TEMP0
Var TEMP1
Var TEMP2
Var TEMP3
Var TEMP4



#----------------------
# Sections here

Section "-Files"
  SetOutPath $INSTDIR
  Push $INSTDIR
  Call MkJavaPath
  Pop $INSTDIRJAVA
  Push $PROFILE
  Call MkJavaPath
  Pop $PROFILE_JAVA
  File resources\GPL.TXT
  File /nonfatal /r /x .svn etc
  File /nonfatal /r /x .svn logs
  SetOutPath $INSTDIR\bin

  # Warn the user that we are stopping the service
  IfFileExists "$PROFILE\.opennms\$KILL_SWITCH_FILE_NAME" 0 SkipSvcStopNotify
  Delete "$PROFILE\.opennms\$KILL_SWITCH_FILE_NAME"
  MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is stopping the $POLLER_SVC_DISP_NAME service.$\r$\n$\r$\nIf you abort the installer, you will need to restart the service manually."
  SkipSvcStopNotify:
  IfFileExists "$INSTDIR\bin\opennmsremotepollerw.exe" 0 SkipStopSystray
  Call StopSysTrayMonitor
  DetailPrint "Pausing 30 seconds to give $POLLER_SVC_DISP_NAME service and/or system tray monitor time to stop..."
  Sleep 30000
  SkipStopSystray:

  File bin\opennms.exe
  File bin\opennmsw.exe

  DetailPrint "Setting user Web Start properties"
  SetOutPath $APPDATA\Sun\Java\Deployment
  File etc\deployment.properties
  SetOutPath $PROFILE\.opennms

  WriteRegStr HKLM "Software\The OpenNMS Group\OpenNMS" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\The OpenNMS Group\OpenNMS" "ServiceUser" "$ServiceUser"
  WriteRegStr HKLM "Software\The OpenNMS Group\OpenNMS" "ServiceDomain" "$ServiceDomain"
  WriteRegStr HKLM "Software\The OpenNMS Group\OpenNMS" "PgMsiGuid" "$PG_MSI_GUID"
  WriteUninstaller "$INSTDIR\$UNINSTALLER_FILE_NAME"
  Call WriteAddRemProgEntry
SectionEnd

Section "System Tray Icon" SecSystray
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OpenNMSSysTray" '"$INSTDIR\bin\opennmsw.exe" //MS//OpenNMS'
  StrCpy $WantSystray "TRUE"
SectionEnd

Section "Uninstall"
  # Stop the OpenNMS service
  IfFileExists "$INSTDIR\bin\opennms.exe" 0 SkipStopService
  Exec '"$INSTDIR\bin\opennms.exe" //SS//$ONMS_SVC_NAME'
  SkipStopService:
  # Try to stop the systray monitor if possible
  IfFileExists "$INSTDIR\bin\opennmsw.exe" 0 SkipStopSysTray
  Exec '"$INSTDIR\bin\opennmsw.exe" //MQ//$ONMS_SVC_NAME'
  SkipStopSysTray:
  DetailPrint "Pausing 30 seconds to give $ONMS_SVC_DISP_NAME service and/or system tray monitor time to stop..."
  Sleep 30000
  IfFileExists "$INSTDIR\bin\opennms.exe" 0 SkipRemoveService
  Call un.RemovePollerSvc
  SkipRemoveService:
  Push $ServiceUser
  Call un.RemoveSvcLogonRight
  Pop $1
  StrCmp $1 "OK" 0 RightRemovalFailed
  DetailPrint "Removed Log On As a Service right from user $ServiceUser"
  Goto RightRemovedOK
  RightRemovalFailed:
  DetailPrint "WARNING: Failed to remove Log On As a Service right from user $ServiceUser"
  MessageBox MB_OK|MB_ICONINFORMATION "The uninstaller was unable to remove the Log On As a Service right from user $ServiceUser.$\r$\n$\r$\nYou may wish to remove this right manually for security reasons."
  RightRemovedOK:
  Call un.RemoveSystrayMonitorStartup
  Delete "$INSTDIR\resources\GPL.TXT"
  Delete "$INSTDIR\bin\opennms.exe"
  Delete "$INSTDIR\bin\opennmsw.exe"
  Delete "$INSTDIR\$UNINSTALLER_FILE_NAME"
  Sleep 1000
  RMDir /r "$INSTDIR\etc"
  RMDir /r "$INSTDIR\logs"
  RMDir /r "$INSTDIR\bin"
  Delete "$INSTDIR\GPL.TXT"
  RMDir "$INSTDIR"
  StrCmp $ShouldRemoveRrdFiles "true" 0 SkipDeleteRrdFiles
  RMDir /r "$INSTDIR\share\rrd\"
  SkipDeleteRrdFiles:
  StrCmp $ShouldRemoveAvailReports "true" 0 SkipDeleteAvailReports
  RMDir /r "$INSTDIR\share\reports"
  SkipDeleteAvailReports:
  StrCmp $ShouldRemoveEtcFiles "true" 0 SkipDeleteEtcFiles
  RMDir /r "$INSTDIR\etc"
  SkipDeleteEtcFiles:
  StrCmp $ShouldDropDatabase "true" 0 SkipDropDatabase
  Call un.DropDatabase
  SkipDropDatabase:
  DeleteRegValue HKLM "Software\The OpenNMS Group\OpenNMS Remote Poller" "InstallLocation"
  DeleteRegKey /ifempty HKLM "Software\The OpenNMS Group\OpenNMS"
  DeleteRegKey /ifempty HKLM "Software\The OpenNMS Group"
  DeleteRegKey /ifempty HKLM "Software\Apache Software Foundation"
  Call un.RemoveAddRemProgEntry
SectionEnd

#--------------------------------
# Section Descriptions

  LangString DESC_SecSystray ${LANG_ENGLISH} "Installs a system tray icon that monitors the state of the $ONMS_SVC_DISP_NAME service."

  #Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSystray} $(DESC_SecSystray)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END


#----------------------
# Functions for the service user info page
Function onmsSvcUserPage
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Please provide the password for the local Windows account under which the OpenNMS Remote Poller service will run."
  Pop $TopLabel

  ${NSD_CreateLabel} 0 40u 40u 12u "Username"
  Pop $UserLabel

  ${NSD_CreateText} 61u 39u 70u 12u "$ServiceUser"
  Pop $UserText
  SendMessage $UserText ${EM_SETREADONLY} 1 0

  ${NSD_CreateLabel} 0 60u 40u 12u "Password"
  Pop $PasswordLabel

  ${NSD_CreatePassword} 61u 59u 70u 12u "$ServicePassword"
  Pop $PasswordText

  ${NSD_CreateLabel} 0 80u 60u 12u "Repeat Password"
  Pop $PasswordRepLabel

  ${NSD_CreatePassword} 61u 79u 70u 12u "$ServicePassword"
  Pop $PasswordRepText

  nsDialogs::Show
FunctionEnd

Function onmsSvcUserPageLeave
  Push $1
  Push $2
  ${NSD_GetText} $PasswordText $1
  ${NSD_GetText} $PasswordRepText $2
  StrCmp $1 $2 PasswordsMatch
  MessageBox MB_OK "The password fields must match.  Please try again."
  Abort
PasswordsMatch:
  StrCpy $ServicePassword $1
  Pop $2
  Pop $1
FunctionEnd

#----------------------
# Functions for the service creation page
Function svcCreationPage
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 100% "The GUI Remote Poller is downloading and launching.  Please be patient as this process may take a few minutes.$\r$\n$\r$\nAfter the remote poller has successfully registered with the OpenNMS server, please close the poller window and click Next to continue.$\r$\n$\r$\nIf the poller window has not appeared after a few moments, please cancel this installation and contact the person in your organization responsible for administering OpenNMS."
  Pop $TopLabel

  nsDialogs::Show  
FunctionEnd

Function svcCreationPageLeave
  Call CreateOrUpdateOnmsSvc
  Pop $1
  StrCmp $1 "OK" ServiceOK ServiceFail
ServiceFail:
  MessageBox MB_OK|MB_ICONEXCLAMATION "The attempt to install or update the OpenNMS service failed.$\r$\n$\r$\nPlease go back and double-check the password for the $serviceUser user.$\r$\n$\r$\nIf this message persists, please cancel this installation, run the uninstaller, delete and recreate the $serviceUser user, and re-run the installer."
  Abort
ServiceOK:
FunctionEnd


Function svcStartPage
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 100% "The installer will now attempt to start the $POLLER_SVC_DISP_NAME service.$\r$\n$\r$\nIf this step fails, please contact the person in your organization responsible for administering OpenNMS."
  Pop $TopLabel

  nsDialogs::Show

  # Add log-on-as-service privilege to service user
  Push $ServiceUser
  Call AddSvcLogonRight
  Pop $1
  StrCmp $1 "OK" AddPrivOK AddPrivFail

AddPrivFail:
  DetailPrint "Failed to add Log On As a Service right to user $ServiceUser, aborting"
  MessageBox MB_OK|MB_ICONEXCLAMATION "The attempt to add the Log On As a Service right to user $ServiceUser failed.$\r$\n$\r$\nPlease contact the person in your organization responsible for administering OpenNMS."
  Abort
AddPrivOK:
  DetailPrint "Added Log On As a Service right for user $ServiceUser"

  DetailPrint "Attempting to start $POLLER_SVC_NAME service..."
  ExecWait '"$SYSDIR\net.exe" start $POLLER_SVC_NAME' $1
  Pop $1
  IntCmp $1 0 SvcStartOK SvcStartFail SvcStartFail
SvcStartFail:
  DetailPrint "Service $POLLER_SVC_NAME failed to start, exit code $1"
  MessageBox MB_OK|MB_ICONEXCLAMATION "The $POLLER_SVC_DISP_NAME service failed to start.  Please contact the person in your organization responsible for administering OpenNMS."
  Abort
SvcStartOK:
  # Launch the systray monitor if wanted and not already running
  StrCmp $WantSystray "TRUE" DoSystray SkipSystray
DoSystray:
  Call LaunchSystrayMonitor
SkipSystray:
FunctionEnd


#
# Page function to check whether we have a valid Java
Function javaCheckPage
  StrCpy $JavaHome ""

  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}

  # See how many Java candidates we have
  # A 1 on the stack means "push the candidates too"
  Push 1
  Call GetJavaHomeCandidates
  Pop $TEMP1
  StrCmp $TEMP1 "0" SkipJavaChooser ShowJavaChooser

  ShowJavaChooser:
  Pop $TEMP2
  ${NSD_CreateLabel} 0 10u 100% 30u "The installer has identified an existing Java 6 JDK installation on this system.  You may$\r$\nuse the existing JDK or install version ${BUNDLED_JDK_VERSION}, which is bundled with$\r$\nthis installer."
  Pop $UserLabel

  ${NSD_CreateRadioButton} 0 10u 100% 12u "Install and use bundled Java 6 JDK in $PROGRAMFILES\Java\jdk(${BUNDLED_JDK_VERSION})"
  Pop $TEMP1
  ${NSD_SetState} $TEMP1 ${BST_CHECKED}
  ${NSD_CreateRadioButton} 0 22u 100% 12u "Use existing Java 6 JDK in $TEMP2"
  Pop $JdkShouldBYOCtrl
  StrCpy $JavaHome $TEMP2
  Goto ShowDialog

  SkipJavaChooser:
  Call IsBundledJDKInstalled
  Pop $TEMP1
  StrCmp $TEMP1 "false" InstallBundledJDK
  ${NSD_CreateLabel} 0 10u 100% 30u "The installer will use the existing Java 6 JDK in $PROGRAMFILES\Java\jdk${BUNDLED_JDK_VERSION}.$\r$\nClick Next to continue."
  Pop $UserLabel
  StrCpy $JdkShouldBYO "true"
  Goto ShowDialog
  InstallBundledJDK:
  ${NSD_CreateLabel} 0 10u 100% 30u "Click Next to install Java 6 JDK in $PROGRAMFILES\Java\jdk${BUNDLED_JDK_VERSION}."
  Pop $UserLabel
  StrCpy $JdkShouldBYO "false"
  StrCpy $JavaHome "$PROGRAMFILES\Java\jdk${BUNDLED_JDK_VERSION}"

  ShowDialog:
  nsDialogs::Show
FunctionEnd

Function javaCheckPageLeave
  StrCmp $JdkShouldBYO "true" SkipToEnd
  StrCmp $JdkShouldBYOCtrl "" InstallBundledJava
  ${NSD_GetState} $JdkShouldBYOCtrl $TEMP1
  StrCmp $TEMP1 ${BST_CHECKED} 0 InstallBundledJava
  StrCpy $JdkShouldBYO "true"
  # $JavaHome is still set from main page function
  Return
  InstallBundledJava:
  SetOutPath $TEMP
  File "bundled\jdk\${BUNDLED_JDK_INSTALLER}"
  ExecWait '"$TEMP\${BUNDLED_JDK_INSTALLER}" ADDLOCAL=ALL INSTALLDIR="$JavaHome" /qb!'
  SkipToEnd:
FunctionEnd


#----------------------
# Functions for the "wait for JDK install" page
Function jdkInstallWaitPage
  StrCmp $JdkShouldBYO "true" 0 WaitDialog
  Abort
  WaitDialog:
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 10u 100% 30u "After the Java 6 JDK installation completes, click Next to continue."
  Pop $UserLabel
  nsDialogs::Show
FunctionEnd

Function jdkInstallWaitPageLeave
  Call IsBundledJDKInstalled
  Pop $TEMP1
  StrCmp $TEMP1 "false" StillWaiting
  Return
  StillWaiting:
  MessageBox MB_OK "Please continue waiting, the Java 6 JDK installation is not yet complete."
  Abort
FunctionEnd

#----------------------
# Functions for uninstall options page
Function un.OptionsPage
  StrCmp $POLLER_PROPS_FILE "" 0 CheckPropsFileExists
  Abort
  CheckPropsFileExists:
  IfFileExists $POLLER_PROPS_FILE ProceedUnOptions 0
  Abort
  ProceedUnOptions:
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog
  ${If} $Dialog == error
    Abort
  ${EndIf}
  ${NSD_CreateCheckBox} 0 10u 100% 12u "Remove &historical latency and performance data"
  Pop $ShouldRemoveRrdFiles
  ${NSD_CreateCheckBox} 0 13u 100% 12u "Remove &configuration files"
  Pop $ShouldRemoveEtcFiles
  nsDialogs::Show
FunctionEnd

Function un.OptionsPageLeave
  ${NSD_GetState} $ShouldRemoveRrdFiles $TEMP1
  StrCmp $TEMP1 ${BST_CHECKED} 0 DontRemoveRrdFiles
  StrCpy $ShouldRemoveRrdFiles "true"
  DontRemoveRrdFiles:
  ${NSD_GetState} $ShouldRemoveEtcFiles $TEMP1
  StrCmp $TEMP1 ${BST_CHECKED} 0 DontRemoveEtcFiles
  StrCpy $ShouldRemoveEtcFiles "true"
  DontRemoveEtcFiles:
  ${NSD_GetState} $ShouldDropDatabase $TEMP1
  StrCmp $TEMP1 ${BST_CHECKED} 0 DontDropDatabase
  StrCpy $ShouldDropDatabase "true"
  DontDropDatabase:
FunctionEnd

Function un.DropDatabase
  MessageBox MB_OK "Function un.DropDatabase not yet implemented"
FunctionEnd


#----------------------
# Function to return a list of candidate JAVA_HOMEs
# Pushes all candidate paths onto the stack, followed
# by a number of paths pushed.  Callers should first pop
# the number (N), and then pop N more values, each of
# which is a candidate path.
Function GetJavaHomeCandidates
  # $TEMP0  tells us whether to push the candidate names
  Pop $TEMP0
  # $TEMP1 will be our path counter
  StrCpy $TEMP1 0
  # Start with the current JDK, if present
  TryJDKCurrent:
  ReadRegStr $TEMP2 HKLM "SOFTWARE\JavaSoft\Java Development Kit" "CurrentVersion"
  StrCmp $TEMP2 "" TryAllJDK 0
  StrCmp $TEMP2 "1.6" UseJDKCurrent TryAllJDK
  UseJDKCurrent:
  ReadRegStr $TEMP3 HKLM "SOFTWARE\JavaSoft\Java Development Kit\$TEMP2" "JavaHome"
  IfFileExists "$TEMP3\bin\javac.exe" 0 TryAllJDK
  StrCmp $TEMP0 1 0 SkipPushJDKCurrent
  Push $TEMP3
  SkipPushJDKCurrent:
  IntOp $TEMP1 $TEMP1 + 1
  Push $TEMP1
  Return

  TryAllJDK:
  # TEMP2 will be our iterator within this loop
  StrCpy $TEMP2 0
  LoopJDK:
    EnumRegKey $TEMP3 HKLM "SOFTWARE\JavaSoft\Java Development Kit" $TEMP2
    StrCmp $TEMP3 "" DoneJDK
    # Check that it's a 1.5 or 1.6 JRE
    StrCmp $TEMP3 "1.6" 0 NextJDK
    ReadRegStr $TEMP3 HKLM "SOFTWARE\JavaSoft\Java Development Kit\$TEMP3" "JavaHome"
    StrCmp $TEMP3 "" NextJDK 0
    IfFileExists "$TEMP3\bin\javac.exe" 0 NextJDK
    IntOp $TEMP1 $TEMP1 + 1
    StrCmp $TEMP0 1 0 NextJDK
    Push $TEMP3
    NextJDK:
    IntOp $TEMP2 $TEMP2 + 1
    Goto LoopJDK
  DoneJDK:
  Push $TEMP1
  Return
FunctionEnd


#----------------------
# Function that creates or updates the OpenNMS service
# TODO: Convert start mode to JVM
Function CreateOrUpdateOnmsSvc
  # Check whether the service exists, decide on our verb (install / update) accordingly
  Push $ONMS_SVC_NAME
  Call CheckSvcExists
  Pop $1
  StrCmp $1 "OK" VerbUpdate VerbInstall
VerbInstall:
  StrCpy $1 "IS"
  Goto DoService
VerbUpdate:
  StrCpy $1 "US"
  Goto DoService
DoService:
  ExecWait '"$INSTDIR\bin\opennms.exe" //$1//$ONMS_SVC_NAME --DisplayName="$ONMS_SVC_DISP_NAME" --Description="$ONMS_SVC_DESCRIPTION"  --DependsOn="$PG_SVC_NAME" --StartMode exe --StopMode exe --ServiceUser=".\$ServiceUser" --ServicePassword="$ServicePassword" --StartImage="$JAVAEXE" --StartParams="start"' $1
  IntCmp $1 0 CreateOK CreateFail CreateFail
CreateFail:
  Push "NOK"
  Return
CreateOK:
  ExecWait '"$INSTDIR\bin\opennms.exe" //US//$ONMS_SVC_NAME  --JvmMx 256 --StopImage="$JAVAEXE" --StopParams="stop" --LogLevel=DEBUG --LogPath="$INSTDIR\logs" --LogPrefix=procrun.log --Startup=auto' $1
  IntCmp $1 0 UpdateOK UpdateFail UpdateFail
  Goto UpdateOK
UpdateFail:
  MessageBox MB_OK "Update failed"
  Push "NOK"
  Return
UpdateOK:
  Push "OK"
  Return
FunctionEnd


#----------------------
# Function that removes the headless poller service
Function un.RemovePollerSvc
  Push $POLLER_SVC_NAME
  Call un.CheckSvcExists
  Pop $1
  StrCmp $1 "OK" 0 SkipRemoval
  ExecWait '"$INSTDIR\bin\opennmsremotepoller.exe" //DS//$POLLER_SVC_NAME'
  SkipRemoval:
FunctionEnd


#----------------------
# Function that launches the systray monitor if it is not already running
Function LaunchSystrayMonitor
  Exec '"$INSTDIR\bin\opennmsw.exe" //MS//$ONMS_SVC_NAME'
FunctionEnd



#----------------------
# Function that stops the systray monitor if it is running
Function StopSystrayMonitor
  Exec '"$INSTDIR\bin\opennmsw.exe" //MQ//$ONMS_SVC_NAME'
FunctionEnd



#----------------------
# Function that removes the systray monitor from Windows startup
Function un.RemoveSystrayMonitorStartup
  DeleteRegValue HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OpenNMSSysTray"
FunctionEnd



#----------------------
# Does the named service exist?
Function CheckSvcExists
Pop $TEMP2
StrCpy $TEMP0 0
loop:
    EnumRegKey $TEMP1 HKLM "SYSTEM\CurrentControlSet\Services" $TEMP0
    StrCmp $TEMP1 $TEMP2 FoundSvc
    StrCmp $TEMP1 "" NotFound
    IntOp $TEMP0 $TEMP0 + 1
  Goto loop
FoundSvc:
  Push "OK"
  Return
NotFound:
  Push "NOK"
  Return
FunctionEnd


#----------------------
# Does the named service exist? (uninstaller copy, keep synchronized!)
Function un.CheckSvcExists
Pop $TEMP2
StrCpy $TEMP0 0
loop:
    EnumRegKey $TEMP1 HKLM "SYSTEM\CurrentControlSet\Services" $TEMP0
    StrCmp $TEMP1 $TEMP2 FoundSvc
    StrCmp $TEMP1 "" NotFound
    IntOp $TEMP0 $TEMP0 + 1
  Goto loop
FoundSvc:
  Push "OK"
  Return
NotFound:
  Push "NOK"
  Return
FunctionEnd


#----------------------
# Function that turns a backslashed pathname into a foreslashed one (ouch!)
Function MkJavaPath
  Var /GLOBAL BSStringLong
  Var /GLOBAL BSString
  Var /GLOBAL FSString
  Var /GLOBAL ThisChar
  Var /GLOBAL BSLength
  Var /GLOBAL CurPos

  # Start clean since we'll be used repeatedly.
  StrCpy $BSString ""
  StrCpy $FSString ""
  StrCpy $ThisChar ""
  StrCpy $BSLength "0"
  StrCpy $CurPos "0"

  Pop $BSStringLong
  GetFullPathName /SHORT $BSString $BSStringLong
  StrLen $BSLength $BSString
  StrCpy $CurPos "0"

loop:
    IntCmp $CurPos $BSLength done
    StrCpy $ThisChar $BSString 1 $CurPos
    StrCmp $ThisChar "\" DoSubst DontSubst
DoSubst:
    StrCpy $FSString "$FSString/"
    Goto SkipChar
DontSubst:
    StrCpy $FSString "$FSString$ThisChar"
SkipChar:
    IntOp $CurPos $CurPos + 1
    Goto loop
done:
  Push $FSString
FunctionEnd


#----------------------
# Function that checks whether the bundled version of the Java 6 JDK
# is installed
Function IsBundledJDKInstalled
  ReadRegStr $TEMP1 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{${JDK_MSI_GUID}}" "UninstallString"
  StrCmp $TEMP1 "" NotInstalled
  Push "true"
  Return
  NotInstalled:
  Push "false"
  Return
FunctionEnd


#----------------------
# Function that writes uninstaller info to the Add/Remove Programs
# Control Panel menu
Function WriteAddRemProgEntry
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "DisplayName" "$ONMS_SVC_DISP_NAME"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "UninstallString" '"$INSTDIR\$UNINSTALLER_FILE_NAME"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "DisplayIcon" "$INSTDIR\bin\opennms.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "Publisher" "The OpenNMS Group, Inc."
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "HelpLink" "http://www.opennms.org/"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME" "NoRepair" 1
FunctionEnd


#----------------------
# Function that removes uninstaller info from the Add/Remove Programs
# Control Panel menu
Function un.RemoveAddRemProgEntry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$ONMS_SVC_NAME"
FunctionEnd


#----------------------
# Function that checks whether a named local user account exists
# TODO: entirely untested
Function DoesUserAcccountExist
  # Pop the username off the stack
  Pop $2
  System::Call '*${strLSA_OBJECT_ATTRIBUTES}(24,n,n,0,n,n).r0'
  System::Call 'advapi32::LsaOpenPolicy(w n, i r0, i ${POLICY_LOOKUP_NAMES_CREATE_ACCOUNT}, *i .R0) i.R8'
  StrCpy $3 ${NSIS_MAX_STRLEN}
  System::Call '*(&w${NSIS_MAX_STRLEN})i.R1'
  System::Call 'Advapi32::LookupAccountNameW(w n, w r2, i R1, *i r3, w .R8, *i r3, *i .r4) i .R8'
  System::Call 'advapi32::LsaNtStatusToWinError(i R8) i.R9'

  # Check the WinError code for success
  IntCmp $R9 0 UserExists UserNotExists
UserExists:
  Push "true"
  Goto DoCleanup
UserNotExists:
  Push "false"
DoCleanup:
  System::Free $0
  System::Free $R1
  System::Call 'advapi32::LsaFreeMemory(i R2) i .R8'
  System::Call 'advapi32::LsaClose(i R0) i .R8'
FunctionEnd

 
#----------------------
# Function that adds the "log on as a service" right to a named local user account
Function AddSvcLogonRight
  # Pop the username off the stack
  Pop $2
  System::Call '*${strLSA_OBJECT_ATTRIBUTES}(24,n,n,0,n,n).r0'
  System::Call 'advapi32::LsaOpenPolicy(w n, i r0, i ${POLICY_LOOKUP_NAMES_CREATE_ACCOUNT}, *i .R0) i.R8'
  StrCpy $3 ${NSIS_MAX_STRLEN}
  System::Call '*(&w${NSIS_MAX_STRLEN})i.R1'
  System::Call 'Advapi32::LookupAccountNameW(w n, w r2, i R1, *i r3, w .R8, *i r3, *i .r4) i .R8'
 
  # Add the rights
  StrCpy $2 "SeServiceLogonRight"
  System::Call '*${strLSA_UNICODE_STRING}(38,38,r2).s'
  Pop $R2

  System::Call 'advapi32::LsaAddAccountRights(i R0, i R1, i R2, i 1)i.R8'
  System::Call 'advapi32::LsaNtStatusToWinError(i R8) i.R9'

  # Check the WinError code for success
  IntCmp $R9 0 AddOK AddFail AddFail
AddOK:
  Push "OK"
  Goto DoAddCleanup
AddFail:
  Push "NOK"
DoAddCleanup:
  System::Free $0
  System::Free $R1
  System::Call 'advapi32::LsaFreeMemory(i R2) i .R8'
  System::Call 'advapi32::LsaClose(i R0) i .R8'
FunctionEnd


#----------------------
# Function that removes the "log on as a service" right from a named local user account
Function un.RemoveSvcLogonRight
  # Pop the username off the stack
  Pop $2
  System::Call '*${strLSA_OBJECT_ATTRIBUTES}(24,n,n,0,n,n).r0'
  System::Call 'advapi32::LsaOpenPolicy(w n, i r0, i ${POLICY_LOOKUP_NAMES_CREATE_ACCOUNT}, *i .R0) i.R8'
  StrCpy $3 ${NSIS_MAX_STRLEN}
  System::Call '*(&w${NSIS_MAX_STRLEN})i.R1'
  System::Call 'Advapi32::LookupAccountNameW(w n, w r2, i R1, *i r3, w .R8, *i r3, *i .r4) i .R8'
 
  # Remove the rights
  StrCpy $2 "SeServiceLogonRight"
  System::Call '*${strLSA_UNICODE_STRING}(38,38,r2).s'
  Pop $R2

  System::Call 'advapi32::LsaRemoveAccountRights(i R0, i R1, i 0, i R2, i 1)i.R8'
  System::Call 'advapi32::LsaNtStatusToWinError(i R8) i.R9'

  # Check the WinError code for success
  IntCmp $R9 0 RemoveOK RemoveFail RemoveFail
RemoveOK:
  Push "OK"
  Goto DoRemoveCleanup
RemoveFail:
  Push "NOK"
DoRemoveCleanup:
  System::Free $0
  System::Free $R1
  System::Call 'advapi32::LsaFreeMemory(i R2) i .R8'
  System::Call 'advapi32::LsaClose(i R0) i .R8'
FunctionEnd
