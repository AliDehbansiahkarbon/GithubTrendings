object Frm_CustomMSG: TFrm_CustomMSG
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Confirm'
  ClientHeight = 97
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 56
    Width = 497
    Height = 41
    Align = alBottom
    ParentBackground = False
    TabOrder = 0
    object Btn_No: TButton
      Left = 418
      Top = 10
      Width = 75
      Height = 25
      Caption = 'No'
      TabOrder = 0
      OnClick = Btn_NoClick
    end
    object Btn_Yes: TButton
      Left = 342
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Yes'
      TabOrder = 1
      OnClick = Btn_YesClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 497
    Height = 56
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lbl_Msg: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 491
      Height = 50
      Align = alClient
      AutoSize = False
      Caption = 'lbl_Msg'
      Layout = tlCenter
      WordWrap = True
      ExplicitLeft = 8
      ExplicitTop = 16
      ExplicitWidth = 485
      ExplicitHeight = 15
    end
  end
end
