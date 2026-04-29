enum Flavor { dev, staging, prod }

extension FlavorX on Flavor {
  String get title => switch (this) {
        Flavor.dev => 'Healthy Hour (DEV)',
        Flavor.staging => 'Healthy Hour (STG)',
        Flavor.prod => 'Healthy Hour',
      };
}
