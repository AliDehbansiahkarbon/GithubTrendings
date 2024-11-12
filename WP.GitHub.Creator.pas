{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit WP.GitHub.Creator;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs,
  ToolsAPI.WelcomePage, ToolsAPI, WP.GitHub.Constants, WP.GitHub.Setting;

type
  TWPDemoPlugInCreator = class(TInterfacedObject, INTAWelcomePagePlugin, INTAWelcomePageContentPluginCreator)
  private
    FWPPluginView: TFrame;
    FIconIndex: Integer;
    { INTAWelcomePageContentPluginCreator }
    function GetView: TFrame;
    function GetIconIndex: Integer;
    procedure SetIconIndex(const Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    class procedure PlugInStartup;
    class procedure PlugInFinish;
    { INTAWelcomePagePlugin }
    function GetPluginID: string;
    function GetPluginName: string;
    function GetPluginVisible: boolean;
    { INTAWelcomePageContentPluginCreator }
    function CreateView: TFrame;
    procedure DestroyView;
    function GetIcon: TGraphicArray;
  end;

procedure Register;

implementation

uses
  WP.GitHub.View;

procedure Register;
begin
  TWPDemoPlugInCreator.PlugInStartup;
end;

{ TWPDemoPlugInCreator }

function TWPDemoPlugInCreator.GetPluginID: string;
begin
  Result := cPluginID;
end;

function TWPDemoPlugInCreator.GetPluginName: string;
begin
  Result := cPluginName;
end;

function TWPDemoPlugInCreator.GetPluginVisible: boolean;
begin
  Result := True;
end;

constructor TWPDemoPlugInCreator.Create;
begin
  FIconIndex := -1;
end;

destructor TWPDemoPlugInCreator.Destroy;
begin
  DestroyView;
  inherited;
end;

function TWPDemoPlugInCreator.CreateView: TFrame;
var
  LPluginView: INTAWelcomePageCaptionFrame;
//  LFrame: TMainFrame;
begin
//  if not Assigned(FWPPluginView) then
//    FWPPluginView := TMainFrame.Create(nil);
//  Result := FWPPluginView;
  if not Assigned(FWPPluginView) then
    FWPPluginView := WelcomePagePluginService.CreateCaptionFrame(cPluginID, cPluginName, nil);

  if Supports(FWPPluginView, INTAWelcomePageCaptionFrame, LPluginView) then
  begin
    MainFrame := TMainFrame.Create(FWPPluginView);
    LPluginView.SetClientFrame(MainFrame);
  end;
  Result := FWPPluginView;
end;

procedure TWPDemoPlugInCreator.DestroyView;
begin
  FreeAndNil(FWPPluginView);
end;

function TWPDemoPlugInCreator.GetIcon: TGraphicArray;
begin
  Result := [];
end;

function TWPDemoPlugInCreator.GetIconIndex: Integer;
begin
  Result := FIconIndex;
end;

procedure TWPDemoPlugInCreator.SetIconIndex(const Value: Integer);
begin
  FIconIndex := Value;
end;

function TWPDemoPlugInCreator.GetView: TFrame;
begin
  Result := FWPPluginView;
end;

class procedure TWPDemoPlugInCreator.PlugInStartup;
begin
  WelcomePagePluginService.RegisterPluginCreator(TWPDemoPlugInCreator.Create);
  TSingletonSettings.Instance;
end;

class procedure TWPDemoPlugInCreator.PlugInFinish;
begin
  if Assigned(WelcomePagePluginService) then
    WelcomePagePluginService.UnRegisterPlugin(cPluginID);
end;

initialization

finalization
  TWPDemoPlugInCreator.PlugInFinish;
end.
