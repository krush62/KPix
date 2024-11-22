/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kpix/util/helper.dart';
import 'package:version/version.dart';

class UpdateInfoPackage
{
  final String url;
  final Version version;

  const UpdateInfoPackage({
    required this.version,
    required this.url,
  });
}

class GithubLatestReleaseData
{
  final String htmlUrl;
  final String tagName;
  static final String htmlUrlId = "html_url";
  static final String tagNameId = "tag_name";


  const GithubLatestReleaseData({
    required this.htmlUrl,
    required this.tagName,
  });

  factory GithubLatestReleaseData.fromJson(Map<String, dynamic> json)
  {
    if (json.containsKey(htmlUrlId) && json.containsKey(tagNameId))
    {
      return GithubLatestReleaseData(
          htmlUrl: json[htmlUrlId],
          tagName: json[tagNameId]
      );
    }
    else
    {
      throw const FormatException('Invalid JSON format!');
    }
  }

}

class UpdateHelper
{
  static final String _apiLink = "https://api.github.com/repos/krush62/kpix/releases/latest";

  static Future<UpdateInfoPackage?> getLatestVersionInfo() async
  {
    try
    {
      http.Response response = await http.get(Uri.parse(_apiLink));
      if (response.statusCode == 200)
      {
        final GithubLatestReleaseData githubData = GithubLatestReleaseData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        final Version? version = Helper.convertStringToVersion(version: githubData.tagName);
        if (version != null)
        {
          return UpdateInfoPackage(version: version, url: githubData.htmlUrl);
        }
      }
    }
    catch(_){}
    return null;
  }
}