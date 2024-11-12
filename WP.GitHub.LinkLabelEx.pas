{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit WP.GitHub.LinkLabelEx;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Winapi.Messages, System.SysUtils;

type
  TLinkLabelEx = class(TLabel)
  private
    FLinkColor: TColor;
    FHoverColor: TColor;
    FVisitedColor: TColor;
    FVisited: Boolean;
    FRegistryKeyName: string;
    FListIndex: Integer;
    FFavoriteImage: TImage;
    FCloneURL: string;
    procedure SetLinkColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetVisitedColor(const Value: TColor);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetCaptionEx(const Value: TCaption);
  protected
    procedure DoLinkClick;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Visited: Boolean read FVisited write FVisited;
    property LinkColor: TColor read FLinkColor write SetLinkColor default clBlue;
    property HoverColor: TColor read FHoverColor write SetHoverColor default clRed;
    property VisitedColor: TColor read FVisitedColor write SetVisitedColor default clPurple;
    property CaptionEx: TCaption write SetCaptionEx;
    property RegistryKeyName: string read FRegistryKeyName write FRegistryKeyName;
    property ListIndex: Integer read FListIndex write FListIndex;
    property FavoriteImage: TImage read FFavoriteImage write FFavoriteImage;
    property CloneURL: string read FCloneURL write FCloneURL;
  end;

implementation

{ TLinkLabelEx }
constructor TLinkLabelEx.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLinkColor := clBlue;
  FHoverColor := clRed;
  FVisitedColor := clPurple;
  Font.Color := FLinkColor;
  FVisited := False;
end;

procedure TLinkLabelEx.SetLinkColor(const Value: TColor);
begin
  FLinkColor := Value;
  if not FVisited then
    Font.Color := FLinkColor;
end;

function CapitalizeFirstChar(const Input: string): string;
begin
  if Input <> '' then
    Result := UpperCase(Input[1]) + Copy(Input, 2, Length(Input) - 1)
  else
    Result := '';
end;

procedure TLinkLabelEx.SetCaptionEx(const Value: TCaption);
begin
  Self.Caption := CapitalizeFirstChar(Value);
end;

procedure TLinkLabelEx.SetHoverColor(const Value: TColor);
begin
  FHoverColor := Value;
end;

procedure TLinkLabelEx.SetVisitedColor(const Value: TColor);
begin
  FVisitedColor := Value;
end;

procedure TLinkLabelEx.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  Font.Color := FHoverColor;
  Font.Style := [TFontStyle.fsUnderline];
  Cursor := crHandPoint;
end;

procedure TLinkLabelEx.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FVisited then
    Font.Color := FVisitedColor
  else
    Font.Color := FLinkColor;

  Font.Style := [];
  Cursor := crDefault;
end;

procedure TLinkLabelEx.DoLinkClick;
begin
  inherited;
  FVisited := True;
  Font.Color := FVisitedColor;
end;

end.

