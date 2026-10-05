import 'package:flutter/material.dart';

import '../../../../layers/presentation/widgets/custom-button/custom_button.dart';
import '../../../../layers/presentation/widgets/custom-popup/custom_pop_up.dart';

abstract interface class NavigationService {
  GlobalKey<NavigatorState> get navigatorKey;
  Future<T?>? push<T extends Object?>(Widget page, {Object? arguments});
  void pop<T extends Object?>([T? result]);
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    Object? arguments,
    TO? result,
  });
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page, {
    RoutePredicate? predicate,
    Object? arguments,
  });
  void popUntil(RoutePredicate predicate);
  void popUntilFirst();
  bool canPop();
  void showSheet(
    Widget sheet, {
    bool isDismissible = true,
    VoidCallback? onDismiss,
  });
  void showFullScreenSheet(Widget sheet, {bool isDismissible = true});

  void showErrorPopUp({
    required String title,
    String? message,
    Widget? content,
    required String buttonTitle,
    bool willPop = false,
  });
  Future<void> showPopUp({
    required String title,
    String? message,
    Widget? content,
    required List<CustomButton> actions,
    Color? textColor,
    bool isDismissible = true,
    ActionsDirection actionsDirection = .horizontal,
    String? icon,
    String? image,
  });

  void showSnackbar({required String message, double? bottomMargin});

  void showLoader();
}
