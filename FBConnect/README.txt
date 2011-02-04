Modifications to vanilla FBConnect:
- Fix compiler warnings.
- Use more recent version of SBJson.
- Renamed file close.png to fbclose.png.
- Moved files fbicon.png and fbclose.png to main bundle.
- Inserted [[NetworkActivity sharedInstance] logURL:[NSURL URLWithString:url]] into Facebook.m's openURL method.
