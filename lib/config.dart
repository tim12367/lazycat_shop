class Config {
  String getLazyCatBaseUrl() {
    return const String.fromEnvironment("lazy.cat.shop.baseurl");
  }
}
