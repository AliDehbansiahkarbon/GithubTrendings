unit WP.GitHub.Helper;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.Net.HttpClientComponent, System.StrUtils,
  System.DateUtils, System.TimeSpan, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Imaging.pngimage, System.Types, Vcl.Dialogs;

const
  FURL = 'https://api.github.com/search/repositories?q=language:%s+created:%s&sort=stars&order=desc&per_page=100&page=1';

type
  TGitHubHelper = class
  private
    class function DateTimeToISO8601(const ADateTime: TDateTime): string;
    class function GetPeriodRange(const APeriod: string): string;
  public
    class function GetTrendingPascalRepositories(const APeriod: string; const ALanguage: string): string;
  end;

  TImaheHelper = class helper for TImage
  public
    procedure LoadImageFromURL(const AImageURL: string);
  end;

implementation

{ TGitHubHelper }
class function TGitHubHelper.DateTimeToISO8601(const ADateTime: TDateTime): string;
var
  TZ: TTimeZone;
  Offset: TTimeSpan;
  Hours, Mins: string;
begin
  // Convert TDateTime to UTC-based ISO 8601 format
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', ADateTime);

  // Get local time zone information
  TZ := TTimeZone.Local;
  Offset := TZ.GetUtcOffset(ADateTime);

  // Check if the time is in UTC
  if Offset = TTimeSpan.Zero then
    Result := Result + 'Z'  // UTC time
  else
  begin
    // Extract hours and minutes from TTimeSpan
    Hours := Format('%.*d', [2, Abs(Offset.Hours)]);  // Hours
    Mins := Format('%.*d', [2, Abs(Offset.Minutes)]); // Minutes

    // Add the time zone offset in ISO 8601 format
    if Offset.TotalHours >= 0 then
      Result := Result + '%2B' + Hours + ':' + Mins
    else
      Result := Result + '-' + Hours + ':' + Mins;
  end;
end;

class function TGitHubHelper.GetPeriodRange(const APeriod: string): string;
var
  FromDate, ToDate: TDateTime;
begin
  ToDate := Now;

  case IndexStr(APeriod, ['daily', 'weekly', 'monthly', 'yearly']) of
    0: FromDate := IncHour(ToDate, -24);  // 24 hours ago
    1: FromDate := IncDay(ToDate, -7);    // 7 days ago
    2: FromDate := IncDay(ToDate, -30);   // 30 days ago
    3: FromDate := IncDay(ToDate, -365);  // 365 days ago
  else
    FromDate := IncHour(ToDate, -24);  // 24 hours ago
  end;

  Result := DateTimeToISO8601(FromDate) + '..' + DateTimeToISO8601(ToDate);
end;

class function TGitHubHelper.GetTrendingPascalRepositories(const APeriod: string; const ALanguage: string): string;
var
  HTTPClient: TNetHTTPClient;
  Response: IHTTPResponse;
  URL: string;
begin
  if IndexStr(APeriod.ToLower, ['daily', 'weekly', 'monthly', 'yearly']) = -1 then
    raise Exception.Create('Invalid PeriodType. Must be "daily", "weekly", "monthly", or "yearly".');

  URL := Format(FURL, [ALanguage, GetPeriodRange(APeriod.ToLower)]);
  HTTPClient := TNetHTTPClient.Create(nil);
  try
    Response := HTTPClient.Get(URL);
    if Response.StatusCode = 200 then
      Result := Response.ContentAsString
    else
      raise Exception.CreateFmt('Error: %d - %s', [Response.StatusCode, Response.StatusText]);
  finally
    HTTPClient.Free;
  end;
end;


{ TImaheHelper }

procedure TImaheHelper.LoadImageFromURL(const AImageURL: string);
var
  HTTPClient: THTTPClient;
begin
  HTTPClient := THTTPClient.Create;
  HTTPClient.BeginGet(
    procedure(const AsyncResult: IAsyncResult)
    var
      Response: IHTTPResponse;
      MemoryStream: TMemoryStream;
    begin
      MemoryStream := TMemoryStream.Create;
      try
        Response := HTTPClient.EndAsyncHTTP(AsyncResult);
        if Response.StatusCode = 200 then
        begin
          MemoryStream.CopyFrom(Response.ContentStream, Response.ContentStream.Size);
          MemoryStream.Position := 0;
          TThread.Synchronize(nil, procedure begin Self.Picture.LoadFromStream(MemoryStream); end);
        end
        else
        begin
          TThread.Synchronize(nil,
          procedure
          begin
            Self.Picture := nil;
            Self.Hint := Format('Failed to load image. Status code: %d', [Response.StatusCode]);
          end);
        end;
      finally
        MemoryStream.Free;
        HTTPClient.Free;
      end;
    end,
    AImageURL
  );
end;
end.
