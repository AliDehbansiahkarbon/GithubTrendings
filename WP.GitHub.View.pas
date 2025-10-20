{ ***************************************************}
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)  }
{   GitHub: https://github.com/AliDehbansiahkarbon   }
{ ***************************************************}

unit WP.GitHub.View;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, System.JSON, System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  System.Net.HttpClientComponent, WP.GitHub.Helper, System.Threading, Vcl.WinXCtrls, Winapi.ShellAPI,
  Vcl.Themes, ToolsAPI, Vcl.Imaging.jpeg, Vcl.GraphUtil, System.Generics.Defaults,
  System.Math, WP.GitHub.LinkLabelEx, Vcl.Imaging.pngimage, WP.GitHub.Constants,
  Vcl.ControlList, System.Win.Registry, WP.GitHub.Setting, Vcl.Buttons,
  System.ImageList, Vcl.ImgList, Vcl.VirtualImageList, System.StrUtils,
  Vcl.BaseImageCollection, Vcl.ImageCollection;

type
  TStyleNotifier = class(TNotifierObject, INTAIDEThemingServicesNotifier)
  private
    procedure ChangingTheme;
    procedure ChangedTheme;
  end;

  TRepository = record
    RepoName: string;
    RepoURL: string;
    Author: string;
    AvatarUrl: string;
    Description: string;
    Language: string;
    StarCount: Integer;
    ForkCount: Integer;
    IssuCount: Integer;
    CreatedDate: TDateTime;
  end;

  TMainFrame = class(TFrame)
    PopupMenuPeriod: TPopupMenu;
    mniDaily: TMenuItem;
    mniWeekly: TMenuItem;
    mniMonthly: TMenuItem;
    pnlBottom: TPanel;
    Btn_LoadRepositories: TButton;
    ActivityIndicator1: TActivityIndicator;
    ScrollBox: TScrollBox;
    mniYearly: TMenuItem;
    lbl_RepoCount: TLabel;
    Btn_ChangeLanguage: TButton;
    PopupMenuLanguage: TPopupMenu;
    mniPascal: TMenuItem;
    mniSQL: TMenuItem;
    mniC: TMenuItem;
    ControlList1: TControlList;
    PopupMenuRepoPanel: TPopupMenu;
    mniFavorites: TMenuItem;
    mniGitClone: TMenuItem;
    pnlTop: TPanel;
    btnReload: TSpeedButton;
    btnSetting: TSpeedButton;
    btnFavorite: TSpeedButton;
    chk_TopTen: TCheckBox;
    mniGitCloneOpenProject: TMenuItem;
    ilTitleFrame: TVirtualImageList;
    ImageCollection1: TImageCollection;
    btnStop: TSpeedButton;
    procedure mniDailyClick(Sender: TObject);
    procedure mniWeeklyClick(Sender: TObject);
    procedure mniMonthlyClick(Sender: TObject);
    procedure mniYearlyClick(Sender: TObject);
    procedure ImgClick(Sender: TObject);
    procedure PanelResize(Sender: TObject);
    procedure mniPascalClick(Sender: TObject);
    procedure mniCClick(Sender: TObject);
    procedure mniSQLClick(Sender: TObject);
    procedure chk_TopTenClick(Sender: TObject);
    procedure PopupMenuRepoPanelPopup(Sender: TObject);
    procedure mniFavoritesClick(Sender: TObject);
    procedure mniGitCloneClick(Sender: TObject);
    procedure btnSettingClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnFavoriteClick(Sender: TObject);
    procedure mniGitCloneOpenProjectClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FStylingNotifierIndex: Integer;
    FPeriod: string;
    FLanguage: string;
    FRepositoryList: TList<TRepository>;
    FStyleNotifier: TStyleNotifier;
    LastClickedLinkLabelEx: TLinkLabelEx;
    FavoriteListLoaded: Boolean;
    FDesignPPI: Integer;
    FLastPPI: Integer;
    FCreationTime: Boolean;
    FStop: Boolean;
    procedure RefreshList;
    procedure AddRepository(const AIndex: Integer; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
    procedure LinkLabel_RepositoryLinkClick(Sender: TObject);
    procedure UpdateUI(AIsEmpty: Boolean = False; AMsg: string = '');
    procedure ChangePeriod(const AListType: string);
    procedure ChangeLanguage(const ALang: string);
    procedure LoadImageFromResource(const AImage: TImage; const AResourceName: string);
    procedure SaveToFavorites(AIndex: Integer);
    procedure RemoveFromFavorites(AIndex: Integer);
    function LoadFavorites: Boolean;
    function IsAlreadyFavorite(ALinkLabel: TLinkLabelEx): Boolean;
    function Dpi(const V: Integer): Integer; inline;
    procedure LayoutRepositoryPanel(const APanel: TPanel);
    function GetSafePPI(const Ref: TControl): Integer;
    function Px(const Ref: TControl; const V: Integer): Integer;
    procedure InitListChrome;
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PullRepoList;
    procedure ClearScrollBox;
  end;

  var
    MainFrame: TMainFrame;

implementation

uses
  WP.GitHub.Creator;

{$R *.dfm}

procedure TMainFrame.PanelResize(Sender: TObject);
begin
  if not FCreationTime then
    LayoutRepositoryPanel(TPanel(Sender)); // keep the item coherent
end;

procedure TMainFrame.PopupMenuRepoPanelPopup(Sender: TObject);
begin
  LastClickedLinkLabelEx := TPopupMenu(Sender).PopupComponent as TLinkLabelEx;
  if IsAlreadyFavorite(LastClickedLinkLabelEx) then
    mniFavorites.Caption := 'Remove from favorites'
  else
    mniFavorites.Caption := 'Add to favorites';
end;

procedure TMainFrame.mniSQLClick(Sender: TObject);
begin
  ChangeLanguage(cSQL);
end;

procedure TMainFrame.PullRepoList;
var
  LvJSONResponse: string;
  LvJSONObj: TJSONObject;
  LvRepositories: TJSONArray;
  LvRepo: TJSONObject;
  LvOwner: TJSONObject;
begin
  FStop := False;

  TThread.Synchronize(TThread.Current,
  procedure
  begin
    ActivityIndicator1.Left := (Self.Width div 2) - (ActivityIndicator1.Width div 2);
    ActivityIndicator1.Top := (Self.Height div 2) - (ActivityIndicator1.Height div 2);
    ActivityIndicator1.StartAnimation;
    ActivityIndicator1.Visible := True;
  end);

  var LvException: string;
  if not TGitHubHelper.CheckInternetAvailabilityAsync('https://www.github.com', LvException) then
  begin
    TThread.Synchronize(TThread.Current, procedure begin UpdateUI(True, LvException); end);
    Exit;
  end;

  TTask.Run(
  procedure
  var
    I: Integer;
  begin
    try
      try
        LvJSONResponse := TGitHubHelper.GetTrendingPascalRepositories(FPeriod, FLanguage);
        try
          LvJSONObj := TJSONObject.ParseJSONValue(LvJSONResponse) as TJSONObject;
        except on E: Exception do
          LvJSONObj := nil;
        end;

        try
          if Assigned(LvJSONObj) then
          begin
            FRepositoryList.Clear;
            LvRepositories := LvJSONObj.GetValue<TJSONArray>('items');

            var LvRepoCount: Integer;
            if chk_TopTen.Checked then
              LvRepoCount := Min(10 , LvRepositories.Count - 1)
            else
              LvRepoCount := Min(100, LvRepositories.Count - 1);

            lbl_RepoCount.Caption := '(' + LvRepoCount.ToString + ')';
            lbl_RepoCount.Align := alRight;

            for I := 0 to LvRepoCount do
            begin
              LvRepo := LvRepositories.Items[I] as TJSONObject;

              if Assigned(LvRepo) then
              begin
                var LvRepoRec: TRepository;
                LvRepoRec.RepoName := LvRepo.GetValue<string>('name');
                LvRepoRec.RepoURL := LvRepo.GetValue<string>('html_url');
                LvRepoRec.Description := LvRepo.GetValue<string>('description');
                LvRepoRec.CreatedDate := LvRepo.GetValue<TDateTime>('created_at');
                LvRepoRec.Language := LvRepo.GetValue<string>('language');
                LvRepoRec.StarCount := LvRepo.GetValue<Integer>('stargazers_count');
                LvRepoRec.ForkCount := LvRepo.GetValue<Integer>('forks');
                LvRepoRec.IssuCount := LvRepo.GetValue<Integer>('open_issues');

                LvOwner := LvRepo.GetValue<TJSONObject>('owner');
                if Assigned(LvOwner) then
                begin
                  LvRepoRec.Author := LvOwner.GetValue<string>('login');
                  LvRepoRec.AvatarUrl := LvOwner.GetValue<string>('avatar_url');
                end;

                FRepositoryList.Add(LvRepoRec);
              end;
            end;
          end;
        finally
          if Assigned(LvJSONObj) then
            LvJSONObj.Free;
        end;
      except on E: Exception do
        ShowMessage('Error: ' + E.Message);
      end;
    finally
      TThread.Queue(TThread.CurrentThread, procedure begin UpdateUI; end);
    end;
  end);
end;

function TMainFrame.GetSafePPI(const Ref: TControl): Integer;
var
  DC: HDC;
  PPI: Integer;
begin
  {$IF CompilerVersion >= 34.0} // 10.4+
  if Assigned(Ref) then
    PPI := Ref.CurrentPPI
  else
    PPI := Screen.PixelsPerInch;
  {$ELSE}
  PPI := Screen.PixelsPerInch;
  {$IFEND}

  if PPI <= 0 then
  begin
    DC := GetDC(0);
    try
      PPI := GetDeviceCaps(DC, LOGPIXELSX);
    finally
      ReleaseDC(0, DC);
    end;
  end;

  if PPI <= 0 then
    PPI := 96;

  FLastPPI := PPI;
  Result := PPI;
end;

function TMainFrame.Px(const Ref: TControl; const V: Integer): Integer;
var
  PPI, DesignPPI: Integer;
begin
  if FDesignPPI = 0 then
    FDesignPPI := 96;

  if FLastPPI > 0 then
    PPI := FLastPPI
  else
    PPI := GetSafePPI(Ref);

  DesignPPI := FDesignPPI;
  if DesignPPI <= 0 then
    DesignPPI := 96;

  Result := MulDiv(V, PPI, DesignPPI);
end;
procedure TMainFrame.UpdateUI(AIsEmpty: Boolean = False; AMsg: string = '');
var
  I: Integer;
  LvThemingServices: IOTAIDEThemingServices;
  LvThemingEnabled: Boolean;
  LvNewColor: TColor;
begin
  LvThemingEnabled := False;
  ActivityIndicator1.StopAnimation;
  ActivityIndicator1.Visible := False;
  LvNewColor := clWindow;

  if AIsEmpty then
  begin
    ClearScrollBox;
    var LvEmptyLabel := TLabel.Create(ScrollBox);
    LvEmptyLabel.Name := 'emptylabel';
    LvEmptyLabel.Parent := ScrollBox;
    LvEmptyLabel.Caption := AMsg;
    LvEmptyLabel.Alignment := taCenter;
    LvEmptyLabel.Font.Size := 12;
    LvEmptyLabel.Align := alTop;
    LvEmptyLabel.AutoSize := True;
    LvEmptyLabel.WordWrap := True;
    Exit;
  end;

  // Ascending sort by Star Count
  FRepositoryList.Sort(TComparer<TRepository>.Construct(
  function(const Left, Right: TRepository): Integer
  begin
    Result := Left.StarCount - Right.StarCount;
  end));

  if FRepositoryList.Count > 0 then
  begin
    if Supports(BorlandIDEServices, IOTAIDEThemingServices, LvThemingServices) and LvThemingServices.IDEThemingEnabled then
    begin
      LvThemingEnabled := True;
      LvNewColor := LvThemingServices.StyleServices.GetSystemColor(clWindow);
    end;

    ClearScrollBox;
    InitListChrome;

    FCreationTime := True;
    for I := 0 to Pred(FRepositoryList.Count) do
    begin
      if FStop then
      begin
        FStop := False;
        Break;
      end;

      AddRepository(I, FRepositoryList.Items[I], LvThemingEnabled, LvNewColor);

      if (I > 0) and (I mod 2 = 0) then
      begin
        ControlList1.Invalidate;
        Application.ProcessMessages;
      end;
    end;
    FCreationTime := False;
  end;
end;

procedure TMainFrame.btnFavoriteClick(Sender: TObject);
begin
  if not FavoriteListLoaded then
  begin
    try
      LoadFavorites;
      btnFavorite.ImageIndex := 3;
      FavoriteListLoaded := True;
    except on E: Exception do
      begin
        btnFavorite.ImageIndex := 2;
        UpdateUI(True, E.Message);
      end;
    end;
  end
  else
  begin
    FavoriteListLoaded := False;
    btnFavorite.ImageIndex := 2;
    RefreshList;
  end;
end;

procedure TMainFrame.btnSettingClick(Sender: TObject);
begin
  Frm_Settings := TFrm_Settings.Create(nil);
  TSingletonSettings.RegisterFormClassForTheming(TFrm_Settings, Frm_Settings);
  Frm_Settings.Position := poMainFormCenter;
  Frm_Settings.ShowModal;
  Frm_Settings.Free;
end;

procedure TMainFrame.btnStopClick(Sender: TObject);
begin
  FStop := True;
end;

procedure TMainFrame.mniCClick(Sender: TObject);
begin
  ChangeLanguage(cC);
end;

procedure TMainFrame.ChangeLanguage(const ALang: string);
begin
  Btn_ChangeLanguage.Caption := ALang;
  FLanguage := ALang.ToLower;
  RefreshList;
end;

procedure TMainFrame.ChangePeriod(const AListType: string);
begin
  Btn_LoadRepositories.Caption := AListType;
  FPeriod := AListType.ToLower;
  RefreshList;
end;

procedure TMainFrame.ChangeScale(M, D: Integer; isDpiChange: Boolean);
var
  I: Integer;
begin
  inherited;
  // Re-layout each item on DPI changes too
  for I := 0 to ControlList1.ControlCount - 1 do
    if ControlList1.Controls[I] is TPanel then
      LayoutRepositoryPanel(TPanel(ControlList1.Controls[I]));
end;

procedure TMainFrame.chk_TopTenClick(Sender: TObject);
begin
  RefreshList;
end;

procedure TMainFrame.ClearScrollBox;
var
  I: Integer;
begin
  for I := Pred(Self.ComponentCount) downto 0 do
  begin
    if (Self.Components[I] is TPanel) and (TPanel(Self.Components[I]).Name <> 'pnlBottom') and (TPanel(Self.Components[I]).Name <> 'pnlTop') then
      Self.Components[I].Free;
  end;

  for I := Pred(ScrollBox.ComponentCount) downto 0 do
  begin
    if (ScrollBox.Components[I] is TLabel) and (TLabel(ScrollBox.Components[I]).Name = 'emptylabel') then
      ScrollBox.Components[I].Free;
  end;

  ControlList1.Height := 0;
  ScrollBox.Invalidate;
end;

constructor TMainFrame.Create(AOwner: TComponent);
begin
  inherited;
  LastClickedLinkLabelEx := nil;
  FStyleNotifier := TStyleNotifier.Create;
  FStylingNotifierIndex := (BorlandIDEServices as IOTAIDEThemingServices).AddNotifier(FStyleNotifier);
  (BorlandIDEServices as IOTAIDEThemingServices).ApplyTheme(Self);

  if not ColorIsBright((BorlandIDEServices as IOTAIDEThemingServices).StyleServices.GetSystemColor(clBtnFace)) then
    ActivityIndicator1.IndicatorColor := aicWhite
  else
    ActivityIndicator1.IndicatorColor := aicBlack;

  FPeriod := cDaily;
  FLanguage := cPascal;
  FRepositoryList := TList<TRepository>.Create;

  var LvPeriod, LvLang: string;
  case TSingletonSettings.Instance.DefaultPeriodIndex of
    0: LvPeriod := cDaily;
    1: LvPeriod := cWeekly;
    2: LvPeriod := cMonthly;
    3: LvPeriod := cYearly;
  end;
  case TSingletonSettings.Instance.DefaultLanguageIndex of
    0: LvLang := cPascal;
    1: LvLang := cC;
    2: LvLang := cSQL;
  end;

  Btn_LoadRepositories.Caption := LvPeriod;
  FPeriod := LvPeriod.ToLower;

  Btn_ChangeLanguage.Caption := LvLang;
  FLanguage := LvLang.ToLower;

  if TSingletonSettings.Instance.StartupLoad then
    RefreshList
  else
    LoadFavorites;
end;

destructor TMainFrame.Destroy;
begin
  TSingletonSettings.Instance.Free;
  FRepositoryList.Free;
  if FStylingNotifierIndex <> -1 then
    (BorlandIDEServices as IOTAIDEThemingServices).RemoveNotifier(FStylingNotifierIndex);
  inherited;
end;

function TMainFrame.Dpi(const V: Integer): Integer;
var
  LCurrentPPI: Integer;
begin
  // Prefer control's PPI if available (Delphi 10.4+)
  {$IF CompilerVersion >= 34.0} // 10.4+
  LCurrentPPI := CurrentPPI;
  {$ELSE}
  LCurrentPPI := Screen.PixelsPerInch;
  {$IFEND}
  if FDesignPPI = 0 then
    FDesignPPI := 96;
  Result := MulDiv(V, LCurrentPPI, FDesignPPI);
end;

procedure TMainFrame.ImgClick(Sender: TObject);
begin
  if FRepositoryList.Count > 0 then
  begin
    var Url: string;
    Url := FRepositoryList.Items[TImage(Sender).Tag].AvatarUrl;
    ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL);
  end;
end;

function TMainFrame.IsAlreadyFavorite(ALinkLabel: TLinkLabelEx): Boolean;
var
  LvRegistry: TRegistry;
begin
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    Result := LvRegistry.KeyExists(cBaseKey + '\' + ALinkLabel.RegistryKeyName);
    LvRegistry.CloseKey;
  finally
    LvRegistry.Free;
  end;
end;

procedure TMainFrame.LayoutRepositoryPanel(const APanel: TPanel);

  function FindCtrl(const AName: string): TControl;
  begin
    Result := APanel.FindChildControl(AName);
  end;

  function FindCtrlByPrefix(const APrefix: string): TControl;
  var
    I: Integer;
  begin
    Result := nil;
    for I := 0 to APanel.ControlCount - 1 do
      if (APanel.Controls[I].Name <> '') and
         SameText(Copy(APanel.Controls[I].Name, 1, Length(APrefix)), APrefix) then
        Exit(APanel.Controls[I]);
  end;

  function PanelIndexSuffix: string;
  var
    PrefLen: Integer;
    Nm: string;
  begin
    Result := '';
    Nm := APanel.Name;
    PrefLen := Length(cPanelPrefix);
    if (Nm <> '') and SameText(Copy(Nm, 1, PrefLen), cPanelPrefix) then
      Result := Copy(Nm, PrefLen + 1, MaxInt);
  end;

  function WrappedTextHeight(ALabel: TLabel; AWidth: Integer): Integer;
  var
    R: TRect;
  begin
    if AWidth < 1 then
      AWidth := 1;
    R := Rect(0, 0, AWidth, 0);
    ALabel.Canvas.Font.Assign(ALabel.Font);
    Winapi.Windows.DrawText(ALabel.Canvas.Handle, PChar(ALabel.Caption), -1, R, DT_CALCRECT or DT_WORDBREAK);
    Result := R.Bottom - R.Top;
    if Result < Px(APanel, 12) then
      Result := Px(APanel, 12);
  end;

var
  IdxStr: string;
  Margin, Gap, RightMargin: Integer;
  RepoLink: TLinkLabelEx;
  Desc: TLabel;
  Avatar, Fav, StarImg, ForkImg, IssueImg: TImage;
  StarLbl, ForkLbl, IssueLbl: TLabel;
  StatsTop, AvailWidth: Integer;
begin
  if APanel = nil then Exit;

  // Scaled paddings
  Margin      := Px(APanel, 7);
  Gap         := Px(APanel, 6);
  RightMargin := Px(APanel, 5);

  // Use the panel's own name suffix to build child names (then fall back by prefix)
  IdxStr := PanelIndexSuffix;

  RepoLink := FindCtrl(cLinkLablePrefix + IdxStr) as TLinkLabelEx;
  if RepoLink = nil then RepoLink := FindCtrlByPrefix(cLinkLablePrefix) as TLinkLabelEx;

  Desc := FindCtrl(cDescriptionLabelPrefix + IdxStr) as TLabel;
  if Desc = nil then Desc := FindCtrlByPrefix(cDescriptionLabelPrefix) as TLabel;

  Avatar := FindCtrl(cAvatarPrefix + IdxStr) as TImage;
  if Avatar = nil then Avatar := FindCtrlByPrefix(cAvatarPrefix) as TImage;

  Fav := FindCtrl(cFavoritePrefix + IdxStr) as TImage;
  if Fav = nil then Fav := FindCtrlByPrefix(cFavoritePrefix) as TImage;

  StarImg := FindCtrl(cStarsPrefix + IdxStr) as TImage;
  if StarImg = nil then StarImg := FindCtrlByPrefix(cStarsPrefix) as TImage;

  StarLbl := FindCtrl(cStarCountPrefix + IdxStr) as TLabel;
  if StarLbl = nil then StarLbl := FindCtrlByPrefix(cStarCountPrefix) as TLabel;

  ForkImg := FindCtrl(cForkPrefix + IdxStr) as TImage;
  if ForkImg = nil then ForkImg := FindCtrlByPrefix(cForkPrefix) as TImage;

  ForkLbl := FindCtrl(cForkCountPrefix + IdxStr) as TLabel;
  if ForkLbl = nil then ForkLbl := FindCtrlByPrefix(cForkCountPrefix) as TLabel;

  IssueImg := FindCtrl(cIssuePrefix + IdxStr) as TImage;
  if IssueImg = nil then IssueImg := FindCtrlByPrefix(cIssuePrefix) as TImage;

  IssueLbl := FindCtrl(cIssueCountPrefix + IdxStr) as TLabel;
  if IssueLbl = nil then IssueLbl := FindCtrlByPrefix(cIssueCountPrefix) as TLabel;

  // If these are missing, nothing to layout (can happen during very early resizes)
  if (RepoLink = nil) or (Desc = nil) or (Avatar = nil) then
    Exit;

  // Defensive: ensure key visuals have sane sizes in case they were created pre-PPI
  if Avatar.Width  = 0 then Avatar.Width  := Px(APanel, 35);
  if Avatar.Height = 0 then Avatar.Height := Px(APanel, 35);

  if StarImg <> nil then
  begin
    if StarImg.Width  = 0 then StarImg.Width  := Px(APanel, 16);
    if StarImg.Height = 0 then StarImg.Height := Px(APanel, 16);
  end;

  if ForkImg <> nil then
  begin
    if ForkImg.Width  = 0 then ForkImg.Width  := Px(APanel, 17);
    if ForkImg.Height = 0 then ForkImg.Height := Px(APanel, 16);
  end;

  if IssueImg <> nil then
  begin
    if IssueImg.Width  = 0 then IssueImg.Width  := Px(APanel, 17);
    if IssueImg.Height = 0 then IssueImg.Height := Px(APanel, 16);
  end;

  if Fav <> nil then
  begin
    if Fav.Width  = 0 then Fav.Width  := Px(APanel, 12);
    if Fav.Height = 0 then Fav.Height := Px(APanel, 12);
  end;

  // 1) Avatar: top-right
  Avatar.SetBounds(
    APanel.ClientWidth - Avatar.Width - RightMargin,
    Px(APanel, 3),
    Avatar.Width,
    Avatar.Height
  );

  // 2) Repo link: span left → avatar - gap
  RepoLink.Anchors := [akLeft, akTop, akRight];
  AvailWidth := Avatar.Left - Gap - RepoLink.Left;
  if AvailWidth < 0 then AvailWidth := 0;
  RepoLink.Width := AvailWidth;

  // 3) Description: fixed width to avatar; compute wrapped height explicitly
  Desc.Anchors  := [akLeft, akTop, akRight];
  Desc.AutoSize := False;
  Desc.WordWrap := True;
  AvailWidth := Avatar.Left - Gap - Desc.Left;
  if AvailWidth < Px(APanel, 20) then
    AvailWidth := Px(APanel, 20);
  Desc.Width  := AvailWidth;
  Desc.Height := WrappedTextHeight(Desc, AvailWidth);

  // 4) Stats row under description
  StatsTop := Desc.Top + Desc.Height + Gap;

  if (StarImg <> nil) and (StarLbl <> nil) then
  begin
    StarImg.SetBounds(Margin, StatsTop, Px(APanel, 16), Px(APanel, 16));
    StarLbl.Top  := StarImg.Top + (StarImg.Height - StarLbl.Height) div 2;
    StarLbl.Left := StarImg.Left + StarImg.Width + Px(APanel, 4);
  end;

  if (ForkImg <> nil) and (ForkLbl <> nil) then
  begin
    ForkImg.Left  := StarLbl.Left + StarLbl.Width + Px(APanel, 12);
    ForkImg.Top   := StatsTop;
    ForkImg.Width := Px(APanel, 17);
    ForkImg.Height:= Px(APanel, 16);

    ForkLbl.Top   := ForkImg.Top + (ForkImg.Height - ForkLbl.Height) div 2;
    ForkLbl.Left  := ForkImg.Left + ForkImg.Width + Px(APanel, 4);
  end;

  if (IssueImg <> nil) and (IssueLbl <> nil) then
  begin
    IssueImg.Left  := ForkLbl.Left + ForkLbl.Width + Px(APanel, 12);
    IssueImg.Top   := StatsTop;
    IssueImg.Width := Px(APanel, 17);
    IssueImg.Height:= Px(APanel, 16);

    IssueLbl.Top   := IssueImg.Top + (IssueImg.Height - IssueLbl.Height) div 2;
    IssueLbl.Left  := IssueImg.Left + IssueImg.Width + Px(APanel, 4);
  end;

  // 5) Favorite: right-aligned on stats row
  if Fav <> nil then
  begin
    Fav.Anchors := [akTop, akRight];
    Fav.Left    := APanel.ClientWidth - Fav.Width - RightMargin;
    Fav.Top     := StatsTop + (Px(APanel, 16) - Fav.Height) div 2;
  end;

  // 6) Panel height fits tallest content + bottom margin
  var BottomY := StatsTop + Px(APanel, 16);
  if (Avatar.Top + Avatar.Height) > BottomY then
    BottomY := Avatar.Top + Avatar.Height;

  Inc(BottomY, Margin);

  if BottomY <> APanel.Height then
    APanel.Height := BottomY;

  //ControlList1.Width := ControlList1.Width - 1;
end;

procedure TMainFrame.LinkLabel_RepositoryLinkClick(Sender: TObject);
begin
  if FRepositoryList.Count > 0 then
  begin
    var Url: string;
    Url := TLinkLabelEx(Sender).CloneURL;
    ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL);

    TLinkLabelEx(Sender).Visited := True;
    TLinkLabelEx(Sender).Font.Color := TLinkLabelEx(Sender).VisitedColor;
  end;
end;

procedure TMainFrame.mniWeeklyClick(Sender: TObject);
begin
  ChangePeriod(cWeekly);
end;

procedure TMainFrame.mniYearlyClick(Sender: TObject);
begin
  ChangePeriod(cYearly);
end;

procedure TMainFrame.mniMonthlyClick(Sender: TObject);
begin
  ChangePeriod(cMonthly);
end;

procedure TMainFrame.mniPascalClick(Sender: TObject);
begin
  ChangeLanguage(cPascal);
end;

procedure TMainFrame.mniDailyClick(Sender: TObject);
begin
  ChangePeriod(cDaily)
end;

procedure TMainFrame.mniFavoritesClick(Sender: TObject);
begin
  if IsAlreadyFavorite(LastClickedLinkLabelEx) then
    RemoveFromFavorites(LastClickedLinkLabelEx.ListIndex)
  else
    SaveToFavorites(LastClickedLinkLabelEx.ListIndex);
end;

procedure TMainFrame.mniGitCloneClick(Sender: TObject);
begin
  TGitHubHelper.CloneGitHubRepo(LastClickedLinkLabelEx.CloneURL, LastClickedLinkLabelEx.RegistryKeyName);
end;

procedure TMainFrame.mniGitCloneOpenProjectClick(Sender: TObject);
begin
  TGitHubHelper.CloneGitHubRepoAndOpen(LastClickedLinkLabelEx.CloneURL, LastClickedLinkLabelEx.RegistryKeyName);
end;

procedure TMainFrame.RefreshList;
begin
  TTask.Run(procedure begin PullRepoList; end);
end;

procedure TMainFrame.RemoveFromFavorites(AIndex: Integer);
var
  LvRegistry: TRegistry;
begin
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    if LvRegistry.KeyExists(cBaseKey + '\' + FRepositoryList.Items[AIndex].RepoName) then
    begin
      LvRegistry.DeleteKey(cBaseKey + '\' + FRepositoryList.Items[AIndex].RepoName);
      LvRegistry.CloseKey;

      LastClickedLinkLabelEx.FavoriteImage.Visible := False;
      if FavoriteListLoaded then
      begin
        FRepositoryList.Delete(AIndex);
        if FRepositoryList.Count = 0 then
          UpdateUI(True, cFavoriteIsEmpty)
        else
          UpdateUI;
      end;
    end;
  finally
    LvRegistry.Free;
  end;
end;

procedure TMainFrame.SaveToFavorites(AIndex: Integer);
var
  LvRegistry: TRegistry;
  LvRepository: TRepository;
begin
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    LvRepository := FRepositoryList.Items[AIndex];
    if LvRegistry.OpenKey(cBaseKey + '\' + LvRepository.RepoName, True) then
    begin
      LvRegistry.WriteString('RepoName', LvRepository.RepoName);
      LvRegistry.WriteString('RepoURL', LvRepository.RepoURL);
      LvRegistry.WriteString('Author', LvRepository.Author);
      LvRegistry.WriteString('AvatarUrl', LvRepository.AvatarUrl);
      LvRegistry.WriteString('Description', LvRepository.Description);
      LvRegistry.WriteString('Language', LvRepository.Language);
      LvRegistry.WriteInteger('StarCount', LvRepository.StarCount);
      LvRegistry.WriteInteger('ForkCount', LvRepository.ForkCount);
      LvRegistry.WriteInteger('IssuCount', LvRepository.IssuCount);
      LvRegistry.WriteDateTime('CreatedDate', LvRepository.CreatedDate);
      LvRegistry.CloseKey;
      LastClickedLinkLabelEx.FavoriteImage.Visible := True;
    end;
  finally
    LvRegistry.Free;
  end;
end;

procedure TMainFrame.btnReloadClick(Sender: TObject);
begin
  RefreshList;
end;

procedure TMainFrame.InitListChrome;
begin
  ControlList1.AlignWithMargins := False;
  ControlList1.BorderStyle := bsNone;
  ControlList1.Padding.SetBounds(0,0,0,0);

  ScrollBox.BevelEdges := [];
  ScrollBox.BevelKind  := bkNone;
  ScrollBox.BorderStyle := bsNone;
  ScrollBox.Padding.SetBounds(0,0,0,0);
end;

procedure TMainFrame.AddRepository(const AIndex: Integer; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
var
  LvPanel: TPanel;
  LblDate, LblDescription, LblStarCount, LblForkCount, LblIssueCount: TLabel;
  ImgStars, ImgFork, ImgIssue, ImgFavorite, ImgAvatar: TImage;
  LinkRepository: TLinkLabelEx;
begin
  LvPanel := TPanel.Create(Self);
  try
    // --- Panel (row container) ---
    LvPanel.Name  := cPanelPrefix + AIndex.ToString;
    LvPanel.Caption := EmptyStr;
    LvPanel.Parent := ControlList1;
    LvPanel.BevelEdges := [];
    LvPanel.BevelKind  := bkNone;
    LvPanel.BevelOuter := bvNone;
    LvPanel.BevelInner := bvNone;
    LvPanel.BorderStyle := bsNone;
    LvPanel.Height := Dpi(88);
    LvPanel.Tag := AIndex;      // used by LayoutRepositoryPanel
    LvPanel.OnResize := PanelResize;
    LvPanel.AutoSize := False;
    LvPanel.Align := alTop;

    if AThemingEnabled then
    begin
      LvPanel.StyleElements := LvPanel.StyleElements - [seClient];
      LvPanel.ParentBackground := False;
      LvPanel.Color := AColor;
    end;

    // --- Date label ---
    LblDate := TLabel.Create(LvPanel);
    with LblDate do
    begin
      Name := cDateLabelPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Left := Dpi(7);
      Top  := Dpi(24);     // initial; final layout will adjust as needed
      Caption := 'Created at ' + FormatDateTime('dd.mm.yyyy', ARepository.CreatedDate);
      Font.Name := 'Segoe UI';   // let VCL size it per DPI; don't set Font.Height
      ParentFont := False;
      ShowHint := False;
      AutoSize := True;
      Anchors := [akLeft, akTop];
      Font.Color := clGrayText;  // slightly themed!
    end;

    // --- Description ---
    LblDescription := TLabel.Create(LvPanel);
    with LblDescription do
    begin
      Name := cDescriptionLabelPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      AutoSize := False;        // width is set, height will be recomputed in layout
      Left := Dpi(7);
      Top  := Dpi(42);          // initial; final height/width set in LayoutRepositoryPanel
      Width := Max(0, ControlList1.ClientWidth - Dpi(14));
      WordWrap := True;
      Caption := ARepository.Description;
      Hint := ARepository.Description;
      ShowHint := True;
      Anchors := [akLeft, akTop, akRight];
    end;

    // --- Stars image ---
    ImgStars := TImage.Create(LvPanel);
    with ImgStars do
    begin
      Name := cStarsPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Width := Dpi(16);
      Height := Dpi(16);
      Left := Dpi(7);
      Top  := Dpi(60); // initial; will be repositioned
      Anchors := [akLeft, akTop];
      LoadImageFromResource(ImgStars, 'STAR');
    end;

    // --- Stars count ---
    LblStarCount := TLabel.Create(LvPanel);
    with LblStarCount do
    begin
      Name := cStarCountPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Caption := ARepository.StarCount.ToString;
      ParentFont := False;
      Font.Name := 'Segoe UI';
      AutoSize := True;
      Left := ImgStars.Left + ImgStars.Width + Dpi(4);
      Top  := ImgStars.Top; // will be vertically centered by layout
      Anchors := [akLeft, akTop];
    end;

    // --- Fork image ---
    ImgFork := TImage.Create(LvPanel);
    with ImgFork do
    begin
      Name := cForkPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Width := Dpi(17);
      Height := Dpi(16);
      Left := LblStarCount.Left + LblStarCount.Width + Dpi(12);
      Top  := ImgStars.Top;
      Anchors := [akLeft, akTop];
      LoadImageFromResource(ImgFork, 'FORK');
    end;

    // --- Fork count ---
    LblForkCount := TLabel.Create(LvPanel);
    with LblForkCount do
    begin
      Name := cForkCountPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Caption := ARepository.ForkCount.ToString;
      ParentFont := False;
      Font.Name := 'Segoe UI';
      AutoSize := True;
      Left := ImgFork.Left + ImgFork.Width + Dpi(4);
      Top  := ImgFork.Top;
      Anchors := [akLeft, akTop];
    end;

    // --- Issue image ---
    ImgIssue := TImage.Create(LvPanel);
    with ImgIssue do
    begin
      Name := cIssuePrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Width := Dpi(17);
      Height := Dpi(16);
      Left := LblForkCount.Left + LblForkCount.Width + Dpi(12);
      Top  := ImgStars.Top;
      Anchors := [akLeft, akTop];
      LoadImageFromResource(ImgIssue, 'ISSUE');
    end;

    // --- Issue count ---
    LblIssueCount := TLabel.Create(LvPanel);
    with LblIssueCount do
    begin
      Name := cIssueCountPrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Caption := ARepository.IssuCount.ToString;
      ParentFont := False;
      Font.Name := 'Segoe UI';
      AutoSize := True;
      Left := ImgIssue.Left + ImgIssue.Width + Dpi(4);
      Top  := ImgIssue.Top;
      Anchors := [akLeft, akTop];
    end;

    // --- Repository link (clickable) ---
    LinkRepository := TLinkLabelEx.Create(LvPanel);
    with LinkRepository do
    begin
      Name := cLinkLablePrefix + AIndex.ToString;
      Parent := LvPanel;
      AutoSize := False;
      Left := Dpi(7);
      Top  := Dpi(5);
      Width := Dpi(150);   // initial; LayoutRepositoryPanel will expand it to avatar
      Height := Dpi(19);
      ListIndex := AIndex;
      TabOrder := 0;
      ParentColor := False;
      ParentFont := True;
      StyleElements := [seBorder];

      LinkColor    := clMenuHighlight;
      HoverColor   := clHighlight;
      VisitedColor := clGray;

      RegistryKeyName := ARepository.RepoName;
      CloneURL := ARepository.RepoURL + '.git';
      CaptionEx := ARepository.Author.TrimRight(['/']) + '/' + ARepository.RepoName;

      Anchors := [akLeft, akTop, akRight];
      OnClick := LinkLabel_RepositoryLinkClick;
      PopupMenu := PopupMenuRepoPanel;
    end;

    // --- Favorite icon (right-aligned on the stats row) ---
    ImgFavorite := TImage.Create(LvPanel);
    LinkRepository.FavoriteImage := ImgFavorite;
    with ImgFavorite do
    begin
      Name := cFavoritePrefix + AIndex.ToString;
      Parent := LvPanel;
      Transparent := True;
      Width := Dpi(12);
      Height := Dpi(12);
      Left := LvPanel.ClientWidth - Width - Dpi(5); // initial; layout will re-place
      Top  := Dpi(80);
      Anchors := [akTop, akRight];
      LoadImageFromResource(ImgFavorite, 'FAV');
      Visible := IsAlreadyFavorite(LinkRepository);
      ShowHint := True;
      Hint := 'Stored in favorite list.';
    end;

    // --- Avatar (top-right) ---
    ImgAvatar := TImage.Create(LvPanel);
    with ImgAvatar do
    begin
      Name := cAvatarPrefix + AIndex.ToString;
      Parent := LvPanel;
      Cursor := crHandPoint;
      Width  := Dpi(35);
      Height := Dpi(35);
      Stretch := True;
      LoadImageFromURL(ARepository.AvatarUrl);
      Tag := AIndex;
      OnClick := ImgClick;
      Hint := ARepository.Author;
      Anchors := [akTop, akRight];
      Left := LvPanel.ClientWidth - Width - Dpi(5); // initial; layout will set precisely
      Top  := Dpi(3);
    end;

    LayoutRepositoryPanel(LvPanel);
  finally
    ControlList1.Height := ControlList1.Height + LvPanel.Height + 1;
  end;
end;

procedure TMainFrame.LoadImageFromResource(const AImage: TImage; const AResourceName: string);
begin
  AImage.Picture.Bitmap.LoadFromResourceName(HInstance, AResourceName);
  AImage.Stretch := True;
  AImage.Proportional := True;
end;

function TMainFrame.LoadFavorites: Boolean;
var
  LvRegistry: TRegistry;
  LvRepository: TRepository;
  LvTempList: TStringList;
begin
  Result := False;
  LvRegistry := TRegistry.Create;
  try
    LvRegistry.RootKey := HKEY_CURRENT_USER;
    if LvRegistry.OpenKeyReadOnly(cBaseKey) then
    begin
      LvTempList:= TStringList.Create;
      try
        LvRegistry.GetKeyNames(LvTempList);
        LvTempList.Delete(LvTempList.IndexOf('GithubTrendingsSettings'));

        if LvTempList.IsEmpty then
          UpdateUI(True, cFavoriteIsEmpty)
        else
        begin
          FRepositoryList.Clear;

          for var LvRepoName in LvTempList do
          begin
            if LvRepoName.ToLower.Equals(RightStr(cSettingsPath, Length(cSettingsPath) - 1).ToLower) then
              Continue;

            if LvRegistry.OpenKeyReadOnly(cBaseKey + '\' + LvRepoName.Trim) then
            begin
              LvRepository := Default(TRepository);

              LvRepository.RepoName  := LvRegistry.ReadString('RepoName');
              LvRepository.RepoURL   := LvRegistry.ReadString('RepoURL');
              LvRepository.Author    := LvRegistry.ReadString('Author');
              LvRepository.AvatarUrl := LvRegistry.ReadString('AvatarUrl');
              LvRepository.Description := LvRegistry.ReadString('Description');
              LvRepository.Language    := LvRegistry.ReadString('Language');
              LvRepository.StarCount   := LvRegistry.ReadInteger('StarCount');
              LvRepository.ForkCount   := LvRegistry.ReadInteger('ForkCount');
              LvRepository.IssuCount   := LvRegistry.ReadInteger('IssuCount');
              LvRepository.CreatedDate := LvRegistry.ReadDateTime('CreatedDate');

              FRepositoryList.Add(LvRepository);
            end;
            LvRegistry.CloseKey;
          end;
          UpdateUI;
        end;
      finally
        LvRegistry.CloseKey;
        LvTempList.Free;
      end;
    end;
  finally
    LvRegistry.Free;
  end;
end;

{ TStyleNotifier }
procedure TStyleNotifier.ChangedTheme;
var
  LvThemingService: IOTAIDEThemingServices;
begin
  if Assigned(MainFrame) and Supports(BorlandIDEServices, IOTAIDEThemingServices, LvThemingService) then
  begin
    MainFrame.UpdateUI;
    LvThemingService.ApplyTheme(MainFrame);
  end;
end;

procedure TStyleNotifier.ChangingTheme;
begin
// Not used.
end;

end.
