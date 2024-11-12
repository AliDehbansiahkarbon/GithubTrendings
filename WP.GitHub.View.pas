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
    SpeedButton1: TSpeedButton;
    btnSetting: TSpeedButton;
    btnFavorite: TSpeedButton;
    chk_TopTen: TCheckBox;
    mniGitCloneOpenProject: TMenuItem;
    ilTitleFrame: TVirtualImageList;
    ImageCollection1: TImageCollection;
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
    procedure SpeedButton1Click(Sender: TObject);
    procedure btnFavoriteClick(Sender: TObject);
    procedure mniGitCloneOpenProjectClick(Sender: TObject);
  private
    FStylingNotifierIndex: Integer;
    FPeriod: string;
    FLanguage: string;
    FRepositoryList: TList<TRepository>;
    FStyleNotifier: TStyleNotifier;
    LastClickedLinkLabelEx: TLinkLabelEx;
    FavoriteListLoaded: Boolean;
    procedure RefreshList;
    procedure AddRepository(const AIndex: Integer; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
    procedure LinkLabel_RepositoryLinkClick(Sender: TObject);
    procedure UpdateUI(AIsEmpty: Boolean = False; AMsg: string = '');
    procedure ChangePeriod(const AListType: string);
    procedure ChangeLanguage(const ALang: string);
    procedure LoadImageFromResource(const AImage: TImage; const AResourceName: string);
    function TruncateTextToFit(ACanvas: TCanvas; const AText: string; AMaxWidth: Integer): string;
    function FindAvatarImage(APanel: TPanel): TImage;
    procedure AdjustAvatars(AAvatar: TImage);
    procedure AdjustRepoLink(ALink: TLinkLabelEx; AAvatar: TImage);
    function FindRepoLink(APanel: TPanel): TLinkLabelEx;
    procedure SaveToFavorites(AIndex: Integer);
    procedure RemoveFromFavorites(AIndex: Integer);
    function LoadFavorites: Boolean;
    function IsAlreadyFavorite(ALinkLabel: TLinkLabelEx): Boolean;
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
  var Avatar := FindAvatarImage(TPanel(Sender));
  AdjustAvatars(Avatar);
  AdjustRepoLink(FindRepoLink(TPanel(Sender)), Avatar);
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
  I: Integer;
begin
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
            LvRepoCount := Min(9 , LvRepositories.Count - 1)
          else
            LvRepoCount := Min(99, LvRepositories.Count - 1);
            
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
    TThread.Synchronize(TThread.Current, procedure begin UpdateUI; end);
  end;
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
    var LvEmptyLabel := TLabel.Create(Self);
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
    for I := 0 to Pred(FRepositoryList.Count) do
      AddRepository(I, FRepositoryList.Items[I], LvThemingEnabled, LvNewColor);
  end;
end;

procedure TMainFrame.AdjustAvatars(AAvatar: TImage);
begin
  if Assigned(AAvatar) then
  begin
    TThread.Synchronize(TThread.Current,
    procedure
    begin
      AAvatar.Left := ControlList1.Width - AAvatar.Width - 5;
      AAvatar.Top := 3;
    end);
  end;
end;

procedure TMainFrame.AdjustRepoLink(ALink: TLinkLabelEx; AAvatar: TImage);
begin
  if Assigned(ALink) and Assigned(AAvatar) then
  begin
    var Bnd := ALink.BoundsRect;
    Bnd.Right := AAvatar.Left - 10;
    ALink.BoundsRect := Bnd;
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
    if (Self.Components[I] is TLabel) and (TLabel(Self.Components[I]).Name = 'emptylabel') then
      Self.Components[I].Free;

    if ScrollBox.Components[I] is TPanel then
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

function TMainFrame.FindAvatarImage(APanel: TPanel): TImage;
begin
  Result := nil;
  for var I := 0 to Pred(APanel.ControlCount) do
  begin
    if APanel.Controls[I] is TImage then
    begin
      var LvImg := TImage(APanel.Controls[I]);
      var LvImgname: string := LvImg.Name;
      if LvImgname.Equals(cAvatarPrefix + LvImg.Tag.ToString) then
        Result := LvImg;
    end;
  end;
end;

function TMainFrame.FindRepoLink(APanel: TPanel): TLinkLabelEx;
begin
  Result := nil;
  for var I := 0 to Pred(APanel.ControlCount) do
  begin
    if APanel.Controls[I] is TLinkLabelEx then
    begin
      var LvImg := TLinkLabelEx(APanel.Controls[I]);
      Result := LvImg;
    end;
  end;
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

procedure TMainFrame.SpeedButton1Click(Sender: TObject);
begin
  RefreshList;
end;

function TMainFrame.TruncateTextToFit(ACanvas: TCanvas; const AText: string; AMaxWidth: Integer): string;
var
  ShortText: string;
  CharIndex: Integer;
begin
  ShortText := AText;

  if ShortText.IsEmpty then
    Exit(cNoDescription);

  if ACanvas.TextWidth(ShortText) <= AMaxWidth then
    Exit(ShortText);

  ShortText := ShortText + '...';
  for CharIndex := Length(AText) downto 1 do
  begin
    ShortText := Copy(AText, 1, CharIndex) + '...';
    if ACanvas.TextWidth(ShortText) <= AMaxWidth then
      Exit(ShortText);
  end;

  Result := cNoDescription;
end;

procedure TMainFrame.AddRepository(const AIndex: Integer; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
var
  LvPanel: TPanel;
  LvIsSmallTextWith: Boolean;
begin
  LvPanel := TPanel.Create(Self);
  LvPanel.Name := cPanelPrefix + AIndex.ToString;
  LvPanel.Caption := EmptyStr;
  LvPanel.Parent := ControlList1;
  LvPanel.Align := alTop;
  LvPanel.Height := 88;
  LvPanel.OnResize := PanelResize;
  LvPanel.BevelEdges := [];
  LvPanel.BevelKind := TBevelKind.bkNone;
  LvPanel.BevelOuter := TBevelCut.bvNone;

  if AThemingEnabled then
  begin
    LvPanel.StyleElements := LvPanel.StyleElements - [seClient];
    LvPanel.ParentBackground := False;
    LvPanel.Color := AColor;
  end;

  LvPanel.BorderStyle := bsNone;
  ControlList1.Height := ControlList1.Height + LvPanel.Height;

  var lbl_Date := TLabel.Create(LvPanel);
  with lbl_Date do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cDateLabelPrefix + AIndex.ToString;
    Left := 7;
    Top := 24;
    Width := 42;
    Height := 12;
    Caption := 'Created at ' + FormatDateTime('dd.mm.yyyy', ARepository.CreatedDate);
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clScrollBar;
    Font.Height := -11;
    Font.Name := 'Segoe UI';
    Font.Style := [];
    ParentFont := False;
  end;

  var lbl_Description := TLabel.Create(LvPanel);
  with lbl_Description do
  begin
    Parent := LvPanel;
    AutoSize := False;
    Transparent := True;
    Name := cDescriptionLabelPrefix + AIndex.ToString;
    Left := 7;
    Top := 42;
    Width := ControlList1.Width - 1;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
    begin
      LvIsSmallTextWith := True;
      Height := 30
    end
    else
    begin
      LvIsSmallTextWith := False;
      Height := 40;
    end;
    WordWrap := True;
    Caption := TruncateTextToFit(lbl_Description.Canvas, ARepository.Description, (LvPanel.Width * 2) - 36);
    Hint := ARepository.Description;
    ShowHint := True;
  end;

  var Img_Stars := TImage.Create(LvPanel);
  with Img_Stars do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cStarsPrefix + AIndex.ToString;
    Left := 7;
    if LvIsSmallTextWith then
      Top := 60
    else
      Top := 70;

    Width := 16;
    Height := 16;
    LoadImageFromResource(Img_Stars, 'STAR');
  end;

  var lbl_StarCount := TLabel.Create(LvPanel);
  with lbl_StarCount do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cStarCountPrefix + AIndex.ToString;
    Left := Img_Stars.Left + Img_Stars.Width + 2;
    if LvIsSmallTextWith then
      Top := 62
    else
      Top := 72;

    Width := 5;
    Height := 12;
    Caption := ARepository.StarCount.ToString;
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clWindowText;
    Font.Height := -9;
    Font.Name := 'Segoe UI';
    Font.Style := [];
    ParentFont := False;
  end;

  var Img_Fork := TImage.Create(LvPanel);
  with Img_Fork do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cForkPrefix + AIndex.ToString;
    Left := lbl_StarCount.Left + lbl_StarCount.Width + 10;
    if LvIsSmallTextWith then
      Top := 60
    else
      Top := 70;

    Width := 17;
    Height := 16;
    LoadImageFromResource(Img_Fork, 'FORK');
  end;

  var lbl_ForkCount := TLabel.Create(LvPanel);
  with lbl_ForkCount do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cForkCountPrefix + AIndex.ToString;
    Left := Img_Fork.Left + Img_Fork.Width + 2;
    if LvIsSmallTextWith then
      Top := 62
    else
      Top := 72;

    Width := 5;
    Height := 12;
    Caption := ARepository.ForkCount.ToString;
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clWindowText;
    Font.Height := -9;
    Font.Name := 'Segoe UI';
    Font.Style := [];
    ParentFont := False;
  end;

  var Img_Issue := TImage.Create(LvPanel);
  with Img_Issue do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cIssuePrefix + AIndex.ToString;
    Left := lbl_ForkCount.Left + lbl_ForkCount.Width + 10;
    if LvIsSmallTextWith then
      Top := 60
    else
      Top := 70;

    Width := 17;
    Height := 16;
    LoadImageFromResource(Img_Issue, 'ISSUE');
  end;

  var lbl_IssuCount := TLabel.Create(LvPanel);
  with lbl_IssuCount do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cIssueCountPrefix + AIndex.ToString;
    Left := Img_Issue.Left + Img_Issue.Width + 2;
    if LvIsSmallTextWith then
      Top := 62
    else
      Top := 72;

    Width := 5;
    Height := 12;
    Caption := ARepository.IssuCount.ToString;
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clWindowText;
    Font.Height := -9;
    Font.Name := 'Segoe UI';
    Font.Style := [];
    ParentFont := False;
  end;

  var LinkLabel_RepositoryLink := TLinkLabelEx.Create(LvPanel);
  with LinkLabel_RepositoryLink do
  begin
    AutoSize := False;
    Parent := LvPanel;
    Name := cLinkLablePrefix + AIndex.ToString;
    Left := 7;
    Top := 5;
    Width := 150;
    Height := 19;
    ListIndex := AIndex;
    TabOrder := 0;
    ParentColor := False;
    ParentFont := False;
    StyleElements := [seBorder];
    Font.Charset := DEFAULT_CHARSET;
    Font.Height := -14;
    Font.Name := 'Segoe UI';
    Font.Style := [];

    LinkColor := clMenuHighlight;
    HoverColor := clHighlight;
    VisitedColor := clGray;

    RegistryKeyName := ARepository.RepoName;
    CloneURL := ARepository.RepoURL + '.git';
    CaptionEx := ARepository.Author + '/' + ARepository.RepoName;

    OnClick := LinkLabel_RepositoryLinkClick;
    PopupMenu := PopupMenuRepoPanel;
  end;

  var Img_Faveorite := TImage.Create(LvPanel);
  LinkLabel_RepositoryLink.FavoriteImage := Img_Faveorite;
  with Img_Faveorite do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cFavoritePrefix + AIndex.ToString;
    //Left := lbl_IssuCount.Left + lbl_IssuCount.Width + 10;
    Left :=  LvPanel.Width - 15;
    if LvIsSmallTextWith then
      Top := 60
    else
      Top := 70;

    Width := 12;
    Height := 12;
    LoadImageFromResource(Img_Faveorite, 'FAV');
    Visible := IsAlreadyFavorite(LinkLabel_RepositoryLink);
    ShowHint := True;
    Hint := 'Stored in favorite list.';
  end;

  var Img_Avatar := TImage.Create(Self);
  with Img_Avatar do
  begin
    Parent := LvPanel;
    Name := cAvatarPrefix + AIndex.ToString;
    Cursor := crHandPoint;
    Height := 35;
    Width := 35;
    Stretch := True;
    LoadImageFromURL(ARepository.AvatarUrl);
    Tag := AIndex;
    OnClick := ImgClick;
    Hint := ARepository.Author;
  end;

  AdjustAvatars(Img_Avatar);
  AdjustRepoLink(LinkLabel_RepositoryLink, Img_Avatar);
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

        if LvTempList.IsEmpty then
          UpdateUI(True, 'Favorite list is empty.')
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

              LvRepository.RepoName := LvRegistry.ReadString('RepoName');
              LvRepository.RepoURL := LvRegistry.ReadString('RepoURL');
              LvRepository.Author := LvRegistry.ReadString('Author');
              LvRepository.AvatarUrl := LvRegistry.ReadString('AvatarUrl');
              LvRepository.Description := LvRegistry.ReadString('Description');
              LvRepository.Language := LvRegistry.ReadString('Language');
              LvRepository.StarCount := LvRegistry.ReadInteger('StarCount');
              LvRepository.ForkCount := LvRegistry.ReadInteger('ForkCount');
              LvRepository.IssuCount := LvRegistry.ReadInteger('IssuCount');
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
