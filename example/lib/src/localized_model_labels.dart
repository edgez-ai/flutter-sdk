import '../l10n/app_localizations.dart';
import 'models.dart';

extension LocalizedDashboardWidget on ExampleDashboardWidget {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ExampleDashboardWidget.tempHumidity => l10n.tempHumidity,
        ExampleDashboardWidget.latestValue => l10n.latestValue,
        ExampleDashboardWidget.imuOrientation => l10n.imuOrientation,
        ExampleDashboardWidget.binaryData => l10n.binaryData,
        ExampleDashboardWidget.timeSeries => l10n.timeSeries,
      };
}

extension LocalizedDashboardRange on ExampleDashboardRange {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ExampleDashboardRange.latest => l10n.latestValue,
        ExampleDashboardRange.last30Minutes => l10n.last30Minutes,
        ExampleDashboardRange.lastHour => l10n.lastHour,
        ExampleDashboardRange.last6Hours => l10n.last6Hours,
      };
}

extension LocalizedDeviceType on ExampleDeviceType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ExampleDeviceType.unspecified => l10n.unspecified,
        ExampleDeviceType.user => l10n.user,
        ExampleDeviceType.gateway => l10n.gatewayType,
        ExampleDeviceType.beacon => l10n.beacon,
        ExampleDeviceType.sensor => l10n.sensor,
        ExampleDeviceType.relay => l10n.relay,
      };
}

extension LocalizedMarker on ExampleMarker {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ExampleMarker.blue => l10n.blue,
        ExampleMarker.red => l10n.red,
        ExampleMarker.green => l10n.green,
        ExampleMarker.orange => l10n.orange,
        ExampleMarker.purple => l10n.purple,
        ExampleMarker.teal => l10n.teal,
        ExampleMarker.gray => l10n.gray,
      };
}
