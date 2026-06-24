import 'package:flutter/foundation.dart';

class AccountService extends ChangeNotifier {
  bool emailNotifications = true;
  bool dashboardAlerts = true;
  bool weeklySummary = false;

  void setEmailNotifications(bool value) {
    emailNotifications = value;
    notifyListeners();
  }

  void setDashboardAlerts(bool value) {
    dashboardAlerts = value;
    notifyListeners();
  }

  void setWeeklySummary(bool value) {
    weeklySummary = value;
    notifyListeners();
  }
}
