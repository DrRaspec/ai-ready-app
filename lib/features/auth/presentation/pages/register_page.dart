import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/core/routers/route_names.dart';
import 'package:ai_chat_bot/core/widgets/app_text_field.dart';
import 'package:ai_chat_bot/features/auth/data/register_request_data.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_kit/flutter_adaptive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const _kAnimDuration = Duration(milliseconds: 260);
  static final _kEmailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
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
    final registerData = RegisterRequestData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    context.read<AuthBloc>().add(
      RegisterFormSubmitted(registerRequestData: registerData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
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
                final horizontalPadding = context.adaptiveOrientation<double>(
                  phonePortrait: 24,
                  phoneLandscape: 28,
                  tabletPortrait: 40,
                  tabletLandscape: 56,
                  desktopPortrait: 80,
                  desktopLandscape: 120,
                );
                final maxContentWidth = context.adaptive<double>(
                  phone: 560,
                  tablet: 760,
                  desktop: 840,
                );

                return Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: AnimatedScale(
                                    duration: _kAnimDuration,
                                    scale: isLoading ? 0.96 : 1,
                                    child: AnimatedContainer(
                                      duration: _kAnimDuration,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withValues(
                                              alpha: isLoading ? 0.55 : 0.3,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 40,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  context.t.createAccount,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.t.joinToStartChatting,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                AnimatedBuilder(
                                  animation: _shakeController,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _FocusReactiveField(
                                              focusNode: _firstNameFocusNode,
                                              child: AppTextField(
                                                controller:
                                                    _firstNameController,
                                                focusNode: _firstNameFocusNode,
                                                hintText: context.t.firstName,
                                                keyboardType:
                                                    TextInputType.name,
                                                textInputAction:
                                                    TextInputAction.next,
                                                enabled: !isLoading,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return context.t.requiredField;
                                                  }
                                                  return null;
                                                },
                                                onSubmitted: (_) =>
                                                    _lastNameFocusNode
                                                        .requestFocus(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _FocusReactiveField(
                                              focusNode: _lastNameFocusNode,
                                              child: AppTextField(
                                                controller: _lastNameController,
                                                focusNode: _lastNameFocusNode,
                                                hintText: context.t.lastName,
                                                keyboardType:
                                                    TextInputType.name,
                                                textInputAction:
                                                    TextInputAction.next,
                                                enabled: !isLoading,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return context.t.requiredField;
                                                  }
                                                  return null;
                                                },
                                                onSubmitted: (_) =>
                                                    _emailFocusNode
                                                        .requestFocus(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _FocusReactiveField(
                                        focusNode: _emailFocusNode,
                                        child: AppTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          hintText: context.t.emailAddress,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          enabled: !isLoading,
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return context.t.pleaseEnterEmail;
                                            }
                                            if (!_kEmailRegex.hasMatch(
                                              value.trim(),
                                            )) {
                                              return context.t
                                                  .pleaseEnterValidEmail;
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) =>
                                              _passwordFocusNode.requestFocus(),
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
                                          textInputAction: TextInputAction.next,
                                          enabled: !isLoading,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return context.t
                                                  .pleaseEnterPassword;
                                            }
                                            if (value.length < 8) {
                                              return context.t.minEightCharacters;
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) =>
                                              _confirmPasswordFocusNode
                                                  .requestFocus(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _FocusReactiveField(
                                        focusNode: _confirmPasswordFocusNode,
                                        child: AppTextField(
                                          controller:
                                              _confirmPasswordController,
                                          focusNode: _confirmPasswordFocusNode,
                                          hintText: context.t.confirmPassword,
                                          obscureText: _obscureConfirmPassword,
                                          textInputAction: TextInputAction.done,
                                          enabled: !isLoading,
                                          prefixIcon: const Icon(
                                            Icons.lock_clock_outlined,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return context.t
                                                  .pleaseConfirmPassword;
                                            }
                                            if (value !=
                                                _passwordController.text) {
                                              return context.t
                                                  .passwordsDoNotMatch;
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) => _handleRegister(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
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
                                const SizedBox(height: 32),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final targetWidth = isLoading
                                        ? 58.0
                                        : constraints.maxWidth;
                                    return Align(
                                      alignment: Alignment.center,
                                      child: AnimatedContainer(
                                        duration: _kAnimDuration,
                                        curve: Curves.easeInOutCubic,
                                        width: targetWidth,
                                        height: 54,
                                        child: FilledButton(
                                          onPressed: isLoading
                                              ? null
                                              : _handleRegister,
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            transitionBuilder:
                                                (child, animation) =>
                                                    FadeTransition(
                                                      opacity: animation,
                                                      child: ScaleTransition(
                                                        scale: animation,
                                                        child: child,
                                                      ),
                                                    ),
                                            child: isLoading
                                                ? SizedBox(
                                                    key: const ValueKey(
                                                      'loading',
                                                    ),
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                          color: colorScheme
                                                              .onPrimary,
                                                        ),
                                                  )
                                                : Padding(
                                                    key: const ValueKey('label'),
                                                    padding: const EdgeInsets.all(
                                                      16.0,
                                                    ),
                                                    child: Text(
                                                      context.t.createAccount,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.t.alreadyHaveAccount,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => context.pop(),
                                      child: Text(context.t.signIn),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
