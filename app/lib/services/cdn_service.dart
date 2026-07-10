class CdnService {
  final String? customCdnBase;

  CdnService({this.customCdnBase});

  /// 获取文件的 CDN 下载 URL
  String getDownloadUrl({
    required String repoOwner,
    required String repoName,
    required String storagePath,
  }) {
    if (customCdnBase != null && customCdnBase!.isNotEmpty) {
      return '${customCdnBase!.replaceAll(RegExp(r'/$'), '')}/$storagePath';
    }
    // 默认使用 jsDelivr
    return 'https://cdn.jsdelivr.net/gh/$repoOwner/$repoName@main/$storagePath';
  }

  /// 获取 Cloudflare Worker 的 URL（如果配置了自定义域名）
  String getCloudflareUrl({
    required String workerHost,
    required String storagePath,
  }) {
    return 'https://$workerHost/$storagePath';
  }

  /// 判断是否使用 jsDelivr
  bool get isUsingJsDelivr => customCdnBase == null || customCdnBase!.isEmpty;
}