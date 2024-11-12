unit WP.GitHub.Constants;

interface

const
  cPluginID = 'WP.GitHubTrendingPlugin';
  cPascal = 'Pascal';
  cC = 'C/C++';
  cSQL = 'SQL';
  cDaily = 'Daily';
  cWeekly = 'Weekly';
  cMonthly = 'Monthly';
  cYearly = 'Yearly';

  cPanelPrefix = 'panel_';
  cDateLabelPrefix = 'lbl_Date_';
  cDescriptionLabelPrefix = 'lbl_Description_';
  cStarsPrefix = 'Img_Start_';
  cStarCountPrefix = 'lbl_StarCount_';
  cForkPrefix = 'Img_Fork_';
  cAvatarPrefix = 'Img_Avatar_';
  cForkCountPrefix = 'lbl_ForkCount_';
  cIssuePrefix = 'Img_Issue_';
  cIssueCountPrefix = 'lbl_IssueCount_';
  cLinkLablePrefix = 'LinkLabel_RepositoryLink_';
  cFavoritePrefix = 'Img_Favorite_';
  cNoDescription = 'No description, website, or topics provided.';

  cGitHubURL = 'https://github.com';
  cURL = 'https://api.github.com/search/repositories?q=language:%s+created:%s&sort=stars&order=desc&per_page=101&page=1';
  cBaseKey = '\Software\GithubTrendingsPlugin';
  cSettingsPath = '\GithubTrendingsSettings';

resourcestring
  cPluginName = 'GitHub Trending Repositories';

implementation

end.
