{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit WP.SplashIcon.Registration;

interface

uses
  Winapi.Windows;

var
  bmSplashScreen: HBITMAP;

const
  OCW_VERSION = 'ver 1.0.0';

implementation

uses
  ToolsAPI, SysUtils, Vcl.Dialogs;

resourcestring
  resPackageName = 'GitHubTrendings ' + OCW_VERSION;
  resLicense = 'Apache License, Version 2.0';
  resAboutTitle = 'GitHubTrendings';
  resAboutDescription = 'https://github.com/AliDehbansiahkarbon/GithubTrendings';

initialization

bmSplashScreen := LoadBitmap(hInstance, 'SPLASH');
(SplashScreenServices as IOTASplashScreenServices).AddPluginBitmap(resPackageName, bmSplashScreen, False, resLicense);

end.
