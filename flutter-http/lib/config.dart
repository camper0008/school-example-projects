class Config {
  final String apiUrl;
  Config({required String apiUrl})
      : apiUrl = apiUrl.endsWith("/")
            ? apiUrl.substring(0, apiUrl.length - 1)
            : apiUrl;
}
