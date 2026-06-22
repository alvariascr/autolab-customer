import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/autolab_customer.dart';
import '../../l10n/app_localizations.dart';
import '../auth/application/auth_session_cubit.dart';

class CustomerOnboardingPage extends StatefulWidget {
  const CustomerOnboardingPage({super.key});

  @override
  State<CustomerOnboardingPage> createState() => _CustomerOnboardingPageState();
}

class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> {
  int _currentPage = 0;

  void _handleStart() {
    context.read<AuthSessionCubit>().markCustomerOnboardingSeen();
    context.go('/home-customer');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = _buildSlides(l10n);
    final size = MediaQuery.sizeOf(context);
    final isCompactHeight = size.height < 720;
    final horizontalPadding = size.width < 360 ? 22.0 : 28.0;
    final verticalPadding = isCompactHeight ? 18.0 : 28.0;
    final buttonHeight = isCompactHeight ? 50.0 : 56.0;
    final buttonBottomGap = isCompactHeight ? 18.0 : 28.0;
    final bottomPadding = isCompactHeight ? 14.0 : 24.0;

    return Scaffold(
      backgroundColor: AutolabCustomer.authBackgroundColor(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: CarouselSlider.builder(
              itemCount: slides.length,
              itemBuilder: (context, index, realIndex) {
                return _OnboardingSlideView(
                  slide: slides[index],
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                );
              },
              options: CarouselOptions(
                height: size.height,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 2),
                autoPlayAnimationDuration: const Duration(milliseconds: 450),
                enableInfiniteScroll: false,
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  setState(() => _currentPage = index);
                },
              ),
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: bottomPadding,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _handleStart,
                      style: AutolabCustomer.primaryButton.copyWith(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.customerOnboardingStartAction,
                        style: AutolabCustomer.h3.copyWith(
                          color: AutolabCustomer.white,
                          fontSize: isCompactHeight ? 16 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: buttonBottomGap),
                  _OnboardingDots(
                    count: slides.length,
                    activeIndex: _currentPage,
                  ),
                  SizedBox(height: isCompactHeight ? 12 : 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_OnboardingSlide> _buildSlides(AppLocalizations l10n) {
    return [
      _OnboardingSlide(
        title: l10n.customerOnboardingSlideVehicleTitle,
        subtitle: l10n.customerOnboardingSlideVehicleSubtitle,
        imagePath: 'assets/images/onboarding/onboarding_1.png',
      ),
      _OnboardingSlide(
        title: l10n.customerOnboardingSlideBookingTitle,
        subtitle: l10n.customerOnboardingSlideBookingSubtitle,
        imagePath: 'assets/images/onboarding/onboarding_2.png',
      ),
      _OnboardingSlide(
        title: l10n.customerOnboardingSlideSearchTitle,
        subtitle: l10n.customerOnboardingSlideSearchSubtitle,
        imagePath: 'assets/images/onboarding/onboarding_3.png',
      ),
      _OnboardingSlide(
        title: l10n.customerOnboardingSlideOrganizedTitle,
        subtitle: l10n.customerOnboardingSlideOrganizedSubtitle,
        imagePath: 'assets/images/onboarding/onboarding_4.png',
      ),
    ];
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final _OnboardingSlide slide;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompactHeight = size.height < 720;
    final isNarrow = size.width < 360;
    final titleSize = isNarrow
        ? 28.0
        : isCompactHeight
        ? 30.0
        : 34.0;
    final subtitleSize = isCompactHeight ? 15.0 : 17.0;
    final topGap = isCompactHeight ? 44.0 : 72.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            slide.imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AutolabCustomer.secondary.withValues(alpha: 0.34),
                  AutolabCustomer.secondary.withValues(alpha: 0.08),
                  AutolabCustomer.secondary.withValues(alpha: 0.42),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding + topGap,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: AutolabCustomer.display.copyWith(
                    color: AutolabCustomer.white,
                    fontSize: titleSize,
                    height: 1.16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 10 : 14),
                Text(
                  slide.subtitle,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.white,
                    fontSize: subtitleSize,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final isCompactHeight = MediaQuery.sizeOf(context).height < 720;
    final activeSize = isCompactHeight ? 12.0 : 14.0;
    final inactiveSize = isCompactHeight ? 10.0 : 12.0;
    final dotMargin = isCompactHeight ? 9.0 : 12.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? activeSize : inactiveSize,
          height: isActive ? activeSize : inactiveSize,
          margin: EdgeInsets.symmetric(horizontal: dotMargin),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AutolabCustomer.primary
                : AutolabCustomer.authInputFillColor(context),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final String imagePath;
}
