# 使用 GitHub Actions 构建 iOS IPA

ClashMi 上游仓库 (KaringX/clashmi) 通过 `.gitignore` 排除了 4 项构建 iOS 版本必需的内容，
因此 CI 构建前需要先提供它们。本仓库的 `.github/workflows/build-ipa.yml`
会在构建时自动获取这些依赖，然后编译出 IPA。

## 需要提供的 4 项内容

| # | 内容 | 作用 | 引用位置 |
|---|------|------|----------|
| 1 | `libclash-vpn-service` Dart 包 | VPN 服务/内核粘合层（Android VPN、桌面 FFI 等） | `pubspec.yaml` → `dependency_overrides` 要求位于仓库**同级目录** `../libclash-vpn-service` |
| 2 | `board-service` Dart 包 | 机场面板 (v2board/xboard/sspanel) 登录与订阅集成 | 同上，位于 `../board-service` |
| 3 | `Libclash.xcframework` | mihomo 内核预编译框架（iOS 在 PacketTunnel 扩展内通过 FFI 运行内核） | `ios/Runner.xcodeproj` → `../bind/apple/Libclash.xcframework` |
| 4 | `app_url_utils_private.dart` | 官方遥测参数签名 / 订阅"备用下载通道" / 公告推送（**可选**） | `lib/app/private/app_url_utils_private.dart` |

> 第 4 项缺失时会自动使用本仓库的存根 `tools/ci/stubs/app_url_utils_private.dart`：
> 跳过官方遥测参数与订阅中转下载通道，其余功能不受影响。前 3 项必须提供，否则构建直接失败。

## 提供方式 A：deps Release（推荐）

在本仓库创建一个 tag 为 **`deps`** 的 Release（可在 GitHub 网页端 Releases → Draft a new release →
填入 tag 名 `deps`），并上传以下资产（文件名需能被通配匹配）：

```text
libclash-vpn-service.tar.gz        # 打包 ../libclash-vpn-service 目录
board-service.tar.gz               # 打包 ../board-service 目录
Libclash.xcframework.zip           # 打包 bind/apple/Libclash.xcframework 目录
app_url_utils_private.dart         # 可选
```

打包示例（在拥有私有依赖的开发机上）：

```sh
cd clashmi/..
tar -czf libclash-vpn-service.tar.gz libclash-vpn-service
tar -czf board-service.tar.gz board-service
cd clashmi/bind/apple
zip -qry Libclash.xcframework.zip Libclash.xcframework
```

之后手动触发 workflow（Actions → Build iOS IPA → Run workflow）即可，`依赖资产所在的 Release 标签`
保持默认 `deps`。

## 提供方式 B：私有 git 仓库

如果两份私有代码在你自己的私有仓库里，可配置：

| 类型 | 名称 | 内容 |
|------|------|------|
| Variable | `LIBCLASH_VPN_SERVICE_REPO` | 形如 `github.com/<owner>/libclash-vpn-service` |
| Variable | `BOARD_SERVICE_REPO` | 形如 `github.com/<owner>/board-service` |
| Secret | `DEPS_PAT` | 有权读取上述私有仓库的 GitHub PAT（classic，需 `repo` 权限） |

`Libclash.xcframework` 仍需按方式 A 上传到 `deps` Release。

## 签名构建（可选）

默认产出**未签名 IPA**（`--no-codesign`），可使用 AltStore / Sideloadly / TrollStore / 爱思助手等
工具自签安装。若要 CI 内直接签名导出，需在手动触发时选择 `signing = manual`，并配置 Secrets：

| Secret | 说明 |
|--------|------|
| `APPLE_TEAM_ID` | Apple 开发者团队 ID（10 位，在开发者后台 Membership 页可见） |
| `APPLE_P12_BASE64` | 签名证书 p12 的 base64：`base64 -i certificate.p12 \| pbcopy` |
| `APPLE_P12_PASSWORD` | 导出 p12 时设置的密码 |
| `APPLE_PROVISION_PROFILE_BASE64` | 主 App（`com.nebula.clashmi`）的 `.mobileprovision` 的 base64 |
| `APPLE_PROFILE_CLASHMISERVICE_BASE64` | 可选，`com.nebula.clashmi.clashmiService`（PacketTunnel 扩展）的描述文件；缺省复用主描述文件 |
| `APPLE_PROFILE_CLASHMIWIDGET_BASE64` | 可选，`com.nebula.clashmi.clashmiWidget`（小组件）的描述文件；缺省复用主描述文件 |

> 注意：PacketTunnel 扩展需要包含 `packet-tunnel-provider` 权限的描述文件，
> 一个普通 App 描述文件通常无法同时覆盖主 App 和扩展，正式分发建议三类描述文件分别提供。
> VPN 类 App 的 `NetworkExtension` 权限需要向 Apple 申请（开发者后台 → Request Additional Capabilities）。

导出方式（`export_method`）：`ad-hoc` / `app-store` / `development`。

## 触发方式与产物

- **手动**：Actions → Build iOS IPA → Run workflow，可选签名方式、Flutter 版本、依赖 Release 标签。
- **自动**：推送 `v*` 标签时以未签名模式构建，并将 IPA 附加到同名 Release。

产物（Actions → Artifacts）：

- `clashmi-ios-ipa-unsigned` / `clashmi-ios-ipa-manual`：IPA 文件
- `clashmi-ios-dsyms`：符号文件（仅签名构建）

## 与上游同步

workflow、`tools/ci/`、`docs/build-ipa.md` 均为本仓库新增文件，不修改上游代码；
拉取上游更新不会产生冲突。
