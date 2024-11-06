unit WP.GitHub.View;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, System.JSON, System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  System.Net.HttpClientComponent, WP.GitHub.Helper, System.Threading, Vcl.WinXCtrls, Winapi.ShellAPI,
  Vcl.Themes, ToolsAPI, Vcl.Imaging.jpeg, Vcl.GraphUtil, System.Generics.Defaults,
  System.Math, WP.GitHub.LinkLabelEx, Vcl.Imaging.pngimage, WP.GitHub.Constants,
  Vcl.ControlList;

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
    chk_TopTen: TCheckBox;
    ControlList1: TControlList;
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
  private
    FStylingNotifierIndex: Integer;
    FPeriod: string;
    FLanguage: string;
    FRepositoryList: TList<TRepository>;
    FStyleNotifier: TStyleNotifier;
    procedure RefreshList;
    procedure AddRepository(const AIndex: string; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
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
            LvRepoCount := 10
          else
            LvRepoCount := Min(100, LvRepositories.Count - 1);
          lbl_RepoCount.Caption := '(Count: ' + LvRepoCount.ToString + ')';
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
      AddRepository(I.ToString, FRepositoryList.Items[I], LvThemingEnabled, LvNewColor);
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
    if (Self.Components[I] is TPanel) and (TPanel(Self.Components[I]).Name <> 'pnlBottom') then
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
  RefreshList;
end;

destructor TMainFrame.Destroy;
begin
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

procedure TMainFrame.LinkLabel_RepositoryLinkClick(Sender: TObject);
begin
  if FRepositoryList.Count > 0 then
  begin
    var Url: string;
    Url := cGitHubURL +'/' + FRepositoryList.Items[TLinkLabel(Sender).Tag].Author + '/' +  FRepositoryList.Items[TLinkLabel(Sender).Tag].RepoName;
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

procedure TMainFrame.RefreshList;
begin
  TTask.Run(procedure begin PullRepoList; end);
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

procedure TMainFrame.AddRepository(const AIndex: string; const ARepository: TRepository; AThemingEnabled: Boolean; AColor: TColor);
var
  LvPanel: TPanel;
begin
  LvPanel := TPanel.Create(Self);
  LvPanel.Name := cPanelPrefix + AIndex;
  LvPanel.Caption := EmptyStr;
  LvPanel.Parent := ControlList1;
  LvPanel.Align := alTop;
  LvPanel.Height := 85;
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
    Name := cDateLabelPrefix + AIndex;
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
    Name := cDescriptionLabelPrefix + AIndex;
    Left := 7;
    Top := 42;
    Width := ControlList1.Width - 1;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
      Height := 30
    else
      Height := 40;
    WordWrap := True;
    Caption := TruncateTextToFit(lbl_Description.Canvas, ARepository.Description, (LvPanel.Width * 2) - 20);
    Hint := ARepository.Description;
    ShowHint := True;
  end;

  var Img_Stars := TImage.Create(LvPanel);
  with Img_Stars do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cStarsPrefix + AIndex;
    Left := 7;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cStarCountPrefix + AIndex;
    Left := Img_Stars.Left + Img_Stars.Width + 2;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cForkPrefix + AIndex;
    Left := lbl_StarCount.Left + lbl_StarCount.Width + 10;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cForkCountPrefix + AIndex;
    Left := Img_Fork.Left + Img_Fork.Width + 2;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cIssuePrefix + AIndex;
    Left := lbl_ForkCount.Left + lbl_ForkCount.Width + 10;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cIssueCountPrefix + AIndex;
    Left := Img_Issue.Left + Img_Issue.Width + 2;
    if lbl_Description.Canvas.TextWidth(ARepository.Description) <= ControlList1.Width then
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
    Name := cLinkLablePrefix + AIndex;
    Left := 7;
    Top := 5;
    Width := 150;
    Height := 19;
    Tag := AIndex.ToInteger;
    CaptionEx := ARepository.Author + '/' + ARepository.RepoName;
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
    OnClick := LinkLabel_RepositoryLinkClick;
  end;

  var Img_Avatar := TImage.Create(Self);
  with Img_Avatar do
  begin
    Parent := LvPanel;
    Name := cAvatarPrefix + AIndex;
    Cursor := crHandPoint;
    Height := 35;
    Width := 35;
    Stretch := True;
    LoadImageFromURL(ARepository.AvatarUrl);
    Tag := AIndex.ToInteger;
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
