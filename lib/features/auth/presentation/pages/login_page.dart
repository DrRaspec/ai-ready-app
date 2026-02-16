import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/core/routers/route_names.dart';
import 'package:ai_chat_bot/core/widgets/app_text_field.dart';
import 'package:ai_chat_bot/features/auth/data/login_request_data.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_kit/flutter_adaptive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _kAnimDuration = Duration(milliseconds: 260);
  static final _kEmailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeOffset =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -14), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -14, end: 14), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 14, end: -10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 2),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
        setState(() {
          _autovalidateMode = AutovalidateMode.onUserInteraction;
        });
      }
      _shakeController.forward(from: 0);
      HapticFeedback.mediumImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    final loginData = LoginRequestData(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    context.read<AuthBloc>().add(
      LoginFormSubmitted(loginRequestData: loginData),
    );
  }

  Widget _buildHeaderSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading, {
    required bool isWideLayout,
    required bool centerContent,
  }) {
    final alignStart = isWideLayout && !centerContent;
    final textAlign = alignStart ? TextAlign.left : TextAlign.center;
    final crossAxis = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        if (alignStart) const SizedBox(height: 20),
        Align(
          alignment: alignStart ? Alignment.centerLeft : Alignment.center,
          child: AnimatedScale(
            duration: _kAnimDuration,
            scale: isLoading ? 0.96 : 1,
            child: AnimatedContainer(
              duration: _kAnimDuration,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(
                  alpha: isLoading ? 0.55 : 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          context.t.welcomeBack,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 8),
        Text(
          context.t.signInToYourAccount,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }

  Widget _buildFormSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _shakeController,
          child: Column(
            children: [
              _FocusReactiveField(
                focusNode: _emailFocusNode,
                child: AppTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  hintText: context.t.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.t.pleaseEnterEmail;
                    }
                    final email = value.trim();
                    final isEmailValid = _kEmailRegex.hasMatch(email);
                    if (!isEmailValid) {
                      return context.t.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FocusReactiveField(
                focusNode: _passwordFocusNode,
                child: AppTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hintText: context.t.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.t.pleaseEnterPassword;
                    }
                    if (value.length < 6) {
                      return context.t.passwordAtLeastSix;
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeOffset.value, 0),
              child: child,
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : () {},
            child: Text(context.t.forgotPassword),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final targetWidth = isLoading ? 58.0 : constraints.maxWidth;
            return Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: _kAnimDuration,
                curve: Curves.easeInOutCubic,
                width: targetWidth,
                height: 54,
                child: FilledButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Padding(
                            key: const ValueKey('label'),
                            padding: const EdgeInsets.all(16),
                            child: Text(context.t.login),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.t.orContinueWith,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              onTap: isLoading
                  ? () {}
                  : () => context.read<AuthBloc>().add(GoogleSignInRequested()),
              label: context.t.tr('Google', 'ហ្គូហ្គល'),
            ),
            _SocialButton(
              icon: Icons.apple,
              onTap: () {},
              label: context.t.tr('Apple', 'អាប់ផែល'),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t.dontHaveAccount,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.pushNamed(RouteNames.register),
              child: Text(context.t.signUp),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.12),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  current is AuthFailure || current is Authenticated,
              buildWhen: (previous, current) {
                final wasLoading = previous is AuthLoading;
                final isLoading = current is AuthLoading;
                return wasLoading != isLoading ||
                    current is AuthFailure ||
                    current is AuthInitial ||
                    current is Unauthenticated;
              },
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else if (state is Authenticated) {
                  context.goNamed(RouteNames.chat);
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                final centerHeaderOnWide =
                    context.isTablet && context.isLandscape;
                final isWideLayout =
                    context.isTablet ||
                    context.isDesktop ||
                    (context.isLandscape && context.screenWidth >= 700);
                final maxContentWidth = context.adaptive<double>(
                  phone: 560,
                  tablet: 980,
                  desktop: 1200,
                );
                final horizontalPadding = context.adaptiveOrientation<double>(
                  phonePortrait: 24,
                  phoneLandscape: 32,
                  tabletPortrait: 40,
                  tabletLandscape: 56,
                  desktopPortrait: 80,
                  desktopLandscape: 120,
                );

                return Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: isWideLayout
                            ? Row(
                                crossAxisAlignment: centerHeaderOnWide
                                    ? CrossAxisAlignment.center
                                    : CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: centerHeaderOnWide ? 0 : 24,
                                        right: 24,
                                      ),
                                      child: _buildHeaderSection(
                                        theme,
                                        colorScheme,
                                        isLoading,
                                        isWideLayout: true,
                                        centerContent: centerHeaderOnWide,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface.withValues(
                                          alpha: 0.92,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: _buildFormSection(
                                          theme,
                                          colorScheme,
                                          isLoading,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 20),
                                  _buildHeaderSection(
                                    theme,
                                    colorScheme,
                                    isLoading,
                                    isWideLayout: false,
                                    centerContent: false,
                                  ),
                                  const SizedBox(height: 32),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface.withValues(
                                        alpha: 0.92,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        20,
                                        20,
                                        8,
                                      ),
                                      child: _buildFormSection(
                                        theme,
                                        colorScheme,
                                        isLoading,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusReactiveField extends StatelessWidget {
  final FocusNode focusNode;
  final Widget child;

  const _FocusReactiveField({required this.focusNode, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: focusNode,
      child: child,
      builder: (context, child) {
        final hasFocus = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  const _SocialButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }
}
