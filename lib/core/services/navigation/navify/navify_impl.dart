import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../layers/presentation/theme/colors/custom_colors.dart';
import '../../../../layers/presentation/widgets/custom-button/custom_button.dart';
import '../../../../layers/presentation/widgets/custom-popup/custom_pop_up.dart';
import '../source/navigation_service.dart';

@Singleton(as: NavigationService)
class NavifyImpl implements NavigationService {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  Future<T?>? push<T extends Object?>(Widget page, {Object? arguments}) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }

  @override
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    Object? arguments,
    TO? result,
  }) {
    return navigatorKey.currentState!.pushReplacement<T, TO>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
      result: result,
    );
  }

  @override
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page, {
    RoutePredicate? predicate,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
      predicate ?? (route) => false,
    );
  }

  @override
  void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState!.popUntil(predicate);
  }

  @override
  void popUntilFirst() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  @override
  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  @override
  void showSheet(
    Widget sheet, {
    bool isDismissible = true,
    VoidCallback? onDismiss,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: CustomColors.transparent,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: CustomColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: isDismissible
            ? const .only(
                topLeft: .circular(16),
                topRight: .circular(16),
              )
            : .zero,
      ),
      context: navigatorKey.currentContext!,
      builder: (context) => sheet,
    ).then((_) {
      if (onDismiss != null) {
        onDismiss();
      }
    });
  }

  @override
  void showFullScreenSheet(
    Widget sheet, {
    bool isDismissible = true,
  }) {
    final rootContext = navigatorKey.currentContext!;
    final rootMediaQuery = MediaQuery.of(rootContext);

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      barrierColor: CustomColors.transparent,
      backgroundColor: CustomColors.transparent,
      shape: null,
      builder: (_) {
        return Material(
          color: CustomColors.white,
          child: Padding(
            padding: .only(
              top: rootMediaQuery.padding.top,
            ),
            child: sheet,
          ),
        );
      },
    );
  }

  @override
  void showErrorPopUp({
    required String title,
    String? message,
    Widget? content,
    required String buttonTitle,
    bool willPop = false,
  }) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => CustomPopUp(
        title: title,
        message: message,
        content: content,
        actions: [
          CustomButton(
            label: buttonTitle,
            onPressed: () {
              pop();
              if (willPop) pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Future<void> showPopUp({
    required String title,
    required List<CustomButton> actions,
    String? message,
    Widget? content,
    Color? textColor,
    ActionsDirection actionsDirection = .horizontal,
    bool isDismissible = true,
    String? icon,
    String? image,
  }) {
    return showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: isDismissible,
      builder: (context) => CustomPopUp(
        title: title,
        message: message,
        content: content,
        actions: actions,
        textColor: textColor,
        actionsDirection: actionsDirection,
        icon: icon,
        image: image,
      ),
    );
  }

  @override
  void showSnackbar({required String message, double? bottomMargin}) {
    final scaffoldMessenger = ScaffoldMessenger.of(
      navigatorKey.currentContext!,
    );

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: CustomColors.gray6,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(16),
        ),
        content: Text(message),
        margin: .only(
          bottom: bottomMargin ?? 16.0,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  void showLoader() {
    final context = navigatorKey.currentContext!;
    showDialog(
      useSafeArea: false,
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 5,
          color: CustomColors.white,
        ),
      ),
    );
  }
}
