object MainFrame: TMainFrame
  Left = 0
  Top = 0
  Width = 381
  Height = 436
  DoubleBuffered = True
  Color = clWindow
  ParentBackground = False
  ParentColor = False
  ParentDoubleBuffered = False
  PopupMenu = PopupMenuPeriod
  TabOrder = 0
  DesignSize = (
    381
    436)
  object pnlBottom: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 403
    Width = 375
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    ParentColor = True
    TabOrder = 0
    DesignSize = (
      375
      30)
    object lbl_RepoCount: TLabel
      AlignWithMargins = True
      Left = 322
      Top = 14
      Width = 3
      Height = 15
      Anchors = [akRight, akBottom]
      Layout = tlCenter
      ExplicitTop = 10
    end
    object Btn_LoadRepositories: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 65
      Height = 24
      Align = alLeft
      Caption = 'Daily'
      DropDownMenu = PopupMenuPeriod
      Style = bsSplitButton
      TabOrder = 0
    end
    object Btn_ChangeLanguage: TButton
      AlignWithMargins = True
      Left = 74
      Top = 3
      Width = 65
      Height = 24
      Align = alLeft
      Caption = 'Pascal'
      DropDownMenu = PopupMenuLanguage
      Style = bsSplitButton
      TabOrder = 1
    end
    object chk_TopTen: TCheckBox
      AlignWithMargins = True
      Left = 145
      Top = 3
      Width = 54
      Height = 24
      Align = alLeft
      Caption = 'Top10'
      TabOrder = 2
      OnClick = chk_TopTenClick
    end
  end
  object ScrollBox: TScrollBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 375
    Height = 394
    VertScrollBar.Increment = 35
    VertScrollBar.Size = 1
    VertScrollBar.Style = ssHotTrack
    VertScrollBar.Tracking = True
    Align = alClient
    BevelOuter = bvNone
    BorderStyle = bsNone
    ParentBackground = True
    TabOrder = 1
    UseWheelForScrolling = True
    StyleElements = [seFont, seBorder]
    object ControlList1: TControlList
      Left = 0
      Top = 0
      Width = 375
      Height = 0
      Margins.Right = 20
      Align = alTop
      BorderStyle = bsNone
      ItemMargins.Left = 0
      ItemMargins.Top = 0
      ItemMargins.Right = 0
      ItemMargins.Bottom = 0
      ColumnLayout = cltMultiTopToBottom
      ParentColor = False
      TabOrder = 0
      SmoothMouseWheelScrolling = True
    end
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 159
    Top = 156
    Anchors = [akLeft, akBottom]
    FrameDelay = 30
    IndicatorSize = aisXLarge
  end
  object PopupMenuPeriod: TPopupMenu
    Left = 54
    Top = 252
    object mniDaily: TMenuItem
      Caption = 'Daily'
      OnClick = mniDailyClick
    end
    object mniWeekly: TMenuItem
      Caption = 'Weekly'
      OnClick = mniWeeklyClick
    end
    object mniMonthly: TMenuItem
      Caption = 'Monthly'
      OnClick = mniMonthlyClick
    end
    object mniYearly: TMenuItem
      Caption = 'Yearly'
      OnClick = mniYearlyClick
    end
  end
  object PopupMenuLanguage: TPopupMenu
    Left = 62
    Top = 180
    object mniPascal: TMenuItem
      Caption = 'Pascal'
      OnClick = mniPascalClick
    end
    object mniC: TMenuItem
      Caption = 'C/C++'
      OnClick = mniCClick
    end
    object mniSQL: TMenuItem
      Caption = 'SQL'
      OnClick = mniSQLClick
    end
  end
end
