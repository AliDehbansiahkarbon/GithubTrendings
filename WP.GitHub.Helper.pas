unit WP.GitHub.Helper;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.Net.HttpClientComponent, System.StrUtils,
  System.DateUtils, System.TimeSpan, Vcl.ExtCtrls, Vcl.Graphics, Winapi.ShellAPI,
  Vcl.Imaging.pngimage, System.Types, Vcl.Dialogs, Winapi.Windows,
  WP.GitHub.Constants, ToolsAPI, System.IOUtils, System.UITypes,
  Vcl.Controls, WP.GitHub.Setting, WP.GitHub.CustomMessage;

type
  TGitHubHelper = class
  private
    class function DateTimeToISO8601(const ADateTime: TDateTime): string;
    class function GetPeriodRange(const APeriod: string): string;
    class function FindFirstDelphiProject(const Directory: string): string; static;
  public
    class procedure CloneGitHubRepo(const ARepoURL: string; const ARepoName: string); static;
    class procedure CloneGitHubRepoAndOpen(const ARepoURL: string; const ARepoName: string); static;
    class function GetTrendingPascalRepositories(const APeriod: string; const ALanguage: string): string; static;
    class function CheckInternetAvailabilityAsync(const URL: string; var AException: string): Boolean; static;
    class procedure OpenProjectInIDE(const ProjectDirectoryPath: string); static;
  end;

  TImageHelper = class helper for TImage
  public
    procedure LoadImageFromURL(const AImageURL: string);
  end;

implementation

{ TGitHubHelper }
class function TGitHubHelper.DateTimeToISO8601(const ADateTime: TDateTime): string;
var
  TZ: TTimeZone;
  Offset: TTimeSpan;
  Hours, Mins: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', ADateTime);
  TZ := TTimeZone.Local;
  Offset := TZ.GetUtcOffset(ADateTime);

  if Offset = TTimeSpan.Zero then
    Result := Result + 'Z'  // UTC time
  else
  begin
    Hours := Format('%.*d', [2, Abs(Offset.Hours)]);  // Hours
    Mins := Format('%.*d', [2, Abs(Offset.Minutes)]); // Minutes

    if Offset.TotalHours >= 0 then
      Result := Result + '%2B' + Hours + ':' + Mins
    else
      Result := Result + '-' + Hours + ':' + Mins;
  end;
end;

class function TGitHubHelper.GetPeriodRange(const APeriod: string): string;
var
  FromDate, ToDate: TDateTime;
begin
  ToDate := Now;

  case IndexStr(APeriod, ['daily', 'weekly', 'monthly', 'yearly']) of
    0: FromDate := IncHour(ToDate, -24);  // 24 hours ago
    1: FromDate := IncDay(ToDate, -7);    // 7 days ago
    2: FromDate := IncDay(ToDate, -30);   // 30 days ago
    3: FromDate := IncDay(ToDate, -365);  // 365 days ago
  else
    FromDate := IncHour(ToDate, -24);  // 24 hours ago
  end;

  Result := DateTimeToISO8601(FromDate) + '..' + DateTimeToISO8601(ToDate);
end;

class function TGitHubHelper.GetTrendingPascalRepositories(const APeriod: string; const ALanguage: string): string;
var
  HTTPClient: TNetHTTPClient;
  Response: IHTTPResponse;
  URL: string;
begin
  if IndexStr(APeriod.ToLower, ['daily', 'weekly', 'monthly', 'yearly']) = -1 then
    raise Exception.Create('Invalid PeriodType. Must be "daily", "weekly", "monthly", or "yearly".');

  URL := Format(cURL, [ALanguage, GetPeriodRange(APeriod.ToLower)]);
  HTTPClient := TNetHTTPClient.Create(nil);
  try
    Response := HTTPClient.Get(URL);
    if Response.StatusCode = 200 then
      Result := Response.ContentAsString
    else
      raise Exception.CreateFmt('Error: %d - %s', [Response.StatusCode, Response.StatusText]);
  finally
    HTTPClient.Free;
  end;
end;

class function TGitHubHelper.CheckInternetAvailabilityAsync(const URL: string; var AException: string): Boolean;
var
  HttpClient: THttpClient;
begin
  Result := False;
  HttpClient := THttpClient.Create;
  HttpClient.ConnectionTimeout := 2000;
  HttpClient.SendTimeout := 2000;
  HttpClient.ResponseTimeout := 2000;
  try
    try
      HttpClient.Head(URL);
      Result := True;
    except on E: Exception do
      begin
        Result := False;
        AException := 'No internet connection.' + sLineBreak + sLineBreak + 'Exception: ' + sLineBreak + E.Message;
      end;
    end;
  finally
    HttpClient.Free;
  end;
end;

class procedure TGitHubHelper.CloneGitHubRepo(const ARepoURL: string; const ARepoName: string);
var
  LvOpenDialog: TFileOpenDialog;
  LvTargetPath: string;
  LvCommand: string;
begin
  LvOpenDialog := TFileOpenDialog.Create(nil);
  try
    LvOpenDialog.Options := LvOpenDialog.Options + [fdoPickFolders]; // Enable folder selection
    LvOpenDialog.Title := 'Select Target Folder for Cloning Repository';

    if LvOpenDialog.Execute then
    begin
      LvTargetPath := LvOpenDialog.FileName;

      if not DirectoryExists(LvTargetPath + '\' + ARepoName) then
      begin
        if ForceDirectories(LvTargetPath + '\' + ARepoName) then
          LvTargetPath := LvTargetPath + '\' + ARepoName;
      end;

      LvCommand := Format('git clone %s "%s"', [ARepoURL, LvTargetPath]);
      ShellExecute(0, 'open', 'cmd.exe', PChar('/C ' + LvCommand), nil, SW_SHOWNORMAL);
    end;
  finally
    LvOpenDialog.Free;
  end;
end;

class procedure TGitHubHelper.CloneGitHubRepoAndOpen(const ARepoURL: string; const ARepoName: string);
var
  LvOpenDialog: TFileOpenDialog;
  LvTargetPath: string;
  LvCommand: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  CmdLine: string;
begin
  LvOpenDialog := TFileOpenDialog.Create(nil);
  try
    LvOpenDialog.Options := LvOpenDialog.Options + [fdoPickFolders]; // Enable folder selection
    LvOpenDialog.Title := 'Select Target Folder for Cloning Repository';

    if LvOpenDialog.Execute then
    begin
      LvTargetPath := LvOpenDialog.FileName;

      if not DirectoryExists(LvTargetPath + '\' + ARepoName) then
      begin
        if ForceDirectories(LvTargetPath + '\' + ARepoName) then
          LvTargetPath := LvTargetPath + '\' + ARepoName;
      end;

      LvCommand := Format('git clone %s "%s"', [ARepoURL, LvTargetPath]);
      CmdLine := Format('cmd.exe /C %s', [LvCommand]);

      ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_SHOW;

      if CreateProcess(nil, PChar(CmdLine), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
      try
        WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
      finally
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end;

      OpenProjectInIDE(LvTargetPath);
    end;
  finally
    LvOpenDialog.Free;
  end;
end;

function ShowStyledMessage(const MsgText, MsgCaption: string): Integer;
var
  MsgForm: TFrm_CustomMSG;
begin
  MsgForm := TFrm_CustomMSG.CreateMessage(MsgText, MsgCaption);
  try
    TSingletonSettings.RegisterFormClassForTheming(TFrm_CustomMSG, MsgForm);
    Result := MsgForm.ShowModal;
  finally
    MsgForm.Free;
  end;
end;

class procedure TGitHubHelper.OpenProjectInIDE(const ProjectDirectoryPath: string);
var
  ModuleServices: IOTAModuleServices;
begin
  var LvFullPath := FindFirstDelphiProject(ProjectDirectoryPath);
  if LvFullPath.Trim.IsEmpty then
    Exit
  else
  begin
    var LvMsg := 'A project file with the name "' + ExtractFileName(LvFullPath) + '" has been found,'
               + sLineBreak + 'Would you like to open it in the IDE now?';

    if ShowStyledMessage(LvMsg, 'Open Project') = mrYes then
    begin
      ModuleServices := BorlandIDEServices as IOTAModuleServices;
      if Assigned(ModuleServices) then
      begin
        try
          ModuleServices.OpenModule(LvFullPath);
        except on E: Exception do
          ShowMessage('Error opening project: ' + E.Message);
        end;
      end
      else
        ShowMessage('Module services are not available in the IDE.');
    end;
  end;
end;

class function TGitHubHelper.FindFirstDelphiProject(const Directory: string): string;
var
  Files: TArray<string>;
begin
  Result := '';
  Files := TDirectory.GetFiles(Directory, '*.dproj', TSearchOption.soAllDirectories);

  if Length(Files) = 0 then
    Files := TDirectory.GetFiles(Directory, '*.dpr', TSearchOption.soAllDirectories);

  if Length(Files) = 0 then
    Files := TDirectory.GetFiles(Directory, '*.cppproj', TSearchOption.soAllDirectories);

  if Length(Files) > 0 then
    Result := Files[0];
end;

{ TImaheHelper }

procedure TImageHelper.LoadImageFromURL(const AImageURL: string);
var
  HTTPClient: THTTPClient;
begin
  HTTPClient := THTTPClient.Create;
  HTTPClient.BeginGet(
    procedure(const AsyncResult: IAsyncResult)
    var
      Response: IHTTPResponse;
      MemoryStream: TMemoryStream;
    begin
      MemoryStream := TMemoryStream.Create;
      try
        Response := HTTPClient.EndAsyncHTTP(AsyncResult);
        if Response.StatusCode = 200 then
        begin
          MemoryStream.CopyFrom(Response.ContentStream, Response.ContentStream.Size);
          MemoryStream.Position := 0;
          TThread.Synchronize(nil, procedure begin Self.Picture.LoadFromStream(MemoryStream); end);
        end
        else
        begin
          TThread.Synchronize(nil,
          procedure
          begin
            Self.Picture := nil;
            Self.Hint := Format('Failed to load image. Status code: %d', [Response.StatusCode]);
          end);
        end;
      finally
        MemoryStream.Free;
        HTTPClient.Free;
      end;
    end,
    AImageURL
  );
end;
end.
