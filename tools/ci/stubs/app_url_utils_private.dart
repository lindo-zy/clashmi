// CI 构建存根 —— 仅在 GitHub Actions 构建且未提供私有文件时,
// 由 .github/workflows/build-ipa.yml 复制到 lib/app/private/app_url_utils_private.dart。
//
// 该文件在上游仓库中被 .gitignore 排除(私有实现), 负责遥测参数签名与
// "订阅中转下载通道"/机场面板公告推送等服务端接口。
// 本存根将其实现为空操作:
//   - 更新检查 URL 不再附加签名的遥测参数 (隐私上更保守)
//   - 订阅"备用下载通道"指向本地无效地址, 请求即失败,
//     订阅更新回退为仅直连下载, 其余功能不受影响
// 若你拥有真实文件, 请上传到 deps Release (见 docs/build-ipa.md)。

import 'package:tuple/tuple.dart';

abstract final class AppUrlUtilsPrivate {
  static String signQueryParams(
    String version,
    String bodyLen,
    Map<String, dynamic> extra,
  ) {
    return '';
  }

  static String signQueryParams2(
    String version,
    Map<String, dynamic> params, {
    String bodyLen = "0",
  }) {
    return params.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}

class ProfileProxyProviderPrivate {
  static const String _stubUrl = 'http://127.0.0.1/clashmi-ci-stub';

  static Tuple3<String, String, String> getProviderProxyUrlAndBody({
    required String app,
    required String version,
    required String did,
    required String boardProviderId,
    required String url,
    required String userAgent,
    required Map<String, String> xhwidHeaders,
  }) {
    return const Tuple3(_stubUrl, '', '{}');
  }
}

class BoardProviderPrivate {
  static const String _stubUrl = 'http://127.0.0.1/clashmi-ci-stub';

  static Tuple3<String, String, String> getBycodeUrlAndBody({
    required String app,
    required String version,
    required String did,
    required String code,
  }) {
    return const Tuple3(_stubUrl, '', '{}');
  }

  static Tuple3<String, String, String> getNotifyIntegrationUrlAndBody({
    required String app,
    required String version,
    required String did,
    required String url,
    required String type,
  }) {
    return const Tuple3(_stubUrl, '', '{}');
  }

  static Tuple3<String, String, String> getNoticePushUrlAndBody({
    required String app,
    required String version,
    required String did,
    required String pid,
  }) {
    return const Tuple3(_stubUrl, '', '{}');
  }
}
