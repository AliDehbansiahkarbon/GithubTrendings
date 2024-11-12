unit WP.GitHub.CustomMessage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFrm_CustomMSG = class(TForm)
    Btn_No: TButton;
    Btn_Yes: TButton;
    lbl_Msg: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Btn_YesClick(Sender: TObject);
    procedure Btn_NoClick(Sender: TObject);
  private
    { Private declarations }
  public
    constructor CreateMessage(const AMessage: string; const ACaption: string); reintroduce;
    { Public declarations }
  end;

var
  Frm_CustomMSG: TFrm_CustomMSG;

implementation

{$R *.dfm}

{ TForm1 }

procedure TFrm_CustomMSG.Btn_NoClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrm_CustomMSG.Btn_YesClick(Sender: TObject);
begin
  ModalResult := mrYes;
end;

constructor TFrm_CustomMSG.CreateMessage(const AMessage, ACaption: string);
begin
  inherited Create(nil);
  Caption := ACaption;
  lbl_Msg.Caption := AMessage;
end;

end.
