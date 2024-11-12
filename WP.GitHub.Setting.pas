{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit WP.GitHub.Setting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, 
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, 
  Vcl.StdCtrls, System.Win.Registry, WP.GitHub.Constants, ToolsAPI,
  Vcl.BaseImageCollection, Vcl.ImageCollection;

type
  TSingletonSettings = class
  private
    FGitPath: string;
    FStartupLoad: Boolean;
    FDefaultPeriodIndex: Byte;
    FDefaultLanguageIndex: Byte;
    class var FInstance: TSingletonSettings;
    class function GetInstance: TSingletonSettings; static;
    constructor Create;
    function LoadFromRegistry: TSingletonSettings;
  public
    class procedure RegisterFormClassForTheming(const AFormClass: TCustomFormClass; const Component: TComponent); static;
    class property Instance: TSingletonSettings read GetInstance;

    property GitPath: string read FGitPath write FGitPath;
    property StartupLoad: Boolean read FStartupLoad write FStartupLoad;
    property DefaultPeriodIndex: Byte read FDefaultPeriodIndex write FDefaultPeriodIndex;
    property DefaultLanguageIndex: Byte read FDefaultLanguageIndex write FDefaultLanguageIndex;
  end;
  
  TFrm_Settings = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edt_GitPath: TEdit;
    Button1: TButton;
    GroupBox2: TGroupBox;
    Btn_Close: TButton;
    Btn_Save: TButton;
    Label2: TLabel;
    cbb_Period: TComboBox;
    Label3: TLabel;
    cbb_Lang: TComboBox;
    chk_StartupLoad: TCheckBox;
    procedure Btn_CloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Btn_SaveClick(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
  public
    { Public declarations }
  end;

var
  Frm_Settings: TFrm_Settings;

implementation

{$R *.dfm}

procedure TFrm_Settings.Btn_CloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrm_Settings.Btn_SaveClick(Sender: TObject);
begin
  SaveSettings;
  Close;
end;

procedure TFrm_Settings.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

procedure TFrm_Settings.LoadSettings;
begin
  var LvSetting := TSingletonSettings.Instance.LoadFromRegistry;
  edt_GitPath.Text := LvSetting.GitPath;
  chk_StartupLoad.Checked := LvSetting.StartupLoad;
  cbb_Period.ItemIndex := LvSetting.DefaultPeriodIndex;
  cbb_Lang.ItemIndex := LvSetting.DefaultLanguageIndex; 
end;

procedure TFrm_Settings.SaveSettings;
var
  LvRegistry: TRegistry;
begin
  if not FileExists(edt_GitPath.Text) then
  begin
    ShowMessage('Git.exe could not be found!');
    Exit;
  end;
 
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    if LvRegistry.OpenKey(cBaseKey + cSettingsPath, True) then
    begin
      var LvSetting := TSingletonSettings.Instance;
      LvSetting.GitPath := edt_GitPath.Text;
      LvSetting.StartupLoad := chk_StartupLoad.Checked;
      LvSetting.DefaultPeriodIndex := cbb_Period.ItemIndex;
      LvSetting.DefaultLanguageIndex := cbb_Lang.ItemIndex;

      LvRegistry.WriteString('GitPath', LvSetting.GitPath);
      LvRegistry.WriteBool('StartupLoad', LvSetting.StartupLoad);
      LvRegistry.WriteInteger('DefaultPeriod', LvSetting.DefaultPeriodIndex);
      LvRegistry.WriteInteger('DefaultLanguage', LvSetting.DefaultLanguageIndex);
      LvRegistry.CloseKey;
    end;
  finally
    LvRegistry.Free;
  end;
end;

{ TSingletonSettings }
constructor TSingletonSettings.Create;
begin
  inherited;
  LoadFromRegistry;
end;

class function TSingletonSettings.GetInstance: TSingletonSettings;
begin
  if not Assigned(FInstance) then
    FInstance := TSingletonSettings.Create;
  Result := FInstance;
end;

function TSingletonSettings.LoadFromRegistry: TSingletonSettings;
var
  LvRegistry: TRegistry;
begin
  Result := FInstance;
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    if LvRegistry.OpenKeyReadOnly(cBaseKey + cSettingsPath) then
    begin
      FGitPath := LvRegistry.ReadString('GitPath');
      FStartupLoad := LvRegistry.ReadBool('StartupLoad');
      FDefaultPeriodIndex := LvRegistry.ReadInteger('DefaultPeriod');
      FDefaultLanguageIndex := LvRegistry.ReadInteger('DefaultLanguage');
      LvRegistry.CloseKey;
    end
    else
    begin //Default settings 
      FGitPath := 'C:\Program Files\Git\bin\git.exe';
      FStartupLoad := True;
      FDefaultPeriodIndex := 0;
      FDefaultLanguageIndex := 0;
    end;
  finally
    LvRegistry.Free;
  end;
end;

class procedure TSingletonSettings.RegisterFormClassForTheming(
  const AFormClass: TCustomFormClass; const Component: TComponent);
var
 ITS: IOTAIDEThemingServices;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, ITS) then
  begin
    if ITS.IDEThemingEnabled then
    begin
      ITS.RegisterFormClass(AFormClass);
      if Assigned(Component) then
        ITS.ApplyTheme(Component);
    end;
  end;
end;

end.
