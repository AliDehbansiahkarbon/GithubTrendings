unit WP.GitHub.View;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, System.JSON, System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  System.Net.HttpClientComponent, WP.GitHub.Helper, System.Threading, Vcl.WinXCtrls, Winapi.ShellAPI,
  Vcl.Themes, ToolsAPI, Vcl.Imaging.jpeg, Vcl.GraphUtil, System.Generics.Defaults,
  System.Math, WP.GitHub.LinkLabelEx, Vcl.Imaging.pngimage, WP.GitHub.Constants;

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
    procedure mniDailyClick(Sender: TObject);
    procedure mniWeeklyClick(Sender: TObject);
    procedure mniMonthlyClick(Sender: TObject);
    procedure mniYearlyClick(Sender: TObject);
    procedure ImgClick(Sender: TObject);
    procedure PanelResize(Sender: TObject);
    procedure mniPascalClick(Sender: TObject);
    procedure mniCClick(Sender: TObject);
    procedure mniSQLClick(Sender: TObject);
  private
    FStylingNotifierIndex: Integer;
    FPeriod: string;
    FLanguage: string;
    FRepositoryList: TList<TRepository>;
    FStyleNotifier: TStyleNotifier;
    procedure RefreshList;
    procedure AddRepository(const AIndex: string; const ARepository: TRepository);
    procedure LinkLabel_RepositoryLinkClick(Sender: TObject);
    procedure UpdateUI;
    procedure ChangePeriod(const AListType: string);
    procedure ChangeLanguage(const ALang: string);
    procedure LoadImageFromResource(const AImage: TImage; const AResourceName: string);
    function TruncateTextToFit(ACanvas: TCanvas; const AText: string; AMaxWidth: Integer): string;
    function FindAvatarImage(APanel: TPanel): TImage;
    procedure AdjustAvatars(AAvatar: TImage);
    procedure MakeImageCircular(AImage: TImage);
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
  AdjustAvatars(FindAvatarImage(TPanel(Sender)));
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
        LvJSONObj.Free;
      end;
    except on E: Exception do
      ShowMessage('Error: ' + E.Message);
    end;
  finally
    TThread.Synchronize(TThread.Current, procedure begin UpdateUI; end);
  end;
end;

procedure TMainFrame.UpdateUI;
var
  I: Integer;
begin
  ActivityIndicator1.StopAnimation;
  ActivityIndicator1.Visible := False;

  // Ascending sort by Star Count
  FRepositoryList.Sort(TComparer<TRepository>.Construct(
  function(const Left, Right: TRepository): Integer
  begin
    Result := Left.StarCount - Right.StarCount;
  end));

  if FRepositoryList.Count > 0 then
  begin
    ClearScrollBox;
    for I := 0 to Pred(FRepositoryList.Count) do
      TThread.Synchronize(TThread.Current, procedure begin AddRepository(I.ToString, FRepositoryList.Items[I]) end);
  end;
end;

procedure TMainFrame.AdjustAvatars(AAvatar: TImage);
begin
  if Assigned(AAvatar) then
  begin
    TThread.Synchronize(TThread.Current,
    procedure
    begin
      AAvatar.Left := ScrollBox.Width - AAvatar.Width - 20;
      AAvatar.Top := 3;
    end);
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
    if ScrollBox.Components[I] is TPanel then
      ScrollBox.Components[I].Free;
  end;

  for I := Pred(ScrollBox.ControlCount) downto 0 do
  begin
    if ScrollBox.Controls[I] is TPanel then
      ScrollBox.Controls[I].Free;
  end;

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

procedure TMainFrame.AddRepository(const AIndex: string; const ARepository: TRepository);
var
  LvPanel: TPanel;
begin
  LvPanel := TPanel.Create(Self);
  LvPanel.Name := cPanelPrefix + AIndex;
  LvPanel.Caption := EmptyStr;
  LvPanel.Parent := ScrollBox;
  LvPanel.Align := alTop;
  LvPanel.Height := 83;
  LvPanel.Width := 360;
  LvPanel.ParentColor := True;
  LvPanel.OnResize := PanelResize;

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
    Caption := 'Created at ' + FormatDateTime('ddd MMM dd yyyy', ARepository.CreatedDate);
    Font.Charset := DEFAULT_CHARSET;
    Font.Color := clScrollBar;
    Font.Height := -9;
    Font.Name := 'Segoe UI';
    Font.Style := [];
    ParentFont := False;
  end;

  var lbl_Description := TLabel.Create(LvPanel);
  with lbl_Description do
  begin
    Parent := LvPanel;
    Transparent := True;
    Name := cDescriptionLabelPrefix + AIndex;
    Left := 7;
    Top := 45;
    Width := 78;
    Height := 15;
    Caption := TruncateTextToFit(lbl_Description.Canvas, ARepository.Description, LvPanel.Width - 10);
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
    Top := 60;
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
    Top := 62;
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
    Top := 60;
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
    Top := 62;
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
    Top := 60;
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
    Top := 62;
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
    Parent := LvPanel;
    Name := cLinkLablePrefix + AIndex;
    Left := 7;
    Top := 5;
    Width := 204;
    Height := 19;
    Tag := AIndex.ToInteger;
    Caption := ARepository.Author + '/' + ARepository.RepoName;
    TabOrder := 0;
    ParentColor := False;
    ParentFont := False;
    StyleElements := [seBorder];

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
  MakeImageCircular(Img_Avatar);
  AdjustAvatars(Img_Avatar);
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
    LvThemingService.ApplyTheme(MainFrame);
end;

procedure TStyleNotifier.ChangingTheme;
begin
// Not used.
end;

procedure TMainFrame.MakeImageCircular(AImage: TImage);
var
  Radius, Diameter: Integer;
  Rect: TRect;
  Bitmap, SourceBitmap: TBitmap;
  Png: TPngImage;
begin
  // Ensure the image is square for a perfect circle.
  Radius := Min(AImage.Width, AImage.Height) div 2;
  Diameter := Radius * 2;
  Rect := TRect.Create(0, 0, Diameter, Diameter);

  // Create a new bitmap with a transparent background
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(Diameter, Diameter);
    Bitmap.PixelFormat := pf32bit;

    // Check if the source image is a TBitmap or TPngImage
    if AImage.Picture.Graphic is TBitmap then
      SourceBitmap := TBitmap(AImage.Picture.Graphic)
    else
    begin
      // If it's not a bitmap, convert the source image to a TBitmap
      SourceBitmap := TBitmap.Create;
      try
        SourceBitmap.Assign(AImage.Picture.Graphic);
      except
        SourceBitmap.Free;
        raise Exception.Create('Could not convert image to TBitmap.');
      end;
    end;

    // Draw a circular clipping area and copy the image within it
    Bitmap.Canvas.Brush.Color := clNone;
    Bitmap.Canvas.FillRect(Rect);
    Bitmap.Canvas.Ellipse(0, 0, Diameter, Diameter);
    Bitmap.Canvas.CopyRect(Rect, SourceBitmap.Canvas, Rect);

    // Convert the circular Bitmap to a PNG with transparency
    Png := TPngImage.Create;
    try
      Png.Assign(Bitmap);
      AImage.Picture.Assign(Png);
    finally
      Png.Free;
    end;

    // Free the SourceBitmap if we created it ourselves
    if SourceBitmap <> TBitmap(AImage.Picture.Graphic) then
      SourceBitmap.Free;
  finally
    Bitmap.Free;
  end;
end;


end.
