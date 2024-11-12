object Frm_Settings: TFrm_Settings
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Settings'
  ClientHeight = 209
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 391
    Height = 96
    Align = alTop
    Caption = 'Git'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 40
      Width = 73
      Height = 15
      Caption = 'Git.exe PATH: '
    end
    object edt_GitPath: TEdit
      Left = 95
      Top = 37
      Width = 282
      Height = 23
      TabOrder = 0
      Text = 'C:\Program Files\Git\bin\git.exe'
      TextHint = 'C:\Program Files\Git\bin\git.exe'
    end
    object Button1: TButton
      Left = 348
      Top = 39
      Width = 26
      Height = 19
      Caption = '...'
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 96
    Width = 391
    Height = 113
    Align = alClient
    Caption = 'Other Options'
    TabOrder = 1
    DesignSize = (
      391
      113)
    object Label2: TLabel
      Left = 18
      Top = 57
      Width = 81
      Height = 15
      Caption = 'Default period: '
    end
    object Label3: TLabel
      Left = 18
      Top = 83
      Width = 99
      Height = 15
      Caption = 'Default Language: '
    end
    object Btn_Close: TButton
      Left = 324
      Top = 87
      Width = 64
      Height = 23
      Anchors = [akRight, akBottom]
      Caption = 'Close'
      TabOrder = 0
      OnClick = Btn_CloseClick
    end
    object Btn_Save: TButton
      Left = 259
      Top = 87
      Width = 64
      Height = 23
      Anchors = [akRight, akBottom]
      Caption = 'Save'
      TabOrder = 1
      OnClick = Btn_SaveClick
    end
    object cbb_Period: TComboBox
      Left = 99
      Top = 54
      Width = 74
      Height = 23
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 2
      Text = 'Daily'
      Items.Strings = (
        'Daily'
        'Weekly'
        'Monthly'
        'Yearly')
    end
    object cbb_Lang: TComboBox
      Left = 117
      Top = 80
      Width = 74
      Height = 23
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 3
      Text = 'Pascal'
      Items.Strings = (
        'Pascal'
        'C/C++'
        'SQL')
    end
    object chk_StartupLoad: TCheckBox
      Left = 18
      Top = 24
      Width = 119
      Height = 17
      Caption = 'Load at IDE startup'
      TabOrder = 4
    end
  end
end
