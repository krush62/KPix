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

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kpix/util/helpers/update_helper.dart';

Future<UpdateInfoPackage?> _latestWith({required final Future<http.Response> Function(http.Request request) answer})
{
  return http.runWithClient(getLatestVersionInfo, () => MockClient(answer));
}

Future<UpdateInfoPackage?> _latestFrom({required final String body, final int status = 200})
{
  return _latestWith(answer: (final http.Request request) async => http.Response(body, status));
}

void main()
{
  group("the latest release", ()
  {
    test("is asked for at GitHub", () async
    {
      Uri? asked;
      await _latestWith(answer: (final http.Request request) async
      {
        asked = request.url;
        return http.Response("{}", 200);
      },);

      expect(asked.toString(), "https://api.github.com/repos/krush62/kpix/releases/latest");
    });

    test("gives the version and where to get it", () async
    {
      final UpdateInfoPackage? info = await _latestFrom(body: '{"html_url": "https://example.com/release", "tag_name": "v1.2.3", "name": "ignored"}');

      expect(info, isNotNull);
      expect(info!.url, "https://example.com/release");
      expect(info.version.major, 1);
      expect(info.version.minor, 2);
      expect(info.version.patch, 3);
    });

    for (final (String, String, int) failure in <(String, String, int)>[
      ("an error from the server", '{"html_url": "https://example.com", "tag_name": "v1.2.3"}', 404),
      ("a rate limit", '{"message": "API rate limit exceeded"}', 403),
      ("something that is not JSON", "<html></html>", 200),
      ("JSON that is not an object", "[]", 200),
      ("no url", '{"tag_name": "v1.2.3"}', 200),
      ("no tag", '{"html_url": "https://example.com"}', 200),
      ("a tag that is no version", '{"html_url": "https://example.com", "tag_name": "nightly"}', 200),
    ])
    {
      test("is unknown after ${failure.$1}", () async
      {
        expect(await _latestFrom(body: failure.$2, status: failure.$3), isNull);
      });
    }

    test("is unknown without a connection", () async
    {
      expect(await _latestWith(answer: (final http.Request request) async => throw http.ClientException("no network")), isNull);
    });
  });

  group("the release data", ()
  {
    test("insists on its fields", ()
    {
      expect(() => GithubLatestReleaseData.fromJson(<String, dynamic>{GithubLatestReleaseData.htmlUrlId: "a"}), throwsFormatException);
      expect(() => GithubLatestReleaseData.fromJson(<String, dynamic>{GithubLatestReleaseData.tagNameId: "b"}), throwsFormatException);
    });

    test("takes what it finds", ()
    {
      final GithubLatestReleaseData data = GithubLatestReleaseData.fromJson(<String, dynamic>{GithubLatestReleaseData.htmlUrlId: "a", GithubLatestReleaseData.tagNameId: "b"});

      expect(data.htmlUrl, "a");
      expect(data.tagName, "b");
    });
  });
}
